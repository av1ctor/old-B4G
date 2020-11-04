[LIBRARY]
[
  description   : BASIC/4G is a functions library that allows use
                  of 32-bit protected-mode assembly routines with
                  Microsoft BASIC interpreters and/or compilers.
                  break the DOS memory limit. use all memory your
                  system has with your programs.
   
  version       : 1E-32b (0.00000....1 Beta)

  date          : 10/23/2000

  price         : zero

  rights        : none. free for use in commercial ;), shareware and
                  freeware applications.

  use           : unlimited (if you know what i mean :])

  source code   : included (do what you want with it)

  requirement   : * a 32-bit processor (386 or great);

                  * a Microsoft BASIC interpreter and/or
                    compiler (QuickBASIC 4.x, PDS 6+ or
                    VBDOS 1) and their tools (LINK, LIB);

                  * a DPMI host (CWSDPMI; 386MAX; Windows 3.x, 9x;
                    OS/2; DOSEmu).

  warranty      : ABSOLUTELY NONE. 
]

[CHANGES]
[
  additions     : * DPMI services wrapper;

                  * VBE 2.0 Linear Frame Buffer example.

  corrections   : * saves ES selector in interrupt(x)386 functions;

                  * now VBDOS interprets the underscore char as
                    line continuation (a space more and voila :]);

                  * some (a lot) words incorrectly written. i must
                    buy a dictionary.
]

[DISTRIBUTION]
[
  readme.txt    this file

  \bi\b4g.bi    BASIC include file with library modules definitions
                and prototypes

  \doc\         (crappy) documentation directory
   core.txt     about core module routines
   mem.txt        /   mem     /      /
   xfile.txt      /   xfile   /      /
   xmap.txt       /   xmap    /      /
   xmem.txt       /   xmem    /      /
   dpmi09.txt   DPMI version 0.9 specification

  \lib\         compiled library directory
   b4g.lib      for use with QuickBASIC 4.x compiler
   b4g.qlb           /           /       /  interpreter
   b4gv.lib          /       VBDOS 1 compiler
   b4gv.qlb          /          /    interpreter
   b4gx.lib          /       PDS 6+  compiler
   b4gx.qlb          /          /    interpreter
  
  \sample\      (stupid) examples directory
   cwsdpmi.exe  CWS DPMI host (needed to run the examples in DOS)
   mk2*.bat     batch files to compile the examples at command line
   ... i'm too lazy to type all files names, browse it if you want :) ...

  \src\         library source code directory
   scr.zip      "unzip -d" and see (9K lines of well
                written (modestly saying :}) assembly code)

]

[HOSTS]
[
  works         : * Windows ver. 3.1 and 9x;
                  * CWSDPMI rel. 4 (special edition. see CWSDPMI section);
                  * 386MAX ver. 7 and 8.

  crashes       : * QDPMI ver. 8 and 9: never returns to V86 mode in some 
                    cases. cause: unknown. i can't debug it using 386SWAT :(.

  untested      : * any others older versions of the hosts above;
                  * Windows NT/2000;
                  * Linux/DOSEmu;
                  * OS/2.
]

[CWSDPMI]
[
  the CWS DPMI host included in this package (the cwsdpmi.exe file) isn't
  the same that comes with DJGPP's programs. it's a modified version made
  to run together with B4G. the changes allow CWS to allocate page-tables
  using DOS memory services with BASIC's memory manager behind. also, this
  modified version _enables_ hardware interrupts to occur when it switches
  the processor to real mode (while the original version doesn't).

  programs that use the B4G library and run in RAW/XMS or VCPI modes, will
  _not_ work with the original CWSDPMI version.
  
  CWSDPMI is copyrighted (C) by CW Sandmann [sandmann@clio.rice.edu].
  original sources: ftp.simtel.net/pub/simtelnet/gnu/djgpp/v2misc/csdpmi4s.zip
  send me an e-mail if you want the modified sources (see CONTACT section).
]

[TODO]
[
  * DPMI emulation in RAW (INT 15h) / XMS (HIMEM.SYS) and
    VCPI (EMM386, QEMM, 386MAX) modes;

  * learn English and be less lazy to write more (and better)
    docs and examples =).
]

[BUGS]
[
  found any? report it, see CONTACT section.
]

[MAKE]
[
  to re-assemble the library is needed:
  * Microsoft maker      : (NMAKER) version 1.2x
  *     /     assembler  : (MASM 32-bit (ML)) version 6.11c
  *     /     linker     : (LINK) version 5.x
  *     /     lib manager: (LIB) version 3.x
]

[NOTES]
[
  * to create executables with QuickBASIC 4.0, you must
    use a newer linker version. the linker that comes with
    QB40 doesn't make correct fix ups in USE32 code segments
    types, so the program linked by it will crash.

  * the BASIC's SHELL function no more works (cause: unknown);

  * ML.EXE in the versions 6.13, 6.14 and 6.15 seems to have
    "forgotten" what the directive 'externdef' means, so, the
    library can't be assembled using it (dear God, how they (M$)
    could? :p).
]

[TOOLS]
[
  docs          : * DPMI specification (see /doc dir);
                  * Ralf Brown's Interrupt List (www.pobox.com/~ralf).

  progs         : * SOFT-ICE (for debug in Windows);
                  * 386SWAT (for debug in DOS);
                  * TurboC (to re-compile CWS);
                  * M$-DOS editor (guess what :]).
]

[THANKS]
[
  * all the people that have downloaded it;

  * the guys that have used it for create awesome programs...well...,
    no one have used it (at least that i know)...anyways...;
]

[CONTACT]
[
  email: av1ctor@yahoo.com.br
]

[DISCLAIMER]
[
  i know, it isn't necessary but...here it goes... 

  this documentation and its associated software are distributed
  without warranties, either expressed or implied, regarding their
  merchantability or fitness for any particular application or purpose.
  in no event shall Andre Victor be liable for any loss of profit or
  any other commercial damage, including but not limited to special,
  incidental, consequential, or other damages resulting from the use
  of or the inability to use this product, even if Andre Victor has been
  notified of the possibility of such damages.

  all brand and product names mentioned in this documentation are
  trademarks or registered trademarks of their respective holders.
]
