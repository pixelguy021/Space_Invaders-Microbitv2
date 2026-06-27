@ --- Micro:bit v3 Bare Metal Assembly (LED Matrix Scan) ---

.syntax unified

.cpu cortex-m4

.thumb

  

@ --- Vector Table ---

.section .vectors

.word 0x20020000 @ Initial Stack Pointer

.word _start + 1 @ Reset Handler

  

.text

.global _start

  

@ i will rewrite by code

_start: @ reg used [0,1,11,12,2,3,8,9,7]

@ --- 1. Set Pin Directions to Output ---

@ Port 0: Rows (21,22,15,24,19) and Cols (28,11,31,30)

ldr r0, =0x50000518 @ GPIO P0 DIRSET

ldr r7, =((1<<21)|(1<<22)|(1<<15)|(1<<24)|(1<<19) | (1<<28)|(1<<11)|(1<<31)|(1<<30))

str r7, [r0]

  

@ Port 1: Col 4 (Pin 5)

ldr r0, =0x50000818 @ GPIO P1 DIRSET

ldr r7, =(1<<5)

str r7, [r0]

  

@ --- Configure Button A (P0.14) ---

ldr r0, =0x50000738 @ PIN_CNF[14]

ldr r7, =0x0000000C @ Bits for: Input + Pull-up

str r7, [r0]

  

ldr r0, =0x5000075C @ PIN_CNF[14]

ldr r7, =0x0000000C @ Bits for: Input + Pull-up

str r7, [r0]

@setting state 2 in ram

  

@ A '1' bit means LED ON. we shift lsl to travel

ldr r1, =0b0000000000000000000000000 @ intial rock state

ldr r2, =0b0000000000000000000000000

ldr r3, =0b0000000000000000000000100

ldr r8, =#0 @ score counter

ldr r9, =#3 @ remaning live (of course you start the game once)

ldr r11,=#0 @ shoot up tick

ldr r12,=#0 @ move rock tick

b game_loop

  
  
  
  

game_loop: @ reg used [12,10,7,1,2,11]

  
  

add r12, r12, #1

cmp r12, #50 @tick rate (how often to check based on the speed of game loop)

it ge

blge move_rock

cmp r12, #0

it eq

bleq collison_Scheck

  

@ can also do as (better)

@ itt

@ blge collison code

  

mov r10,#1

render1:

@ stores

bl loop @ display code

subs r10, r10, #1

bne render1

@ swap

mov r7,r1

mov r1,r2

mov r2,r7

@ swap ends

tst r11,#11

it eq

bleq buttons

  
  

add r11, r11, #1

cmp r11, #15 @ tick rate

it ge

blge shoot_up

  

cmp r11, #0

it eq

bleq collison_Scheck

  

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

b game_loop

  

loop: @ reg used [6,1,7]

push {lr}

mov r6,r1 @ our temp register r6

@ we left shift r

  

@first row

ldr r7,=(1<<21)

bl display_row

@ second

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

  

@ displays the playerseprately

mov r6,r3

ldr r7,=(1<<19)

bl display_row

  

pop {pc}

  

display_row: @ reg used [0,5,6,7] r0 for address r7 is my the row which is active,@ r6 stores what to display

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

  

@ bit masking r6 to check which leds turn on (stored in r5 , r7 as temp register)

@ and eq thing is done to say one regisyer

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

  

@ freed r5 to save register r9 .. may but it as life counter

mov r5,#(1<<14)

delay_loop:

subs r5,r5,#1

bne delay_loop

  

ldr r0 ,=0x5000050C

str r7 ,[r0] @ rests the row to low

bx lr

  

@ [Can the register values if conflicting]

get_random_byte: @ works reg used [1,2,0]

push {r1, r2}

@ 1. Start the RNG Task

ldr r0, =0x4000D000 @ TASKS_START

mov r1, #1

str r1, [r0]

  

@ 2. Wait for the Value Ready Event

ldr r0, =0x4000D100 @ EVENTS_VALRDY

wait_rng:

ldr r1, [r0] @ Read the event register

cmp r1, #0 @ Is it still 0?

beq wait_rng @ If yes, keep waiting

  

@ 3. Clear the Event (Mandatory for next time)

mov r1, #0

str r1, [r0]

  

@ 4. Read the Random Byte

ldr r0, =0x4000D508 @ VALUE register

ldr r0, [r0] @ r0 now contains a number 0-255

and r0,r0, #0b11111 @ so that any new value can fit in the row

pop {r1, r2}

mov r1,r0

bx lr

  

move_rock: @ reg used [1,5,12]

push {lr} @ Save Link Register because we are calling another function

  

lsl r1,r1,5

@ i need in the last 5 bit any one is 1 after the move the trigger game over

ldr r5,=#0b00000001111100000000000000000000

and r5,r1,r5 @ the top 5 bits

cmp r5,#0

bne death

  

mov r5,r1

bl get_random_byte

orr r1,r5,r0 @ New random row data into Row 1

ldr r12,=#0

pop {pc} @ Return

shoot_up: @ reg used [1,5,11]

push {lr}

  

lsr r1,r1,5

lsl r5,r3,15

orr r1,r1,r5

ldr r11,=#0

  

pop {pc}

buttons:

push {lr}

ldr r0, =0x50000510 @ GPIO P0 IN Register

ldr r7, [r0]

tst r7, #(1 << 14) @ Test bit 14 (Button A)

it eq @ if 0 button is pressed

bleq move_left

  
  

tst r7, #(1 << 23) @ Test bit 23 (Button B)

it eq

bleq move_right

  

pop {pc}

  
  

move_left: @reg used [3]@ code to go left

@ and Button A (Left) is pressed:

lsl r3, r3, #1 @ Move player left

cmp r3, #(1 << 5) @ Check if we went off the 5-bit screen

it hs @ If Higher or Same

movhs r3, #(1 << 4) @ Snap back to leftmost column (bit 4)

bx lr

move_right: @ reg used [3]

@ and Button B (Right) is pressed:

lsr r3, r3, #1 @ Move player right

cmp r3, #0 @ Check if we shifted out to zero

it eq

moveq r3, #1 @ Snap back to rightmost column (bit 0)

bx lr

  

collison_Scheck: @ reg[4,1,2,5,8]

@ [note : old thought as the logic is symmetric it doens't matter ] considering bullets are in r1 , so after 1 swap

push {lr}

eor r4,r1,r2 @xor of both

mov r5,r2 @ copy of old bits for score

@ FOR ROCK

and r2,r2,r4

@ old - new and num of in them should give me score

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

  
  
  
  

death: @ reg used [1,3,10,9]

ldr r1,=#0b00011100111001110111111010101110

ldr r3,=#0

mov r10,#270

render3:

bl loop

subs r10,r10,#1

bne render3

@ shows the remaning lifes

  

mov r1,r9

mov r10,#300

render5:

bl loop

subs r10,r10,#1

bne render5

@ if lives remaning = 0 exits else

cmp r9,#0

beq game_over

  

subs r9,r9,1

@ resting game state else it will be too hard.. something collor

ldr r1, =0b0000000000000000000000000

ldr r2, =0b0000000000000000000000000

ldr r3, =0b0000000000000000000000100

  

@ sending back to game bcz not dead

b game_loop

  
  

game_over: @ reg used [1,3,10,8]

  

ldr r1,=#0b00011100111001110111111010101110

ldr r3,=#0

mov r10,#270

render6:

bl loop

subs r10,r10,#1

bne render6

mov r1,r8

  

render4:

bl loop

b render4
