; File: boot.asm
; ================================
; 一级点火：加载loader.bin并执行，突破512字节限制。

org 0x7c00                          ; BIOS读取此程序后设置CS:IP为0:7c00h，伪指令org指定当前偏移。
base_of_stack           equ 0x7c00  ; 栈基地址
base_of_loader          equ 0x0000  ; 加载loader存放的段基地址
offset_of_loader        equ 0x1000  ; 加载loader存放的偏移地址 
addr_of_sec_buf         equ 0x8000  ; 加载的软盘扇区临时存放地址

struc root_dir_entry
    .name:      resb 11     ; 文件名8字节，扩展名3字节
    .attr:      resb 1      ; 属性
    .reserve    resb 10     ; 保留字段
    .wrt_time   resw 1      ; 最后一次写入时间 
    .wrt_date   resw 1      ; 最后一次写入日期
    .fst_clus   resw 1      ; 第一个簇号
    .file_size  resd 1      ; 文件长度(Byte)
endstruc

BS_jmp_boot:                        ; 跳转指令部分，跳转到boot的开始，3字节
    jmp short label_boot_start      ; 必须加short，不加short编译后的该指令是3字节。
    nop                             ; nop指令编译后1个字节，加上面的2个字节指令刚好3字节。
BS_OEMName          db 'Teapot  '   ; 生产厂商名, 8db 不足8位补空格
BPB_BytesPerSec     dw 0x0200       ; 每扇区的字节数, 512 Byte
BPB_SecPerClus      db 0x01         ; 每簇的扇区数, FAT12为1
BPB_RsvdSecCnt      dw 0x0001       ; 保留扇区数，Boot占用的扇区数 
BPB_NumFATs         db 0x02         ; FAT表的数量, FAT12有两个FAT1和FAT2，两个数据一致，互为备份
BPB_RootEntCnt      dw 0x00E0       ; 根目录表的最大表项数量，224，根目录表每个表项占用32字节
BPB_TotSec16        dw 0x0b40       ; 逻辑扇区总数，2磁头 * 80磁道 * 18扇区/磁道 = 2880 扇区
BPB_Media           db 0xf0         ; 介质描述符
BPB_FATSz16         dw 0x0009       ; 每个FAT占用的扇区数，9
BPB_SecPerTrk       dw 0x0012       ; 每个磁道的扇区数， 18
BPB_NumHeads        dw 0x0002       ; 磁头数，2
BPB_HiddSec         dd 0x00000000   ; 隐藏的扇区数
BPB_TotSec32        dd 0x00000000   ; 如果BPB_TotSec16为0，则在这里记录扇区总数
BS_DrvNum           db 0x00         ; 中断13的驱动器号
BS_Reserved1        db 0x00         ; 保留未使用字段
BS_BootSig          db 0x29         ; 扩展引导标志
BS_VolID            dd 0x00000000   ; 卷序列号
BS_VolLab:          db 'Boot       '; 卷标，Windows或Linux系统中显示的磁盘名, 必须11个字符，不足空格填补。
BS_FileSysType      db 'FAT12   '   ; 文件系统类型，必须8个字符，不足填充空格 

label_boot_start:
    ; 初始化段寄存器
    ; =========================
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, base_of_stack

    ; 调用BIOS 10h中断清屏
    ; ==============================
    mov ax, 0x0600      ; ah: 子功能号 06H - 向上滚屏, al: 滚动的行数，0-清除窗口 
    mov bx, 0x0700      ; bh: 空白区域的属性
    mov cx, 0           ; ch:cl 窗口的左上角位置 行：列
    mov dx, 0x184f      ; dh:dl 出口的右下角位置 行：列, 屏幕默认是 25行×80列16色模式，即 19H*50H
    int 10h

    ; 显示boot信息
    ; ==============================
    mov bp, boot_msg
    mov cx, boot_msg_len
    mov dx, 0x0000          ; 第一行第一列，坐标为(0,0)
    call sub_show_str

    mov word [var_rdir_count],  14      ; 初始化根目录区扇区数量为14
    mov word [var_rdir_sec_no], 19      ; 初始化根目录区开始逻辑扇区编号为19
    loop_load_rdir_sec:
        ; 循环读取根目录区扇区
        mov ax, [var_rdir_sec_no]
        mov bx, addr_of_sec_buf
        call sub_load_one_sector
        ; 在ES:BX的扇区数据中查找LOADER BIN
        mov ax, 16  ; 一个扇区共16个目录项
        loop_rdir_entry_cmp:
            push cx
            mov si, target_name
            mov di, bx
            mov cx, 11
            call sub_compare_2str
            jcxz lable_founded
            add bx, root_dir_entry_size ; add bx, 32
            dec ax
            cmp ax, 0
            jne loop_rdir_entry_cmp
        sub word [var_rdir_count], 1
        add word [var_rdir_sec_no], 1
        cmp word [var_rdir_count], 0
        jne loop_load_rdir_sec
label_load_failed:
    mov bp, loader_fail_msg
    mov cx, loader_fail_msg_len
    mov dx, 0x0100              ; 第二行第一列显示
    call sub_show_str
    jmp label_boot_end
