.global _start
.intel_syntax noprefix

.equ STDIN, 0
.equ STDOUT, 1

// Sys Calls
.equ SYS_WRITE, 1
.equ SYS_OPEN, 2
.equ SYS_STAT, 4
.equ SYS_IOCTL, 16
.equ SYS_EXIT, 60
.equ SYS_GETDENTS, 217

.data
start_log:
    .asciz "[INFO] Communicating via ioctl and hidraw\n"
    .equ start_log_len, . - start_log

start_sequence_payload:
    .incbin "payload/startSequence.bin"

lighting_mode_sequence_payload:
    .incbin "payload/modeSelectionSequence.bin"

clear_lights_payload:
    .incbin "payload/noColors.bin"

sample_backlight_payload:
    .incbin "payload/sample.bin"

hidraw_err_log:
    .asciz "[ERR] Failed to open the hidraw file\n"
    .equ hidraw_err_log_len, . - hidraw_err_log

get_device_report:
    .byte 0x06
    .skip 520, 0

hidraw_file:
    .asciz "/dev/hidraw6"

.bss
device_name:
    .skip 64, 0

.text
_start:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [start_log]
    mov rdx, start_log_len
    syscall

    // Open the hidraw file
    mov rax, SYS_OPEN
    lea rdi, [hidraw_file]
    mov rsi, 2
    mov rdx, 0
    syscall

    // checking if successful else exiting
    js hidraw_file_read_error

    // Keep the file descriptor in a register
    mov r10, rax

    mov rax, SYS_IOCTL
    mov rdi, r10
    // int value for HIDIOCGRAWNAME len 64
    // Source is the kernel.org docs,
    // and /usr/include/linux/ 
    // and a "hack" of printing it with C :)
    mov rsi, 0x80404804 
    lea rdx, [device_name]
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [device_name]
    mov rdx, 64
    syscall

    // Using sys_write over sys_ioctl for hidraw initially
    // reverted to sys_ioctl since write is causing issues.

    mov rax, SYS_IOCTL
    mov rdi, r10
    mov rsi, 0xc2084806
    lea rdx, [start_sequence_payload]
    syscall

    js hidraw_file_read_error

    // Get report sequence
    mov rax, SYS_IOCTL
    mov rdi, r10
    // Used c again to calculate the hex value for 
    // macro HIDIOCGFEATURE of len 521 
    // 1st byte is report id and rest the paylaod.
    mov rsi, 0xc2094807
    lea rdx, [get_device_report]
    syscall

    js hidraw_file_read_error

    mov rax, SYS_IOCTL
    mov rdi, r10
    mov rsi, 0xc2084806
    lea rdx, [lighting_mode_sequence_payload]
    syscall

    js hidraw_file_read_error

    mov rax, SYS_IOCTL
    mov rdi, r10
    mov rsi, 0xc2084806
    lea rdx, [sample_backlight_payload]
    syscall

    js hidraw_file_read_error

    call successful_exit

hidraw_file_read_error:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    lea rsi, [hidraw_err_log]
    mov rdx, hidraw_err_log_len
    syscall

    mov rax, SYS_EXIT
    mov rdi, rax
    syscall

successful_exit:
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
