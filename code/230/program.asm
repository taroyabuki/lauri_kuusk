; 230 fireworks drawing core for MSX2 / Pasmo
;
; BASIC chooses 1 to 3 firework centers, colors, and sizes. ASM draws their
; launch trails and explosion points in SCREEN 5 using direct V9938 VRAM access.

CHSNS   equ $009C
CHGET   equ $009F
JIFFY   equ $FC9E

VDP_DATA equ $98
VDP_CTRL equ $99

fx      equ $C000
fy      equ $C001
fcol    equ $C002
state   equ $C003
lastj   equ $C004
ycur    equ $C005
rcnt    equ $C006
pcnt    equ $C007
cx      equ $C008
cy      equ $C009
colv    equ $C00A
bytev   equ $C00B
keepv   equ $C00C
fcnt    equ $C00D
fscale  equ $C00E

slot1   equ $C010
slot2   equ $C014
slot3   equ $C018

BACK_COLOR equ 1

        org $D100

entry:
        xor a
        ld (state),a
        ld a,(JIFFY)
        ld (lastj),a
        call launch
        ld a,(state)
        or a
        jr z,entry_burst
        call reset_vram_high
        ret
entry_burst:
        call burst
        call reset_vram_high
        ret

launch:
        ld a,184
        ld (ycur),a
launch_loop:
        call check_space
        ret nz
        call draw_all_launch_lines
        call wait_frame
        call wait_frame
        call clear_all_launch_lines
        ld a,(ycur)
        sub 8
        ld (ycur),a
        call any_launch_active
        ret z
        jr launch_loop

draw_all_launch_lines:
        call load_slot1
        call draw_launch_line_if_active
        ld a,(fcnt)
        cp 2
        ret c
        call load_slot2
        call draw_launch_line_if_active
        ld a,(fcnt)
        cp 3
        ret c
        call load_slot3
        call draw_launch_line_if_active
        ret

clear_all_launch_lines:
        call load_slot1
        call clear_launch_line_if_active
        ld a,(fcnt)
        cp 2
        ret c
        call load_slot2
        call clear_launch_line_if_active
        ld a,(fcnt)
        cp 3
        ret c
        call load_slot3
        call clear_launch_line_if_active
        ret

draw_launch_line_if_active:
        call is_launch_active
        ret z
        call draw_launch_line
        ret

clear_launch_line_if_active:
        call is_launch_active
        ret z
        call clear_launch_line
        ret

any_launch_active:
        call load_slot1
        call is_launch_active
        jr nz,launch_active
        ld a,(fcnt)
        cp 2
        jr c,launch_inactive
        call load_slot2
        call is_launch_active
        jr nz,launch_active
        ld a,(fcnt)
        cp 3
        jr c,launch_inactive
        call load_slot3
        call is_launch_active
        jr nz,launch_active
launch_inactive:
        xor a
        ret

is_launch_active:
        ld a,(fy)
        ld b,a
        ld a,(ycur)
        cp b
        jr z,launch_inactive
        jr c,launch_inactive
launch_active:
        ld a,1
        or a
        ret

load_slot1:
        ld hl,slot1
        jr load_slot_common

load_slot2:
        ld hl,slot2
        jr load_slot_common

load_slot3:
        ld hl,slot3

load_slot_common:
        ld a,(hl)
        ld (fx),a
        inc hl
        ld a,(hl)
        ld (fy),a
        inc hl
        ld a,(hl)
        ld (fcol),a
        inc hl
        ld a,(hl)
        ld (fscale),a
        ret

draw_launch_line:
        ld a,(fcol)
        ld (colv),a
        ld a,184
        ld (cy),a
draw_launch_loop:
        ld a,(cy)
        ld b,a
        ld a,(fx)
        ld c,a
        ld a,(colv)
        call plot_set
        ld a,(cy)
        ld b,a
        ld a,(ycur)
        cp b
        ret z
        ld a,(cy)
        dec a
        ld (cy),a
        jr draw_launch_loop

clear_launch_line:
        ld a,184
        ld (cy),a
clear_launch_loop:
        ld a,(cy)
        ld b,a
        ld a,(fx)
        ld c,a
        call plot_clear
        ld a,(cy)
        ld b,a
        ld a,(ycur)
        cp b
        ret z
        ld a,(cy)
        dec a
        ld (cy),a
        jr clear_launch_loop

burst:
        ld hl,burst_offsets
        ld a,7
        ld (rcnt),a
burst_loop:
        call check_space
        ret nz
        push hl
        call draw_all_points
        pop hl
        call wait_frame
        call wait_frame
        call wait_frame
        call wait_frame
        ld de,32
        add hl,de
        ld a,(rcnt)
        dec a
        ld (rcnt),a
        jr nz,burst_loop
        ld a,36
        ld (rcnt),a
hold_loop:
        call check_space
        ret nz
        call wait_frame
        ld a,(rcnt)
        dec a
        ld (rcnt),a
        jr nz,hold_loop
        ld hl,burst_offsets
        ld a,7
        ld (rcnt),a
clear_burst_loop:
        push hl
        call clear_all_points
        pop hl
        ld de,32
        add hl,de
        ld a,(rcnt)
        dec a
        ld (rcnt),a
        jr nz,clear_burst_loop
        ret

draw_all_points:
        push hl
        call load_slot1
        pop hl
        push hl
        call draw_points
        pop hl
        ld a,(fcnt)
        cp 2
        ret c
        push hl
        call load_slot2
        pop hl
        push hl
        call draw_points
        pop hl
        ld a,(fcnt)
        cp 3
        ret c
        push hl
        call load_slot3
        pop hl
        call draw_points
        ret

