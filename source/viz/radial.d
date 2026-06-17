module viz.radial;

import raylib;
import viz.engine;
import audio.spectrum;
import core.stdc.math : sin, cos;

private enum int NUM_RADIALS = 64;

void radialRender(float w, float h, float time, float energy) {
    auto sd = spectrumGetData();
    
    float cx = w * 0.65f;
    float cy = h * 0.40f;
    
    float innerRadius = 80.0f;
    
    Color baseCol = vizGetSecondaryColor(energy);
    
    float rotation = time * (360.0f / 90.0f); // 90s per revolution
    
    for (int i = 0; i < NUM_RADIALS; i++) {
        // Map to 128 bins
        int bin = cast(int)((cast(float)i / NUM_RADIALS) * 128.0f);
        if (bin >= 128) bin = 127;
        
        float specVal = sd.spectrum[bin];
        float outerRadius = innerRadius + specVal * 400.0f;
        
        if (outerRadius <= innerRadius + 1.0f) continue;
        
        float angleDeg = (cast(float)i / NUM_RADIALS) * 360.0f + rotation;
        float angleRad = angleDeg * 3.14159f / 180.0f;
        
        float alpha = specVal * 2.0f;
        if (alpha > 1.0f) alpha = 1.0f;
        Color col = Color(baseCol.r, baseCol.g, baseCol.b, cast(ubyte)(alpha * 200.0f));
        
        Vector2 start = Vector2(cx + cos(angleRad) * innerRadius, cy + sin(angleRad) * innerRadius);
        Vector2 end = Vector2(cx + cos(angleRad) * outerRadius, cy + sin(angleRad) * outerRadius);
        
        DrawLineEx(start, end, 1.0f, col);
    }
}
