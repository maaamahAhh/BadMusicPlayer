module viz.engine;

import raylib;
import ui.theme;
import audio.spectrum;

// Submodules
import viz.flowlines;
import viz.ripples;
import viz.waveform;
import viz.lissajous;
import viz.vizspectrum;
import viz.radial;

struct VizEngineState {
    bool isInitialized;
    float time;
    float energy;
    float bassEnergy;
    bool isOnset;
}

private __gshared VizEngineState gVizState;

void vizEngineInit() {
    gVizState.isInitialized = true;
    gVizState.time = 0.0f;
    gVizState.energy = 0.0f;
    gVizState.bassEnergy = 0.0f;
    gVizState.isOnset = false;
}

void vizEngineUpdate(float dt) {
    if (!gVizState.isInitialized) return;
    
    gVizState.time += dt;
    
    auto sd = spectrumGetData();
    gVizState.energy = sd.energy;
    gVizState.bassEnergy = sd.bassEnergy;
    gVizState.isOnset = sd.isOnset;
}

void vizEngineRender(float w, float h) {
    if (!gVizState.isInitialized) return;
    
    float time = gVizState.time;
    float energy = gVizState.energy;
    float bassEnergy = gVizState.bassEnergy;
    bool isOnset = gVizState.isOnset;
    
    // Render layers in order from back to front
    flowlinesRender(w, h, time, energy);
    ripplesRender(w, h, time, isOnset, bassEnergy);
    waveformRender(w, h, time, energy);
    radialRender(w, h, time, energy);
    lissajousRender(w, h, time, energy);
    vizSpectrumRender(w, h, time, energy);
}

void vizEngineShutdown() {
    if (!gVizState.isInitialized) return;
    
    flowlinesShutdown();
    ripplesShutdown();
    lissajousShutdown();
    
    gVizState.isInitialized = false;
}

Color vizGetPrimaryColor(float energy) {
    float brightness = 0.3f + energy * 3.0f;
    if (brightness > 1.0f) brightness = 1.0f;
    Color c = themeGetAccent();
    return colorWithAlpha(c, brightness);
}

Color vizGetSecondaryColor(float energy) {
    float brightness = 0.3f + energy * 2.0f;
    if (brightness > 1.0f) brightness = 1.0f;
    Color c = themeGetAccentSecondary();
    return colorWithAlpha(c, brightness);
}

Color vizGetDimColor(float energy) {
    float brightness = 0.2f + energy * 1.5f;
    if (brightness > 0.8f) brightness = 0.8f;
    Color c = themeGetAccentDim();
    return colorWithAlpha(c, brightness);
}
