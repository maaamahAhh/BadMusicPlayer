module app;

import raylib;
import audio.player;
import ui.renderer;
import ui.theme;
import platform.win32;

extern(C) int main(int argc, char** argv) {
    int winWidth = WINDOW_DEFAULT_WIDTH;
    int winHeight = WINDOW_DEFAULT_HEIGHT;
    
    SetConfigFlags(ConfigFlags.FLAG_VSYNC_HINT | ConfigFlags.FLAG_WINDOW_UNDECORATED | ConfigFlags.FLAG_WINDOW_HIDDEN | ConfigFlags.FLAG_WINDOW_RESIZABLE);
    InitWindow(winWidth, winHeight, "BadMusicPlayer");
    SetTargetFPS(60);
    
    // Platform specific setup for custom Titlebar (DWM)
    setupPlatform();
    registerFileAssociations();
    
    initAudio();
    rendererInit();
    
    // Reveal window after setup
    ClearWindowState(ConfigFlags.FLAG_WINDOW_HIDDEN);
    
    // Command line args for file dropping
    if (argc > 1 && argv[1] != null) {
        loadAndPlay(argv[1]);
    }
    
    while (!WindowShouldClose()) {
        if (IsFileDropped()) {
            FilePathList droppedFiles = LoadDroppedFiles();
            if (droppedFiles.count > 0) {
                loadAndPlay(droppedFiles.paths[0]);
            }
            UnloadDroppedFiles(droppedFiles);
        }
        
        // Handle input
        if (IsKeyPressed(KeyboardKey.KEY_SPACE)) {
            togglePlayPause();
        }
        if (IsKeyPressed(KeyboardKey.KEY_M)) {
            if (getVolume() > 0.0f) setVolume(0.0f);
            else setVolume(0.8f);
        }
        if (IsKeyPressed(KeyboardKey.KEY_UP)) {
            setVolume(getVolume() + 0.1f);
        }
        if (IsKeyPressed(KeyboardKey.KEY_DOWN)) {
            setVolume(getVolume() - 0.1f);
        }
        if (IsKeyPressed(KeyboardKey.KEY_RIGHT)) {
            seekTo(getTimePlayed() + 10.0f);
        }
        if (IsKeyPressed(KeyboardKey.KEY_LEFT)) {
            seekTo(getTimePlayed() - 10.0f);
        }
        if (IsKeyPressed(KeyboardKey.KEY_F11)) {
            toggleMaximize();
        }
        
        // Titlebar dragging and custom actions
        float mx = cast(float)GetMouseX();
        float my = cast(float)GetMouseY();
        bool inTitleBar = my < cast(float)TITLE_BAR_HEIGHT;
        float w = cast(float)GetScreenWidth();
        
        if (inTitleBar && IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
            if (mx > w - 46.0f) {
                break; // Close
            } else if (mx > w - 92.0f) {
                toggleMaximize();
            } else if (mx > w - 138.0f) {
                minimizeWindow();
            } else {
                startWindowDrag();
            }
        }
        
        updateAudio();
        updateWindowDrag();
        
        BeginDrawing();
        rendererFrame();
        EndDrawing();
    }
    
    rendererShutdown();
    shutdownAudio();
    CloseWindow();
    
    return 0;
}
