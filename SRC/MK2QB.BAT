@echo off
rem
rem creates b4g.lib and b4g.qlb (that works with QB4.5)
rem

set MAKE2=QB
set ML611C=ml611
call nmake.exe
set ML611C=
set MAKE2=
