; 320 pseudo rotation race for MSX2 / Pasmo
;
; SCREEN 5 replaces the old SCREEN 2 bit/VRAM read-modify-write drawing.
; V9938 HMMV clears the scene and double buffering keeps the tilted horizon and
; road rotation stable while the steering angle smoothly follows a target.

GTSTCK  equ $00D5
GTTRIG  equ $00D8
JIFFY   equ $FC9E

VDP_DATA equ $98
VDP_CTRL equ $99

px      equ $D000
tick    equ $D001
maskv   equ $D002
x1v     equ $D003
x2v     equ $D004
yv      equ $D005
cv      equ $D006
wv      equ $D007
qv      equ $D008
zv      equ $D009
xbv     equ $D00A
xev     equ $D00B
xcv     equ $D00C
tmpn    equ $D00D
tmpy    equ $D00E
anglev  equ $D00F
lastj   equ $D010
keyv    equ $D011
targeta equ $D012
seg0y   equ $D013
seg1y   equ $D014
seg2y   equ $D015
seg3y   equ $D016
halfw   equ $D017
basey   equ $D018
tiltv   equ $D019
pagev   equ $D01A
ampv    equ $D01B
signv   equ $D01C
edgev   equ $D01D
stepv   equ $D01E
errv    equ $D01F

SCREEN_H    equ 212
SKY_BYTE    equ $44
GROUND_BYTE equ $22
LINE_BYTE   equ $FF
CAR_BYTE    equ $FF
CAR_DARK    equ $11

        org $D100

entry:
        ld a,128
        ld (px),a
        ld a,18
        ld (anglev),a
        ld (targeta),a
        xor a
        ld (tick),a
        ld (keyv),a
        ld (pagev),a

        call init_screen
        call draw_frame
        call set_display_page
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
        call update_angle
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
        jr rotate_right

got_left:
        jr rotate_left

rotate_right:
        ld a,(targeta)
        cp 36
        jr nc,input_done
        inc a
        ld (targeta),a
        jr input_done

rotate_left:
        ld a,(targeta)
        or a
        jr z,input_done
        dec a
        ld (targeta),a

input_done:
        xor a
        ret

update_angle:
        ld a,(targeta)
        ld b,a
        ld a,(anglev)
        cp b
        ret z
        jr c,angle_right
        ld a,(anglev)
        dec a
        ld (anglev),a
        ret

angle_right:
        ld a,(anglev)
        inc a
        ld (anglev),a
        ret

init_screen:
        call reset_vram_high
        xor a
        ld (pagev),a
        ret

draw_frame:
        call clear_scene

        xor a
        ld (zv),a
        ld a,(tick)
        and 7
        add a,66
        ld (yv),a
        ld a,8
        ld (wv),a

road_loop:
        ld a,(zv)
        cp 14
        jp z,frame_done

        call calc_center
        call tilted_road_line

        ld a,(zv)
        and 1
        jr nz,skip_center
        ld a,(yv)
        inc a
        ld (tmpy),a
        ld a,4
        ld (tmpn),a
center_loop:
        ld a,(cv)
        ld b,a
        ld c,a
        ld a,(tmpy)
        ld d,a
        call hline
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr nz,center_loop

skip_center:
        ld a,(zv)
        inc a
        ld (zv),a
        ld a,(yv)
        add a,8
        ld (yv),a
        ld a,(wv)
        add a,6
        ld (wv),a
        jp road_loop

frame_done:
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
        ld d,SCREEN_H
        ld e,128
        ld a,GROUND_BYTE
        call hmmv_rect

        call setup_horizon
        ld a,(tmpy)
        ld (x1v),a
        ld a,(tmpn)
        ld (x2v),a
        ld a,(x1v)
        or a
        jr z,skip_full_sky
        ld b,0
        ld c,0
        ld d,a
        ld e,128
        ld a,SKY_BYTE
        call hmmv_rect
skip_full_sky:
        ld a,(x1v)
        ld (tmpy),a
        ld a,(x2v)
        ld (tmpn),a
        ld a,(ampv)
        or a
        ret z

