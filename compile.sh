#!/bin/bash

# create new .o
nasm -f elf64 main.asm -o main.o
nasm -f elf64 showGrid.asm -o showGrid.o
nasm -f elf64 play.asm -o play.o
nasm -f elf64 win.asm -o win.o
nasm -f elf64 opponent.asm -o opponent.o
nasm -f elf64 filters.asm -o filters.o

# delete older executable
rm game

# Link the objects and create the executable
ld -o game main.o showGrid.o play.o win.o opponent.o filters.o

# Remove the .o files
rm *.o

# Launch the executable
./game
