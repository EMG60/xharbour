@ECHO OFF

SET _PRESET_PATH=%PATH%
SET _PRESET_INCLUDE=%INCLUDE%
SET _PRESET_LIB=%LIB%
SET _PRESET_CFLAGS=%CFLAGS%
SET _PRESET_LFLAGS=%LFLAGS%
 
:FIND_VC
   IF EXIST "%ProgramFiles%\Microsoft Visual Studio 9.0\vc"  GOTO SET_VC2008
   IF EXIST "%ProgramFiles%\Microsoft Visual Studio 8\vc"    GOTO SET_VC2005
   IF EXIST "%ProgramFiles%\Microsoft Visual Studio 2003\vc" GOTO SET_VC2003
   IF EXIST "%ProgramFiles%\Microsoft Visual Studio\vc8"     GOTO SET_VC6
   GOTO NONE

:SET_VC2008
   CALL "%ProgramFiles%\Microsoft Visual Studio 9.0\vc\vcvarsall.bat"
   REM SET MSVCDIR=%ProgramFiles%\Microsoft Visual Studio 9.0\vc
   GOTO READY

:SET_VC2005
   CALL "%ProgramFiles%\Microsoft Visual Studio 8\vc\vcvarsall.bat"
   REM SET MSVCDIR=%ProgramFiles%\Microsoft Visual Studio 8\vc
   GOTO READY

:SET_VC2003
   CALL "%ProgramFiles%\Microsoft Visual Studio .NET 2003\VC7\vcvarsall.bat"
   REM SET MSVCDIR=%ProgramFiles%\Microsoft Visual .NET 2003\vc
   GOTO READY

:SET_VC6
   CALL "%ProgramFiles%\Microsoft Visual Studio\VC98\vcvarsall.bat"
   REM SET MSVCDIR=%ProgramFiles%\Microsoft Visual Studio\vc98
   GOTO READY

:NONE   

:READY

SET PELLESCDIR=%ProgramFiles%\PellesC
SET XCCDIR=\xhb\bin
SET PATH=%PATH%;"%XCCDIR%"

REM SET CFLAGS=/Od /EHsc /RTC1 /MTd /Gs /GS /Gy /GR /Zi /D_CRT_SECURE_NO_DEPRECATE /D_CRT_NONSTDC_NO_DEPRECATE
REM SET LFLAGS=-DEBUG -DEBUGTYPE:CV

IF NOT EXIST Objs MD Objs
IF NOT EXIST mtObjs MD mtObjs

echo single-thread > log
nmake >> log
if errorlevel 1 goto q

echo multi-thread >>log
nmake __MT__=1 >> log
if errorlevel 1 goto q

echo wince
..\utils\narmw -o wince\xdiv.obj -f win32 wince\xdiv.asm
@if errorlevel 1 goto Q
xlib.exe -out:crtce.lib wince\xdiv.obj

:q
IF ERRORLEVEL 0 xcopy crt.lib \xhb\c_lib /d /r /y
IF ERRORLEVEL 0 xcopy crtmt.lib \xhb\c_lib /d /r /y
xcopy "%PELLESCDIR%\lib\win" \xhb\c_lib\win /d /y 

SET PATH=%_PRESET_PATH%
SET INCLUDE=%_PRESET_INCLUDE% 
SET LIB=%_PRESET_LIB% 
SET CFLAGS=%_PRESET_CFLAGS% 
SET LFLAGS=%_PRESET_LFLAGS% 

SET _PRESET_PATH=
SET _PRESET_INCLUDE=
SET _PRESET_LIB=
SET _PRESET_CFLAGS=
SET _PRESET_LFLAGS=
