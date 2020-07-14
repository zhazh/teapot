#/usr/bin/sh
cp ../../src/core/boot/boot.bin ./
dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
