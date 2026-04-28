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

@ i will rewrite by code 
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

    @ =r1 will be the rock array ( main in the begin)
    @ r2 will be the shoot array (secondary)
    @ r3 will be player row
    @ row1-5
    




    @ add r0,r0,#20 @adderss for the skull 
    @ @ making skull
    @ ldr r7,=0b01110
    @ str r7,[r0]
    @ ldr r7,=0b10101
    @ str r7,[r0, #4]
    @ ldr r7,=0b11111
    @ str r7,[r0, #8]
    @ ldr r7,=0b01110
    @ str r7,[r0, #12]
    @ ldr r7,=0b01110
    @ str r7,[r0, #16]



    @ setting state 1 in registers
    @ --- 2. Load Image Data into r1-r5 ---
    @ A '1' bit means LED ON. We use 5 bits (LSB).
    ldr r1, =0b0000000000000000000000000   @ Row 1 ( . X . X . )
    ldr r2, =0b0000000000000000000000000
    ldr r3, =0b0000000000000000000000100
    ldr r8, =#0
    b game_loop


@ bx lr only works one layer deep
    
 
game_loop:


    


    add r12, r12, #1
    cmp r12, #32    @ Try 100 for ~1.5 seconds
    it ge
    blge move_rock   
    
    mov r10,#1
    render1:
            @ stores 
        bl loop               @ Call your 5-row scan
        subs r10, r10, #1
        bne render1
        
        @ swap
    mov r7,r1
    mov r1,r2
    mov r2,r7
       @ swap ends
    
    ldr r0, =0x50000510    @ GPIO P0 IN Register
    ldr r10, [r0]           @ Read all pins on Port 0
    tst r10, #(1 << 14)     @ Test bit 14 (Button A)
    it eq                  @ If result is 0 (Equal to zero), button is PRESSED
    bleq move_left        @ Call your swap function!


    tst r10, #(1 << 23)     @ Test bit 23 (Button B)
    it eq                  @ If result is 0 (Equal to zero), button is PRESSED
    bleq move_right       @ Call your swap function!


    add r11, r11, #1
    cmp r11, #10      @ Try 100 for ~1.5 seconds
    it ge
    blge shoot_up        @ This MUST reset r11 to 0 inside the function

    bl collison_Scheck

    mov r10,#2
    render:
       bl loop
       subs r10,r10,#1
        bne render
            @ swap
    mov r7,r1
    mov r1,r2
    mov r2,r7
       @ swap end
    

    @ cmp r11, #19         @ Try 100 for ~1.5 seconds
    @ it ge
    @ blge collison_check

    
    
    b game_loop

loop:
    push {lr}
    @ --- Row 1 ---
    mov r6,r1 @ our temp register r6
    @modify this r6

    @first row
    ldr r7,=(1<<21)
    bl display_row
    
    lsr r6,r6,5
    ldr r7,=(1<<22)

    bl display_row

    lsr r6,r6,5
    ldr r7,=(1<<15)

    bl display_row

    lsr r6,r6,5
    ldr r7,=(1<<24)

    bl display_row

    lsr r6,r6,5
    ldr r7,=(1<<19)

    bl display_row

    mov r6,r3
    ldr r7,=(1<<19)
    bl display_row

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
    ldr r5 ,=((1<<28)|(1<<11)|(1<<30)|(1<<31))
    str r5 ,[r0]

    
    ldr r0 ,=0x50000808
    ldr r5 ,=(1<<5)
    str r5 ,[r0]

    ldr r0 ,=0x50000508
    str r7 ,[r0]

    
    @ some optimization i could use r1 for this code too
    @ bit masking r6 to check which leds turn on (stored in r5 , r7 as temp register)
    @ Don't like this wanted to implement it diffreently but IT restriction only allow this way, Now it looks like a variable change
        @ clm 4 
        ldr r0 ,=0x5000080C
        mov r5,#1<<5

        tst r6,#(1<<1)
        ite ne
        orrne r5,r5,r5
        andeq r5, r5,#0b11111111111111111111111111011111
        str r5, [r0]
        
        mov r5, #0
        @right most led so clm 5
          @clm 3
        orr r5,r5,#(1<<31)
        tst r6, #(1<<2)
        ite ne
        orrne r5,r5,r5
        andeq r5, r5,#0b01111111111111111111111111111111
        
        @ldr r10 ,=(1<<30)

        orr r5,r5,#(1<<30)
        tst r6, #1
        ite ne
        orrne r5,r5,r5
        andeq r5, r5,#0b10111111111111111111111111111111

      
        @clm 2
        @ldr r10 ,=((1<<11))
        orr r5,r5,#(1<<11)
        tst r6, #(1<<3)
        ite ne
        orrne r5,r5,r5
        andeq r5, r5,#0b11111111111111111111011111111111

        @clm 1
        @ldr r10 ,=((1<<28))
        orr r5,r5,#(1<<28)
        tst r6, #(1<<4)
        ite ne
        orrne r5,r5,r5
        andeq r5, r5,#0b11101111111111111111111111111111

    ldr r0,=0x5000050C
    str r5,[r0]

    
    mov r9,#(1<<14)
    delay_loop:
        subs r9,r9,#1
        bne delay_loop

    ldr r0 ,=0x5000050C
    str r7 ,[r0]
    
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
    @ mov r5, r4    @ Row 4 moves to Row 5
    @ mov r4, r3    @ Row 3 moves to Row 4
    @ mov r3, r2    @ Row 2 moves to Row 3
    @ mov r2, r1    @ Row 1 moves to Row 2
    lsl r1,r1,5 
    @ i need in the last 5 bit any one is 1 after the move the trigger game over
    ldr r5,=#0b00000001111100000000000000000000
    and r5,r1,r5 @ the top 5 bits
    cmp r5,#0
    bne game_over

    mov r5,r1
    push {lr}     @ Save Link Register because we are calling another function
    bl get_random_byte
    orr r1,r5,r0    @ New random row data into Row 1
    ldr r12,=#0
    pop {pc}      @ Return
    
shoot_up:

    @ mov r1,r2
    @ mov r2,r3
    @ mov r3,r4
    @ mov r4,r5
    lsr r1,r1,5
    lsl r5,r3,15
    orr r1,r1,r5
    push {lr}  
    ldr r11,=#0

    pop {pc}
move_left:
    @ and Button A (Left) is pressed:
        lsl r3, r3, #1    @ Move player left
        cmp r3, #(1 << 5) @ Check if we went off the 5-bit screen
        it hs             @ If Higher or Same
        movhs r3, #(1 << 4) @ Snap back to leftmost column (bit 4)
        bx lr
move_right:
    @ and Button B (Right) is pressed:
        lsr r3, r3, #1    @ Move player right
        cmp r3, #0        @ Check if we shifted out to zero
        it eq
        moveq r3, #1      @ Snap back to rightmost column (bit 0)
      bx lr

collison_Scheck:@ considering bullets are in r1 , so after 1 swap
    push {lr}
    eor r4,r1,r2  @xor of both
    mov r5,r2 @ copy of old bits for score 
    @ FOR ROCK
    and r2,r2,r4
    @  old - new and num of in them should give me score
    sub r5,r5,r2 @ old - new
    @ count number of bits in r5
    count:
        tst r5,#1 
        it ne
        addne r8,r8,#1
        lsr r5,r5,1
        cmp r5,#0
        bne count
    @ the score would be number of bits in 

    @ for shooting
    and r1,r1,r4
    @ no score for now
    pop {pc}
@ Ram starting 0x20000000

game_over:
    ldr r1,=#0b00011100111001110111111010101110
    
    ldr r3,=#0
    mov r10,#270
    render3:
       bl loop
       subs r10,r10,#1
        bne render3

    mov r1,r8

    render4:
        bl loop
        b render4


    
    
    
    
    