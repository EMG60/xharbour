#ifndef _WINDEF_H
#define _WINDEF_H

/* Windows Basic Type Definitions */

#ifndef NO_STRICT
#ifndef STRICT
#define STRICT  1
#endif
#endif /* NO_STRICT */

#ifdef __cplusplus
extern "C" {
#endif

#if __POCC__ >= 290
#pragma warn(push)
#pragma warn(disable:2028)  /* Missing prototype */
#endif

#ifndef WINVER
#define WINVER  0x0500
#endif

#ifndef BASETYPES
#define BASETYPES
typedef unsigned long ULONG;
typedef ULONG *PULONG;
typedef unsigned short USHORT;
typedef USHORT *PUSHORT;
typedef unsigned char UCHAR;
typedef UCHAR *PUCHAR;
typedef char *PSZ;
#endif /* BASETYPES */

#define MAX_PATH  260

#ifndef NULL
#ifdef __cplusplus
#define NULL  0
#else
#define NULL  ((void *)0)
#endif
#endif

#ifndef FALSE
#define FALSE  0
#endif

#ifndef TRUE
#define TRUE  1
#endif

#undef pascal
#define pascal __stdcall

#define cdecl
#ifndef CDECL
#define CDECL
#endif

#define far
#ifndef FAR
#define FAR
#endif

#define near
#ifndef NEAR
#define NEAR
#endif

#define CALLBACK  __stdcall
#define WINAPI  __stdcall
#define WINAPIV  __cdecl
#define APIENTRY  WINAPI
#define APIPRIVATE  __stdcall
#define PASCAL  __stdcall

#ifndef CONST
#define CONST const
#endif

typedef unsigned long DWORD;
typedef int BOOL;
typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef float FLOAT;
typedef FLOAT *PFLOAT;
typedef BOOL *PBOOL;
typedef BOOL *LPBOOL;
typedef BYTE *PBYTE;
typedef BYTE *LPBYTE;
typedef int INT;
typedef int *PINT;
typedef int *LPINT;
typedef unsigned int UINT;
typedef unsigned int *PUINT;
typedef WORD *PWORD;
typedef WORD *LPWORD;
typedef long *LPLONG;
typedef DWORD *PDWORD;
typedef DWORD *LPDWORD;
typedef void *LPVOID;
typedef CONST void *LPCVOID;

#ifndef NT_INCLUDED
#include <winnt.h>
#endif /* NT_INCLUDED */

typedef UINT_PTR WPARAM;
typedef LONG_PTR LPARAM;
typedef LONG_PTR LRESULT;

#ifndef NOMINMAX
#ifndef max
#define max(a,b)  (((a)>(b))?(a):(b))
#endif
#ifndef min
#define min(a,b)  (((a)<(b))?(a):(b))
#endif
#endif /* NOMINMAX */

#define MAKEWORD(a, b)  ((WORD)(((BYTE)((DWORD_PTR)(a)&0xFF))|((WORD)((BYTE)((DWORD_PTR)(b)&0xFF)))<<8))
#define MAKELONG(a, b)  ((LONG)(((WORD)((DWORD_PTR)(a)&0xFFFF))|((DWORD)((WORD)((DWORD_PTR)(b)&0xFFFF)))<<16))
#define LOWORD(l)  ((WORD)((DWORD_PTR)(l)&0xFFFF))
#define HIWORD(l)  ((WORD)((DWORD_PTR)(l)>>16))
#define LOBYTE(w)  ((BYTE)((DWORD_PTR)(w)&0xFF))
#define HIBYTE(w)  ((BYTE)((DWORD_PTR)(w)>>8))

DECLARE_HANDLE(HWND);
DECLARE_HANDLE(HHOOK);
#ifdef WINABLE
DECLARE_HANDLE(HEVENT);
#endif

typedef WORD ATOM;

typedef HANDLE *SPHANDLE;
typedef HANDLE *LPHANDLE;
typedef HANDLE HGLOBAL;
typedef HANDLE HLOCAL;
typedef HANDLE GLOBALHANDLE;
typedef HANDLE LOCALHANDLE;
#ifdef _WIN64
typedef INT_PTR (WINAPI *FARPROC)();
typedef INT_PTR (WINAPI *NEARPROC)();
typedef INT_PTR (WINAPI *PROC)();
#else
typedef int (WINAPI *FARPROC)();
typedef int (WINAPI *NEARPROC)();
typedef int (WINAPI *PROC)();
#endif /* _WIN64 */

#ifdef STRICT
typedef void *HGDIOBJ;
#else
DECLARE_HANDLE(HGDIOBJ);
#endif

DECLARE_HANDLE(HKEY);
typedef HKEY *PHKEY;

DECLARE_HANDLE(HACCEL);
DECLARE_HANDLE(HBITMAP);
DECLARE_HANDLE(HBRUSH);
DECLARE_HANDLE(HCOLORSPACE);
DECLARE_HANDLE(HDC);
DECLARE_HANDLE(HGLRC);
DECLARE_HANDLE(HDESK);
DECLARE_HANDLE(HENHMETAFILE);
DECLARE_HANDLE(HFONT);
DECLARE_HANDLE(HICON);
DECLARE_HANDLE(HMENU);
DECLARE_HANDLE(HMETAFILE);
DECLARE_HANDLE(HINSTANCE);
typedef HINSTANCE HMODULE;
DECLARE_HANDLE(HPALETTE);
DECLARE_HANDLE(HPEN);
DECLARE_HANDLE(HRGN);
DECLARE_HANDLE(HRSRC);
DECLARE_HANDLE(HSTR);
DECLARE_HANDLE(HTASK);
DECLARE_HANDLE(HWINSTA);
DECLARE_HANDLE(HKL);

#if (WINVER >= 0x0500)
DECLARE_HANDLE(HMONITOR);
DECLARE_HANDLE(HWINEVENTHOOK);
#endif /* WINVER >= 0x0500 */

typedef int HFILE;
typedef HICON HCURSOR;

typedef DWORD COLORREF;
typedef DWORD *LPCOLORREF;

#define HFILE_ERROR ((HFILE)-1)

typedef struct tagRECT {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
} RECT, *PRECT, *NPRECT, *LPRECT;
typedef const RECT *LPCRECT;

typedef struct _RECTL {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
} RECTL, *PRECTL, *LPRECTL;
typedef const RECTL *LPCRECTL;

typedef struct tagPOINT {
    LONG x;
    LONG y;
} POINT, *PPOINT, *NPPOINT, *LPPOINT;

typedef struct _POINTL {
    LONG x;
    LONG y;
} POINTL, *PPOINTL;

typedef struct tagSIZE {
    LONG cx;
    LONG cy;
} SIZE, *PSIZE, *LPSIZE;

typedef SIZE SIZEL;
typedef SIZE *PSIZEL, *LPSIZEL;

typedef struct tagPOINTS {
    SHORT x;
    SHORT y;
} POINTS, *PPOINTS, *LPPOINTS;

#define DM_UPDATE  1
#define DM_COPY  2
#define DM_PROMPT  4
#define DM_MODIFY  8

#define DM_IN_BUFFER  DM_MODIFY
#define DM_IN_PROMPT  DM_PROMPT
#define DM_OUT_BUFFER  DM_COPY
#define DM_OUT_DEFAULT  DM_UPDATE

#define DC_FIELDS  1
#define DC_PAPERS  2
#define DC_PAPERSIZE  3
#define DC_MINEXTENT  4
#define DC_MAXEXTENT  5
#define DC_BINS  6
#define DC_DUPLEX  7
#define DC_SIZE  8
#define DC_EXTRA  9
#define DC_VERSION  10
#define DC_DRIVER  11
#define DC_BINNAMES  12
#define DC_ENUMRESOLUTIONS  13
#define DC_FILEDEPENDENCIES  14
#define DC_TRUETYPE  15
#define DC_PAPERNAMES  16
#define DC_ORIENTATION  17
#define DC_COPIES  18

#if __POCC__ >= 290
#pragma warn(pop)
#endif

#ifdef __cplusplus
}
#endif

#endif /* _WINDEF_H */

