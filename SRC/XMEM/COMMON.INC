;;
;; internal xmem module definitions
;;

                .model  medium, basic
                .486
                option  proc:private
                
                include ..\inc\equ.inc
                include ..\inc\addr.inc
                include ..\inc\dpmi.inc
                include ..\inc\core.inc
                include ..\inc\xmem.inc

                BLOCK_MIN       equ 100000h     ;; 1M

HEAP            struct                          ;; heap header
                prev            dword   ?
                next            dword   ?
                _size           dword   ?       ;; w/o header
                handle          dword   ?
                fblk_head       dword   ?       ;; free block list head
HEAP            ends

BLOCK           struct                          ;; allocated block header
                prev            dword   ?       ;; preview physical block
                next            dword   ?       ;; next       "       "
                _size           dword   ?       ;; w/o header
                heap            dword   ?
BLOCK           ends

FBLOCK          struct                          ;; free block header
                                BLOCK   <>
                prevf           dword   ?       ;; preview logical block
                nextf           dword   ?       ;; next       "      "
FBLOCK          ends

                STC_DIFF        equ T FBLOCK - T BLOCK

                ;; - the physical list have free and allocated blocks that 
                ;;   _must_ follow a sequential order inside the heap
                ;;
                ;; - the logical list have _only_ free blocks that can be
                ;;   anywhere inside the heap


                ;; globals :::::

                ;; from heap.asm:
                global  xm$free_mem_inf:byte
                global  xm$heap_tail:dword
                global  xm$heap_alloc:near32
                global  xm$heap_erase:near32
                
                ;; from block.asm:
                global  xm$block_find:near32
                global  xm$block_split:near32


comment ^
 .___________.
 | heap tail |--------------------------------+
 `~~~~~~~~~~~'                                |
        .____________.   .__________.   ._____v_____.
 NULL<--| first heap |<->| ... heap |<->| last heap |-->NULL
        `~~~~~~~~~~~~'   `~~~~~~~~~~'   `~~~~~~~~~~~'
       .________________________________.
 heap= | heap header | heap space . . . |
       `~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
              ._________________________________________________________.
 heap header= | preview heap | next heap | heap size | free block head  |
              `~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
             ._____________________________________________________________.
 heap space= | blk header | allocated blk | blk hdr | free blk space | ... |
             `~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
               .__________________________________________________________.
 block header= | preview blk | next blk | blk size | blk heap (0 if free) |
               | if blk is free: preview free blk | next free blk         |
               `~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
              .______________________.
 block space= | anything you want ;) |
              `~~~~~~~~~~~~~~~~~~~~~~'
^
