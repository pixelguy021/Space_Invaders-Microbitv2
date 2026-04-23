@ --- Micro:bit v2 Bare Metal Assembly (LED Matrix Scan) ---
.syntax unified
.cpu cortex-m4
.thumb

@ --- Vector Table ---
.section .vectors
    .word 0x20020000      @ Initial Stack Pointer
    .word _start + 1      @ Reset Handler

.text
.global _start

_start:
    @ --- 1. Set Pin Directions to Output ---
    @ Port 0: Rows (21,22,15,24,19) and Cols (28,11,31,30)
    ldr r0, =0x50000518      @ GPIO P0 DIRSET
    ldr r1, =((1<<21)|(1<<22)|(1<<15)|(1<<24)|(1<<19) | (1<<28)|(1<<11)|(1<<31)|(1<<30))
    str r1, [r0]

    @ Port 1: Col 4 (Pin 5)
    ldr r0, =0x50000818      @ GPIO P1 DIRSET
    ldr r1, =(1<<5)
    str r1, [r0]

    @ --- 2. Load Image Data into r1-r5 ---
    @ A '1' bit means LED ON. We use 5 bits (LSB).
    ldr r1, =0b01010   @ Row 1 ( . X . X . )
    ldr r2, =0b11111   @ Row 2 ( X X X X X )
    ldr r3, =0b11111   @ Row 3 ( X X X X X )
    ldr r4, =0b01110   @ Row 4 ( . X X X . )
    ldr r5, =0b00100   @ Row 5 ( . . X . . )

    bl display_row
loop:
    @ --- Row 1 ---
    mov r6, r1          @ Get Row 1 data
    mov r7, #(1<<21)    @ Row 1 Pin (P0.21)
    bl  display_row

    @ --- Row 2 ---
    mov r6, r2
    mov r7, #(1<<22)    @ Row 2 Pin (P0.22)
    bl  display_row

    @ --- Row 3 ---
    mov r6, r3
    mov r7, #(1<<15)    @ Row 3 Pin (P0.15)
    bl  display_row

    @ --- Row 4 ---
    mov r6, r4
    mov r7, #(1<<24)    @ Row 4 Pin (P0.24)
    bl  display_row

    @ --- Row 5 ---
    mov r6, r5
    mov r7, #(1<<19)    @ Row 5 Pin (P0.19)
    bl  display_row


@ --- Subroutine: Display a Row ---
@ r6 = row data bits, r7 = row pin mask
display_row: @r7 is my the row which is active,@ r6 stores what to display 
    @0x5000050C outclr(low) for P0.x
    @0x5000080C outclr(low) for P1.x (clm 4,5)
    @0x50000508 outset(high) for P0.x
    @0x50000808 outset(high) for P1.x

    @setting all rows to low
    ldr r0 ,=0x5000050C
    ldr r8 ,=((1<<28)|(1<<11)|(1<<30)|(1<<31))
    str r8 ,[r0]

    ldr r0 ,=0x5000080C
    ldr r8 ,=(1<<5)
    str r8 ,[r0]
    @this much code works.. i will make git hub for this now :)
    
    @ for testing just setting row3 as high
    ldr r0 ,=0x50000508
    ldr r8 ,=((1<<15)|(1<<21)|(1<<19))
    str r8 ,[r0]
    
    