; 350 crystal trio drawing helpers for MSX2 / Pasmo
;
; BASIC keeps the game logic and input. This routine only draws SCREEN 5
; rectangles using V9938 HMMV.

VDP_CTRL equ $99

cmd     equ $D000
gx      equ $D001
gy      equ $D002
kind    equ $D003
active  equ $D004
tmpx    equ $D005
tmpy    equ $D006
recth   equ $D007
rectw   equ $D008
recty   equ $D009
rectx   equ $D00A

BOARD_X equ 8       ; SCREEN 5 byte-X coordinate for pixel X=16
BOARD_Y equ 48
CELL_W  equ 8
CELL_H  equ 16

BG_COLOR     equ $11
GROUND_COLOR equ $22
WATER_COLOR  equ $44
ROCK_COLOR   equ $66
CRACK_COLOR  equ $99
GATE_COLOR   equ $EE
SWITCH_COLOR equ $AA
YGATE_COLOR  equ $BB
ACTIVE_COLOR equ $FF

        org $D100

entry:
        ld a,(cmd)
        cp 1
        jp z,draw_tile
        cp 2
        jp z,draw_crystal
        cp 3
        jp z,draw_character
        ret

draw_tile:
        call calc_cell_pos
        ld a,(kind)
        call tile_color
        push af
        ld a,(tmpy)
        ld b,a
        ld a,(tmpx)
        ld c,a
        ld d,CELL_H
        ld e,CELL_W
        pop af
        call hmmv_rect
        call draw_tile_border
        ld a,(kind)
        cp 5
        jr z,draw_switch_mark
        cp 4
        jr z,draw_gate_mark
        cp 6
        jr z,draw_gate_mark
        jp wait_vdp_cmd
draw_switch_mark:
        ld a,(tmpy)
        add a,5
        ld b,a
        ld a,(tmpx)
        add a,3
        ld c,a
        ld d,7
        ld e,2
        ld a,ACTIVE_COLOR
        call hmmv_rect
        jp wait_vdp_cmd
draw_gate_mark:
        call draw_gate_bars
        jp wait_vdp_cmd

draw_crystal:
        call calc_cell_pos
        ld a,(tmpy)
        add a,2
        ld b,a
        ld a,(tmpx)
        add a,4
        ld c,a
        ld d,2
        ld e,1
        ld a,ACTIVE_COLOR
        call hmmv_rect
        ld a,(tmpy)
        add a,4
        ld b,a
        ld a,(tmpx)
        add a,3
        ld c,a
        ld d,3
        ld e,3
        ld a,ACTIVE_COLOR
        call hmmv_rect
        ld a,(tmpy)
        add a,6
        ld b,a
        ld a,(tmpx)
        add a,2
        ld c,a
        ld d,4
        ld e,5
        ld a,ACTIVE_COLOR
        call hmmv_rect
        ld a,(tmpy)
        add a,10
        ld b,a
        ld a,(tmpx)
        add a,3
        ld c,a
        ld d,2
        ld e,3
        ld a,ACTIVE_COLOR
        call hmmv_rect
        ld a,(tmpy)
        add a,12
        ld b,a
        ld a,(tmpx)
        add a,4
        ld c,a
        ld d,2
        ld e,1
        ld a,ACTIVE_COLOR
        call hmmv_rect
        jp wait_vdp_cmd

draw_character:
        call calc_cell_pos
        ld a,(kind)
        call actor_color
        push af
        ld a,(tmpy)
        add a,3
        ld b,a
        ld a,(tmpx)
        add a,2
        ld c,a
        ld d,10
        ld e,4
        pop af
        call hmmv_rect
        ld a,(kind)
        ld b,a
        ld a,(active)
        cp b
        jp nz,wait_vdp_cmd
        call draw_active_border
        jp wait_vdp_cmd

draw_tile_border:
        ld a,(tmpy)
        ld b,a
        ld a,(tmpx)
        ld c,a
        ld d,1
        ld e,CELL_W
        ld a,BG_COLOR
        call hmmv_rect
        ld a,(tmpy)
        add a,CELL_H-1
        ld b,a
        ld a,(tmpx)
        ld c,a
        ld d,1
        ld e,CELL_W
        ld a,BG_COLOR
        call hmmv_rect
        ret

