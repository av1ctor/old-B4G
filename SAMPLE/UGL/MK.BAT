@echo off
rem
rem make ugl_test example
rem

bc /o /Fpi ugl_test.bas;
if errorlevel 1 goto end

link ugl_test.obj+ugl.obj+kbd.obj,,nul,..\..\lib\b4g.lib+bcom45.lib;
if exist ugl_test.obj del ugl_test.obj
