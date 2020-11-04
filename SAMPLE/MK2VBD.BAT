@echo off
rem
rem compiles an example file and link w/ b4gv.lib
rem

if [%1]==[] goto error

set obj2=
if [%2]==[] goto comp
set obj2=+%2.obj

:comp
bcv /o /G2 /Fpi %1.bas;
if errorlevel 1 goto end

link %1.obj%obj2%,,nul,..\lib\b4gv.lib+vbdcl10e.lib;
if exist %1.obj del %1.obj

goto end

:error
echo. usage: mk2vbd basfile

:end