sky_slope_loop:
        ld a,(tmpn)
        or a
        ret z
        call next_edge
        ld b,a
        ld a,(signv)
        or a
        ld a,b
        jr nz,sky_positive
        ld c,a
        ld a,128
        sub c
        ld e,a
        jr sky_write
sky_positive:
        ld c,0
        inc a
        ld e,a
sky_write:
        ld a,(tmpy)
        ld b,a
        ld a,SKY_BYTE
        call write_run
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr sky_slope_loop

calc_center:
        ld a,(anglev)
        ld l,a
        ld h,0
        add hl,hl
        push hl
        add hl,hl
        add hl,hl
        add hl,hl
        pop de
        or a
        sbc hl,de
        ld a,(zv)
        ld e,a
        ld d,0
        add hl,de
        ld de,center_table
        add hl,de
        ld a,(hl)
        add a,128
        ld (cv),a
        ret

tilted_road_line:
        call load_road_tilt_ys
        ld a,(cv)
        ld e,a
        ld a,(wv)
        ld d,a
        ld a,e
        sub d
        srl a
        ld (x1v),a
        ld a,e
        add a,d
        srl a
        ld (x2v),a

        ld a,(tiltv)
        or a
        jp z,road_flat_line
        jp m,road_line_negative

road_line_positive:
        ld (ampv),a
        ld a,1
        ld (signv),a
        ld a,(x2v)
        ld b,a
        ld a,(x1v)
        ld c,a
        ld a,b
        sub c
        ld (x2v),a
        ld a,b
        ld (x1v),a
        jp setup_road_diag

road_line_negative:
        neg
        ld (ampv),a
        xor a
        ld (signv),a
        ld a,(x2v)
        ld b,a
        ld a,(x1v)
        ld c,a
        ld a,b
        sub c
        ld (x2v),a

setup_road_diag:
        ld a,(basey)
        ld b,a
        ld a,(ampv)
        ld c,a
        ld a,b
        sub c
        ld (tmpy),a
        ld a,(ampv)
        add a,a
        ld (stepv),a
        inc a
        ld (tmpn),a
        xor a
        ld (edgev),a
        ld (errv),a
        call next_road_x
        ld (xbv),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
road_diag_loop:
        ld a,(tmpn)
        or a
        jr z,road_last_dot
        call next_road_x
        ld (xev),a
        ld a,(xbv)
        ld c,a
        ld a,(xev)
        cp c
        jr nc,road_diag_forward
        ld c,a
        ld a,(xbv)
road_diag_forward:
        sub c
        inc a
        ld e,a
        ld a,(tmpy)
        ld b,a
        ld a,LINE_BYTE
        call write_run
        ld a,(xev)
        ld (xbv),a
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr road_diag_loop

road_last_dot:
        ld a,(xbv)
        ld c,a
        ld e,1
        ld a,(tmpy)
        ld b,a
        ld a,LINE_BYTE
        call write_run
        ld a,(basey)
        ld (yv),a
        ret

road_flat_line:
        ld a,(x2v)
        ld b,a
        ld a,(x1v)
        ld c,a
        ld a,b
        sub c
        inc a
        ld e,a
        ld a,(basey)
        ld b,a
        ld a,LINE_BYTE
        call write_run
        ld a,(basey)
        ld (yv),a
        ret

load_screen_tilt_ys:
        ld a,(yv)
        ld (basey),a
        ld a,(anglev)
        ld l,a
        ld h,0
        ld de,screen_tilt_amp_table
        add hl,de
        ld a,(hl)
        call store_tilt_ys
        ret

load_road_tilt_ys:
        ld a,(yv)
        ld (basey),a
        ld a,(anglev)
        ld l,a
        ld h,0
        add hl,hl
        push hl
        add hl,hl
        add hl,hl
        add hl,hl
        pop de
        or a
        sbc hl,de
        ld a,(zv)
        ld e,a
        ld d,0
        add hl,de
        ld de,road_tilt_amp_table
        add hl,de
        ld a,(hl)
        call store_tilt_ys
        ret

