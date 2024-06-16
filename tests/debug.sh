#!/bin/bash

# Vérifie si un argument est passé
if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

# Nom du fichier sans l'extension
FILENAME=$1

# Assemble le fichier .asm en fichier objet .o
nasm -f elf -g -F dwarf "$FILENAME.asm" -o "$FILENAME.o"
if [ $? -ne 0 ]; then
  echo "Erreur : échec de l'assemblage de $FILENAME.asm"
  exit 1
fi

# Enleve l'ancien exécutable
rm "$FILENAME"

# Lie le fichier objet pour créer l'exécutable
ld -m elf_i386 -o "$FILENAME" "$FILENAME.o"
if [ $? -ne 0 ]; then
  echo "Erreur : échec de la liaison de $FILENAME.o"
  exit 1
fi

# Supprime le fichier objet intermédiaire
rm "$FILENAME.o"

# Execute le resultat
gdb ./$FILENAME
