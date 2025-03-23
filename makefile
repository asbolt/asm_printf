ASM_FILES = *.asm
O_FILES = *.o
SPP_FILES = *.cpp

all: 
	nasm -f elf64 $(ASM_FILES)
	gcc -no-pie $(SPP_FILES) $(O_FILES) -o result

clean:
	rm *.o
	rm result