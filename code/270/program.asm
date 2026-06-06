; 270 MSX2 pseudo-3D race for MSXPen / Pasmo
;
; SCREEN 5 bitmap writes replace the old SCREEN 2 bit/VRAM read-modify-write
; road drawing. Coordinates use SCREEN 5 byte-X units.

GTSTCK  equ $00D5
GTTRIG  equ $00D8
JIFFY   equ $FC9E

VDP_DATA equ $98
VDP_CTRL equ $99

px      equ $D000
tick    equ $D001
cv      equ $D002
leftv   equ $D003
rightv  equ $D004
yv      equ $D005
wv      equ $D006
zv      equ $D007
qv      equ $D008
tmpy    equ $D009
tmpn    equ $D00A
tmpw    equ $D00B
tmpc    equ $D00C
patp    equ $D00D       ; word
targetx equ $D00F
lastj   equ $D010
keyv    equ $D011
pagev   equ $D012

SCREEN_H     equ 212
HORIZON_Y    equ 70
PLAYER_Y     equ 174
PLAYER_MIN_X equ 8
PLAYER_MAX_X equ 120
PLAYER_W     equ 6
PLAYER_H     equ 12
ROAD_STRIPS  equ 18
ENEMY_MAX_Z  equ 15
ROAD_START_W equ 4
ROAD_MAX_W   equ 34
ROAD_LAST_Y   equ 206
ROAD_LAST_H   equ SCREEN_H-ROAD_LAST_Y

SKY_BYTE     equ $44
GRASS_BYTE   equ $22
ROAD_A_BYTE  equ $EE
ROAD_B_BYTE  equ $77
CURB_BYTE    equ $88
ENEMY_BYTE   equ $99
LINE_BYTE    equ $FF

        org $D100

entry:
        ld a,64
        ld (px),a
        ld (targetx),a
        xor a
        ld (tick),a
        ld (keyv),a
        ld (pagev),a
        call reset_vram_high
        call set_display_page
        call draw_frame
        ld a,(JIFFY)
        ld (lastj),a

main_loop:
        call wait_vblank
        call read_input
        or a
        jr z,continue_game
        call shutdown_vdp
        ret
continue_game:
        call update_player
        ld a,(tick)
        inc a
        and 63
        ld (tick),a
        call flip_page
        call draw_frame
        call set_display_page
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

read_input:
        xor a
        call GTTRIG
        or a
        jr nz,quit_input
        ld a,1
        call GTTRIG
        or a
        jr nz,quit_input

        xor a
        call GTSTCK
        or a
        jr nz,got_stick
        ld a,1
        call GTSTCK
got_stick:
        cp 2
        jr z,got_right
        cp 3
        jr z,got_right
        cp 4
        jr z,got_right
        cp 6
        jr z,got_left
        cp 7
        jr z,got_left
        cp 8
        jr z,got_left
        xor a
        ld (keyv),a
        ret

quit_input:
        ld a,1
        ret

got_right:
        ld a,(keyv)
        cp 1
        jr z,input_done
        ld a,1
        ld (keyv),a
        jr move_right

got_left:
        ld a,(keyv)
        cp 2
        jr z,input_done
        ld a,2
        ld (keyv),a
        jr move_left

move_right:
        ld a,(targetx)
        cp PLAYER_MAX_X-5
        jr nc,set_right_edge
        add a,6
        ld (targetx),a
        jr input_done
set_right_edge:
        ld a,PLAYER_MAX_X
        ld (targetx),a
        jr input_done

move_left:
        ld a,(targetx)
        cp PLAYER_MIN_X+6
        jr c,set_left_edge
        sub 6
        ld (targetx),a
        jr input_done
set_left_edge:
        ld a,PLAYER_MIN_X
        ld (targetx),a

input_done:
        xor a
        ret

update_player:
        ld a,(targetx)
        ld b,a
        ld a,(px)
        cp b
        ret z
        jr c,player_right
        sub b
        cp 3
        jr c,player_snap
        ld a,(px)
        sub 2
        ld (px),a
        ret

player_right:
        ld c,a
        ld a,b
        sub c
        cp 3
        jr c,player_snap
        ld a,c
        add a,2
        ld (px),a
        ret

player_snap:
        ld a,b
        ld (px),a
        ret

draw_frame:
        call clear_scene
        call draw_road
        call draw_enemy
        call draw_player
        ret

flip_page:
        ld a,(pagev)
        xor 1
        ld (pagev),a
        ret

clear_scene:
        ld b,0
        ld c,0
        ld d,HORIZON_Y
        ld e,128
        ld a,SKY_BYTE
        call hmmv_rect
        ld b,HORIZON_Y
        ld c,0
        ld d,SCREEN_H-HORIZON_Y
        ld e,128
        ld a,GRASS_BYTE
        call hmmv_rect
        ret

