; 220 imaginary rocket drawing core for MSX2 / Pasmo
;
; BASIC calculates orbit and rocket coordinates. This ASM draws them in
; SCREEN 5 using direct V9938 VRAM access.

JIFFY   equ $FC9E

VDP_DATA equ $98
VDP_CTRL equ $99

cmdv    equ $C000
rxv     equ $C001
ryv     equ $C002
exv     equ $C003
eyv     equ $C004
mxv     equ $C005
myv     equ $C006
pexv    equ $C007
peyv    equ $C008
pmxv    equ $C009
pmyv    equ $C00A
lastj   equ $C00B
cntv    equ $C00C
cx      equ $C00D
cy      equ $C00E
rowy    equ $C00F
widthv  equ $C010
curx    equ $C011
endx    equ $C012
colv    equ $C013
bytev   equ $C014
keepv   equ $C015

EARTH_ORBIT equ $C020
MARS_ORBIT  equ $C0E0

EARTH_COLOR  equ 4
MARS_COLOR   equ 8
SUN_COLOR    equ 10
ROCKET_COLOR equ 15
ORBIT_COLOR  equ 7
BACK_COLOR   equ 1
BACK_BYTE    equ $11

EARTH_ORBIT_COUNT equ 96
MARS_ORBIT_COUNT  equ 128

        org $D100

entry:
        ld a,(cmdv)
        or a
        jp z,init_scene
        dec a
        jp z,draw_frame
        ret

init_scene:
        ld a,$FF
        ld (pexv),a
        ld (pmxv),a
        call clear_screen5
        call draw_orbits
        call draw_sun
        ld a,(JIFFY)
        ld (lastj),a
        call reset_vram_high
        ret

draw_frame:
        call wait_vblank
        call erase_prev_earth
        call erase_prev_mars
        call draw_orbits
        call draw_sun
        call draw_current_earth
        call draw_current_mars
        call draw_rocket
        call save_planets
        call reset_vram_high
        ret

wait_vblank:
        ld a,(lastj)
wait_loop:
        ld b,a
        ld a,(JIFFY)
        cp b
        jr z,wait_loop
        ld (lastj),a
        ret

save_planets:
        ld a,(exv)
        ld (pexv),a
        ld a,(eyv)
        ld (peyv),a
        ld a,(mxv)
        ld (pmxv),a
        ld a,(myv)
        ld (pmyv),a
        ret

erase_prev_earth:
        ld a,(pexv)
        cp $FF
        ret z
        ld (cx),a
        ld a,(peyv)
        ld (cy),a
        call clear_earth_disk
        ret

erase_prev_mars:
        ld a,(pmxv)
        cp $FF
        ret z
        ld (cx),a
        ld a,(pmyv)
        ld (cy),a
        call clear_mars_disk
        ret

draw_current_earth:
        ld a,(exv)
        ld (cx),a
        ld a,(eyv)
        ld (cy),a
        ld a,EARTH_COLOR
        ld (colv),a
        call fill_earth_disk
        ret

draw_current_mars:
        ld a,(mxv)
        ld (cx),a
        ld a,(myv)
        ld (cy),a
        ld a,MARS_COLOR
        ld (colv),a
        call fill_mars_disk
        ret

draw_rocket:
        ld a,(ryv)
        ld b,a
        ld a,(rxv)
        ld c,a
        ld a,ROCKET_COLOR
        call plot_set
        ld a,(ryv)
        ld b,a
        ld a,(rxv)
        inc a
        ld c,a
        ld a,ROCKET_COLOR
        call plot_set
        ret

draw_orbits:
        call draw_earth_orbit
        call draw_mars_orbit
        ret

draw_earth_orbit:
        ld hl,EARTH_ORBIT
        ld a,EARTH_ORBIT_COUNT
        jr draw_orbit_common

draw_mars_orbit:
        ld hl,MARS_ORBIT
        ld a,MARS_ORBIT_COUNT

draw_orbit_common:
        ld (cntv),a
        ld a,ORBIT_COLOR
        ld (colv),a
draw_orbit_loop:
        ld a,(hl)
        ld c,a
        inc hl
        ld a,(hl)
        ld b,a
        inc hl
        push hl
        ld a,(colv)
        call plot_set
        pop hl
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,draw_orbit_loop
        ret

draw_sun:
        ld a,128
        ld (cx),a
        ld a,96
        ld (cy),a
        ld a,SUN_COLOR
        ld (colv),a
        call fill_sun_disk
        ret

fill_earth_disk:
        ld hl,width_earth
        ld a,(cy)
        sub 6
        ld (rowy),a
        ld a,13
        ld (cntv),a
        jp fill_disk

fill_mars_disk:
        ld hl,width_mars
        ld a,(cy)
        sub 7
        ld (rowy),a
        ld a,15
        ld (cntv),a
        jp fill_disk

fill_sun_disk:
        ld hl,width_sun
        ld a,(cy)
        sub 5
        ld (rowy),a
        ld a,11
        ld (cntv),a
        jp fill_disk

clear_earth_disk:
        ld hl,width_earth
        ld a,(cy)
        sub 6
        ld (rowy),a
        ld a,13
        ld (cntv),a
        jp clear_disk

clear_mars_disk:
        ld hl,width_mars
        ld a,(cy)
        sub 7
        ld (rowy),a
        ld a,15
        ld (cntv),a
        jp clear_disk

fill_disk:
        ld a,(hl)
        inc hl
        ld (widthv),a
        push hl
        call setup_span
        call hline_set
        pop hl
        call next_disk_row
        jr nz,fill_disk
        ret

clear_disk:
        ld a,(hl)
        inc hl
        ld (widthv),a
        push hl
        call setup_span
        call hline_clear
        pop hl
        call next_disk_row
        jr nz,clear_disk
        ret

setup_span:
        ld a,(cx)
        ld c,a
        ld a,(widthv)
        ld e,a
        ld a,c
        sub e
        ld (curx),a
        ld a,(cx)
        ld c,a
        ld a,(widthv)
        add a,c
        ld (endx),a
        ret

next_disk_row:
        ld a,(rowy)
        inc a
        ld (rowy),a
        ld a,(cntv)
        dec a
        ld (cntv),a
        ret

hline_set:
        ld a,(rowy)
        ld b,a
        ld a,(curx)
        ld c,a
        ld a,(colv)
        call plot_set
        ld a,(curx)
        ld c,a
        ld a,(endx)
        cp c
        ret z
        ld a,(curx)
        inc a
        ld (curx),a
        jr hline_set

hline_clear:
        ld a,(rowy)
        ld b,a
        ld a,(curx)
        ld c,a
        ld a,BACK_COLOR
        call plot_set
        ld a,(curx)
        ld c,a
        ld a,(endx)
        cp c
        ret z
        ld a,(curx)
        inc a
        ld (curx),a
        jr hline_clear

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

clear_screen5:
        ld hl,$0000
        ld bc,$6A00
        ld a,BACK_BYTE
        call fill_vram
        ret

fill_vram:
        ld (bytev),a
        call set_vram_write
        ld a,(bytev)
fill_vram_loop:
        out (VDP_DATA),a
        dec bc
        ld d,a
        ld a,b
        or c
        ld a,d
        jr nz,fill_vram_loop
        ret

width_earth:
        db 0,3,4,5,6,6,6,6,6,5,4,3,0
width_mars:
        db 0,4,5,6,6,7,7,7,7,7,6,6,5,4,0
width_sun:
        db 0,3,4,5,5,5,5,5,4,3,0
