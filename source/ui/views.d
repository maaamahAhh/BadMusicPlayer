module ui.views;

import raylib;
import ui.theme;
import ui.widgets;
import ui.animation;
import audio.player;
import audio.metadata;
import ui.font;
import core.stdc.string : strlen, strcmp, memcpy, strncpy;

private __gshared ProgressBar gProgressBar;
private __gshared SlideAnim gCoverSlide;
private __gshared char[256] gLastFilePath;
private __gshared bool gViewsInitialized;
private __gshared SongMetadata gCurrentMeta;
private __gshared Texture2D gCoverTexture;
private __gshared bool gHasCoverTexture = false;

void drawPlayView(float windowWidth, float windowHeight) {
    if (!gViewsInitialized) {
        gProgressBar = progressBarCreate();
        gCoverSlide = slideCreate();
        gViewsInitialized = true;
    }

    checkFileChange();
    drawCoverAndInfo(windowWidth, windowHeight);
    drawBottomControls(windowWidth, windowHeight);
}

private void checkFileChange() {
    const(char)* path = getFilePath();
    if (path is null) return;

    bool changed = !isLoaded() || strcmp(gLastFilePath.ptr, path) != 0;

    if (!changed) return;

    strncpy(gLastFilePath.ptr, path, 255);
    gLastFilePath[255] = '\0';

    extractMetadata(path, &gCurrentMeta);
    loadCoverTexture();
    slideTriggerIn(&gCoverSlide, 20.0f);
}

private void loadCoverTexture() {
    if (gHasCoverTexture) {
        UnloadTexture(gCoverTexture);
        gHasCoverTexture = false;
    }
    
    if (gCurrentMeta.coverData == null || gCurrentMeta.coverDataSize <= 0) {
        themeResetAccent();
        return;
    }

    const(char)* imgExt = ".jpg";
    if (gCurrentMeta.coverDataSize >= 4 &&
        gCurrentMeta.coverData[0] == 0x89 &&
        gCurrentMeta.coverData[1] == 0x50 &&
        gCurrentMeta.coverData[2] == 0x4E &&
        gCurrentMeta.coverData[3] == 0x47) {
        imgExt = ".png";
    }
    Image img = LoadImageFromMemory(imgExt, gCurrentMeta.coverData, gCurrentMeta.coverDataSize);
    if (img.data == null) {
        themeResetAccent();
        return;
    }

    Color c1 = GetImageColor(img, img.width / 4, img.height / 4);
    Color c2 = GetImageColor(img, img.width * 3 / 4, img.height * 3 / 4);
    c1.a = 255;
    c2.a = 255;
    if (c1.r < 30 && c1.g < 30 && c1.b < 30) { c1.r += 40; c1.g += 40; c1.b += 40; }
    if (c2.r < 20 && c2.g < 20 && c2.b < 20) { c2.r += 30; c2.g += 30; c2.b += 30; }
    int lum1 = c1.r * 3 + c1.g * 5 + c1.b * 2;
    int lum2 = c2.r * 3 + c2.g * 5 + c2.b * 2;
    Color bright = (lum1 >= lum2) ? c1 : c2;
    Color dark   = (lum1 >= lum2) ? c2 : c1;
    themeSetAccent(bright, colorWithAlpha(bright, 0.7f), dark);
    
    gCoverTexture = LoadTextureFromImage(img);
    UnloadImage(img);
    gHasCoverTexture = true;
}

private void drawCoverAndInfo(float w, float h) {
    if (!isLoaded()) return;

    slideUpdate(&gCoverSlide, GetFrameTime());
    float offsetX = gCoverSlide.offset.current;
    float opacity = gCoverSlide.opacity.current;

    float coverSize = cast(float)COVER_SIZE;
    float coverX = cast(float)COVER_MARGIN_LEFT + offsetX;
    float controlAreaH = cast(float)CONTROL_AREA_HEIGHT;
    float coverY = h - controlAreaH - cast(float)COVER_MARGIN_BOTTOM - coverSize;

    drawCoverPlaceholder(coverX, coverY, coverSize, opacity);
    drawCoverBorder(coverX, coverY, coverSize, opacity);
    drawSongInfo(coverX + coverSize + 16.0f, coverY + 10.0f, opacity);
}

