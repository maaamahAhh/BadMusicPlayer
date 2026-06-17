module platform.win32;

alias HWND = void*;
alias UINT = uint;
alias WPARAM = size_t;
alias LPARAM = ptrdiff_t;
alias LRESULT = ptrdiff_t;
alias BOOL = int;

private enum UINT WM_NCLBUTTONDOWN = 0x00A1;
private enum WPARAM HTCAPTION = 2;
private enum int SW_MINIMIZE = 6;
private enum int SW_MAXIMIZE = 3;
private enum int SW_RESTORE = 9;

alias LONG_PTR = ptrdiff_t;
struct POINT { int x; int y; }
struct RECT { int left; int top; int right; int bottom; }

// --- File scanning types ---
alias HANDLE = void*;
struct FILETIME { DWORD dwLowDateTime; DWORD dwHighDateTime; }
struct WIN32_FIND_DATAW {
    DWORD dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD nFileSizeHigh;
    DWORD nFileSizeLow;
    DWORD dwReserved0;
    DWORD dwReserved1;
    wchar[260] cFileName;
    wchar[14] cAlternateFileName;
}

extern(Windows) HANDLE FindFirstFileW(const(wchar)*, WIN32_FIND_DATAW*);
extern(Windows) BOOL FindNextFileW(HANDLE, WIN32_FIND_DATAW*);
extern(Windows) BOOL FindClose(HANDLE);
extern(Windows) int WideCharToMultiByte(uint CodePage, DWORD dwFlags, const(wchar)* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, const(char)* lpDefaultChar, BOOL* lpUsedDefaultChar);
extern(Windows) int MultiByteToWideChar(uint CodePage, DWORD dwFlags, const(char)* lpMultiByteStr, int cbMultiByte, wchar* lpWideCharStr, int cchWideChar);
extern(Windows) DWORD GetLastError();

enum uint CP_UTF8 = 65001;
enum HANDLE INVALID_HANDLE_VALUE = cast(HANDLE)(cast(ptrdiff_t)(-1));

// C runtime
extern(C) int _strnicmp(const(char)*, const(char)*, size_t);

extern(Windows) LRESULT SendMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
extern(Windows) BOOL ShowWindow(HWND hWnd, int nCmdShow);
extern(Windows) LONG_PTR GetWindowLongPtrW(HWND hWnd, int nIndex);
extern(Windows) BOOL IsZoomed(HWND hWnd);
extern(Windows) BOOL ReleaseCapture();
extern(Windows) BOOL GetCursorPos(POINT* lpPoint);
extern(Windows) BOOL SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags);
extern(Windows) BOOL GetWindowRect(HWND hWnd, RECT* lpRect);

private enum UINT SWP_NOSIZE = 0x0001;
private enum UINT SWP_NOZORDER = 0x0004;
private HWND HWND_NOTOPMOST = cast(HWND)(cast(ptrdiff_t)(-2));

private HWND getHwnd() {
    import raylib : GetWindowHandle;
    return GetWindowHandle();
}

private __gshared HWND cachedHwnd = null;

private __gshared bool gDragging = false;
private __gshared int gDragStartMouseX = 0;
private __gshared int gDragStartMouseY = 0;
private __gshared int gDragStartWinX = 0;
private __gshared int gDragStartWinY = 0;

void setupPlatform() {
    cachedHwnd = getHwnd();
}

void startWindowDrag() {
    HWND hwnd = cachedHwnd;
    if (hwnd is null)
        hwnd = getHwnd();
    if (hwnd is null)
        return;

    POINT pt;
    GetCursorPos(&pt);
    RECT rc;
    GetWindowRect(hwnd, &rc);

    gDragStartMouseX = pt.x;
    gDragStartMouseY = pt.y;
    gDragStartWinX = rc.left;
    gDragStartWinY = rc.top;
    gDragging = true;
}