clear_all_points:
        push hl
        call load_slot1
        pop hl
        push hl
        call clear_points
        pop hl
        ld a,(fcnt)
        cp 2
        ret c
        push hl
        call load_slot2
        pop hl
        push hl
        call clear_points
        pop hl
        ld a,(fcnt)
        cp 3
        ret c
        push hl
        call load_slot3
        pop hl
        call clear_points
        ret

draw_points:
        ld a,16
        ld (pcnt),a
draw_points_loop:
        ld a,(hl)
        inc hl
        call scale_offset
        ld e,a
        ld a,(fx)
        add a,e
        ld c,a
        ld a,(hl)
        inc hl
        call scale_offset
        ld e,a
        ld a,(fy)
        add a,e
        ld b,a
        push hl
        ld a,(fcol)
        call plot_set
        pop hl
        ld a,(pcnt)
        dec a
        ld (pcnt),a
        jr nz,draw_points_loop
        ret

clear_points:
        ld a,16
        ld (pcnt),a
clear_points_loop:
        ld a,(hl)
        inc hl
        call scale_offset
        ld e,a
        ld a,(fx)
        add a,e
        ld c,a
        ld a,(hl)
        inc hl
        call scale_offset
        ld e,a
        ld a,(fy)
        add a,e
        ld b,a
        push hl
        call plot_clear
        pop hl
        ld a,(pcnt)
        dec a
        ld (pcnt),a
        jr nz,clear_points_loop
        ret

scale_offset:
        ld d,0
        bit 7,a
        jr z,scale_abs_ready
        cpl
        inc a
        ld d,1
scale_abs_ready:
        ld e,a
        ld a,(fscale)
        ld b,a
        xor a
scale_mul_loop:
        add a,e
        djnz scale_mul_loop
        srl a
        srl a
        ld e,a
        ld a,d
        or a
        ld a,e
        ret z
        cpl
        inc a
        ret

wait_frame:
        ld a,(lastj)
wait_loop:
        ld b,a
        ld a,(JIFFY)
        cp b
        jr z,wait_loop
        ld (lastj),a
        ret

check_space:
        call CHSNS
        jr nz,key_ready
        xor a
        ret
key_ready:
        call CHGET
        cp $20
        jr z,space_pressed
        xor a
        ret
space_pressed:
        ld a,1
        ld (state),a
        ret

plot_set:
        ld (colv),a
        call calc_addr_pixel
        push hl
        call read_vram
        ld d,a
        ld a,(keepv)
        and d
        ld d,a
        ld a,(bytev)
        or d
        pop hl
        call write_vram
        ret

plot_clear:
        ld a,BACK_COLOR
        call plot_set
        ret

calc_addr_pixel:
        ld a,c
        and 1
        jr nz,pixel_odd
        ld a,(colv)
        and $0F
        add a,a
        add a,a
        add a,a
        add a,a
        ld (bytev),a
        ld a,$0F
        ld (keepv),a
        jr calc_addr_common
pixel_odd:
        ld a,(colv)
        and $0F
        ld (bytev),a
        ld a,$F0
        ld (keepv),a

; SCREEN 5: address = y * 128 + x / 2.
calc_addr_common:
        ld h,0
        ld l,b
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,c
        srl a
        ld e,a
        ld d,0
        add hl,de
        ret

read_vram:
        call set_vram_read
        in a,(VDP_DATA)
        ret

write_vram:
        ld (bytev),a
        call set_vram_write
        ld a,(bytev)
        out (VDP_DATA),a
        ret

set_vram_read:
        di
        ld a,h
        rlca
        rlca
        and 3
        out (VDP_CTRL),a
        ld a,$8E
        out (VDP_CTRL),a
        ld a,l
        out (VDP_CTRL),a
        ld a,h
        and $3F
        out (VDP_CTRL),a
        ei
        ret

set_vram_write:
        di
        ld a,h
        rlca
        rlca
        and 3
        out (VDP_CTRL),a
        ld a,$8E
        out (VDP_CTRL),a
        ld a,l
        out (VDP_CTRL),a
        ld a,h
        and $3F
        or $40
        out (VDP_CTRL),a
        ei
        ret

reset_vram_high:
        xor a
        out (VDP_CTRL),a
        ld a,$8E
        out (VDP_CTRL),a
        ret

burst_offsets:
        db 0,-4,2,-4,3,-3,4,-2,4,0,4,2,3,3,2,4
        db 0,4,-2,4,-3,3,-4,2,-4,0,-4,-2,-3,-3,-2,-4
        db 0,-8,4,-8,6,-6,8,-4,8,0,8,4,6,6,4,8
        db 0,8,-4,8,-6,6,-8,4,-8,0,-8,-4,-6,-6,-4,-8
        db 0,-12,6,-12,9,-9,12,-6,12,0,12,6,9,9,6,12
        db 0,12,-6,12,-9,9,-12,6,-12,0,-12,-6,-9,-9,-6,-12
        db 0,-16,8,-16,12,-12,16,-8,16,0,16,8,12,12,8,16
        db 0,16,-8,16,-12,12,-16,8,-16,0,-16,-8,-12,-12,-8,-16
        db 0,-20,10,-20,15,-15,20,-10,20,0,20,10,15,15,10,20
        db 0,20,-10,20,-15,15,-20,10,-20,0,-20,-10,-15,-15,-10,-20
        db 0,-24,12,-24,18,-18,24,-12,24,0,24,12,18,18,12,24
        db 0,24,-12,24,-18,18,-24,12,-24,0,-24,-12,-18,-18,-12,-24
        db 0,-28,14,-28,21,-21,28,-14,28,0,28,14,21,21,14,28
        db 0,28,-14,28,-21,21,-28,14,-28,0,-28,-14,-21,-21,-14,-28
