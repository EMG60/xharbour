/* Wrappers for API functions not implemented on Windows 95 or Windows NT versions less than 4.0 SP 3 */

/*
 *  To enable GetDiskFreeSpaceEx define WANT_GETDISKFREESPACEEX_WRAPPER.
 *  To enable GetLongPathName define WANT_GETLONGPATHNAME_WRAPPER.
 *  To enable GetFileAttributesEx define WANT_GETFILEATTRIBUTESEX_WRAPPER.
 *  To enable IsDebuggerPresent define WANT_ISDEBUGGERPRESENT_WRAPPER.
 *
 *  One file, and one file only, must use:
 * #define COMPILE_NEWAPIS_STUBS
 * #include <newapis.h>
 */

#ifdef __cplusplus
extern "C" {
#endif

#if __POCC__ >= 290
#pragma warn(push)
#pragma warn(disable:2028)  /* Missing prototype */
#endif

#ifdef WANT_GETDISKFREESPACEEX_WRAPPER

#undef GetDiskFreeSpaceEx
#define GetDiskFreeSpaceEx  _GetDiskFreeSpaceEx

extern BOOL (CALLBACK *GetDiskFreeSpaceEx)(LPCTSTR,PULARGE_INTEGER,PULARGE_INTEGER,PULARGE_INTEGER);

#ifdef COMPILE_NEWAPIS_STUBS

static BOOL WINAPI Emulate_GetDiskFreeSpaceEx(LPCTSTR ptszRoot, PULARGE_INTEGER pliQuota, PULARGE_INTEGER pliTotal, PULARGE_INTEGER pliFree)
{
    DWORD dwSecPerClus, dwBytesPerSec, dwFreeClus, dwTotalClus;
    BOOL fRc;

    fRc = GetDiskFreeSpace(ptszRoot, &dwSecPerClus, &dwBytesPerSec, &dwFreeClus, &dwTotalClus);
    if (fRc) 
    {
        DWORD dwBytesPerClus = dwSecPerClus * dwBytesPerSec;
        *(__int64 *)pliQuota = Int32x32To64(dwBytesPerClus, dwFreeClus);
        if (pliFree) *pliFree = *pliQuota;
        *(__int64 *)pliTotal = Int32x32To64(dwBytesPerClus, dwTotalClus);
    }

    return fRc;
}

static BOOL WINAPI Probe_GetDiskFreeSpaceEx(LPCTSTR ptszRoot, PULARGE_INTEGER pliQuota, PULARGE_INTEGER pliTotal, PULARGE_INTEGER pliFree)
{
    HINSTANCE hinst;
    FARPROC fp;
    BOOL fRc;
    BOOL (CALLBACK *RealGetDiskFreeSpaceEx)(LPCTSTR,PULARGE_INTEGER,PULARGE_INTEGER,PULARGE_INTEGER);

    hinst = GetModuleHandle(TEXT("KERNEL32"));
#ifdef UNICODE
    fp = GetProcAddress(hinst, "GetDiskFreeSpaceExW");
#else
    fp = GetProcAddress(hinst, "GetDiskFreeSpaceExA");
#endif

    if (fp)
    {
        *(FARPROC *)&RealGetDiskFreeSpaceEx = fp;
        fRc = RealGetDiskFreeSpaceEx(ptszRoot, pliQuota, pliTotal, pliFree);
        if (fRc || GetLastError() != ERROR_CALL_NOT_IMPLEMENTED)
        {
            GetDiskFreeSpaceEx = RealGetDiskFreeSpaceEx;
        }
        else
        {
            GetDiskFreeSpaceEx = Emulate_GetDiskFreeSpaceEx;
            fRc = GetDiskFreeSpaceEx(ptszRoot, pliQuota, pliTotal, pliFree);
        }
    }
    else
    {
        GetDiskFreeSpaceEx = Emulate_GetDiskFreeSpaceEx;
        fRc = GetDiskFreeSpaceEx(ptszRoot, pliQuota, pliTotal, pliFree);
    }

    return fRc;

}

BOOL (CALLBACK *GetDiskFreeSpaceEx)(LPCTSTR,PULARGE_INTEGER,PULARGE_INTEGER,PULARGE_INTEGER) = Probe_GetDiskFreeSpaceEx;

#endif /* COMPILE_NEWAPIS_STUBS */
#endif /* WANT_GETDISKFREESPACEEX_WRAPPER */

#ifdef WANT_GETLONGPATHNAME_WRAPPER

#include <shlobj.h>

#undef GetLongPathName
#define GetLongPathName  _GetLongPathName

extern DWORD (CALLBACK *GetLongPathName)(LPCTSTR,LPTSTR,DWORD);

#ifdef COMPILE_NEWAPIS_STUBS

static DWORD WINAPI Emulate_GetLongPathName(LPCTSTR ptszShort, LPTSTR ptszLong, DWORD ctchBuf)
{
    LPSHELLFOLDER psfDesk;
    HRESULT hr;
    LPITEMIDLIST pidl;
    TCHAR tsz[MAX_PATH];
    DWORD dwRc;
    LPMALLOC pMalloc;

    if (GetFileAttributes(ptszShort) == 0xFFFFFFFF)
        return 0;

    dwRc = GetFullPathName(ptszShort, MAX_PATH, tsz, NULL);
    if (dwRc == 0)
    {
        /* Failed; GFPN already did SetLastError(). */
    }
    else if (dwRc >= MAX_PATH)
    {
        SetLastError(ERROR_BUFFER_OVERFLOW);
        dwRc = 0;
    }
    else
    {
        hr = SHGetDesktopFolder(&psfDesk);
        if (SUCCEEDED(hr))
        {
            ULONG cwchEaten;

#ifdef UNICODE
#ifdef __cplusplus
            hr = psfDesk->ParseDisplayName(NULL, NULL, tsz, &cwchEaten, &pidl, NULL);
#else
            hr = psfDesk->lpVtbl->ParseDisplayName(psfDesk, NULL, NULL, tsz, &cwchEaten, &pidl, NULL);
#endif /* __cplusplus */
#else /* UNICODE */
            WCHAR wsz[MAX_PATH];

            dwRc = MultiByteToWideChar(AreFileApisANSI() ? CP_ACP : CP_OEMCP, 0, tsz, -1, wsz, MAX_PATH);
            if (dwRc == 0)
            {
                if (GetLastError() == ERROR_INSUFFICIENT_BUFFER)
                    SetLastError(ERROR_BUFFER_OVERFLOW);
                dwRc = 0;
            }
            else
            {
#ifdef __cplusplus
                hr = psfDesk->ParseDisplayName(NULL, NULL, wsz, &cwchEaten, &pidl, NULL);
#else
                hr = psfDesk->lpVtbl->ParseDisplayName(psfDesk, NULL, NULL, wsz, &cwchEaten, &pidl, NULL);
#endif /* __cplusplus */
#endif /* UNICODE */

                if (FAILED(hr))
                {
                    if (HRESULT_FACILITY(hr) == FACILITY_WIN32)
                        SetLastError(HRESULT_CODE(hr));
                    else
                        SetLastError(ERROR_INVALID_DATA);
                    dwRc = 0;
                }
                else
                {
                    dwRc = SHGetPathFromIDList(pidl, tsz);
                    if (dwRc == 0 && tsz[0])
                    {
                        SetLastError(ERROR_INVALID_DATA);
                    }
                    else
                    {
                        dwRc = lstrlen(tsz);
                        if (dwRc + 1 > ctchBuf)
                        {
                            SetLastError(ERROR_INSUFFICIENT_BUFFER);
                            dwRc = dwRc + 1;
                        }
                        else
                        {
                            lstrcpyn(ptszLong, tsz, ctchBuf);
                        }
                    }

                    if (SUCCEEDED(SHGetMalloc(&pMalloc)))
                    {
#ifdef __cplusplus
                        pMalloc->Free(pidl);
                        pMalloc->Release();
#else
                        pMalloc->lpVtbl->Free(pMalloc, pidl);
                        pMalloc->lpVtbl->Release(pMalloc);
#endif /* __cplusplus */
                    }
                }
#ifndef UNICODE
            }
#endif
#ifdef __cplusplus
            psfDesk->Release();
#else
            psfDesk->lpVtbl->Release(psfDesk);
#endif
        }
    }
    return dwRc;
}

static DWORD WINAPI Probe_GetLongPathName(LPCTSTR ptszShort, LPTSTR ptszLong, DWORD ctchBuf)
{
    HINSTANCE hinst;
    FARPROC fp;
    DWORD dwRc;
    DWORD (CALLBACK *RealGetLongPathName)(LPCTSTR,LPTSTR,DWORD);

    hinst = GetModuleHandle(TEXT("KERNEL32"));
#ifdef UNICODE
    fp = GetProcAddress(hinst, "GetLongPathNameW");
#else
    fp = GetProcAddress(hinst, "GetLongPathNameA");
#endif

    if (fp)
    {
        *(FARPROC *)&RealGetLongPathName = fp;
        dwRc = RealGetLongPathName(ptszShort, ptszLong, ctchBuf);
        if (dwRc || GetLastError() != ERROR_CALL_NOT_IMPLEMENTED)
        {
            GetLongPathName = RealGetLongPathName;
        }
        else
        {
            GetLongPathName = Emulate_GetLongPathName;
            dwRc = GetLongPathName(ptszShort, ptszLong, ctchBuf);
        }
    }
    else
    {
        GetLongPathName = Emulate_GetLongPathName;
        dwRc = GetLongPathName(ptszShort, ptszLong, ctchBuf);
    }

    return dwRc;

}

DWORD (CALLBACK *GetLongPathName)(LPCTSTR, LPTSTR, DWORD) = Probe_GetLongPathName;

#endif /* COMPILE_NEWAPIS_STUBS */
#endif /* WANT_GETLONGPATHNAME_WRAPPER */

#ifdef WANT_GETFILEATTRIBUTESEX_WRAPPER

#undef GetFileAttributesEx
#define GetFileAttributesEx  _GetFileAttributesEx

#if WINVER < 0x040A
typedef enum _GET_FILEEX_INFO_LEVELS {
    GetFileExInfoStandard,
    GetFileExMaxInfoLevel
} GET_FILEEX_INFO_LEVELS;

typedef struct _WIN32_FILE_ATTRIBUTE_DATA {
    DWORD dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD nFileSizeHigh;
    DWORD nFileSizeLow;
} WIN32_FILE_ATTRIBUTE_DATA, *LPWIN32_FILE_ATTRIBUTE_DATA;
#endif /* WINVER < 0x040A */

extern BOOL (CALLBACK *GetFileAttributesEx)(LPCTSTR,GET_FILEEX_INFO_LEVELS,LPVOID);

#ifdef COMPILE_NEWAPIS_STUBS

static BOOL WINAPI Emulate_GetFileAttributesEx(LPCTSTR ptszFile, GET_FILEEX_INFO_LEVELS level, LPVOID pv)
{
    BOOL fRc;

    if (level == GetFileExInfoStandard)
    {
        if (GetFileAttributes(ptszFile) != 0xFFFFFFFF)
        {
            HANDLE hfind;
            WIN32_FIND_DATA wfd;

            hfind = FindFirstFile(ptszFile, &wfd);
            if (hfind != INVALID_HANDLE_VALUE)
            {
                LPWIN32_FILE_ATTRIBUTE_DATA pfad = pv;
                FindClose(hfind);

                pfad->dwFileAttributes = wfd.dwFileAttributes;
                pfad->ftCreationTime = wfd.ftCreationTime;
                pfad->ftLastAccessTime = wfd.ftLastAccessTime;
                pfad->ftLastWriteTime = wfd.ftLastWriteTime;
                pfad->nFileSizeHigh = wfd.nFileSizeHigh;
                pfad->nFileSizeLow = wfd.nFileSizeLow;

                fRc = TRUE;
            }
            else
            {
                fRc = FALSE;
            }
        }
        else
        {
            fRc = FALSE;
        }
    }
    else
    {
        SetLastError(ERROR_INVALID_PARAMETER);
        fRc = FALSE;
    }

    return fRc;
}

static BOOL WINAPI Probe_GetFileAttributesEx(LPCTSTR ptszFile, GET_FILEEX_INFO_LEVELS level, LPVOID pv)
{
    HINSTANCE hinst;
    FARPROC fp;
    BOOL fRc;
    BOOL (CALLBACK *RealGetFileAttributesEx)(LPCTSTR,GET_FILEEX_INFO_LEVELS,LPVOID);

    hinst = GetModuleHandle(TEXT("KERNEL32"));
#ifdef UNICODE
    fp = GetProcAddress(hinst, "GetFileAttributesExW");
#else
    fp = GetProcAddress(hinst, "GetFileAttributesExA");
#endif

    if (fp)
    {
        *(FARPROC *)&RealGetFileAttributesEx = fp;
        fRc = RealGetFileAttributesEx(ptszFile, level, pv);
        if (fRc || GetLastError() != ERROR_CALL_NOT_IMPLEMENTED)
        {
            GetFileAttributesEx = RealGetFileAttributesEx;
        }
        else
        {
            GetFileAttributesEx = Emulate_GetFileAttributesEx;
            fRc = GetFileAttributesEx(ptszFile, level, pv);
        }
    }
    else
    {
        GetFileAttributesEx = Emulate_GetFileAttributesEx;
        fRc = GetFileAttributesEx(ptszFile, level, pv);
    }

    return fRc;

}

BOOL (CALLBACK *GetFileAttributesEx)(LPCTSTR,GET_FILEEX_INFO_LEVELS,LPVOID) = Probe_GetFileAttributesEx;

#endif /* COMPILE_NEWAPIS_STUBS */
#endif /* WANT_GETFILEATTRIBUTESEX_WRAPPER */

#ifdef WANT_ISDEBUGGERPRESENT_WRAPPER

#define IsDebuggerPresent  _IsDebuggerPresent

extern BOOL (CALLBACK *IsDebuggerPresent)(VOID);

#ifdef COMPILE_NEWAPIS_STUBS

static BOOL WINAPI Emulate_IsDebuggerPresent(VOID)
{
    return FALSE;
}

static BOOL WINAPI Probe_IsDebuggerPresent(VOID)
{
    HINSTANCE hinst;
    FARPROC fp;

    hinst = GetModuleHandle(TEXT("KERNEL32"));
    fp = GetProcAddress(hinst, "IsDebuggerPresent");

    if (fp)
        *(FARPROC *)&IsDebuggerPresent = fp;
    else
        IsDebuggerPresent = Emulate_IsDebuggerPresent;

    return IsDebuggerPresent();
}

BOOL (CALLBACK *IsDebuggerPresent)(VOID) = Probe_IsDebuggerPresent;

#endif /* COMPILE_NEWAPIS_STUBS */
#endif /* WANT_ISDEBUGGERPRESENT_WRAPPER */

#if __POCC__ >= 290
#pragma warn(pop)
#endif

#ifdef __cplusplus
}
#endif
