module ui.theme;

import raylib;

// --- Colors ---

enum Color CANVAS          = Color(  9,   9,  11, 255);
enum Color PRIMARY         = Color(250, 250, 250, 255);
enum Color SECONDARY       = Color(161, 161, 170, 255);
enum Color TERTIARY        = Color(113, 113, 122, 255);
enum Color BORDER          = Color( 39,  39,  42, 255);
enum Color DEFAULT_ACCENT  = Color(139,  92, 246, 255);

// --- Layout ---

enum int TITLE_BAR_HEIGHT        = 32;
enum int COVER_SIZE              = 120;
enum int COVER_CORNER_RADIUS     = 4;
enum int COVER_MARGIN_LEFT       = 24;
enum int COVER_MARGIN_BOTTOM     = 20;
enum int CONTROL_AREA_HEIGHT     = 56;
enum int PROGRESS_BAR_HEIGHT_NORMAL = 2;
enum int PROGRESS_BAR_HEIGHT_HOVER  = 4;
enum int PLAY_BUTTON_SIZE        = 36;
enum int SKIP_BUTTON_SIZE        = 28;
enum int BUTTON_SPACING          = 16;
enum int WINDOW_DEFAULT_WIDTH    = 1280;
enum int WINDOW_DEFAULT_HEIGHT   = 720;

// --- Font Sizes ---

enum int FONT_SIZE_TITLE    = 16;
enum int FONT_SIZE_ARTIST   = 13;
enum int FONT_SIZE_META     = 11;
enum int FONT_SIZE_APP_NAME = 14;

// --- Dynamic Accent Color ---

private __gshared Color accentPrimary   = DEFAULT_ACCENT;
private __gshared Color accentSecondary = Color(139, 92, 246, 180);
private __gshared Color accentDim       = Color( 60, 30, 120, 255);

void themeInit() {
    themeResetAccent();
}

void themeSetAccent(Color primary, Color secondary, Color dim) {
    accentPrimary   = primary;
    accentSecondary = secondary;
    accentDim       = dim;
}

void themeResetAccent() {
    accentPrimary   = DEFAULT_ACCENT;
    accentSecondary = Color(139, 92, 246, 180);
    accentDim       = Color( 60, 30, 120, 255);
}

Color themeGetAccent()          { return accentPrimary; }
Color themeGetAccentSecondary() { return accentSecondary; }
Color themeGetAccentDim()       { return accentDim; }

// --- Utilities ---

Color colorWithAlpha(Color c, float alpha) {
    ubyte a = cast(ubyte)(alpha * 255.0f);
    return Color(c.r, c.g, c.b, a);
}