draw_road:
        xor a
        ld (zv),a
        ld a,HORIZON_Y
        ld (yv),a
        ld a,ROAD_START_W
        ld (wv),a
road_loop:
        ld a,(zv)
        cp ROAD_STRIPS
        ret z
        call calc_center
        call draw_road_strip
        ld a,(tick)
        and 1
        ld b,a
        ld a,(zv)
        add a,b
        and 1
        call z,draw_center_dash
        call draw_side_posts
        ld a,(zv)
        inc a
        ld (zv),a
        ld a,(yv)
        add a,8
        ld (yv),a
        ld a,(wv)
        add a,2
        ld (wv),a
        jr road_loop

calc_center:
        ld a,(zv)
        add a,a
        ld b,a
        ld a,(tick)
        add a,b
        and 63
        ld (qv),a
        cp 16
        jr c,center_first
        cp 48
        jr c,center_middle
        ld (cv),a
        ret
center_first:
        add a,64
        ld (cv),a
        ret
center_middle:
        ld b,a
        ld a,96
        sub b
        ld (cv),a
        ret

draw_road_strip:
        ld a,(cv)
        ld b,a
        ld a,(wv)
        cp ROAD_MAX_W
        jr c,road_width_ready
        ld a,ROAD_MAX_W
road_width_ready:
        ld c,a
        ld a,b
        sub c
        ld (leftv),a
        ld a,b
        add a,c
        ld (rightv),a
        ld a,(yv)
        ld (tmpy),a
        ld a,(tmpy)
        cp ROAD_LAST_Y
        jr nc,last_strip_height
        ld a,8
        jr strip_height_done
last_strip_height:
        ld a,ROAD_LAST_H
strip_height_done:
        ld (tmpn),a
        ld a,(zv)
        ld b,a
        ld a,(tick)
        add a,b
        and 1
        ld a,ROAD_A_BYTE
        jr z,road_color_ready
        ld a,ROAD_B_BYTE
road_color_ready:
        ld (qv),a
        ld a,(rightv)
        ld e,a
        ld a,(leftv)
        ld d,a
        ld a,e
        sub d
        inc a
        ld e,a
        ld a,(tmpn)
        ld d,a
        ld a,(tmpy)
        ld b,a
        ld a,(leftv)
        ld c,a
        ld a,(qv)
        call hmmv_rect

        ld a,(tmpy)
        ld b,a
        ld a,(leftv)
        ld c,a
        ld a,(rightv)
        ld e,a
        ld a,(leftv)
        ld d,a
        ld a,e
        sub d
        inc a
        ld e,a
        ld a,LINE_BYTE
        call write_run
strip_row:
        ld a,(tmpy)
        ld b,a
        ld a,(leftv)
        ld c,a
        ld a,CURB_BYTE
        ld e,1
        call write_run

        ld a,(tmpy)
        ld b,a
        ld a,(rightv)
        ld c,a
        ld a,CURB_BYTE
        ld e,1
        call write_run

        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr nz,strip_row
        ret

draw_center_dash:
        ld a,(yv)
        inc a
        ld (tmpy),a
        cp 209
        jr nc,last_dash_height
        ld a,5
        jr dash_height_done
last_dash_height:
        ld a,3
dash_height_done:
        ld (tmpn),a
dash_row:
        ld a,(tmpy)
        ld b,a
        ld a,(cv)
        ld c,a
        ld a,LINE_BYTE
        ld e,1
        call write_run
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr nz,dash_row
        ret

draw_side_posts:
        ld a,(tick)
        and 15
        ld b,a
        ld a,(zv)
        add a,b
        and 3
        ret nz
        ld a,(zv)
        rrca
        rrca
        and 7
        add a,2
        ld (tmpw),a
        ld a,(leftv)
        sub 3
        ld c,a
        call draw_post_at_c
        ld a,(rightv)
        add a,3
        ld c,a
        call draw_post_at_c
        ret

draw_post_at_c:
        ld a,(yv)
        ld (tmpy),a
        ld a,(tmpw)
        ld (tmpn),a
post_row:
        ld a,(tmpy)
        cp 212
        ret nc
        ld b,a
        ld a,LINE_BYTE
        ld e,1
        call write_run
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr nz,post_row
        ret

draw_player:
        ld hl,player_pat
        ld (patp),hl
        ld a,PLAYER_Y
        ld (tmpy),a
        ld a,PLAYER_H
        ld (tmpn),a
player_row:
        ld a,(tmpy)
        ld b,a
        ld a,(px)
        sub 3
        ld c,a
        call calc_addr_byte
        call set_vram_write
        ld hl,(patp)
        ld e,PLAYER_W
