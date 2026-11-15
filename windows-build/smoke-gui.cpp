#define UNICODE
#define _UNICODE
#include <windows.h>

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
    MessageBoxW(nullptr, L"M C++ Studio Windows GUI smoke test", L"Build verification", MB_OK | MB_ICONINFORMATION);
    return 0;
}
