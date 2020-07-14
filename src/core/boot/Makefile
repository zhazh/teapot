ASM = nasm
RM = rm -rf

all: boot.bin

boot.bin: boot.asm
	$(ASM) boot.asm -o boot.bin

clean:
	$(RM) *.o boot.bin

.PHONY: all clean
