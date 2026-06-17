module audio.metadata;

import core.stdc.stdio : FILE, fopen, fread, fseek, ftell, fclose, SEEK_SET, SEEK_END, SEEK_CUR;
import core.stdc.stdlib : malloc, free;
import core.stdc.string : memcpy, strncmp, strlen;

struct SongMetadata {
    char[256] title;
    char[256] artist;
    char[256] album;
    
    ubyte* coverData = null;
    int coverDataSize = 0;
}

private uint readSynchsafe(ubyte[4] bytes) {
    return (bytes[0] << 21) | (bytes[1] << 14) | (bytes[2] << 7) | bytes[3];
}

private uint readU32BE(ubyte[4] bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
}

private uint readU32LE(ubyte* data) {
    return (cast(uint)data[3] << 24) | (cast(uint)data[2] << 16) |
           (cast(uint)data[1] << 8)  | cast(uint)data[0];
}

void extractMetadata(const(char)* filepath, SongMetadata* meta) {
    meta.title[0] = '\0';
    meta.artist[0] = '\0';
    meta.album[0] = '\0';
    if (meta.coverData) { free(meta.coverData); meta.coverData = null; }
    meta.coverDataSize = 0;

    FILE* f = fopen(filepath, "rb");
    if (!f) return;
    scope(exit) fclose(f);

    ubyte[10] header;
    if (fread(header.ptr, 1, 10, f) != 10) return;

    if (header[0] == 'I' && header[1] == 'D' && header[2] == '3') {
        parseID3(f, header, meta);
    } else if (header[0] == 'f' && header[1] == 'L' && header[2] == 'a' && header[3] == 'C') {
        parseFLAC(f, meta);
    }
}

// --- ID3v2 ---

private void parseID3(FILE* f, ref ubyte[10] header, SongMetadata* meta) {
    ubyte version_ = header[3];
    uint totalSize = readSynchsafe(header[6 .. 10]);
    uint bytesRead = 0;

    while (bytesRead + 10 <= totalSize) {
        ubyte[10] frameHeader;
        if (fread(frameHeader.ptr, 1, 10, f) != 10) break;
        if (frameHeader[0] == 0) break;
        
        uint frameSize;
        if (version_ >= 4)
            frameSize = readSynchsafe(frameHeader[4 .. 8]);
        else
            frameSize = readU32BE(frameHeader[4 .. 8]);
        
        if (frameSize == 0 || bytesRead + 10 + frameSize > totalSize) break;
        
        if (strncmp(cast(char*)frameHeader, "APIC", 4) == 0 && meta.coverData == null) {
            parseID3Cover(f, frameSize, meta);
        } else if (strncmp(cast(char*)frameHeader, "TIT2", 4) == 0 && meta.title[0] == '\0') {
            parseID3Text(f, frameSize, meta.title.ptr, 256);
        } else if (strncmp(cast(char*)frameHeader, "TPE1", 4) == 0 && meta.artist[0] == '\0') {
            parseID3Text(f, frameSize, meta.artist.ptr, 256);
        } else {
            fseek(f, frameSize, SEEK_CUR);
        }
        
        bytesRead += 10 + frameSize;
    }
}

private void parseID3Cover(FILE* f, uint frameSize, SongMetadata* meta) {
    ubyte* frameData = cast(ubyte*)malloc(frameSize);
    if (!frameData) { fseek(f, frameSize, SEEK_CUR); return; }
    scope(exit) free(frameData);

    fread(frameData, 1, frameSize, f);
    
    int imgStart = -1;
    for (int i = 0; i < cast(int)frameSize - 4; i++) {
        if (frameData[i] == 0xFF && frameData[i+1] == 0xD8 && frameData[i+2] == 0xFF) { imgStart = i; break; }
        if (frameData[i] == 0x89 && frameData[i+1] == 0x50 && frameData[i+2] == 0x4E && frameData[i+3] == 0x47) { imgStart = i; break; }
    }
    
    if (imgStart >= 0) {
        meta.coverDataSize = cast(int)(frameSize - imgStart);
        meta.coverData = cast(ubyte*)malloc(meta.coverDataSize);
        if (meta.coverData) memcpy(meta.coverData, frameData + imgStart, meta.coverDataSize);
    }
}

private void parseID3Text(FILE* f, uint frameSize, char* outBuf, int maxLen) {
    ubyte* frameData = cast(ubyte*)malloc(frameSize);
    if (!frameData) { fseek(f, frameSize, SEEK_CUR); return; }
    scope(exit) free(frameData);

    fread(frameData, 1, frameSize, f);
    extractText(frameData, frameSize, outBuf, maxLen);
}

// --- FLAC ---

