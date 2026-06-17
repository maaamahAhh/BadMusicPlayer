module ui.widgets;

import raylib;
import ui.theme;
import ui.icons;
import ui.animation;
import audio.player;
import ui.font;

bool isMouseInRect(float mx, float my, float rx, float ry, float rw, float rh) {
    return mx >= rx && mx <= rx + rw && my >= ry && my <= ry + rh;
}

// --- ProgressBar ---

struct ProgressBar {
    float x;
    float y;
    float width;
    float progress;
    bool isHovered;
    bool isDragging;
    SpringAnim heightAnim;
}

ProgressBar progressBarCreate() {
    ProgressBar bar;
    bar.heightAnim = springCreate();
    bar.heightAnim.current = cast(float)PROGRESS_BAR_HEIGHT_NORMAL;
    bar.heightAnim.target = cast(float)PROGRESS_BAR_HEIGHT_NORMAL;
    return bar;
}

ProgressBar progressBarUpdate(ProgressBar bar, float x, float y, float width, float progressVal) {
    bar.x = x;
    bar.y = y;
    bar.width = width;
    
    float mx = cast(float)GetMouseX();
    float my = cast(float)GetMouseY();
    
    bar.isHovered = isMouseInRect(mx, my, x, y - 8.0f, width, 16.0f);
    
    if (bar.isHovered && IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
        bar.isDragging = true;
    }
    if (IsMouseButtonReleased(MouseButton.MOUSE_BUTTON_LEFT)) {
        bar.isDragging = false;
    }
    
    if (bar.isDragging) {
        float p = (mx - x) / width;
        if (p < 0.0f) p = 0.0f;
        if (p > 1.0f) p = 1.0f;
        bar.progress = p;
    } else {
        bar.progress = progressVal;
    }
    
    float targetHeight = (bar.isHovered || bar.isDragging) 
                         ? cast(float)PROGRESS_BAR_HEIGHT_HOVER 
                         : cast(float)PROGRESS_BAR_HEIGHT_NORMAL;
    springSetTarget(&bar.heightAnim, targetHeight);
    springUpdate(&bar.heightAnim, GetFrameTime());
    
    return bar;
}

void progressBarDraw(ProgressBar* bar) {
    float h = bar.heightAnim.current;
    float cy = bar.y - h * 0.5f;
    
    // Background track
    DrawRectangleRec(Rectangle(bar.x, cy, bar.width, h), BORDER);
    
    // Filled progress
    float fillW = bar.width * bar.progress;
    if (fillW > 0.0f) {
        DrawRectangleRec(Rectangle(bar.x, cy, fillW, h), themeGetAccent());
    }
}

// --- Play Controls ---

struct PlayControlsLayout {
    float prevX;
    float playX;
    float nextX;
    float prevSize;
    float playSize;
}

private PlayControlsLayout calcPlayLayout(float centerX, float y) {
    float spacing = cast(float)BUTTON_SPACING;
    float pSize = cast(float)PLAY_BUTTON_SIZE;
    float sSize = cast(float)SKIP_BUTTON_SIZE;
    
    return PlayControlsLayout(
        centerX - spacing * 2.0f - pSize * 0.5f - sSize * 0.5f,
        centerX,
        centerX + spacing * 2.0f + pSize * 0.5f + sSize * 0.5f,
        sSize,
        pSize
    );
}

void drawPlayControls(float centerX, float y, PlayState state) {
    float mx = cast(float)GetMouseX();
    float my = cast(float)GetMouseY();
    
    auto layout = calcPlayLayout(centerX, y);
    
    bool hoverPrev = isMouseInRect(mx, my, layout.prevX - layout.prevSize, y - layout.prevSize, layout.prevSize * 2.0f, layout.prevSize * 2.0f);
    bool hoverPlay = isMouseInRect(mx, my, layout.playX - layout.playSize, y - layout.playSize, layout.playSize * 2.0f, layout.playSize * 2.0f);
    bool hoverNext = isMouseInRect(mx, my, layout.nextX - layout.prevSize, y - layout.prevSize, layout.prevSize * 2.0f, layout.prevSize * 2.0f);
    
    iconPrev(layout.prevX, y, layout.prevSize, hoverPrev ? PRIMARY : SECONDARY);
    iconNext(layout.nextX, y, layout.prevSize, hoverNext ? PRIMARY : SECONDARY);
    
    if (state == PlayState.playing) {
        iconPause(layout.playX, y, layout.playSize, hoverPlay ? PRIMARY : SECONDARY);
    } else {
        iconPlay(layout.playX, y, layout.playSize, hoverPlay ? PRIMARY : SECONDARY);
    }
}

int checkPlayControlsClick(float centerX, float y) {
    if (!IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) return 0;
    
    float mx = cast(float)GetMouseX();
    float my = cast(float)GetMouseY();
    
    auto layout = calcPlayLayout(centerX, y);
    
    if (isMouseInRect(mx, my, layout.prevX - layout.prevSize, y - layout.prevSize, layout.prevSize * 2.0f, layout.prevSize * 2.0f)) return 1;
    if (isMouseInRect(mx, my, layout.playX - layout.playSize, y - layout.playSize, layout.playSize * 2.0f, layout.playSize * 2.0f)) return 2;
    if (isMouseInRect(mx, my, layout.nextX - layout.prevSize, y - layout.prevSize, layout.prevSize * 2.0f, layout.prevSize * 2.0f)) return 3;
    
    return 0;
}

// --- Time Display ---

private void formatTime(char* buf, int seconds) {
    int m = seconds / 60;
    int s = seconds % 60;
    buf[0] = cast(char)('0' + (m / 10));
    buf[1] = cast(char)('0' + (m % 10));
    buf[2] = ':';
    buf[3] = cast(char)('0' + (s / 10));
    buf[4] = cast(char)('0' + (s % 10));
    buf[5] = '\0';
}

void drawTimeStamps(float progressX, float progressWidth, float y, float currentSec, float totalSec) {
    char[16] curBuf;
    char[16] totBuf;
    formatTime(curBuf.ptr, cast(int)currentSec);
    formatTime(totBuf.ptr, cast(int)totalSec);
    
    float fs = cast(float)FONT_SIZE_META;
    float textY = y - fs * 0.5f;
    
    float curLen = measureTextX(curBuf.ptr, fs);
    float totLen = measureTextX(totBuf.ptr, fs);
    
    drawTextEx(curBuf.ptr, progressX - curLen - 12.0f, textY, fs, TERTIARY);
    drawTextEx(totBuf.ptr, progressX + progressWidth + 12.0f, textY, fs, TERTIARY);
}

// --- Volume Control ---

void drawVolumeControl(float x, float y, float volume, bool isMuted) {
    Color col = SECONDARY;
    float iconSize = 24.0f;
    if (isMuted) {
        iconVolumeMuted(x, y, iconSize, col);
    } else if (volume > 0.5f) {
        iconVolumeHigh(x, y, iconSize, col);
    } else {
        iconVolumeLow(x, y, iconSize, col);
    }
    
    float barX = x + iconSize;
    float barW = 40.0f;
    float barY = y - 1.0f;
    DrawRectangleRec(Rectangle(barX, barY, barW, 2.0f), BORDER);
    if (!isMuted && volume > 0.0f) {
        DrawRectangleRec(Rectangle(barX, barY, barW * volume, 2.0f), themeGetAccent());
    }
}
