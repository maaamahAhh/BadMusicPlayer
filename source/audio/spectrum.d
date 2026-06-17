module audio.spectrum;

import core.stdc.math : sinf, cosf, sqrtf, logf, expf, atan2f, fabsf;

nothrow @nogc:

enum FFT_SIZE = 2048;
enum NUM_BINS = 128;
enum SMOOTHING_NEW = 0.7f;
enum SMOOTHING_PREV = 0.3f;
enum ONSET_THRESHOLD = 1.5f;

private enum PI = 3.14159265358979323846f;

struct SpectrumData {
    float[NUM_BINS] spectrum = 0;
    float energy = 0.0f;
    float bassEnergy = 0.0f;
    bool isOnset = false;
}

private __gshared float[NUM_BINS] prevSpectrum = 0;
private __gshared float prevEnergy = 0.0f;
private __gshared float[FFT_SIZE] fftReal = 0;
private __gshared float[FFT_SIZE] fftImag = 0;
private __gshared SpectrumData gLatestSpectrum;

SpectrumData spectrumGetData() {
    return gLatestSpectrum;
}

extern(C) void spectrumAudioCallback(void* bufferData, uint frames) nothrow {
    const(float)* samples = cast(const(float)*)bufferData;
    // Raylib audio streams are typically 32-bit float, 2 channels.
    // We pass frames * 2 because of stereo.
    gLatestSpectrum = analyzeSpectrum(samples, frames * 2);
}

SpectrumData analyzeSpectrum(const(float)* samples, int sampleCount) {
    SpectrumData result;

    if (samples is null || sampleCount <= 0)
        return result;

    int n = (sampleCount < FFT_SIZE) ? sampleCount : FFT_SIZE;
    applyHannWindow(samples, n);
    fft();
    computeLogBins(&result);
    smoothSpectrum(&result);
    computeEnergy(&result);
    detectOnset(&result);

    return result;
}

private void applyHannWindow(const(float)* samples, int n) {
    for (int i = 0; i < n; i++) {
        float window = 0.5f * (1.0f - cosf(2.0f * PI * cast(float) i / cast(float)(n - 1)));
        fftReal[i] = samples[i] * window;
        fftImag[i] = 0.0f;
    }
    for (int i = n; i < FFT_SIZE; i++) {
        fftReal[i] = 0.0f;
        fftImag[i] = 0.0f;
    }
}

private void fft() {
    bitReverse();
    cooleyTukey();
}

private void bitReverse() {
    int n = FFT_SIZE;
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
        if (i < j) {
            float tr = fftReal[i];
            float ti = fftImag[i];
            fftReal[i] = fftReal[j];
            fftImag[i] = fftImag[j];
            fftReal[j] = tr;
            fftImag[j] = ti;
        }
        int k = n >> 1;
        while (k <= j) {
            j -= k;
            k >>= 1;
        }
        j += k;
    }
}

private void cooleyTukey() {
    int n = FFT_SIZE;
    int step = 1;
    while (step < n) {
        int halfStep = step;
        step <<= 1;
        float angleStep = -PI / cast(float) halfStep;

        for (int group = 0; group < halfStep; group++) {
            float angle = angleStep * cast(float) group;
            float wr = cosf(angle);
            float wi = sinf(angle);

            int j = group;
            while (j < n) {
                int k = j + halfStep;
                float tr = wr * fftReal[k] - wi * fftImag[k];
                float ti = wr * fftImag[k] + wi * fftReal[k];
                fftReal[k] = fftReal[j] - tr;
                fftImag[k] = fftImag[j] - ti;
                fftReal[j] += tr;
                fftImag[j] += ti;
                j += step;
            }
        }
    }
}

private void computeLogBins(SpectrumData* data) {
    int halfSize = FFT_SIZE / 2;
    float minFreq = 1.0f;
    float maxFreq = cast(float) halfSize;
    float logMin = logf(minFreq);
    float logMax = logf(maxFreq);

    for (int bin = 0; bin < NUM_BINS; bin++) {
        float t0 = cast(float) bin / cast(float) NUM_BINS;
        float t1 = cast(float)(bin + 1) / cast(float) NUM_BINS;
        int lo = cast(int) expf(logMin + t0 * (logMax - logMin));
        int hi = cast(int) expf(logMin + t1 * (logMax - logMin));

        if (lo < 1) lo = 1;
        if (hi >= halfSize) hi = halfSize - 1;
        if (hi < lo) hi = lo;

        float sum = 0.0f;
        int count = 0;
        for (int i = lo; i <= hi; i++) {
            float mag = sqrtf(fftReal[i] * fftReal[i] + fftImag[i] * fftImag[i]);
            sum += mag;
            count++;
        }
        data.spectrum[bin] = (count > 0) ? (sum / cast(float) count) : 0.0f;
    }
}

private void smoothSpectrum(SpectrumData* data) {
    for (int i = 0; i < NUM_BINS; i++) {
        data.spectrum[i] = SMOOTHING_NEW * data.spectrum[i] + SMOOTHING_PREV * prevSpectrum[i];
        prevSpectrum[i] = data.spectrum[i];
    }
}

private void computeEnergy(SpectrumData* data) {
    enum BASS_BINS = 16;
    float total = 0.0f;
    float bass = 0.0f;

    for (int i = 0; i < NUM_BINS; i++) {
        total += data.spectrum[i] * data.spectrum[i];
        if (i < BASS_BINS)
            bass += data.spectrum[i] * data.spectrum[i];
    }

    data.energy = sqrtf(total / cast(float) NUM_BINS);
    data.bassEnergy = sqrtf(bass / cast(float) BASS_BINS);
}

private void detectOnset(SpectrumData* data) {
    bool onset = false;
    if (prevEnergy > 0.001f) {
        float ratio = data.energy / prevEnergy;
        onset = ratio > ONSET_THRESHOLD;
    }
    data.isOnset = onset;
    prevEnergy = data.energy;
}

void resetSpectrum() {
    for (int i = 0; i < NUM_BINS; i++)
        prevSpectrum[i] = 0.0f;
    prevEnergy = 0.0f;
}
