; File: loader.asm
; =============================
; 二级助推器：加载核心程序，为核心程序运行做准备。
org 0x1000
base_of_stack   equ 0x1000  ; 栈基地址

mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax
mov sp, base_of_stack

; 调用子函数清屏
; ====================
call sub_clear_scr

; 调用子函数显示字符串
; ====================
mov bp, loader_msg
mov cx, loader_msg_len
mov dx, 0x0000
call sub_show_str

loader_end: hlt
    jmp short loader_end

; 以下静态数据
; ==========================
loader_msg:     db  'loader run.'
loader_msg_len  equ $ - loader_msg

; 以下为子函数
; ==========================
sub_show_str:
    ; 调用BIOS 10H中断显示字符串
    ; =========================
    ; ES:BP     字符串首地址
    ; CX        字符串长度
    ; DH:DL     字符串坐标（行:列）
    ; =========================
    push ax
    push bx
    mov ax, 0x1301      ; al=1, 显示字符串后光标位置移动。
    mov bx, 0x0007      ; 黑底白字
    int 10h
    pop bx
    pop ax
    ret

sub_clear_scr:
    ; 调用BIOS 10h中断清屏
    ; ========================
    push ax
    push bx
    push cx
    push dx
    mov ax, 0x0600      ; ah: 子功能号 06H - 向上滚屏, al: 滚动的行数，0-清除窗口 
    mov bx, 0x0700      ; bh: 空白区域的属性
    mov cx, 0           ; ch:cl 窗口的左上角位置 行：列
    mov dx, 0x184f      ; dh:dl 出口的右下角位置 行：列, 屏幕默认是 25行×80列16色模式，即 19H*50H
    int 10h
    pop dx 
    pop cx
    pop bx
    pop ax
    ret
