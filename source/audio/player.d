module audio.player;

import raylib;
import core.stdc.stdlib : malloc, free, realloc;
import core.stdc.string : memcpy, strlen, strcmp;
import audio.spectrum;
import platform.win32;

enum PlayState {
    stopped,
    playing,
    paused,
}

enum MAX_TRACKS = 4096;

struct AudioPlayer {
    Music music;
    PlayState state = PlayState.stopped;
    float volume = 0.8f;
    bool loaded = false;
    char* filePath = null;

    // Playlist (same directory)
    char** trackPaths = null;
    int trackCount = 0;
    int trackIndex = -1;
}

private __gshared AudioPlayer player;

void initAudio() {
    InitAudioDevice();
    SetAudioStreamBufferSizeDefault(16384);
    player = AudioPlayer.init;
}

void shutdownAudio() {
    unloadCurrentTrack();
    freePlaylist();
    CloseAudioDevice();
}

void updateAudio() {
    if (player.loaded && player.state == PlayState.playing) {
        UpdateMusicStream(player.music);
    }
}

bool loadAndPlay(const(char)* path) {
    unloadCurrentTrack();
    storeFilePath(path);
    buildPlaylist(path);

    player.music = LoadMusicStream(path);
    if (!IsMusicValid(player.music)) {
        freeFilePath();
        return false;
    }
    AttachAudioStreamProcessor(player.music.stream, &spectrumAudioCallback);
    SetMusicVolume(player.music, player.volume);
    PlayMusicStream(player.music);

    player.loaded = true;
    player.state = PlayState.playing;
    return true;
}

void togglePlayPause() {
    if (!player.loaded) return;

    final switch (player.state) {
        case PlayState.playing:
            PauseMusicStream(player.music);
            player.state = PlayState.paused;
            break;
        case PlayState.paused:
            ResumeMusicStream(player.music);
            player.state = PlayState.playing;
            break;
        case PlayState.stopped:
            PlayMusicStream(player.music);
            player.state = PlayState.playing;
            break;
    }
}

void playNext() {
    if (player.trackCount <= 0) return;
    int next = (player.trackIndex + 1) % player.trackCount;
    loadAndPlay(player.trackPaths[next]);
}

void playPrev() {
    if (player.trackCount <= 0) return;
    int prev = player.trackIndex - 1;
    if (prev < 0) prev = player.trackCount - 1;
    loadAndPlay(player.trackPaths[prev]);
}

void stopPlayback() {
    if (!player.loaded) return;
    StopMusicStream(player.music);
    player.state = PlayState.stopped;
}

void seekTo(float timeSeconds) {
    if (!player.loaded) return;
    SeekMusicStream(player.music, timeSeconds);
}

void setVolume(float vol) {
    player.volume = clampf(vol, 0.0f, 1.0f);
    if (player.loaded) SetMusicVolume(player.music, player.volume);
}

float getVolume() {
    return player.volume;
}

float getTimePlayed() {
    if (!player.loaded) return 0.0f;
    return GetMusicTimePlayed(player.music);
}

float getTimeLength() {
    if (!player.loaded) return 0.0f;
    return GetMusicTimeLength(player.music);
}

PlayState getPlayState() {
    return player.state;
}

bool isLoaded() {
    return player.loaded;
}

const(char)* getFilePath() {
    return player.filePath;
}

private void unloadCurrentTrack() {
    if (!player.loaded) return;
    StopMusicStream(player.music);
    DetachAudioStreamProcessor(player.music.stream, &spectrumAudioCallback);
    UnloadMusicStream(player.music);
    player.loaded = false;
    player.state = PlayState.stopped;
    freeFilePath();
}

private void storeFilePath(const(char)* path) {
    freeFilePath();
    if (path is null) return;

    size_t len = strlen(path);
    player.filePath = cast(char*) malloc(len + 1);
    if (player.filePath !is null)
        memcpy(player.filePath, path, len + 1);
}

private void freeFilePath() {
    if (player.filePath !is null) {
        free(player.filePath);
        player.filePath = null;
    }
}