private void drawCoverPlaceholder(float x, float y, float size, float opacity) {
    if (gHasCoverTexture) {
        Color tint = Color(255, 255, 255, cast(ubyte)(opacity * 255.0f));
        Rectangle source = Rectangle(0, 0, cast(float)gCoverTexture.width, cast(float)gCoverTexture.height);
        Rectangle dest = Rectangle(x, y, size, size);
        Vector2 origin = Vector2(0, 0);
        DrawTexturePro(gCoverTexture, source, dest, origin, 0.0f, tint);
    } else {
        Color bg = Color(38, 38, 38, cast(ubyte)(opacity * 255.0f));
        DrawRectangleRec(Rectangle(x, y, size, size), bg);

        Color iconColor = Color(64, 64, 64, cast(ubyte)(opacity * 255.0f));
        float cx = x + size * 0.5f;
        float cy = y + size * 0.5f;
        DrawCircleV(Vector2(cx - 6.0f, cy + 8.0f), 6.0f, iconColor);
        DrawLineEx(Vector2(cx, cy + 8.0f), Vector2(cx, cy - 16.0f), 1.5f, iconColor);
        DrawLineEx(Vector2(cx, cy - 16.0f), Vector2(cx + 12.0f, cy - 12.0f), 1.5f, iconColor);
    }
}

private void drawCoverBorder(float x, float y, float size, float opacity) {
    Color border = BORDER;
    border.a = cast(ubyte)(opacity * cast(float)border.a);
    DrawRectangleLinesEx(Rectangle(x, y, size, size), 1.0f, border);
}

private void drawSongInfo(float x, float y, float opacity) {
    char[256] nameBuf;
    if (gCurrentMeta.title[0] != '\0') {
        int i = 0;
        for (; i < 255 && gCurrentMeta.title[i] != '\0'; i++) nameBuf[i] = gCurrentMeta.title[i];
        nameBuf[i] = '\0';
    } else {
        extractFileName(nameBuf.ptr, 256);
    }

    Color titleColor = colorWithAlpha(PRIMARY, opacity);
    drawTextEx(nameBuf.ptr, x, y, cast(float)FONT_SIZE_TITLE, titleColor);

    Color artistColor = colorWithAlpha(SECONDARY, opacity);
    const(char)* artistStr = gCurrentMeta.artist[0] != '\0' ? gCurrentMeta.artist.ptr : "Unknown Artist";
    drawTextEx(artistStr, x, y + 24.0f, cast(float)FONT_SIZE_ARTIST, artistColor);

    Color metaColor = colorWithAlpha(TERTIARY, opacity);
    const(char)* extStr = "Audio File";
    if (getFilePath() != null) {
        int len = cast(int)strlen(getFilePath());
        if (len > 4 && getFilePath()[len-4] == '.') extStr = getFilePath() + len - 3;
    }
    drawTextEx(extStr, x, y + 44.0f, cast(float)FONT_SIZE_META, metaColor);
}

private void extractFileName(char* buf, int bufLen) {
    const(char)* path = getFilePath();
    if (path is null || path[0] == '\0') {
        const(char)* noFile = "No File";
        memcpy(buf, noFile, 8);
        return;
    }

    int lastSlash = -1;
    for (int i = 0; path[i] != '\0'; i++) {
        if (path[i] == '\\' || path[i] == '/') lastSlash = i;
    }

    const(char)* name = path + (lastSlash + 1);
    int i = 0;
    int lastDot = -1;
    for (; name[i] != '\0' && i < bufLen - 1; i++) {
        buf[i] = name[i];
        if (name[i] == '.') lastDot = i;
    }
    if (lastDot > 0) i = lastDot;
    buf[i] = '\0';
}

private void drawBottomControls(float w, float h) {
    float controlAreaH = cast(float)CONTROL_AREA_HEIGHT;
    float controlY = h - controlAreaH;

    float progressW = w * 0.6f;
    float progressX = (w - progressW) * 0.5f;
    float progressY = controlY + 44.0f; // progress bar lower in the control area

    float progress = 0.0f;
    float duration = getTimeLength();
    if (isLoaded() && duration > 0.0f) {
        progress = getTimePlayed() / duration;
        if (progress > 1.0f) progress = 1.0f;
    }

    gProgressBar = progressBarUpdate(gProgressBar, progressX, progressY, progressW, progress);
    progressBarDraw(&gProgressBar);

    if (gProgressBar.isDragging && isLoaded()) {
        seekTo(gProgressBar.progress * duration);
    }

    float btnY = controlY + 20.0f; // buttons above progress bar
    float centerX = w * 0.5f;
    drawPlayControls(centerX, btnY, getPlayState());

    int clicked = checkPlayControlsClick(centerX, btnY);
    if (clicked == 1) playPrev();
    else if (clicked == 2) togglePlayPause();
    else if (clicked == 3) playNext();

    float currentSec = getTimePlayed();
    float totalSec = duration;
    drawTimeStamps(progressX, progressW, progressY, currentSec, totalSec);
}