setup_horizon:
        ld a,64
        ld (yv),a
        call load_screen_tilt_ys
        ld a,(tiltv)
        or a
        jr z,setup_flat_horizon
        jp m,setup_negative_horizon
        ld (ampv),a
        ld a,1
        ld (signv),a
        jr setup_horizon_common
setup_negative_horizon:
        neg
        ld (ampv),a
        xor a
        ld (signv),a
        jr setup_horizon_common
setup_flat_horizon:
        xor a
        ld (ampv),a
        ld (signv),a
setup_horizon_common:
        ld a,(basey)
        ld b,a
        ld a,(ampv)
        ld c,a
        ld a,b
        sub c
        ld (tmpy),a
        ld a,(ampv)
        add a,a
        ld (stepv),a
        inc a
        ld (tmpn),a
        xor a
        ld (edgev),a
        ld (errv),a
        ret

next_edge:
        ld a,(edgev)
        ld b,a
        ld a,(errv)
        add a,127
        ld (errv),a
next_edge_advance:
        ld a,(stepv)
        ld c,a
        ld a,(errv)
        cp c
        jr c,next_edge_done
        sub c
        ld (errv),a
        ld a,(edgev)
        inc a
        ld (edgev),a
        jr next_edge_advance
next_edge_done:
        ld a,(signv)
        or a
        ld a,b
        ret z
        ld a,127
        sub b
        ret

next_road_x:
        ld a,(edgev)
        ld b,a
        ld a,(errv)
        ld c,a
        ld a,(x2v)
        add a,c
        ld (errv),a
next_road_x_advance:
        ld a,(stepv)
        ld c,a
        ld a,(errv)
        cp c
        jr c,next_road_x_done
        sub c
        ld (errv),a
        ld a,(edgev)
        inc a
        ld (edgev),a
        jr next_road_x_advance
next_road_x_done:
        ld a,(signv)
        or a
        ld a,(x1v)
        jr nz,next_road_x_decrease
        add a,b
        ret
next_road_x_decrease:
        sub b
        ret

store_tilt_ys:
        ld (tiltv),a
        ld a,(basey)
        ld b,a
        ld a,(tiltv)
        add a,b
        ld (seg0y),a
        ld a,(tiltv)
        sra a
        ld (qv),a
        add a,b
        ld (seg1y),a
        ld a,(qv)
        neg
        add a,b
        ld (seg2y),a
        ld a,(tiltv)
        neg
        add a,b
        ld (seg3y),a
        ret

; Draw pixels x=B..C at y=D on SCREEN 5. X is converted to byte coordinates,
; so the line has 2-pixel horizontal granularity.
hline:
        ld a,b
        srl a
        ld (xbv),a
        ld a,c
        srl a
        ld (xev),a
        ld a,(xev)
        ld b,a
        ld a,(xbv)
        cp b
        jr c,hline_width_ready
        jr z,hline_width_ready
        ret
hline_width_ready:
        ld c,a
        ld a,b
        sub c
        inc a
        ld e,a
        ld b,d
        ld a,LINE_BYTE
        call write_run
        ret

draw_player:
        call load_car_tilt

        ld b,158
        ld a,(errv)
        add a,60
        ld c,a
        ld d,3
        ld e,8
        ld a,CAR_BYTE
        call hmmv_rect

        ld b,161
        ld a,(edgev)
        add a,58
        ld c,a
        ld d,3
        ld e,12
        ld a,CAR_BYTE
        call hmmv_rect

        ld b,164
        ld c,56
        ld d,5
        ld e,16
        ld a,CAR_BYTE
        call hmmv_rect

        ld b,169
        ld a,(edgev)
        neg
        add a,56
        ld c,a
        ld d,4
        ld e,16
        ld a,CAR_BYTE
        call hmmv_rect

        ld b,173
        ld a,(errv)
        neg
        add a,52
        ld c,a
        ld d,2
        ld e,24
        ld a,CAR_BYTE
        call hmmv_rect

        ld b,162
        ld a,(edgev)
        add a,62
        ld c,a
        ld d,3
        ld e,4
        ld a,CAR_DARK
        call hmmv_rect
        ret