draw_gate_bars:
        ld a,(tmpy)
        add a,2
        ld b,a
        ld a,(tmpx)
        add a,1
        ld c,a
        ld d,12
        ld e,1
        ld a,BG_COLOR
        call hmmv_rect
        ld a,(tmpy)
        add a,2
        ld b,a
        ld a,(tmpx)
        add a,3
        ld c,a
        ld d,12
        ld e,1
        ld a,BG_COLOR
        call hmmv_rect
        ld a,(tmpy)
        add a,2
        ld b,a
        ld a,(tmpx)
        add a,5
        ld c,a
        ld d,12
        ld e,1
        ld a,BG_COLOR
        call hmmv_rect
        ld a,(tmpy)
        add a,7
        ld b,a
        ld a,(tmpx)
        add a,1
        ld c,a
        ld d,1
        ld e,6
        ld a,BG_COLOR
        call hmmv_rect
        ret

draw_active_border:
        ld a,(tmpy)
        ld b,a
        ld a,(tmpx)
        ld c,a
        ld d,1
        ld e,CELL_W
        ld a,ACTIVE_COLOR
        call hmmv_rect
        ld a,(tmpy)
        add a,CELL_H-1
        ld b,a
        ld a,(tmpx)
        ld c,a
        ld d,1
        ld e,CELL_W
        ld a,ACTIVE_COLOR
        call hmmv_rect
        ld a,(tmpy)
        ld b,a
        ld a,(tmpx)
        ld c,a
        ld d,CELL_H
        ld e,1
        ld a,ACTIVE_COLOR
        call hmmv_rect
        ld a,(tmpy)
        ld b,a
        ld a,(tmpx)
        add a,CELL_W-1
        ld c,a
        ld d,CELL_H
        ld e,1
        ld a,ACTIVE_COLOR
        call hmmv_rect
        ret

calc_cell_pos:
        ld a,(gx)
        add a,a
        add a,a
        add a,a
        add a,BOARD_X
        ld (tmpx),a
        ld a,(gy)
        add a,a
        add a,a
        add a,a
        add a,a
        add a,BOARD_Y
        ld (tmpy),a
        ret

tile_color:
        or a
        jr z,tile_ground
        cp 1
        jr z,tile_water
        cp 2
        jr z,tile_rock
        cp 3
        jr z,tile_crack
        cp 4
        jr z,tile_gate
        cp 5
        jr z,tile_switch
        cp 6
        jr z,tile_yellow
tile_ground:
        ld a,GROUND_COLOR
        ret
tile_water:
        ld a,WATER_COLOR
        ret
tile_rock:
        ld a,ROCK_COLOR
        ret
tile_crack:
        ld a,CRACK_COLOR
        ret
tile_gate:
        ld a,GATE_COLOR
        ret
tile_switch:
        ld a,SWITCH_COLOR
        ret
tile_yellow:
        ld a,YGATE_COLOR
        ret

actor_color:
        or a
        jr z,actor_blue
        cp 1
        jr z,actor_red
        ld a,SWITCH_COLOR
        ret
actor_blue:
        ld a,WATER_COLOR
        ret
actor_red:
        ld a,$88
        ret

; HMMV rectangle fill in SCREEN 5 byte-X coordinates.
; A=color, B=y, C=byte_x, D=height, E=width bytes.
hmmv_rect:
        push af
        ld a,d
        ld (recth),a
        ld a,e
        ld (rectw),a
        ld a,b
        ld (recty),a
        ld a,c
        ld (rectx),a
        call wait_vdp_cmd
        di
        ld a,(rectx)
        add a,a
        ld c,36
        call set_vdp_reg
        xor a
        ld c,37
        call set_vdp_reg
        ld a,(recty)
        ld c,38
        call set_vdp_reg
        xor a
        ld c,39
        call set_vdp_reg
        ld a,(rectw)
        add a,a
        ld e,a
        ld a,0
        adc a,0
        ld d,a
        ld a,e
        ld c,40
        call set_vdp_reg
        ld a,d
        ld c,41
        call set_vdp_reg
        ld a,(recth)
        ld c,42
        call set_vdp_reg
        xor a
        ld c,43
        call set_vdp_reg
        pop af
        ld c,44
        call set_vdp_reg
        xor a
        ld c,45
        call set_vdp_reg
        ld a,$C0
        ld c,46
        call set_vdp_reg
        ei
        ret

set_vdp_reg:
        out (VDP_CTRL),a
        ld a,c
        or $80
        out (VDP_CTRL),a
        ret

wait_vdp_cmd:
wait_vdp_poll:
        di
        ld a,2
        out (VDP_CTRL),a
        ld a,$8F
        out (VDP_CTRL),a
        in a,(VDP_CTRL)
        push af
        xor a
        out (VDP_CTRL),a
        ld a,$8F
        out (VDP_CTRL),a
        ei
        pop af
        and 1
        jr nz,wait_vdp_poll
        ret
