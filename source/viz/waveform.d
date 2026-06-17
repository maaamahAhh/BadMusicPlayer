module viz.waveform;

import raylib;
import viz.engine;
import audio.spectrum;
import core.stdc.math : sin, cos, fabsf;

private enum int WAVE_POINTS = 256;

void waveformRender(float w, float h, float time, float energy) {
    float cy = h * 0.4f;
    float dx = w / cast(float)(WAVE_POINTS - 1);
    
    auto sd = spectrumGetData();
    
    Color baseCol = vizGetPrimaryColor(energy);
    
    Vector2 prevPoint;
    bool hasPrev = false;
    
    float amplitude = 20.0f + energy * 200.0f;
    float fadeZone = w * 0.1f;
    
    for (int i = 0; i < WAVE_POINTS; i++) {
        float x = cast(float)i * dx;
        
        // Sample spectrum circularly for continuous wave look
        int bin = i % 128;
        float specVal = sd.spectrum[bin];
        
        float waveShift = sin(x * 0.01f + time * 2.0f) * 0.5f;
        float y = cy + (specVal * amplitude) * sin(x * 0.05f - time * 5.0f) + waveShift * 50.0f * energy;
        
        // Fade out at edges
        float alphaMult = 1.0f;
        if (x < fadeZone) {
            alphaMult = x / fadeZone;
        } else if (x > w - fadeZone) {
            alphaMult = (w - x) / fadeZone;
        }
        
        Color col = Color(baseCol.r, baseCol.g, baseCol.b, cast(ubyte)(baseCol.a * alphaMult));
        
        Vector2 pt = Vector2(x, y);
        if (hasPrev) {
            DrawLineEx(prevPoint, pt, 2.0f, col);
        }
        prevPoint = pt;
        hasPrev = true;
    }
}
