#!/bin/bash

# Assemble the source files
nasm -f elf64 -g -F dwarf main.asm -o main.o
nasm -f elf64 -g -F dwarf showGrid.asm -o showGrid.o
nasm -f elf64 -g -F dwarf play.asm -o play.o
nasm -f elf64 -g -F dwarf win.asm -o win.o
nasm -f elf64 -g -F dwarf opponent.asm -o opponent.o
nasm -f elf64 -g -F dwarf filters.asm -o filters.o

# Check if there were any errors during assembly
if [ $? -ne 0 ]; then
  echo "Assembly failed"
  exit 1
fi

# Link the object files to create the executable
ld -m elf_x86_64 -o game main.o showGrid.o play.o win.o opponent.o filters.o

# Check if there were any errors during linking
if [ $? -ne 0 ]; then
  echo "Linking failed"
  exit 1
fi

# Remove the .o files
rm *.o

# Run GDB with the executable
gdb game