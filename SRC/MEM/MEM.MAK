##
## make file to create mem.lib
##

.SUFFIXES:

LIB     = mem

!if     ("$(MAKE2)"=="QB")
ASMCMD  = $(ML611C) /c /Cp
!else
ASMCMD  = $(ML611C) /c /Cp /D__FAR_STRINGS__
!endif

LIBCMD  = lib /NOI

INC     = common.inc ..\inc\equ.inc ..\inc\dos.inc ..\inc\mem.inc\
          ..\inc\core.inc
SRC     = malloc.asm mfree.asm mrealloc.asm mavail.asm addr.asm

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
