ASM = nasm
RM = rm -rf

all: boot.bin loader.bin

%.bin: %.asm
	$(ASM) $< -o $@

clean:
	$(RM) *.o boot.bin loader.bin

burning:
	# burning into floppy image.
	dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
	cp boot.img ../../../test/bochs/
# mount boot.img /media/ -t vfat -o loop
# cp loader.bin /media/
# sync
# umount /media/
.PHONY: all clean burning