load_car_tilt:
        ld a,(anglev)
        ld l,a
        ld h,0
        ld de,car_tilt_table
        add hl,de
        ld a,(hl)
        ld (edgev),a
        add a,a
        ld (errv),a
        ret

write_run:
        ld (maskv),a
        ld a,e
        or a
        ret z
        ld (xcv),a
        call calc_addr_byte
        call set_vram_write
        ld a,(xcv)
        ld b,a
        ld a,(maskv)
write_run_loop:
        out (VDP_DATA),a
        djnz write_run_loop
        ret

; HMMV rectangle fill in SCREEN 5 byte-X coordinates.
; A=color byte, B=y, C=byte_x, D=height, E=width bytes.
hmmv_rect:
        push af
        ld a,d
        ld (tmpn),a
        ld a,e
        ld (wv),a
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
        ld a,(wv)
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
        call wait_vdp_cmd
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

center_table:
        db -48,-42,-36,-30,-24,-18,-12,-6,0,6,14,22,31,40
        db -45,-40,-34,-28,-23,-17,-11,-6,0,6,13,21,29,38
        db -43,-37,-32,-27,-21,-16,-11,-5,0,5,12,20,28,36
        db -40,-35,-30,-25,-20,-15,-10,-5,0,5,12,18,26,33
        db -37,-33,-28,-23,-19,-14,-9,-5,0,5,11,17,24,31
        db -35,-30,-26,-22,-17,-13,-9,-4,0,4,10,16,22,29
        db -32,-28,-24,-20,-16,-12,-8,-4,0,4,9,15,21,27
        db -29,-26,-22,-18,-15,-11,-7,-4,0,4,9,13,19,24
        db -27,-23,-20,-17,-13,-10,-7,-3,0,3,8,12,17,22
        db -24,-21,-18,-15,-12,-9,-6,-3,0,3,7,11,16,20
        db -21,-19,-16,-13,-11,-8,-5,-3,0,3,6,10,14,18
        db -19,-16,-14,-12,-9,-7,-5,-2,0,2,5,9,12,16
        db -16,-14,-12,-10,-8,-6,-4,-2,0,2,5,7,10,13
        db -13,-12,-10,-8,-7,-5,-3,-2,0,2,4,6,9,11
        db -11,-9,-8,-7,-5,-4,-3,-1,0,1,3,5,7,9
        db -8,-7,-6,-5,-4,-3,-2,-1,0,1,2,4,5,7
        db -5,-5,-4,-3,-3,-2,-1,-1,0,1,2,2,3,4
        db -3,-2,-2,-2,-1,-1,-1,0,0,0,1,1,2,2
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 3,2,2,2,1,1,1,0,0,0,-1,-1,-2,-2
        db 5,5,4,3,3,2,1,1,0,-1,-2,-2,-3,-4
        db 8,7,6,5,4,3,2,1,0,-1,-2,-4,-5,-7
        db 11,9,8,7,5,4,3,1,0,-1,-3,-5,-7,-9
        db 13,12,10,8,7,5,3,2,0,-2,-4,-6,-9,-11
        db 16,14,12,10,8,6,4,2,0,-2,-5,-7,-10,-13
        db 19,16,14,12,9,7,5,2,0,-2,-5,-9,-12,-16
        db 21,19,16,13,11,8,5,3,0,-3,-6,-10,-14,-18
        db 24,21,18,15,12,9,6,3,0,-3,-7,-11,-16,-20
        db 27,23,20,17,13,10,7,3,0,-3,-8,-12,-17,-22
        db 29,26,22,18,15,11,7,4,0,-4,-9,-13,-19,-24
        db 32,28,24,20,16,12,8,4,0,-4,-9,-15,-21,-27
        db 35,30,26,22,17,13,9,4,0,-4,-10,-16,-22,-29
        db 37,33,28,23,19,14,9,5,0,-5,-11,-17,-24,-31
        db 40,35,30,25,20,15,10,5,0,-5,-12,-18,-26,-33
        db 43,37,32,27,21,16,11,5,0,-5,-12,-20,-28,-36
        db 45,40,34,28,23,17,11,6,0,-6,-13,-21,-29,-38
        db 48,42,36,30,24,18,12,6,0,-6,-14,-22,-31,-40

