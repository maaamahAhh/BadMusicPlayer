module viz.vizspectrum;

import raylib;
import viz.engine;
import audio.spectrum;
import ui.theme;

private enum int NUM_BARS = 96;

void vizSpectrumRender(float w, float h, float time, float energy) {
    auto sd = spectrumGetData();
    
    float controlAreaH = cast(float)CONTROL_AREA_HEIGHT;
    float baseY = h - controlAreaH - 4.0f;
    
    float barWidthFull = w / cast(float)NUM_BARS;
    float barWidth = barWidthFull * 0.7f; // 30% gap
    
    Color baseCol = vizGetPrimaryColor(energy);
    Color barCol = Color(baseCol.r, baseCol.g, baseCol.b, cast(ubyte)(baseCol.a * 0.79f)); // 79% opacity
    
    for (int i = 0; i < NUM_BARS; i++) {
        // Map 96 bars to 128 spectrum bins (simple stretch)
        int bin = cast(int)((cast(float)i / NUM_BARS) * 128.0f);
        if (bin >= 128) bin = 127;
        
        float specVal = sd.spectrum[bin];
        float barH = specVal * h * 0.4f;
        
        if (barH > 0.5f) {
            float x = cast(float)i * barWidthFull + (barWidthFull - barWidth) * 0.5f;
            float y = baseY - barH;
            
            // Draw gradient line
            DrawLineEx(Vector2(x, y), Vector2(x, baseY), barWidth, barCol);
        }
    }
}
