#!/bin/bash

# Assemble the source files
nasm -f elf -g -F dwarf main.asm -o main.o
nasm -f elf -g -F dwarf showGrid.asm -o showGrid.o
nasm -f elf -g -F dwarf play.asm -o play.o
nasm -f elf -g -F dwarf win.asm -o win.o

# Check if there were any errors during assembly
if [ $? -ne 0 ]; then
  echo "Assembly failed"
  exit 1
fi

# Link the object files to create the executable
ld -m elf_i386 -o game main.o showGrid.o play.o win.o

# Check if there were any errors during linking
if [ $? -ne 0 ]; then
  echo "Linking failed"
  exit 1
fi

# Remove the .o files
rm *.o

# Run GDB with the executable
gdb game