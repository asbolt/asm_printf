all: 
	nasm -f elf64 3.asm
	gcc -no-pie main.cpp 3.o -o result

clean:
	rm *.o
	rm result