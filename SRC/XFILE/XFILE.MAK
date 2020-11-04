##
## make file to create xfile.lib
##

.SUFFIXES:

LIB     = xfile

!if     ("$(MAKE2)"=="QB")
ASMCMD  = $(ML611C) /c /Cp
!else
ASMCMD  = $(ML611C) /c /Cp /D__FAR_STRINGS__
!endif

LIBCMD = lib /NOI

INC    = common.inc ..\inc\equ.inc ..\inc\addr.inc ..\inc\dos.inc\
         ..\inc\bas.inc ..\inc\mem.inc ..\inc\core.inc ..\inc\xfile.inc
SRC    = b2z.asm xfhandle.asm xfopen.asm xfclose.asm xfread.asm\
         xfwrite.asm xfseek.asm xfpos.asm xfsize.asm xfflush.asm

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
