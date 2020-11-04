##
## make file to create xmem.lib
##

.SUFFIXES:

LIB     = xmem

!if     ("$(MAKE2)"=="QB")
ASMCMD  = $(ML611C) /c /Cp
!else
ASMCMD  = $(ML611C) /c /Cp /D__FAR_STRINGS__
!endif

LIBCMD = lib /NOI

INC    = common.inc ..\inc\equ.inc ..\inc\addr.inc ..\inc\dpmi.inc\
         ..\inc\bas.inc ..\inc\core.inc ..\inc\xmem.inc
SRC    = block.asm heap.asm linear.asm xmalloc.asm xmcalloc.asm\
         xmralloc.asm xmfree.asm xmmove.asm xmfill.asm xmmovef.asm\
         xmpeek.asm xmpoke.asm xmavail.asm xmdump.asm

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
