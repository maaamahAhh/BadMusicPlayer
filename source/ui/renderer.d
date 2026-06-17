module ui.renderer;

import raylib;
import ui.theme;
import ui.views;
import viz.engine;
import ui.font;

private __gshared bool gInitialized;

void rendererInit() {
    fontInit();
    themeInit();
    vizEngineInit();
    gInitialized = true;
}

void rendererFrame() {
    if (!gInitialized) return;

    int w = GetScreenWidth();
    int h = GetScreenHeight();
    float fw = cast(float)w;
    float fh = cast(float)h;

    ClearBackground(CANVAS);

    float dt = GetFrameTime();
    vizEngineUpdate(dt);
    vizEngineRender(fw, fh);

    drawTitleBar(fw);
    drawPlayView(fw, fh);
}

void rendererShutdown() {
    vizEngineShutdown();
    fontShutdown();
    gInitialized = false;
}

private void drawTitleBar(float windowWidth) {
    import ui.icons;

    float cy = cast(float)TITLE_BAR_HEIGHT * 0.5f;
    float mx = cast(float)GetMouseX();
    float my = cast(float)GetMouseY();
    bool inTitleBar = my < cast(float)TITLE_BAR_HEIGHT;

    drawTextEx("BadMusicPlayer", 12.0f, cy - FONT_SIZE_APP_NAME * 0.5f, cast(float)FONT_SIZE_APP_NAME, SECONDARY);

    // Close button (×) — hover turns red background
    float closeX = windowWidth - 23.0f;
    bool closeHover = inTitleBar && mx > windowWidth - 46.0f;
    if (closeHover) {
        DrawRectangleRec(Rectangle(windowWidth - 46.0f, 0.0f, 46.0f, cast(float)TITLE_BAR_HEIGHT),
                         Color(232, 17, 35, 51));
    }
    Color closeColor = closeHover ? Color(232, 17, 35, 255) : SECONDARY;
    float crossSize = 5.0f;
    DrawLineEx(Vector2(closeX - crossSize, cy - crossSize), Vector2(closeX + crossSize, cy + crossSize), 1.5f, closeColor);
    DrawLineEx(Vector2(closeX + crossSize, cy - crossSize), Vector2(closeX - crossSize, cy + crossSize), 1.5f, closeColor);

    // Maximize button (□)
    float maxX = windowWidth - 69.0f;
    bool maxHover = inTitleBar && mx > windowWidth - 92.0f && mx <= windowWidth - 46.0f;
    if (maxHover) {
        DrawRectangleRec(Rectangle(windowWidth - 92.0f, 0.0f, 46.0f, cast(float)TITLE_BAR_HEIGHT),
                         Color(255, 255, 255, 20));
    }
    Color maxColor = maxHover ? PRIMARY : SECONDARY;
    DrawRectangleLinesEx(Rectangle(maxX - 5.0f, cy - 5.0f, 10.0f, 10.0f), 1.5f, maxColor);

    // Minimize button (—)
    float minX = windowWidth - 106.0f;
    bool minHover = inTitleBar && mx > windowWidth - 138.0f && mx <= windowWidth - 92.0f;
    if (minHover) {
        DrawRectangleRec(Rectangle(windowWidth - 138.0f, 0.0f, 46.0f, cast(float)TITLE_BAR_HEIGHT),
                         Color(255, 255, 255, 20));
    }
    Color minColor = minHover ? PRIMARY : SECONDARY;
    DrawLineEx(Vector2(minX - 5.0f, cy), Vector2(minX + 5.0f, cy), 1.5f, minColor);
}