screen_tilt_amp_table:
        db 18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
        db -1,-2,-3,-4,-5,-6,-7,-8,-9,-10,-11,-12,-13,-14,-15,-16,-17,-18

road_tilt_amp_table:
        db 0,1,1,2,2,3,3,4,5,6,7,8,9,10
        db 0,1,1,2,2,3,3,4,5,6,7,8,8,9
        db 0,1,1,2,2,3,3,4,4,5,6,7,8,9
        db 0,1,1,2,2,2,2,3,4,5,6,7,8,8
        db 0,1,1,2,2,2,2,3,4,5,5,6,7,8
        db 0,1,1,1,1,2,2,3,4,4,5,6,6,7
        db 0,1,1,1,1,2,2,3,3,4,5,5,6,7
        db 0,1,1,1,1,2,2,2,3,4,4,5,6,6
        db 0,1,1,1,1,2,2,2,3,3,4,4,5,6
        db 0,0,0,1,1,2,2,2,2,3,4,4,4,5
        db 0,0,0,1,1,1,1,2,2,3,3,4,4,4
        db 0,0,0,1,1,1,1,2,2,2,3,3,4,4
        db 0,0,0,1,1,1,1,1,2,2,2,3,3,3
        db 0,0,0,1,1,1,1,1,1,2,2,2,2,3
        db 0,0,0,0,0,1,1,1,1,1,2,2,2,2
        db 0,0,0,0,0,0,0,1,1,1,1,1,2,2
        db 0,0,0,0,0,0,0,0,1,1,1,1,1,1
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,1
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,-1
        db 0,0,0,0,0,0,0,0,-1,-1,-1,-1,-1,-1
        db 0,0,0,0,0,0,0,-1,-1,-1,-1,-1,-2,-2
        db 0,0,0,0,0,-1,-1,-1,-1,-1,-2,-2,-2,-2
        db 0,0,0,-1,-1,-1,-1,-1,-1,-2,-2,-2,-2,-3
        db 0,0,0,-1,-1,-1,-1,-1,-2,-2,-2,-3,-3,-3
        db 0,0,0,-1,-1,-1,-1,-2,-2,-2,-3,-3,-4,-4
        db 0,0,0,-1,-1,-1,-1,-2,-2,-3,-3,-4,-4,-4
        db 0,0,0,-1,-1,-2,-2,-2,-2,-3,-4,-4,-4,-5
        db 0,-1,-1,-1,-1,-2,-2,-2,-3,-3,-4,-4,-5,-6
        db 0,-1,-1,-1,-1,-2,-2,-2,-3,-4,-4,-5,-6,-6
        db 0,-1,-1,-1,-1,-2,-2,-3,-3,-4,-5,-5,-6,-7
        db 0,-1,-1,-1,-1,-2,-2,-3,-4,-4,-5,-6,-6,-7
        db 0,-1,-1,-2,-2,-2,-2,-3,-4,-5,-5,-6,-7,-8
        db 0,-1,-1,-2,-2,-2,-2,-3,-4,-5,-6,-7,-8,-8
        db 0,-1,-1,-2,-2,-3,-3,-4,-4,-5,-6,-7,-8,-9
        db 0,-1,-1,-2,-2,-3,-3,-4,-5,-6,-7,-8,-8,-9
        db 0,-1,-1,-2,-2,-3,-3,-4,-5,-6,-7,-8,-9,-10

car_tilt_table:
        db 3,3,3,3,2,2,2,2,1,1,1,1,0,0,0,0,0,0,0
        db 0,0,0,0,-1,-1,-1,-1,-2,-2,-2,-2,-2,-3,-3,-3,-3,-3