private void parseFLAC(FILE* f, SongMetadata* meta) {
    fseek(f, 4, SEEK_SET);
    bool isLast = false;
    while (!isLast) {
        ubyte[4] blockHeader;
        if (fread(blockHeader.ptr, 1, 4, f) != 4) break;
        
        isLast = (blockHeader[0] & 0x80) != 0;
        ubyte blockType = blockHeader[0] & 0x7F;
        uint blockSize = (blockHeader[1] << 16) | (blockHeader[2] << 8) | blockHeader[3];
        
        if (blockSize == 0 || blockSize > 1024 * 1024 * 50) break;
        
        if (blockType == 6 && meta.coverData == null) {
            parseFLACPicture(f, blockSize, meta);
        } else if (blockType == 4) {
            parseFLACVorbisComment(f, blockSize, meta);
        } else {
            fseek(f, blockSize, SEEK_CUR);
        }
    }
}

private void parseFLACPicture(FILE* f, uint blockSize, SongMetadata* meta) {
    ubyte* blockData = cast(ubyte*)malloc(blockSize);
    if (!blockData) { fseek(f, blockSize, SEEK_CUR); return; }
    scope(exit) free(blockData);

    uint actualRead = cast(uint)fread(blockData, 1, blockSize, f);
    uint p = 4;
    if (p + 4 > actualRead) return;
    uint mimeLen = readU32BE(*cast(ubyte[4]*)(blockData + p)); p += 4 + mimeLen;
    if (p + 4 > actualRead) return;
    uint descLen = readU32BE(*cast(ubyte[4]*)(blockData + p)); p += 4 + descLen;
    p += 16;
    if (p + 4 > actualRead) return;
    uint picLen = readU32BE(*cast(ubyte[4]*)(blockData + p)); p += 4;
    if (p + picLen > actualRead) return;
    meta.coverDataSize = cast(int)picLen;
    meta.coverData = cast(ubyte*)malloc(meta.coverDataSize);
    if (meta.coverData) memcpy(meta.coverData, blockData + p, picLen);
}

private void parseFLACVorbisComment(FILE* f, uint blockSize, SongMetadata* meta) {
    ubyte* blockData = cast(ubyte*)malloc(blockSize);
    if (!blockData) { fseek(f, blockSize, SEEK_CUR); return; }
    scope(exit) free(blockData);

    uint actualRead = cast(uint)fread(blockData, 1, blockSize, f);
    if (actualRead <= 8) return;

    uint vendorLength = readU32LE(blockData);
    if (4 + vendorLength + 4 > actualRead) return;
    uint listStart = 4 + vendorLength;
    uint commentCount = readU32LE(blockData + listStart);
    uint p = listStart + 4;

    for (uint i = 0; i < commentCount && p + 4 <= actualRead; i++) {
        uint len = readU32LE(blockData + p);
        p += 4;
        if (p + len > actualRead) break;
        if (len > 6 && strncmp(cast(char*)(blockData + p), "TITLE=", 6) == 0 && meta.title[0] == '\0') {
            uint tlen = len - 6;
            if (tlen > 255) tlen = 255;
            memcpy(meta.title.ptr, blockData + p + 6, tlen);
            meta.title[tlen] = '\0';
        } else if (len > 7 && strncmp(cast(char*)(blockData + p), "ARTIST=", 7) == 0 && meta.artist[0] == '\0') {
            uint tlen = len - 7;
            if (tlen > 255) tlen = 255;
            memcpy(meta.artist.ptr, blockData + p + 7, tlen);
            meta.artist[tlen] = '\0';
        }
        p += len;
    }
}

// --- Text extraction ---

private void extractText(ubyte* frameData, uint frameSize, char* outBuf, int maxLen) {
    if (frameSize < 2) return;
    ubyte encoding = frameData[0];
    uint p = 1;
    uint len = 0;
    
    if (encoding == 0 || encoding == 3) {
        while (p < frameSize && len < maxLen - 1 && frameData[p] != '\0') {
            outBuf[len++] = cast(char)frameData[p++];
        }
    } else if (encoding == 1 || encoding == 2) {
        if (p + 2 <= frameSize) {
            if ((frameData[p] == 0xFF && frameData[p+1] == 0xFE) || 
                (frameData[p] == 0xFE && frameData[p+1] == 0xFF)) {
                p += 2;
            }
        }
        while (p + 1 < frameSize && len < maxLen - 1) {
            char c1 = cast(char)frameData[p];
            char c2 = cast(char)frameData[p+1];
            if (c1 == 0 && c2 == 0) break;
            
            if (c1 != 0) outBuf[len++] = c1;
            else if (c2 != 0) outBuf[len++] = c2;
            
            p += 2;
        }
    }
    outBuf[len] = '\0';
}
