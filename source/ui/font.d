module ui.font;

import raylib;

private __gshared Font gMainFont;
private __gshared bool gFontLoaded;

void fontInit() {
    // Load Windows Segoe UI as an elegant modern font substitute
    gMainFont = LoadFontEx("C:/Windows/Fonts/segoeui.ttf", 32, null, 0);
    SetTextureFilter(gMainFont.texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
    gFontLoaded = true;
}

void fontShutdown() {
    if (gFontLoaded) {
        UnloadFont(gMainFont);
        gFontLoaded = false;
    }
}

Font getFont() {
    if (!gFontLoaded) return GetFontDefault();
    return gMainFont;
}

void drawTextEx(const(char)* text, float x, float y, float fontSize, Color color) {
    if (!gFontLoaded) {
        DrawText(text, cast(int)x, cast(int)y, cast(int)fontSize, color);
        return;
    }
    
    Vector2 pos = Vector2(x, y);
    float spacing = 1.0f;
    DrawTextEx(gMainFont, text, pos, fontSize, spacing, color);
}

float measureTextX(const(char)* text, float fontSize) {
    if (!gFontLoaded) {
        return cast(float)MeasureText(text, cast(int)fontSize);
    }
    Vector2 size = MeasureTextEx(gMainFont, text, fontSize, 1.0f);
    return size.x;
}