void updateWindowDrag() {
    import raylib : IsMouseButtonDown, MouseButton;
    if (!gDragging) return;

    POINT pt;
    GetCursorPos(&pt);

    if (IsMouseButtonDown(MouseButton.MOUSE_BUTTON_LEFT)) {
        int dx = pt.x - gDragStartMouseX;
        int dy = pt.y - gDragStartMouseY;
        int newX = gDragStartWinX + dx;
        int newY = gDragStartWinY + dy;

        HWND hwnd = cachedHwnd;
        if (hwnd is null) hwnd = getHwnd();
        if (hwnd !is null) {
            SetWindowPos(hwnd, HWND_NOTOPMOST, newX, newY, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
        }
    } else {
        gDragging = false;
    }
}

void toggleMaximize() {
    HWND hwnd = cachedHwnd;
    if (hwnd is null)
        hwnd = getHwnd();
    if (hwnd is null)
        return;

    if (IsZoomed(hwnd))
        ShowWindow(hwnd, SW_RESTORE);
    else
        ShowWindow(hwnd, SW_MAXIMIZE);
}

void minimizeWindow() {
    HWND hwnd = cachedHwnd;
    if (hwnd is null)
        hwnd = getHwnd();
    if (hwnd is null)
        return;

    ShowWindow(hwnd, SW_MINIMIZE);
}

bool isWindowMaximized() {
    HWND hwnd = cachedHwnd;
    if (hwnd is null)
        hwnd = getHwnd();
    if (hwnd is null)
        return false;

    return IsZoomed(hwnd) != 0;
}

// --- File Association Registration ---

alias HKEY = void*;
alias LONG = int;
alias DWORD = uint;
alias REGSAM = uint;

private enum LONG ERROR_SUCCESS = 0;
private enum DWORD REG_SZ = 1;
private enum HKEY HKEY_CURRENT_USER = cast(HKEY)(cast(ptrdiff_t)(0x80000001));

extern(Windows) LONG RegCreateKeyExW(HKEY hKey, const(wchar)* lpSubKey, DWORD Reserved, wchar* lpClass, DWORD dwOptions, REGSAM samDesired, void* lpSecurityAttributes, HKEY* phkResult, DWORD* lpdwDisposition);
extern(Windows) LONG RegSetValueExW(HKEY hKey, const(wchar)* lpValueName, DWORD Reserved, DWORD dwType, const(ubyte)* lpData, DWORD cbData);
extern(Windows) LONG RegCloseKey(HKEY hKey);
extern(Windows) DWORD GetModuleFileNameW(void* hModule, wchar* lpFilename, DWORD nSize);

private enum DWORD KEY_WRITE = 0x20006;

void registerFileAssociations() {
    // Get exe path
    wchar[512] exePath;
    DWORD exeLen = GetModuleFileNameW(null, exePath.ptr, 512);
    if (exeLen == 0) return;

    // Build command: "path\to\BadMusicPlayer.exe" "%1"
    wchar[600] cmdLine;
    int pos = 0;
    cmdLine[pos++] = '"';
    for (DWORD i = 0; i < exeLen; i++) cmdLine[pos++] = exePath[i];
    cmdLine[pos++] = '"';
    cmdLine[pos++] = ' ';
    cmdLine[pos++] = '"';
    cmdLine[pos++] = '%';
    cmdLine[pos++] = '1';
    cmdLine[pos++] = '"';
    cmdLine[pos] = '\0';

    // String constants
    auto progIdStr = "BadMusicPlayer.audio"w;
    auto descStr = "Audio File (BadMusicPlayer)"w;
    auto shellOpenStr = "shell\\open\\command"w;
    auto friendlyNameStr = "BadMusicPlayer"w;
    auto appDescStr = "Windows local music player with immersive visualization"w;
    auto capPathStr = "Software\\BadMusicPlayer\\Capabilities"w;
    auto capAssocStr = "Software\\BadMusicPlayer\\Capabilities\\FileAssociations"w;
    auto regAppStr = "Software\\RegisteredApplications"w;

    // Create ProgID key
    HKEY hKey;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, progIdStr.ptr, 0, null, 0, KEY_WRITE, null, &hKey, null) != ERROR_SUCCESS)
        return;
    RegSetValueExW(hKey, null, 0, REG_SZ, cast(const(ubyte)*)descStr.ptr, cast(uint)(descStr.length + 1) * 2);
    RegCloseKey(hKey);

    // Set shell\open\command
    if (RegCreateKeyExW(HKEY_CURRENT_USER, progIdStr.ptr, 0, null, 0, KEY_WRITE, null, &hKey, null) == ERROR_SUCCESS) {
        HKEY hCmdKey;
        if (RegCreateKeyExW(hKey, shellOpenStr.ptr, 0, null, 0, KEY_WRITE, null, &hCmdKey, null) == ERROR_SUCCESS) {
            RegSetValueExW(hCmdKey, null, 0, REG_SZ, cast(const(ubyte)*)cmdLine.ptr, pos * 2 + 2);
            RegCloseKey(hCmdKey);
        }
        RegCloseKey(hKey);
    }

    // Register supported extensions
    static const(wchar*)[7] extensions = [
        ".mp3"w.ptr, ".wav"w.ptr, ".ogg"w.ptr, ".flac"w.ptr,
        ".xm"w.ptr, ".mod"w.ptr, ".qoa"w.ptr
    ];

    for (int i = 0; i < 7; i++) {
        HKEY hExtKey;
        if (RegCreateKeyExW(HKEY_CURRENT_USER, extensions[i], 0, null, 0, KEY_WRITE, null, &hExtKey, null) == ERROR_SUCCESS) {
            RegSetValueExW(hExtKey, null, 0, REG_SZ, cast(const(ubyte)*)progIdStr.ptr, cast(uint)(progIdStr.length + 1) * 2);
            RegCloseKey(hExtKey);
        }
    }

    // Register in RegisteredApplications so it appears in "Open With"
    HKEY hRegApp;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, regAppStr.ptr, 0, null, 0, KEY_WRITE, null, &hRegApp, null) == ERROR_SUCCESS) {
        RegSetValueExW(hRegApp, friendlyNameStr.ptr, 0, REG_SZ, cast(const(ubyte)*)capPathStr.ptr, cast(uint)(capPathStr.length + 1) * 2);
        RegCloseKey(hRegApp);
    }

    // Register capabilities
    HKEY hCap;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, capPathStr.ptr, 0, null, 0, KEY_WRITE, null, &hCap, null) == ERROR_SUCCESS) {
        RegSetValueExW(hCap, "ApplicationName"w.ptr, 0, REG_SZ, cast(const(ubyte)*)friendlyNameStr.ptr, cast(uint)(friendlyNameStr.length + 1) * 2);
        RegSetValueExW(hCap, "ApplicationDescription"w.ptr, 0, REG_SZ, cast(const(ubyte)*)appDescStr.ptr, cast(uint)(appDescStr.length + 1) * 2);
        RegCloseKey(hCap);
    }

    // Register file associations under capabilities
    HKEY hAssoc;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, capAssocStr.ptr, 0, null, 0, KEY_WRITE, null, &hAssoc, null) == ERROR_SUCCESS) {
        for (int i = 0; i < 7; i++) {
            RegSetValueExW(hAssoc, extensions[i], 0, REG_SZ, cast(const(ubyte)*)progIdStr.ptr, cast(uint)(progIdStr.length + 1) * 2);
        }
        RegCloseKey(hAssoc);
    }
}
