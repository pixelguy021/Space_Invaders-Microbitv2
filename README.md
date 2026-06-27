
## Objective 
The objective of this was to use the microbit v2.2 and create a space invaders/ asteroids like game. The basic working of the game space invaders where aliens come down from the top and you move around to shoot the asteroids to get points :) , pretty neat. (This has rocks instead of aliens so they don't shoot back, and no cover to hide because they are rocks)
<img width="737" height="789" alt="Pasted image 20260327235254" src="https://github.com/user-attachments/assets/4daceb8f-ce55-447e-bed7-79b06a379843" />


## Implementations
The game is implemented using a FSM and 2 ticks which control different functions
#### FSM Diagram 
<img width="1197" height="729" alt="Pasted image 20260429181827" src="https://github.com/user-attachments/assets/86245d31-4d6a-43d1-9114-96258743511f" />

#### Scoring Logic & Hit Detection 
<img width="1398" height="842" alt="Pasted image 20260429192947" src="https://github.com/user-attachments/assets/c6d4cbd5-b909-42d6-8a1f-07395ca9e513" />

#### Rocks moving down & Bullets going up
For Both of these , Left shift , Right shift by 5 to move the value up or down in the led
### Functions used
#### Main functions
##### Game Loop : 
 Run the game in the loop and contains everything side  
##### Move Rock :
Move the Rock down by using left shift . It also check condition for death
##### Buttons :
Runs code access button (added so i can use ticked based system for both of them )
##### Shoot Up
Spawn a new bullet above the player and move all bullets up by 1 row
##### Collision SCheck
Run the hit detection and scoring code
##### Display row
Display the row give to it in r6
##### Death 
Updates life resets to default state and if the lives are 0 then goes to game over

##### Game over
Displays Score
#### Helper functions
##### Loop
Displays the element in r1
##### Get Random byte
Get Random byte uses the in builds RNG generator inside the CPU
##### Wait Rng
Waits for the RNG Generator to give a value 

##### Delay Code
Gives time control by making a  effectively a time.sleep() in assembly
```assmebly
mov r5,#(1<<14)

delay_loop:

subs r5,r5,#1

bne delay_loop
```
Some logic for this is to occupy cpu in a lot of compute so it spends a some time there. It is needed for led to be on for long enough to be visible
### Registers

| Register name | Type      | Function of the Register                                                                          | Functions in which it is changed                                                                                            |
| ------------- | --------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| r0            | Addresses | As temp variable for address                                                                      | start, display_row , get_random_byte                                                                                        |
| r1            | Data      | Initiallized as rock array and switches b/w rock and bullets array<br>(The main working register) | start, game_loop, loop,<br>get_random_byte (can be removed)<br>move_rock, shoot_up ,collision_Scheck ,death , game_over<br> |
| r2            | Data      | Internalized as bullets and switches b/w rock and bullets array<br> (The storage register)        | start,game_loop,get_random byte (can be removed),collison_Scheck                                                            |
| r3            | Data      | Player register (stores where the player is )                                                     | start, move_left, move_right,<br>death, game_over                                                                           |
| r4            | Temp      | Store xor of r1 ,r2 in collison_scheck                                                            | collison_Scheck                                                                                                             |
| r5            | Temp      | General temp variable                                                                             | almost everywhere                                                                                                           |
| r6            | Temp      | Stores r1 for display                                                                             | loop, display row                                                                                                           |
| r7            | Temp      | Swap and stores for ldr,str GPIO stuff                                                            | game_loop, loop, display,row                                                                                                |
| r8            | Tata      | Player score                                                                                      | collision_Scheck, game_over                                                                                                 |
| r9            | Data      | Remaining lives                                                                                   | death                                                                                                                       |
| r10           | Temp      | Clock durations                                                                                   | all render functions                                                                                                        |
| r11           | Data      | Hold tick for move rock                                                                           | start, game_loop, move_rock                                                                                                 |
| r12           | Data      | Hold tick for shoot up                                                                            | start, game_loop, move_rock                                                                                                 |
Note : This is definitely the not most efficient but the register  sort nicely so i am keeping this way 
### Hardware 
#### LEDs
The Leds are row wise and to turn them on you need to set the row to high and columns to low using the
```assembly 
@0x5000050C outclr(low) for P0.x

@0x5000080C outclr(low) for P1.x (clm 4,5)

@0x50000508 outset(high) for P0.x

@0x50000808 outset(high) for P1.x


@ example how to set values
ldr r0, =0x50000518 @ GPIO P0 DIRSET

ldr r7, =((1<<21)|(1<<22)|(1<<15)|(1<<24)|(1<<19) | (1<<28)|(1<<11)|(1<<31)|(1<<30))

str r7, [r0]

ldr r0, =0x50000818 @ GPIO P1 DIRSET

ldr r7, =(1<<5)

str r7, [r0]

```

<img width="605" height="815" alt="Pasted image 20260421231828" src="https://github.com/user-attachments/assets/339b43ed-5826-4270-a974-89c116242ef7" />


#### Buttons
Code to run the Buttons 
``` assembly
ldr r0, =0x50000738 

ldr r7, =0x0000000C

str r7, [r0]
```


#### Memory

|Memory Type|Start Address|End Address|Size|Access|
|---|---|---|---|---|
|**Flash**|`0x00000000`|`0x0007FFFF`|512 KB|Read-Only (mostly)|
|**SRAM**|`0x20000000`|`0x2001FFFF`|128 KB|Read/Write|
|**Peripherals**|`0x40000000`|`0x5FFFFFFF`|—|Hardware Control|

Linker file used
```
MEMORY
{
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 512K
  RAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 128K
}

SECTIONS
{
  .text : {
    KEEP(*(.vectors))
    *(.text*)
    *(.rodata*)    /* Read-only data like constants */
  } > FLASH

  /* This is where your 'memory storage' lives */
  .data : {
    *(.data*)
  } > RAM AT > FLASH

  .bss : {
    *(.bss*)
    *(COMMON)
  } > RAM
}
```

## Challenges and Fixes

#### Displaying
Problem : The way hardware is made you can't light up one pixel individually and the power is sent to entire row / column will get the power

Fix : The fix idea came from old CRT TVs where instead of displaying the whole image at once i can do a line wise scan and as long as the scan is fast enough our eyes can't tell the difference 

#### Timings
Problem : To properly set how many times rocks come down , bullets shoot up was really hard . as there is no time functions or any way to interact with time at all

Fix : The Fix was made up of 2 parts 

1. Delay Loop : This would the CPU a long calculation to solve in a loop give us some way to pause time (like time.sleep())
```assembly
mov r5,#(1<<14)

delay_loop:

subs r5,r5,#1

bne delay_loop
```
2. Tick Based System : With the delay run each loop will have run for a time t, you can have a tick -> i , and when it reach n we know n * t time has passed we can use these 2 together to control time is a lot of case
``` assembly 
add r11, r11, #1

cmp r11, #15 @ tick rate

it ge

blge shoot_up
```

Note : Although this works this is still a very crude approach 

#### Branching Issue
Problem : When using function inside function , multiple bl's one inside another they seem to fail

Fix : It is kind of dumb solution but i just made a rule to only nest 2 functions :) i was much easier than handling all the addressing into stack (i tried it failed randomly probably improper handling but this was much easier so.. )

#### Debugging Issues
Problem : The cortexM debug vscode and every other thing was not working on my system while openogdb

Fix : I gave up and just used to input the data in to let and  it work fine (also pen paper and dry running the code )

## Results and Future Implementations
### Results 
It is a fun game made in assembly :) . So Success 

### Future Implementations
Quite a few things can be added to this game for features , like

- [ ]  Having variable brightness to show difference in Rocks and Bullets
- [ ]  Adding gyroscopic controls 
- [ ]  Adding hit sounds to the game and some animations
- [ ]  Having different difficulties and a way to choose among them
- [ ]  Adding 2D movement using Gyroscope and spawn Rocks from all sides 

 
