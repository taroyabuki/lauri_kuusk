; 240 falling snow demo for MSXPen / Pasmo
;
; BASIC is only a loader. ASM updates and draws the snow field.

CHSNS   equ $009C
CHGET   equ $009F
RDVRM   equ $004A
WRTVRM  equ $004D
JIFFY   equ $FC9E

VDP_DATA equ $98
VDP_CTRL equ $99

seed    equ $C000
lastj   equ $C001
cntv    equ $C002
cx      equ $C003
cy      equ $C004
colv    equ $C005
fillv   equ $C006

FLAKES  equ $C020
FLAKE_COUNT equ 80

SNOW_COLOR equ 15
BACK_COLOR equ 1

        org $D100

entry:
        ld a,(JIFFY)
        or 1
        ld (seed),a
        ld (lastj),a
        call clear_screen2
        call draw_ground
        call init_flakes

main_loop:
        call wait_vblank
        call check_space
        or a
        ret nz
        call erase_flakes
        call update_draw_flakes
        jp main_loop

wait_vblank:
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
        ret

init_flakes:
        ld ix,FLAKES
        ld a,FLAKE_COUNT
        ld (cntv),a
init_loop:
        call reset_flake_ix
        call rand8
        and 127
        ld (ix+1),a
        ld de,5
        add ix,de
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,init_loop
        ret

reset_flake_ix:
        call rand8
        ld (ix+0),a
        call rand8
        and 15
        ld (ix+1),a
        call rand8
        and 1
        inc a
        ld (ix+2),a
        call rand8
        and 3
        ld hl,drift_table
        ld e,a
        ld d,0
        add hl,de
        ld a,(hl)
        ld (ix+3),a
        call rand8
        ld (ix+4),a
        ret

erase_flakes:
        ld ix,FLAKES
        ld a,FLAKE_COUNT
        ld (cntv),a
erase_loop:
        ld c,(ix+0)
        ld b,(ix+1)
        call plot_clear
        ld de,5
        add ix,de
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,erase_loop
        ret

update_draw_flakes:
        ld ix,FLAKES
        ld a,FLAKE_COUNT
        ld (cntv),a
update_loop:
        ld e,(ix+2)
        ld a,(ix+4)
        inc a
        ld (ix+4),a
        xor (ix+0)
        and 7
        jr z,fall_speed_fast
        cp 4
        jr nz,fall_speed_ready
        ld a,e
        cp 2
        jr c,fall_speed_ready
        dec e
        jr fall_speed_ready
fall_speed_fast:
        inc e
fall_speed_ready:
        ld a,(ix+1)
        add a,e
        cp 179
        jr c,flake_in_air
        call reset_flake_ix
        jr draw_flake
flake_in_air:
        ld (ix+1),a
        ld a,(ix+0)
        add a,(ix+3)
        ld (ix+0),a
draw_flake:
        ld c,(ix+0)
        ld b,(ix+1)
        ld a,SNOW_COLOR
        call plot_set
        ld de,5
        add ix,de
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,update_loop
        ret

rand8:
        ld a,(seed)
        rlca
        jr nc,rand_store
        xor $1D
rand_store:
        or 1
        ld (seed),a
        ret

draw_ground:
        ld b,180
ground_row_loop:
        push bc
        ld c,0
        call calc_addr_mask
        ld a,$FF
        call fill_stride_row
        pop bc
        push bc
        ld c,0
        call calc_addr_mask
        ld a,h
        add a,$20
        ld h,a
        ld a,$F1
        call fill_stride_row
        pop bc
        inc b
        ld a,b
        cp 192
        jr nz,ground_row_loop
        ret

fill_stride_row:
        ld (fillv),a
        ld a,32
        ld (cntv),a
fill_stride_loop:
        ld a,(fillv)
        call write_vram
        ld de,8
        add hl,de
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,fill_stride_loop
        ret

plot_set:
        ld (colv),a
        call calc_addr_mask
        push hl
        push de
        call read_vram
        pop de
        or e
        pop hl
        call write_vram
        ld a,h
        add a,$20
        ld h,a
        ld a,(colv)
        add a,a
        add a,a
        add a,a
        add a,a
        or BACK_COLOR
        call write_vram
        ret

plot_clear:
        call calc_addr_mask
        push hl
        push de
        call read_vram
        pop de
        ld d,a
        ld a,e
        cpl
        and d
        pop hl
        call write_vram
        ret

calc_addr_mask:
        ld a,b
        bit 7,a
        jr nz,addr_bank2
        bit 6,a
        jr nz,addr_bank1
        ld h,0
        jr addr_row
addr_bank1:
        ld h,8
        jr addr_row
addr_bank2:
        ld h,16
addr_row:
        ld a,b
        and $38
        rrca
        rrca
        rrca
        add a,h
        ld h,a
        ld a,c
        and $F8
        ld l,a
        ld a,b
        and 7
        add a,l
        ld l,a
        ld a,c
        and 7
        ld e,$80
        or a
        ret z
mask_loop:
        srl e
        dec a
        jr nz,mask_loop
        ret

read_vram:
        call RDVRM
        ret

write_vram:
        push hl
        call WRTVRM
        pop hl
        ret

clear_screen2:
        ld hl,$0000
        ld bc,$1800
        xor a
        call fill_vram
        ld hl,$2000
        ld bc,$1800
        ld a,$F1
        call fill_vram
        ret

fill_vram:
        push af
        di
        ld a,l
        out (VDP_CTRL),a
        ld a,h
        and $3F
        or $40
        out (VDP_CTRL),a
        pop af
fill_vram_loop:
        out (VDP_DATA),a
        dec bc
        ld d,a
        ld a,b
        or c
        ld a,d
        jr nz,fill_vram_loop
        ei
        ret

drift_table:
        db 255,0,1,0
