#!/bin/bash
arm-none-eabi-as -mcpu=cortex-m4 -mthumb main.s -o main.o
arm-none-eabi-ld -T layout.ld main.o -o main.elf
arm-none-eabi-objcopy -O ihex main.elf main.hex
sudo mount <mount your microbit>
sudo cp <hex file path> <microbit is mounted>
echo "Complied :)"
