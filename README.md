# Space_Invaders-Microbitv2
 Space Invaders in Microbitv2 .21 using assembly
## Initial "Research" 
Since the v2 uses an ARM Cortex-M4 (specifically the Nordic nRF52833 chip), you'll be writing ARM Thumb-2 assembly.

Here is the roadmap and the resources you need to get started.
#### 1. The Toolchain: How to Compile

You can't just drop a .s file onto the micro:bit; you need to compile it into a .hex file. The industry standard is the GNU Arm Embedded Toolchain.

Assembler/Linker: arm-none-eabi-gcc or arm-none-eabi-as.

Workflow: 
	1. Write your code in a text editor (VS Code works well).
    2. Assemble to an object file (.o).
    3. Link to an executable (.elf) using a linker script (to tell the code where the micro:bit’s memory is).
    4. Convert to .hex using arm-none-eabi-objcopy.
    5. Drag the .hex onto the MICROBIT drive.

Key Resource:

[Micro:bit v2 "The Hard Way" (Level Up Coding)](https://levelup.gitconnected.com/micro-bit-v2-21-the-hard-way-1ab0aef6ee3a)

#### 2. Understanding the Hardware (Registers & Memory)

Assembly is all about moving bits between registers and memory addresses. You need the "maps" for the nRF52833.

Memory Map: You need to know that Flash starts at 0x00000000 and RAM starts at 0x20000000.

GPIO Addresses: To turn on an LED, you have to write to specific memory-mapped registers (e.g., the OUT or DIR registers for Port 0).

Key Documents:
- [nRF52833 Product Specification (Nordic): The "Bible" for your chip. Look for the "GPIO" and "Memory" sections.](https://infocenter.nordicsemi.com/pdf/nRF52833_PS_v1.3.pdf)
- [Micro:bit v2 Schematic: To see which pins on the chip actually connect to the LED matrix.](https://tech.microbit.org/hardware/schematic/)
- [ARMv7-M Architecture Reference Manual: Defines every assembly instruction (like MOV, LDR, STR) available on the Cortex-M4.](https://developer.arm.com/documentation/ddi0403/latest/)
#### 3. Learning the Language (ARM Thumb-2)

The micro:bit v2 uses the Thumb-2 instruction set. It's a mix of 16-bit and 32-bit instructions designed for efficiency.

Registers: You have 13 general-purpose registers (r0-r12), a Stack Pointer (sp), a Link Register (lr), and a Program Counter (pc).

Calling Convention: If you want to mix Assembly with C, you must follow the AAPCS (Procedure Call Standard).

Learning Resources:

- [ANU COMP2300 Micro:bit Assembly Guide: A high-quality university guide specifically for programming the micro:bit in assembly.](https://cs.anu.edu.au/courses/comp2300/resources/microbit-style/)
- [Bare Metal Micro:bit (Oriel College, Oxford): A deep dive into the processor core differences and register-level programming](https://spivey.oriel.ox.ac.uk/baremetal/The_microbit_page).

Summary Checklist for Your First Script
- Define the Vector Table: The first two words in your code must be the Initial Stack Pointer and the Reset Handler address.
- Enable GPIO: Find the DIRSET register for Port 0 (Address 0x50000518) and set the bit for the LED pin you want to use.
- Toggle the Pin: Write to the OUTSET or OUTCLR registers to turn the LED on or off.
- Loop: Use a branch instruction (b loop) to keep the code running.


### Testcode by AI
To get you started, we’ll write a Bare Metal assembly program. This code bypasses all operating systems (like Zephyr or MicroPython) and talks directly to the processor.

This example will turn on a single LED on the micro:bit v2. To do this, we must drive Row 1 (P0.21) high and Col 1 (P0.28) low.
#### 1. The Assembly Code (main.s)

Create a file named main.s. This uses ARM Unified Assembler Language (UAL) syntax.
```
@ --- Micro:bit v2 Bare Metal Assembly (LED On) ---
.syntax unified
.cpu cortex-m4
.thumb

@ --- Vector Table (Required for Boot) ---
.section .vectors
    .word 0x20020000     @ Initial Stack Pointer (Top of RAM)
    .word _start + 1     @ Reset Handler address (+1 for Thumb mode)

.text
.global _start

_start:
    @ --- 1. Set Pin Directions to Output ---
    @ GPIO Port 0 Base: 0x50000500
    @ DIRSET Offset: 0x518 (Writing a '1' makes a pin an output)
    ldr r0, =0x50000518
    
    @ We need Pin 21 (Row 1) and Pin 28 (Col 1)
    ldr r1, =( (1 << 21) | (1 << 28) )
    str r1, [r0]

    @ --- 2. Set Pin States ---
    @ To turn on a v2 LED: Row must be HIGH (1), Column must be LOW (0)
    
    @ Set Row 1 (P0.21) HIGH using OUTSET (Offset 0x508)
    ldr r0, =0x50000508
    ldr r1, =(1 << 21)
    str r1, [r0]

    @ Set Column 1 (P0.28) LOW using OUTCLR (Offset 0x50C)
    ldr r0, =0x5000050C
    ldr r1, =(1 << 28)
    str r1, [r0]

loop:
    b loop               @ Infinite loop to keep CPU busy
```

#### 2. The Linker Script (layout.ld)

The linker tells the compiler exactly where the Flash memory starts. Create layout.ld:
```
MEMORY
{
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 512K
  RAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 128K
}

SECTIONS
{
  .text : {
    KEEP(*(.vectors))   /* Ensure vector table is at the very start */
    *(.text*)
  } > FLASH
}
```

#### 3. How to Compile (The Terminal Commands)

You will need the arm-none-eabi toolchain installed (sudo apt install gcc-arm-none-eabi on Linux/WSL). Run these commands in order:

Assemble: ```
```
arm-none-eabi-as -mcpu=cortex-m4 -mthumb main.s -o main.o
```

Link: 
```
arm-none-eabi-ld -T layout.ld main.o -o main.elf
```

Convert to Intel HEX: (This is what the micro:bit accepts)

```
arm-none-eabi-objcopy -O ihex main.elf main.hex
```
Finally: Plug in your micro:bit and drag main.hex into the MICROBIT drive. You should see the top-left LED light up!
Key Resources & References

[Nordic nRF52833 Register Map: GPIO Registers (Section 6.10) - This confirms that DIRSET is at offset 0x518.](https://www.google.com/search?q=https://infocenter.nordicsemi.com/topic/ps_nrf52833/gpio.html%3Fcp%3D5_1_0_5_8_2%23register&authuser=1)

[Micro:bit v2 Hardware Specs: Pinmap Info - This confirms Row 1 is P0.21.](https://tech.microbit.org/hardware/schematic/)

[~~ARM Thumb Instructions: Quick Reference Card - Useful for looking up LDR, STR, and B syntax~~.](https://www.st.com/resource/en/programming_manual/pm0214-stm32-cortexm4-mcus-and-mpus-programming-manual-stmicroelectronics.pd)(not working)

One more [ARM guide](https://developer.arm.com/documentation/dui0231/b/arm-instruction-reference) 

So all of this work , now i need to do is code in simulator.

... 
# Debuugger v2 (may not be stable on linux.. will try windows rn)
## 1. Install the "Big Three" Prerequisites

You need three external tools installed on your computer for VS Code to talk to the micro:bit hardware.

- **ARM GNU Toolchain:** Provides `arm-none-eabi-gdb` (the debugger engine).
    
    - _Download:_ [Arm GNU Toolchain Downloads](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads).
        
- **OpenOCD:** The "bridge" that connects your USB port to the micro:bit's debug chip.
    
    - _Windows:_ Download the latest `.7z` from [xPack OpenOCD](https://github.com/xpack-dev-tools/openocd-xpack/releases).
        
    - _Mac:_ `brew install openocd`
        
- **VS Code Extensions:** Search the marketplace and install:
    
    1. **Cortex-Debug** (by marus25) — This is the most critical one.
        
    2. **Arm Debugger** (optional but helpful for a cleaner UI).
        

---

## 2. Configure the VS Code "Launch" File

VS Code needs to know exactly how to start the debugger. In your project folder, create a folder named `.vscode` and a file inside it called `launch.json`. Paste this configuration:

JSON

```
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Micro:bit Debug",
            "cwd": "${workspaceRoot}",
            "executable": "${workspaceRoot}/your_project.elf", 
            "request": "launch",
            "type": "cortex-debug",
            "servertype": "openocd",
            "device": "nrf52",
            "configFiles": [
                "interface/cmsis-dap.cfg",
                "target/nrf52.cfg"
            ],
            "runToEntryPoint": "main",
            "svdFile": "${workspaceRoot}/nrf52.svd"
        }
    ]
}
```

> **Note:** Change `your_project.elf` to whatever the name of your compiled output file is.

---

## 3. Map Your Paths (The "Last Mile")

If VS Code says "OpenOCD not found," you need to tell it where you installed the tools.

1. Open **File > Preferences > Settings**.
    
2. Search for **Cortex Debug**.
    
3. Find the settings for **OpenOCD Path** and **Arm Toolchain Path**.
    
4. Paste the full path to the `bin` folder of each tool.
    
    - _Example Windows:_ `C:\Users\Name\AppData\Roaming\xPacks\openocd\bin\openocd.exe`
        

---

## 4. The Live Debugging Experience

Once configured, plug in your micro:bit and press **F5**.

### What you will see:

- **The Register Pane:** On the left side, a list will appear showing R0 through R15. If you step through your code, you will see these numbers change from black to **red** when they are updated.
    
- **Breakpoints:** Click to the left of any line number in your Assembly code. A red dot appears. The micro:bit will physically stop running the moment it hits that line.
    
- **Memory View:** You can open a "Memory View" tab and type a hex address (like `0x20000000`) to see the raw bytes in RAM.
    

### Pro-Tip: The SVD File

If you want to see things like "is the Button A pin currently high or low?" instead of just raw numbers, download the **nRF52 SVD file** (the "map" of the micro:bit's brain). Link to it in your `launch.json` under `svdFile`. This will turn cryptic hex addresses into readable labels like `GPIO_IN`.


## Conclusions: 
so this failed for arch dk why but i am running of time so i  am just gonna use comp2300 setup to make my life easier . may fix it some other day
# Planned Program and Functions
### FSM based Basic Space Invaders


![[Pasted image 20260327235254.png]]


### Planned Implementation inside of Microbit:-v2
#### Game Design 
A spaceship is stuck in space trying to go ahead but oh no..... there are asteroids so shoot them to travel along safely. The game uses the Microbit left right button to move along in the left and right spaces it shoots out periodically which shoots to clear the way. 
#### Display 
Use 5x5 display to play the game :
The bottom row will only house a the character and it will move around using the buttons while the first row will have the new in coming rocks will coming there. If the rock row hit the bottom row the game will end.
#### Memory
the memory will have 2 arrays on 4x5 (20 values) index to store the array values where the rocks are , each rock will get a initial value and be shift by +5  to indicate the shift in a new row
will 5 more values will store the bullets and player position

#### Display Function :
Function which will take in a value (eg : 25,4 ) and will on the led accordingly.
A supplementary function will take go thorough the array when give the initial and how many elements it has and go thorough each value of that array will it to the led enable function.

#### Shooting Function 
A waits for some time then shoots out a element based the value of where the spaceship is. It will also increment each bull to one. It will also check will there is a contact with one of the rock the it turns that rock to 0.

#### Move Function 
It will listen for the button inputs and move according to the value of the spaceship controller 

#### Rock Maker
It will take in random value from one of the functions and take it value and to 1+ (value from the sensor)mod 3 to get a source of randomness for the numbers of rocks generated. it will also put in the value in the first of 5 value in the rock functions.
## Flowchart of the game:

Rock Maker -> Display Function -> Move Function -> Move Functions -> Shooting Function -> Memory Mover -> Rock Maker -> Display Function ....

## Timeline
#### 1. Attempt to make the game run just on a code then add display and all that stuff

##