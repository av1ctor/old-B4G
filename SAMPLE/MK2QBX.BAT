@echo off
rem
rem compiles an example file and link w/ b4gx.lib
rem

if [%1]==[] goto error

set obj2=
if [%2]==[] goto comp
set obj2=+%2.obj

:comp
bcx /o /Ot /Fs /G2 /Fpi %1.bas;
if errorlevel 1 goto end

linkx %1.obj%obj2%,,nul,..\lib\b4gx.lib+bcl71efr.lib;
if exist %1.obj del %1.obj

goto end

:error
echo. usage: mk2qbx basfile

:end
