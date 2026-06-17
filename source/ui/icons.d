module ui.icons;

import raylib;

// All icons drawn with 1.5px clean lines.
// Colors and alpha should be pre-multiplied by caller.

void iconPlay(float cx, float cy, float size, Color color) {
    float hSize = size * 0.4f;
    Vector2 v1 = Vector2(cx - hSize * 0.5f, cy - hSize);
    Vector2 v2 = Vector2(cx - hSize * 0.5f, cy + hSize);
    Vector2 v3 = Vector2(cx + hSize, cy);
    // DrawTriangle points must be counter-clockwise!
    DrawTriangle(v1, v2, v3, color);
}

void iconPause(float cx, float cy, float size, Color color) {
    float hSize = size * 0.35f;
    float w = size * 0.2f;
    DrawRectangleRec(Rectangle(cx - hSize, cy - hSize, w, hSize * 2.0f), color);
    DrawRectangleRec(Rectangle(cx + hSize - w, cy - hSize, w, hSize * 2.0f), color);
}

void iconPrev(float cx, float cy, float size, Color color) {
    float hSize = size * 0.35f;
    // Triangle pointing left
    Vector2 v1 = Vector2(cx + hSize, cy - hSize);
    Vector2 v2 = Vector2(cx - hSize + 2.0f, cy);
    Vector2 v3 = Vector2(cx + hSize, cy + hSize);
    DrawTriangle(v1, v2, v3, color);
    // Left bar
    DrawRectangleRec(Rectangle(cx - hSize - 2.0f, cy - hSize, 2.0f, hSize * 2.0f), color);
}

void iconNext(float cx, float cy, float size, Color color) {
    float hSize = size * 0.35f;
    // Triangle pointing right
    Vector2 v1 = Vector2(cx - hSize, cy - hSize);
    Vector2 v2 = Vector2(cx - hSize, cy + hSize);
    Vector2 v3 = Vector2(cx + hSize - 2.0f, cy);
    DrawTriangle(v1, v2, v3, color);
    // Right bar
    DrawRectangleRec(Rectangle(cx + hSize, cy - hSize, 2.0f, hSize * 2.0f), color);
}

void iconVolumeHigh(float cx, float cy, float size, Color color) {
    float hSize = size * 0.3f;
    drawSpeakerCone(cx - 2.0f, cy, hSize, color);
    DrawRing(Vector2(cx - 2.0f, cy), hSize * 1.2f, hSize * 1.2f + 1.5f, -45.0f, 45.0f, 16, color);
    DrawRing(Vector2(cx - 2.0f, cy), hSize * 1.8f, hSize * 1.8f + 1.5f, -45.0f, 45.0f, 16, color);
}

void iconVolumeLow(float cx, float cy, float size, Color color) {
    float hSize = size * 0.3f;
    drawSpeakerCone(cx - 2.0f, cy, hSize, color);
    DrawRing(Vector2(cx - 2.0f, cy), hSize * 1.2f, hSize * 1.2f + 1.5f, -45.0f, 45.0f, 16, color);
}

void iconVolumeMuted(float cx, float cy, float size, Color color) {
    float hSize = size * 0.3f;
    drawSpeakerCone(cx - 4.0f, cy, hSize, color);
    float xx = cx + hSize;
    DrawLineEx(Vector2(xx - 3.0f, cy - 3.0f), Vector2(xx + 3.0f, cy + 3.0f), 1.5f, color);
    DrawLineEx(Vector2(xx + 3.0f, cy - 3.0f), Vector2(xx - 3.0f, cy + 3.0f), 1.5f, color);
}

private void drawSpeakerCone(float cx, float cy, float size, Color color) {
    float bodyW = size * 0.6f;
    float bodyH = size * 0.8f;
    DrawRectangleRec(Rectangle(cx - size, cy - bodyH * 0.5f, bodyW, bodyH), color);
    
    Vector2 v1 = Vector2(cx - size + bodyW, cy - bodyH * 0.5f);
    Vector2 v2 = Vector2(cx - size + bodyW, cy + bodyH * 0.5f);
    Vector2 v3 = Vector2(cx + size * 0.4f, cy + size);
    Vector2 v4 = Vector2(cx + size * 0.4f, cy - size);
    // Draw polygon for cone
    DrawTriangle(v1, v2, v3, color);
    DrawTriangle(v1, v3, v4, color);
}
