@echo off
rem
rem make lfb example
rem

c:\prg\cmp\qb\bcq.exe /o /fpi lfb.bas;
if errorlevel 1 goto end
c:\prg\cmp\qb\bcq.exe /o /fpi vbe2.bas;
if errorlevel 1 goto end

c:\prg\cmp\qb\linkq.exe lfb.obj+vbe2.obj,,nul,..\..\lib\b4g.lib+c:\prg\cmp\qb\lib\bcom45.lib+c:\prg\cmp\qb\lib\qb.lib;

if exist lfb.obj del lfb.obj
if exist vbe2.obj del vbe2.obj

:end