private bool isAudioExtension(const(char)* filename) {
    int len = cast(int)strlen(filename);
    if (len < 4) return false;
    // Check 4-char extensions: .mp3 .wav .ogg .qoa .mod
    if (len >= 4) {
        const(char)* ext4 = filename + len - 4;
        if (_strnicmp(ext4, ".mp3", 4) == 0 ||
            _strnicmp(ext4, ".wav", 4) == 0 ||
            _strnicmp(ext4, ".ogg", 4) == 0 ||
            _strnicmp(ext4, ".qoa", 4) == 0 ||
            _strnicmp(ext4, ".mod", 4) == 0)
            return true;
    }
    // Check 3-char extensions: .xm
    if (len >= 3) {
        const(char)* ext3 = filename + len - 3;
        if (_strnicmp(ext3, ".xm", 3) == 0)
            return true;
    }
    // Check 5-char extensions: .flac
    if (len >= 5) {
        const(char)* ext5 = filename + len - 5;
        if (_strnicmp(ext5, ".flac", 5) == 0)
            return true;
    }
    return false;
}

private int wideToUtf8(const(wchar)* wide, char* buf, int bufLen) {
    return WideCharToMultiByte(CP_UTF8, 0, wide, -1, buf, bufLen, null, null);
}

private void buildPlaylist(const(char)* path) {
    freePlaylist();
    if (path is null) return;

    // Extract directory from path
    int pathLen = cast(int)strlen(path);
    int lastSlash = -1;
    for (int i = 0; i < pathLen; i++) {
        if (path[i] == '\\' || path[i] == '/') lastSlash = i;
    }
    if (lastSlash < 0) return;

    int dirLen = lastSlash + 1;

    // Build search pattern: dir\*
    wchar[512] searchPattern;
    char[512] utf8Pattern;
    memcpy(utf8Pattern.ptr, path, dirLen);
    utf8Pattern[dirLen] = '*';
    utf8Pattern[dirLen + 1] = '\0';

    // Convert UTF-8 to wide char (MultiByteToWideChar)
    MultiByteToWideChar(CP_UTF8, 0, utf8Pattern.ptr, -1, searchPattern.ptr, 512);

    WIN32_FIND_DATAW findData;
    HANDLE hFind = FindFirstFileW(searchPattern.ptr, &findData);
    if (hFind == INVALID_HANDLE_VALUE)
        return;

    // Allocate track array
    player.trackPaths = cast(char**)malloc(MAX_TRACKS * (char*).sizeof);
    if (player.trackPaths is null) {
        FindClose(hFind);
        return;
    }

    do {
        // Skip directories
        if (findData.cFileName[0] == '.' && (findData.cFileName[1] == '\0' ||
            (findData.cFileName[1] == '.' && findData.cFileName[2] == '\0')))
            continue;

        // Convert wide filename to UTF-8
        char[512] utf8Name;
        int nameLen = wideToUtf8(findData.cFileName.ptr, utf8Name.ptr, 512);
        if (nameLen <= 0) continue;

        if (!isAudioExtension(utf8Name.ptr)) continue;

        // Build full path: dir + filename
        int nameStrLen = cast(int)strlen(utf8Name.ptr);
        int fullPathLen = dirLen + nameStrLen;
        char* fullPath = cast(char*)malloc(fullPathLen + 1);
        if (fullPath is null) continue;
        memcpy(fullPath, path, dirLen);
        memcpy(fullPath + dirLen, utf8Name.ptr, nameStrLen + 1);

        if (player.trackCount < MAX_TRACKS) {
            player.trackPaths[player.trackCount] = fullPath;
            player.trackCount++;
        } else {
            free(fullPath);
        }
    } while (FindNextFileW(hFind, &findData));

    FindClose(hFind);

    // Sort tracks by filename
    sortTracks(dirLen);

    // Find current track index
    player.trackIndex = -1;
    for (int i = 0; i < player.trackCount; i++) {
        if (strcmp(player.trackPaths[i], path) == 0) {
            player.trackIndex = i;
            break;
        }
    }
}

private void sortTracks(int dirLen) {
    // Simple insertion sort by filename (after dir prefix)
    for (int i = 1; i < player.trackCount; i++) {
        char* key = player.trackPaths[i];
        int j = i - 1;
        while (j >= 0 && strcmp(player.trackPaths[j] + dirLen, key + dirLen) > 0) {
            player.trackPaths[j + 1] = player.trackPaths[j];
            j--;
        }
        player.trackPaths[j + 1] = key;
    }
}

private void freePlaylist() {
    if (player.trackPaths !is null) {
        for (int i = 0; i < player.trackCount; i++) {
            if (player.trackPaths[i] !is null)
                free(player.trackPaths[i]);
        }
        free(player.trackPaths);
        player.trackPaths = null;
    }
    player.trackCount = 0;
    player.trackIndex = -1;
}

private float clampf(float val, float lo, float hi) {
    if (val < lo) return lo;
    if (val > hi) return hi;
    return val;
}
