##
## make file to create xmap.lib
##

.SUFFIXES:

LIB     = xmap

!if     ("$(MAKE2)"=="QB")
ASMCMD  = $(ML611C) /c /Cp
!else
ASMCMD  = $(ML611C) /c /Cp /D__FAR_STRINGS__
!endif

LIBCMD = lib /NOI

INC    = common.inc ..\inc\equ.inc ..\inc\addr.inc ..\inc\bas.inc\
         ..\inc\core.inc ..\inc\mem.inc ..\inc\xmap.inc
SRC    = xmap.asm xmappeek.asm xmappoke.asm

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