lable_founded:
    ; ES:BX 是该目录项首地址
    mov ax, [bx + root_dir_entry.fst_clus]
    mov [var_loader_clus_no], ax
    mov ax, es
    mov [var_es_bak], ax
    mov ax, base_of_loader
    mov es, ax
    mov bx, offset_of_loader
    loop_get_clus:
        ; 加载数据区扇区到ES:BX位置处
        mov ax, [var_loader_clus_no]
        sub ax, 2       ; 数据区簇编号从2开始
        add ax, 33      ; 数据区起始逻辑扇区是33
        call sub_load_one_sector
        add bx, 512

        mov ax, [var_loader_clus_no]
        call sub_get_next_clus_no
        cmp ax, 0x0fff      ; 本簇是最后一个簇
        je label_jmp_loader
        mov [var_loader_clus_no], ax    ; 保存下一簇簇号
        cmp ax, 0x0ff5
        jb loop_get_clus
        jmp lable_fat_entry_error
    label_jmp_loader:
        jmp base_of_loader:offset_of_loader
    lable_fat_entry_error:
        mov ax, cs
        mov es, ax
        jmp label_load_failed
label_boot_end:
    hlt
    jmp short label_boot_end

    sub_show_str:
        ; 显示字符串，入参如下：
        ; ========================
        ; ES:BP     字符串首地址
        ; CX        字符串长度
        ; DH:DL     字符串坐标（行:列）
        push ax
        push bx
        mov ax, 0x1301      ; al=1, 显示字符串后光标位置移动。
        mov bx, 0x0007      ; 黑底白字
        int 10h
        pop bx
        pop ax
        ret
    
    sub_load_one_sector:
        ; 读取1个扇区软盘数据，入参如下：
        ; ================================
        ; AX: 逻辑扇区编号
        ; ES:BX 缓冲区首地址
        push bp
        push bx
        push cx
        push dx
        push ax

        ; 复位软盘控制器
        ; ================
        xor ah, ah
        xor dl, dl
        int 13h

        ; 换算逻辑编号为物理CHS
        ; =======================
        mov bp, sp
        mov ax, [ss:bp]         ; 恢复ax的值
        mov dx, [BPB_SecPerTrk] ; 软盘为每磁道18扇区
        div dl                  ; 逻辑编号/18, 余数+1为扇区编号，商/2为柱面号，商&0x01为磁头号
        inc ah
        mov cl, ah      ; 扇区
        mov ch, al
        shr ch, 1       ; 柱面
        mov dh, al
        and dh, 0x01    ; 磁头
        mov dl, 0       ; 软驱编号0: Floppy A
        _loop_los_read_sec:
            mov ax, 0x0201  ; AL=1 读取1个扇区， AH=2，子功能编号
            int 13h
            jc _loop_los_read_sec  ; 重复读取，直到成功。
        pop ax
        pop dx
        pop cx
        pop bx
        pop bp
        ret

    sub_compare_2str:
        ; 比较两个字符串是否相等
        ; 入参：
        ; =================================
        ; DS:SI 字符串1首地址 
        ; DS:DI 字符串2首地址
        ; CX    比较字符串的长度
        ; 出参：
        ; =================================
        ; CX：  为0则两个字符串相同
        push ax
        push bx
        mov bx, 0
        _loop_c2s_cmp_char:    
            mov ah, [bx+si]
            mov al, [bx+di]
            inc bx
            cmp ah, al
            jne _label_c2s_end
            loop _loop_c2s_cmp_char
        _label_c2s_end:
        pop bx
        pop ax
        ret
    
    sub_get_next_clus_no:
        ; 读取FAT表，根据当前簇号，获取下一个簇号。
        ; 入参：
        ; ===========================
        ; AX: 当前簇号 有效值：0x001 - 0xff6
        ; 出参：
        ; ===========================
        ; AX: 下一个簇号
        push ax
        push bx
        push cx
        push dx

        mov cx, 12
        mul cx          ; DX$AX = AX * 12
        mov cx, 512     
        div cx          ; DX$AX/512, 商AX为FAT1表的偏移扇区，余数DX为FAT项的开始字节号
        add ax, 1       ; FAT1表开始编号为1
        ; 读取两个连续扇区的数据到缓冲中
        mov bx, addr_of_sec_buf
        call sub_load_one_sector
        inc ax
        add bx, 512
        call sub_load_one_sector

        mov bx, dx
        mov ax, [bx + addr_of_sec_buf]
        and ax, 0x0fff

        pop dx
        pop cx
        pop bx
        pop ax
        ret

var_rdir_count              dw 0x0000
var_rdir_sec_no             dw 0x0000
var_loader_clus_no          dw 0x0000
var_es_bak                  dw 0x0000
boot_msg                    db 'Boot start'
boot_msg_len                equ $ - boot_msg
target_name                 db 'LOADER  BIN'    ; 目标文件名称
loader_fail_msg             db 'Load fail!'
loader_fail_msg_len         equ $ - loader_fail_msg 
fat_err_msg                 db 'fat error.'
fat_err_msg_len             equ $ - fat_err_msg 
; ======= fill zero util one sector ======
times 510 - ($ - $$) db 0
dw 0xaa55