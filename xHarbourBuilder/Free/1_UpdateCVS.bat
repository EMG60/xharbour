TortoiseProc.exe /command:update /path:"c:\xHarbour\" /closeonend:1

rem SET ROBOCOPY_FROM=w:\xHarbour
rem SET ROBOCOPY_XF=
rem SET ROBOCOPY_XD=CVS CVSROOT debian .SVN
rem ROBOCOPY "%ROBOCOPY_FROM%" C:\xHarbour *.* /XO /NS /NC /NP /E /XD %ROBOCOPY_XD%

IF NOT EXIST "%ProgramFiles%\GnuWin32" ROBOCOPY "W:\Program Files\GnuWin32" "%ProgramFiles%\GnuWin32" *.* /XO /NS /NC /NP /S /E /PURGE
IF NOT EXIST "%ProgramFiles%\Advantage 11.10\acesdk" ROBOCOPY "W:\Program Files\Advantage 11.10\acesdk" "%ProgramFiles%\Advantage 11.10\acesdk" *.* /XO /NS /NC /NP /S /E /PURGE
IF NOT EXIST "C:\xHarbour\Lib\%2\ACE32.lib" MD "C:\xHarbour\Lib\%2"
IF NOT EXIST "C:\xHarbour\Lib\%2\ACE32.lib" COPY "w:\Clean CVS\xHarbour.com\Free\%1\ACE32.lib" C:\xHarbour\Lib\%2

IF NOT EXIST "%ProgramFiles%\Microsoft Visual Studio 9.0\Common7\Tools\Bin" ROBOCOPY "W:\Program Files\Microsoft Visual Studio 9.0\Common7\Tools\Bin" "%ProgramFiles%\Microsoft Visual Studio 9.0\Common7\Tools\Bin" *.* /XO /NS /NC /NP /S /E /PURGE
