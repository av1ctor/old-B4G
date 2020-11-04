##
## make file to create core.lib
##

.SUFFIXES:

LIB     = core

!if     ("$(MAKE2)"=="QB")
ASMCMD  = $(ML611C) /c /Cp
!else
ASMCMD  = $(ML611C) /c /Cp /D__FAR_STRINGS__
!endif

LIBCMD  = lib /NOI

INC     = common.inc ..\inc\addr.inc ..\inc\equ.inc ..\inc\dos.inc\
          ..\inc\dpmi.inc ..\inc\bas.inc ..\inc\core.inc
SRC     = init.asm done.asm call.asm int.asm excpt.asm dpmi_wp.asm

all:            include source $(LIB).lib

include:        $(INC)

source:         $(SRC)
                $(ASMCMD) @<<
                $(?: =^
                )
<<

$(LIB).lib:     $(SRC:.asm=.obj)
                if exist $@ del $@
                $(LIBCMD) $@ @<<
                +$(?: = &^
                +)
                ;
<<
                !if exist $** del $**
