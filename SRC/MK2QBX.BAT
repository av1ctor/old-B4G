@echo off
rem
rem creates b4gx.lib and b4gx.qlb (that works with QB7.x)
rem

set MAKE2=QBX
set ML611C=ml611
call nmake.exe
set ML611C=
set MAKE2=
