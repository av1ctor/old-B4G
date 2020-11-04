@echo off
rem
rem creates b4gv.lib and b4gv.qlb (that works with VBDOS)
rem

set MAKE2=VBD
set ML611C=ml611
call nmake.exe
set ML611C=
set MAKE2=
