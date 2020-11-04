@echo off
rem
rem compiles an example file and link w/ b4g.lib
rem

if [%1]==[] goto error

set obj2=
if [%2]==[] goto comp
set obj2=+%2.obj

:comp
bc /o /Fpi %1.bas;
if errorlevel 1 goto end

link %1.obj%obj2%,,nul,..\lib\b4g.lib+bcom45.lib;
if exist %1.obj del %1.obj

goto end

:error
echo. usage: mk2qb basfile

:end
