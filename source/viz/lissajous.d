module viz.lissajous;

import raylib;
import viz.engine;
import audio.spectrum;
import core.stdc.stdlib : malloc, free;
import core.stdc.math : sin, cos;

private enum int MAX_TRAIL = 300;

private struct LissajousPoint {
    float x;
    float y;
    float age; // 0.0 to 1.0 (1.0 = dead)
}

private __gshared LissajousPoint* gTrail = null;
private __gshared int gHead = 0;
private __gshared bool gInit = false;

private void initLissajous() {
    if (gInit) return;
    gTrail = cast(LissajousPoint*)malloc(LissajousPoint.sizeof * MAX_TRAIL);
    if (gTrail !is null) {
        for (int i = 0; i < MAX_TRAIL; i++) {
            gTrail[i].age = 1.0f;
        }
    }
    gInit = true;
}

void lissajousRender(float w, float h, float time, float energy) {
    if (!gInit) initLissajous();
    if (gTrail is null) return;
    
    auto sd = spectrumGetData();
    
    // Sum low and high bins for left/right mapping
    float leftVal = 0.0f;
    float rightVal = 0.0f;
    for (int i = 0; i < 32; i++) leftVal += sd.spectrum[i];
    for (int i = 32; i < 96; i++) rightVal += sd.spectrum[i];
    leftVal *= 0.1f;
    rightVal *= 0.1f;
    
    float cx = w * 0.65f;
    float cy = h * 0.40f;
    
    float baseSize = 80.0f + energy * 600.0f;
    float posX = cx + sin(time * 3.0f + leftVal * 10.0f) * baseSize * (0.3f + leftVal * 2.0f);
    float posY = cy + cos(time * 2.0f + rightVal * 10.0f) * baseSize * (0.3f + rightVal * 2.0f);
    
    // Age existing points
    float dt = GetFrameTime();
    float ageStep = dt / 2.5f; // 2.5s fade
    for (int i = 0; i < MAX_TRAIL; i++) {
        if (gTrail[i].age < 1.0f) {
            gTrail[i].age += ageStep;
        }
    }
    
    // Add new point
    gTrail[gHead].x = posX;
    gTrail[gHead].y = posY;
    gTrail[gHead].age = 0.0f;
    gHead = (gHead + 1) % MAX_TRAIL;
    
    Color baseCol = vizGetPrimaryColor(energy);
    
    // Draw trail
    int prevIdx = -1;
    for (int i = 0; i < MAX_TRAIL; i++) {
        int idx = (gHead + i) % MAX_TRAIL;
        if (gTrail[idx].age >= 1.0f) continue;
        
        if (prevIdx != -1) {
            float alpha = 1.0f - gTrail[idx].age;
            Color col = Color(baseCol.r, baseCol.g, baseCol.b, cast(ubyte)(baseCol.a * alpha));
            DrawLineEx(Vector2(gTrail[prevIdx].x, gTrail[prevIdx].y), 
                       Vector2(gTrail[idx].x, gTrail[idx].y), 1.5f, col);
        }
        prevIdx = idx;
    }
}

void lissajousShutdown() {
    if (gTrail !is null) {
        free(gTrail);
        gTrail = null;
    }
    gInit = false;
}
