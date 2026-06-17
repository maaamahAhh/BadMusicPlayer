module viz.flowlines;

import raylib;
import core.stdc.stdlib : malloc, free;
import core.stdc.math : sin, cos, fmod;
import viz.engine;

private enum int NUM_LINES = 200;
private enum int STEPS = 80;

private struct LineState {
    float x;
    float y;
}

private __gshared LineState* gLines = null;
private __gshared bool gFlowInitialized = false;

private void flowInit(float w, float h) {
    if (gFlowInitialized) return;
    gLines = cast(LineState*)malloc(LineState.sizeof * NUM_LINES);
    if (gLines !is null) {
        for (int i = 0; i < NUM_LINES; i++) {
            gLines[i].x = cast(float)GetRandomValue(0, cast(int)w);
            gLines[i].y = cast(float)GetRandomValue(0, cast(int)h);
        }
    }
    gFlowInitialized = true;
}

void flowlinesRender(float w, float h, float time, float energy) {
    if (!gFlowInitialized) flowInit(w, h);
    if (gLines is null) return;
    
    float alpha = 0.15f + energy * 0.25f; // 15% - 40%
    if (alpha > 1.0f) alpha = 1.0f;
    
    Color baseColor = vizGetDimColor(energy);
    Color lineCol = Color(baseColor.r, baseColor.g, baseColor.b, cast(ubyte)(alpha * 255.0f));
    
    float speed = 1.0f + energy * 3.0f;
    float curl = 0.005f + energy * 0.01f;
    
    for (int i = 0; i < NUM_LINES; i++) {
        float cx = gLines[i].x;
        float cy = gLines[i].y;
        
        for (int step = 0; step < STEPS; step++) {
            float angle = sin(cx * curl + time) * 3.14159f + cos(cy * curl - time) * 3.14159f;
            float nx = cx + cos(angle) * speed;
            float ny = cy + sin(angle) * speed;
            
            DrawLineV(Vector2(cx, cy), Vector2(nx, ny), lineCol);
            cx = nx;
            cy = ny;
        }
        
        // Update origin for next frame
        gLines[i].x += speed * 0.5f;
        
        // Wrap
        if (gLines[i].x > w) gLines[i].x = 0.0f;
        if (gLines[i].x < 0.0f) gLines[i].x = w;
        if (gLines[i].y > h) gLines[i].y = 0.0f;
        if (gLines[i].y < 0.0f) gLines[i].y = h;
    }
}

void flowlinesShutdown() {
    if (gLines !is null) {
        free(gLines);
        gLines = null;
    }
    gFlowInitialized = false;
}
