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
    ldr r11,=#0
    ldr r12,=#0
    @ --- Configure Button A (P0.14) ---
             
    ldr r0, =0x50000738    @ PIN_CNF[14]
    ldr r1, =0x0000000C    @ Bits for: Input + Pull-up
    str r1, [r0]

    ldr r0, =0x5000075C    @ PIN_CNF[14]
    ldr r1, =0x0000000C    @ Bits for: Input + Pull-up
    str r1, [r0]
     @setting state 2 in ram

    ldr r0,=0x20000000
    @ row1-5
    ldr r7,=0b00000
    str r7,[r0]
    ldr r7,=0b00000
    str r7,[r0, #4]
    ldr r7,=0b00000
    str r7,[r0, #8]
    ldr r7,=0b00000
    str r7,[r0, #12]
    ldr r7,=0b00100
    str r7,[r0, #16]

    add r0,r0,#20 @adderss for the skull 
    @ making skull
    ldr r7,=0b01110
    str r7,[r0]
    ldr r7,=0b10101
    str r7,[r0, #4]
    ldr r7,=0b11111
    str r7,[r0, #8]
    ldr r7,=0b01110
    str r7,[r0, #12]
    ldr r7,=0b01110
    str r7,[r0, #16]



    @ setting state 1 in registers
    @ --- 2. Load Image Data into r1-r5 ---
    @ A '1' bit means LED ON. We use 5 bits (LSB).
    ldr r1, =0b11111   @ Row 1 ( . X . X . )
    ldr r2, =0b10001   @ Row 2 ( X X X X X )
    ldr r3, =0b11011 @ Row 3 ( X X X X X )
    ldr r4, =0b11111   @ Row 4 ( . X X X . )
    ldr r5, =0b10001   @ Row 5 ( . . X . . )

    b game_loop


@ bx lr only works one layer deep
    

game_loop:
    

    mov r10,#1
    render:
       bl loop
       subs r10,r10,#1
        bne render
    
    bl store_swap 
    add r12, r12, #1
    cmp r12, #100        @ Try 100 for ~1.5 seconds
    it ge
    blge move_rock   
    
    mov r10,#1
    render1:
            @ stores 
        bl loop               @ Call your 5-row scan
        subs r10, r10, #1
        bne render1
        
    bl store_swap
    
    ldr r0, =0x50000510    @ GPIO P0 IN Register
    ldr r10, [r0]           @ Read all pins on Port 0
    tst r10, #(1 << 14)     @ Test bit 14 (Button A)
    it eq                  @ If result is 0 (Equal to zero), button is PRESSED
    bleq move_left        @ Call your swap function!


    tst r10, #(1 << 23)     @ Test bit 23 (Button B)
    it eq                  @ If result is 0 (Equal to zero), button is PRESSED
    bleq move_right       @ Call your swap function!


    add r11, r11, #1
    cmp r11, #20         @ Try 100 for ~1.5 seconds
    it ge
    blge shoot_up        @ This MUST reset r11 to 0 inside the function

    
    
    b game_loop

loop:
    push {lr}
    @ --- Row 1 ---
    mov r6, r1          @ Get Row 1 data
    ldr r7 ,=(1<<21)    @ Row 1 Pin (P0.21)
    bl  display_row

    @ --- Row 2 ---
    mov r6 , r2
    ldr r7 , =(1<<22)    @ Row 2 Pin (P0.22)
    bl  display_row

    @ --- Row 3 ---
    mov r6 , r3
    ldr r7 ,=(1<<15)    @ Row 3 Pin (P0.15)
    bl  display_row

    @ --- Row 4 ---
    mov r6, r4
    ldr r7, =(1<<24)    @ Row 4 Pin (P0.24)
    bl  display_row

    @ --- Row 5 ---
    mov r6 ,r5
    ldr r7, =(1<<19)    @ Row 5 Pin (P0.19)
    bl  display_row

    pop {pc}
@ --- Subroutine: Display a Row ---
@ r6 = row data bits, r7 = row pin mask
display_row: @r7 is my the row which is active,@ r6 stores what to display 
    @0x5000050C outclr(low) for P0.x
    @0x5000080C outclr(low) for P1.x (clm 4,5)
    @0x50000508 outset(high) for P0.x
    @0x50000808 outset(high) for P1.x
    
    @setting all clm to high and main value too high , now trying cmp thing 
    ldr r0 ,=0x50000508
    ldr r8 ,=((1<<28)|(1<<11)|(1<<30)|(1<<31))
    str r8 ,[r0]

    
    ldr r0 ,=0x50000808
    ldr r8 ,=(1<<5)
    str r8 ,[r0]

    ldr r0 ,=0x50000508
    str r7 ,[r0]

    
    @ some optimization i could use r1 for this code too
    @ bit masking r6 to check which leds turn on (stored in r8 , r7 as temp register)
    @ Don't like this wanted to implement it diffreently but IT restriction only allow this way, Now it looks like a variable change
        @ clm 4 
        ldr r0 ,=0x5000080C
        mov r8,#1<<5

        tst r6,#(1<<1)
        ite ne
        orrne r8,r8,r8
        andeq r8, r8,#0b11111111111111111111111111011111
        str r8, [r0]
        
        mov r8, #0
        @right most led so clm 5
          @clm 3
        orr r8,r8,#(1<<31)
        tst r6, #(1<<2)
        ite ne
        orrne r8,r8,r8
        andeq r8, r8,#0b01111111111111111111111111111111
        
        @ldr r10 ,=(1<<30)

        orr r8,r8,#(1<<30)
        tst r6, #1
        ite ne
        orrne r8,r8,r8
        andeq r8, r8,#0b10111111111111111111111111111111

      
        @clm 2
        @ldr r10 ,=((1<<11))
        orr r8,r8,#(1<<11)
        tst r6, #(1<<3)
        ite ne
        orrne r8,r8,r8
        andeq r8, r8,#0b11111111111111111111011111111111

        @clm 1
        @ldr r10 ,=((1<<28))
        orr r8,r8,#(1<<28)
        tst r6, #(1<<4)
        ite ne
        orrne r8,r8,r8
        andeq r8, r8,#0b11101111111111111111111111111111

    ldr r0,=0x5000050C
    str r8,[r0]

    
    mov r9,#(1<<16)
    delay_loop:
        subs r9,r9,#1
        bne delay_loop

    ldr r0 ,=0x5000050C
    str r7 ,[r0]
    
    bx lr


store_swap:@bring the  state 1 in memory and bring state 2 out of it
    @ using 3 register (1.copy temp(r7) 2. address holder(r0)) @we need to switch r1,r2,r3,r4,r5
    ldr r0,=0x20000000 @ starting value of ram
    
    @row 1
    mov r7,r1 @ copiped r1 to store
    ldr r1,[r0] @ load the new value in r1
    str r7,[r0] @ store the old value from r7 in the ram 

    @ row 2
    mov r7,r2 @ copiped r2 to store old value in r7
    ldr r2,[r0, #4] @ load the new value in r2
    str r7,[r0, #4] @ store the old value from r7 in the ram 

    @ @ row 3
    mov r7,r3 @ copiped r3 to store old value in r7
    ldr r3,[r0, #8] @ load the new value in r3
    str r7,[r0, #8] @ store the old value from r7 in the ram 
    
    @ row 4
    mov r7,r4 @ copiped r4 to store old value in r7
    ldr r4,[r0, #12] @ load the new value in r4
    str r7,[r0, #12] @ store the old value from r7 in the ram 

   @ row 5    
    mov r7,r5 @ copiped r5 to store old value in r7
    ldr r5,[r0, #16] @ load the new value in r5
    str r7,[r0, #16] @ store the old value from r7 in the ram 
    
    mov r9,#(1<<11)
    delay_loopbutton:
        subs r9,r9,#1
        bne delay_loopbutton
    
    bx lr



@ @ to try this sinnpet (by displaing the outputs) [Can the register values if conflicting]
get_random_byte:
    push {r1, r2}
    
    @ 1. Start the RNG Task
    ldr r0, =0x4000D000    @ TASKS_START
    mov r1, #1
    str r1, [r0]

    @ 2. Wait for the Value Ready Event
    ldr r0, =0x4000D100    @ EVENTS_VALRDY
wait_rng:
    ldr r1, [r0]           @ Read the event register
    cmp r1, #0             @ Is it still 0?
    beq wait_rng           @ If yes, keep waiting

    @ 3. Clear the Event (Mandatory for next time)
    mov r1, #0
    str r1, [r0]

    @ 4. Read the Random Byte
    ldr r0, =0x4000D508    @ VALUE register
    ldr r0, [r0]           @ r0 now contains a number 0-255
    and r0,r0, #0b11111   @ so that any new value can fit in the row
    pop {r1, r2}
    mov r1,r0
    bx lr

 
move_rock:
    @ i don't need 7&6 so they will be used
    mov r5, r4    @ Row 4 moves to Row 5
    mov r4, r3    @ Row 3 moves to Row 4
    mov r3, r2    @ Row 2 moves to Row 3
    mov r2, r1    @ Row 1 moves to Row 2

    push {lr}     @ Save Link Register because we are calling another function
    bl get_random_byte
    mov r1, r0    @ New random row data into Row 1
    ldr r12,=#0
    pop {pc}      @ Return
    
shoot_up:

    mov r1,r2
    mov r2,r3
    mov r3,r4
    mov r4,r5
    push {lr}  
    ldr r11,=#0

    
   
    pop {pc}
move_left:
    @ and Button A (Left) is pressed:
        lsl r5, r5, #1    @ Move player left
        cmp r5, #(1 << 5) @ Check if we went off the 5-bit screen
        it hs             @ If Higher or Same
        movhs r5, #(1 << 4) @ Snap back to leftmost column (bit 4)
          bx lr
move_right:
    @ and Button B (Right) is pressed:
        lsr r5, r5, #1    @ Move player right
        cmp r5, #0        @ Check if we shifted out to zero
        it eq
        moveq r5, #1      @ Snap back to rightmost column (bit 0)
      bx lr

compare_score:

@ Ram starting 0x20000000

