module viz.ripples;

import raylib;
import viz.engine;
import ui.theme;

private enum int MAX_RIPPLES = 20;

private struct Ripple {
    float x;
    float y;
    float radius;
    float maxRadius;
    float speed;
    float opacity;
    bool active;
}

private __gshared Ripple[MAX_RIPPLES] gRipples;

void ripplesRender(float w, float h, float time, bool isOnset, float bassEnergy) {
    float coverSize = cast(float)COVER_SIZE;
    float controlAreaH = cast(float)CONTROL_AREA_HEIGHT;
    float cx = cast(float)COVER_MARGIN_LEFT + coverSize * 0.5f;
    float cy = h - controlAreaH - cast(float)COVER_MARGIN_BOTTOM - coverSize * 0.5f;
    
    if (isOnset) {
        for (int i = 0; i < MAX_RIPPLES; i++) {
            if (!gRipples[i].active) {
                gRipples[i].x = cx;
                gRipples[i].y = cy;
                gRipples[i].radius = coverSize * 0.5f;
                gRipples[i].maxRadius = 300.0f + bassEnergy * 800.0f;
                gRipples[i].speed = 100.0f + bassEnergy * 300.0f;
                gRipples[i].opacity = 1.0f;
                gRipples[i].active = true;
                break; // spawn only one per onset
            }
        }
    }
    
    float dt = GetFrameTime();
    Color baseCol = vizGetPrimaryColor(bassEnergy);
    
    for (int i = 0; i < MAX_RIPPLES; i++) {
        if (!gRipples[i].active) continue;
        
        gRipples[i].radius += gRipples[i].speed * dt;
        gRipples[i].opacity = 1.0f - (gRipples[i].radius / gRipples[i].maxRadius);
        
        if (gRipples[i].opacity <= 0.01f || gRipples[i].radius >= gRipples[i].maxRadius) {
            gRipples[i].active = false;
            continue;
        }
        
        Color col = Color(baseCol.r, baseCol.g, baseCol.b, cast(ubyte)(gRipples[i].opacity * 255.0f));
        DrawRingLines(Vector2(gRipples[i].x, gRipples[i].y), 
                      gRipples[i].radius, gRipples[i].radius + 1.0f, 
                      0.0f, 360.0f, 60, col);
    }
}

void ripplesShutdown() {
    for (int i = 0; i < MAX_RIPPLES; i++) {
        gRipples[i].active = false;
    }
}

// DrawRingLines is missing from some raylib-d versions, if so implement manually:
private void DrawRingLines(Vector2 center, float innerRadius, float outerRadius, float startAngle, float endAngle, int segments, Color color) {
    import core.stdc.math : sin, cos;
    float step = (endAngle - startAngle) / cast(float)segments;
    float radStart = startAngle * 3.14159f / 180.0f;
    float radStep = step * 3.14159f / 180.0f;
    
    for (int i = 0; i < segments; i++) {
        float a1 = radStart + cast(float)i * radStep;
        float a2 = radStart + cast(float)(i + 1) * radStep;
        
        Vector2 p1 = Vector2(center.x + cos(a1) * innerRadius, center.y + sin(a1) * innerRadius);
        Vector2 p2 = Vector2(center.x + cos(a2) * innerRadius, center.y + sin(a2) * innerRadius);
        DrawLineEx(p1, p2, 1.0f, color);
        
        Vector2 p3 = Vector2(center.x + cos(a1) * outerRadius, center.y + sin(a1) * outerRadius);
        Vector2 p4 = Vector2(center.x + cos(a2) * outerRadius, center.y + sin(a2) * outerRadius);
        DrawLineEx(p3, p4, 1.0f, color);
    }
}
