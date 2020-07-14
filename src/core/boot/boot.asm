; boot.asm
; ========================
org 0x7c00
base_of_stack equ 0x7c00
start_label:
mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax
mov sp, base_of_stack

; 调用BIOS 10h中断清屏
; ==============================
; 屏幕默认是 25行×80列16色模式，即 19H*50H
; ah: 子功能号 06H - 向上滚屏
; al: 滚动的行数，0-清除窗口
; bh: 空白区域的属性
; ch:cl 窗口的左上角位置 行：列
; dh:dl 出口的右下角位置 行：列
mov ax, 0x0600  
mov bx, 0x0700
mov cx, 0
mov dx, 0x184f
int 10h

; 调用BIOS中断设置光标位置
; ==============================
; ah: 子功能号 02h
; bh: 显示的页码
; dh:dl 设置光标所在的行：列
mov ax, 0x0200
mov bx, 0
mov dx, 0
int 10h

; 调用BIOS中断显示字符串
; ===============================
; ah: 子功能号 13h - 显示字符串
; bh: 页码
; bl: 属性
; cx: 字符串长度
; dh:dl 行：列
; es:bp 显示字符串的地址
; al: 显示输出方式
; 0 - 字符串中只含显示字符， 其显示属性在bl中定义。显示后光标位置不变
; 1 - 字符串中只含显示字符， 其显示属性在bl中定义。显示后光标位置改变
; 2 - 字符串中含有显示字符和属性， 显示后，光标位置不变
; 3 - 字符串中含有显示字符和属性， 显示后，光标位置不变
mov ax, 0x1301
mov bx, 0x0004  ; 黑底红字
mov cx, boot_msg_len
mov dx, 0
mov bp, boot_msg
int 10h

; 调用BIOS中断复位软盘
; =======================
xor ah, ah
xor dl, dl
int 13h
boot_end:
nop
jmp boot_end

boot_msg:   db 'teapot start boot!'
boot_msg_len: equ $-boot_msg

; ======= fill zero util one sector ======
times 510 - ($ - $$) db 0
dw 0xaa55