player_col:
        ld a,(hl)
        out (VDP_DATA),a
        inc hl
        dec e
        jr nz,player_col
        ld (patp),hl
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr nz,player_row
        ret

draw_enemy:
        ld a,(tick)
        rrca
        and ENEMY_MAX_Z
        ld (zv),a
        call calc_center
        ld a,(tick)
        and 32
        jr z,enemy_left_lane
        ld a,(cv)
        add a,8
        jr enemy_lane_done
enemy_left_lane:
        ld a,(cv)
        sub 8
enemy_lane_done:
        ld b,a
        ld a,(zv)
        rrca
        and 7
        add a,2
        ld (wv),a
        srl a
        ld c,a
        ld a,b
        sub c
        ld (leftv),a
        ld a,(zv)
        add a,a
        add a,a
        add a,a
        add a,HORIZON_Y+6
        ld (tmpy),a
        ld a,(zv)
        rrca
        rrca
        and 7
        add a,2
        ld (tmpn),a
        ld a,(tmpy)
        ld b,a
        ld a,(leftv)
        ld c,a
        ld a,(tmpn)
        ld d,a
        ld a,(wv)
        ld e,a
        ld a,ENEMY_BYTE
        call hmmv_rect
        ld a,(tmpy)
        ld b,a
        ld a,(leftv)
        ld c,a
        ld a,LINE_BYTE
        push af
        ld a,(wv)
        ld e,a
        pop af
        call write_run
enemy_side_loop:
        ld a,(tmpy)
        cp 212
        ret nc
        ld b,a
        ld a,(leftv)
        ld c,a
        ld a,LINE_BYTE
        ld e,1
        call write_run
        ld a,(leftv)
        ld b,a
        ld a,(wv)
        add a,b
        dec a
        ld c,a
        ld a,(tmpy)
        ld b,a
        ld a,LINE_BYTE
        ld e,1
        call write_run
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr nz,enemy_side_loop
        ld a,(tmpy)
        dec a
        ld b,a
        ld a,(leftv)
        ld c,a
        ld a,LINE_BYTE
        push af
        ld a,(wv)
        ld e,a
        pop af
        call write_run
        ret

write_run:
        ld (tmpc),a
        ld a,e
        ld (tmpw),a
        call calc_addr_byte
        call set_vram_write
        ld a,(tmpw)
        ld e,a
        ld a,(tmpc)
write_run_loop:
        out (VDP_DATA),a
        dec e
        jr nz,write_run_loop
        ret

; HMMV rectangle fill in SCREEN 5 byte-X coordinates.
; A=color byte, B=y, C=byte_x, D=height, E=width bytes.
hmmv_rect:
        push af
        ld a,d
        ld (tmpn),a
        ld a,e
        ld (tmpw),a
        ld a,b
        ld (tmpy),a
        ld a,c
        ld (qv),a
        call wait_vdp_cmd
        di
        ld a,(qv)
        add a,a
        ld c,36
        call set_vdp_reg
        xor a
        ld c,37
        call set_vdp_reg
        ld a,(tmpy)
        ld c,38
        call set_vdp_reg
        ld a,(pagev)
        ld c,39
        call set_vdp_reg
        ld a,(tmpw)
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
        ld a,(tmpn)
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

; SCREEN 5 byte coordinate: address = y * 128 + byte_x.
calc_addr_byte:
        ld h,0
        ld l,b
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld e,c
        ld d,0
        add hl,de
        ld a,(pagev)
        or a
        ret z
        ld de,$8000
        add hl,de
        ret

set_vram_write:
        call wait_vdp_cmd
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

set_display_page:
        di
        ld a,(pagev)
        or a
        jr z,set_display_page0
        ld a,$3F
        jr set_display_reg
set_display_page0:
        ld a,$1F
set_display_reg:
        out (VDP_CTRL),a
        ld a,$82
        out (VDP_CTRL),a
        ei
        ret

shutdown_vdp:
        xor a
        ld (pagev),a
        call set_display_page
        call reset_vram_high
        ret

player_pat:
        db $EE,$EE,$FF,$FF,$EE,$EE
        db $EE,$EF,$FF,$FF,$FE,$EE
        db $EE,$EF,$F8,$8F,$FE,$EE
        db $EE,$FF,$F8,$8F,$FF,$EE
        db $EF,$FF,$FF,$FF,$FF,$FE
        db $EF,$FE,$FF,$FF,$EF,$FE
        db $EF,$FE,$FF,$FF,$EF,$FE
        db $EF,$FF,$FF,$FF,$FF,$FE
        db $EE,$FF,$F8,$8F,$FF,$EE
        db $EE,$EF,$F8,$8F,$FE,$EE
        db $EE,$EF,$FF,$FF,$FE,$EE
        db $EE,$EE,$FF,$FF,$EE,$EE
