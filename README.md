# BadMusicPlayer

An audio player with 6 visualizations (flowlines, lissajous, radial, ripples, spectrum, waveform) stacked simultaneously. Windows only.

Plays MP3, WAV, OGG, FLAC, XM, MOD, QOA. Extracts cover art and accent colors from file metadata. All visualizations run at once without intensity limits — expect flashing.

## Building

```
dub build -b release
```

## Third-party

`libs/raylib.lib` is a custom build of [raylib](https://github.com/raysan5/raylib) (zlib license) with JPEG and FLAC support enabled.

---

<img width="1280" height="720" alt="image" src="https://github.com/user-attachments/assets/694b052e-02eb-4c7e-aa70-be95407f7203" />
