; 260 MSX2 hardware smooth scroll race for MSXPen / Pasmo
;
; SCREEN 5 is used for a bitmap road. The road is drawn once into a 256-line
; virtual page, then V9938 register 23 scrolls it by one pixel per frame.
; Cars are small software sprites drawn at screen coordinates.

GTSTCK  equ $00D5
GTTRIG  equ $00D8
JIFFY   equ $FC9E

VDP_DATA equ $98
VDP_CTRL equ $99

px      equ $D000       ; player x in SCREEN 5 byte coordinates
scrollv equ $D001
lastj   equ $D003
score   equ $D004       ; word
state   equ $D006
targetx equ $D007
keyv    equ $D008
lanes   equ $D010       ; lane id 0..3, or direct byte-x for a front spawn
eys     equ $D014
speeds  equ $D018
tmpx    equ $D01C
tmpy    equ $D01D
tmpw    equ $D01E
tmph    equ $D01F
cntv    equ $D020
patp    equ $D021       ; word

ROAD_LEFT    equ 36
ROAD_RIGHT   equ 96
ROAD_END     equ 97
LANE_A       equ 54
LANE_B       equ 66
LANE_C       equ 80

PLAYER_Y     equ 168
PLAYER_MIN_X equ 50
PLAYER_MAX_X equ 86
CAR_WIDTH    equ 5
CAR_HEIGHT   equ 10
ENEMY_LIMIT  equ 193
HIT_TOP      equ 160
HIT_BOTTOM   equ 178

GRASS_BYTE   equ $22
ROAD_BYTE    equ $EE
LANE_BYTE    equ $FF
CURB_BYTE    equ $88

        org $D100

entry:
        ld a,58
        ld (px),a
        ld (targetx),a
        xor a
        ld (scrollv),a
        ld (state),a
        ld (keyv),a
        ld hl,0
        ld (score),hl

        ld hl,lanes
        ld (hl),0
        inc hl
        ld (hl),1
        inc hl
        ld (hl),2
        inc hl
        ld (hl),3

        ld hl,eys
        ld (hl),32
        inc hl
        ld (hl),72
        inc hl
        ld (hl),120
        inc hl
        ld (hl),168

        ld hl,speeds
        ld (hl),2
        inc hl
        ld (hl),2
        inc hl
        ld (hl),3
        inc hl
        ld (hl),2

        call init_vram
        call draw_all
        ld a,(JIFFY)
        ld (lastj),a

main_loop:
        call wait_vblank
        call erase_all
        call read_input
        or a
        jr z,continue_game
        call shutdown_vdp
        ret

continue_game:
        call update_player
        call update_scroll
        call update_enemies
        ld a,(state)
        or a
        jr z,draw_frame
        call shutdown_vdp
        ret
draw_frame:
        call draw_all
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
        jr z,read_stick
        xor a
        ld (state),a
        ld a,1
        ret

read_stick:
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
        cp PLAYER_MAX_X
        jr nc,input_done
        add a,4
        ld (targetx),a
        xor a
        ret

move_left:
        ld a,(targetx)
        cp PLAYER_MIN_X
        jr c,input_done
        sub 4
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
        cp 2
        jr c,player_snap
        ld a,(px)
        dec a
        ld (px),a
        ret

player_right:
        ld c,a
        ld a,b
        sub c
        cp 2
        jr c,player_snap
        ld a,c
        inc a
        ld (px),a
        ret

player_snap:
        ld a,b
        ld (px),a
        ret

update_scroll:
        ld a,(scrollv)
        dec a
        ld (scrollv),a
        call set_vscroll
        ret

update_enemies:
        ld ix,eys
        ld iy,speeds
        ld hl,lanes
        ld b,4
        ld c,0
enemy_loop:
        ld a,(ix+0)
        add a,(iy+0)
        ld (ix+0),a
        cp ENEMY_LIMIT
        jr c,enemy_collision

        ld (ix+0),24
        ld a,(score)
        add a,c
        and 3
        jr nz,normal_spawn_lane
        ld a,(px)
        jr store_spawn_lane

normal_spawn_lane:
        ld a,(hl)
        inc a
        add a,c
        and 3
store_spawn_lane:
        ld (hl),a
        push hl
        ld hl,(score)
        inc hl
        ld (score),hl
        pop hl

enemy_collision:
        push bc
        push hl
        ld a,(hl)
        call lane_to_x
        ld c,a
        ld a,(ix+0)
        cp HIT_TOP
        jr c,no_hit
        cp HIT_BOTTOM
        jr nc,no_hit
        ld a,(px)
        sub c
        jr nc,abs_ready
        neg
abs_ready:
        cp 5
        jr nc,no_hit
        ld a,1
        ld (state),a
        pop hl
        pop bc
        ret
no_hit:
        pop hl
        pop bc
        inc ix
        inc iy
        inc hl
        inc c
        djnz enemy_loop
        ret

init_vram:
        call reset_vram_high
        xor a
        ld (scrollv),a
        call set_vscroll
        call draw_background
        ret

draw_background:
        xor a
        ld (tmpy),a
draw_bg_loop:
        ld a,(tmpy)
        ld b,a
        call draw_bg_line
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        jr nz,draw_bg_loop
        ret

draw_bg_line:
        ld c,0
        push bc
        call calc_addr_byte
        call set_vram_write
        pop bc
        ld c,0
        ld e,128
draw_bg_byte:
        call bg_byte_for
        out (VDP_DATA),a
        inc c
        dec e
        jr nz,draw_bg_byte
        ret

bg_byte_for:
        ld a,c
        cp ROAD_LEFT
        jr c,bg_grass
        cp ROAD_END
        jr nc,bg_grass
        cp ROAD_LEFT
        jr z,bg_curb
        cp ROAD_RIGHT
        jr z,bg_curb
        cp LANE_A
        jr z,bg_lane
        cp LANE_B
        jr z,bg_lane
        cp LANE_C
        jr z,bg_lane
bg_road:
        ld a,ROAD_BYTE
        ret
bg_lane:
        ld a,b
        and 15
        cp 8
        jr nc,bg_road
        ld a,LANE_BYTE
        ret
bg_curb:
        ld a,b
        and 8
        jr z,bg_curb_white
        ld a,CURB_BYTE
        ret
bg_curb_white:
        ld a,LANE_BYTE
        ret
bg_grass:
        ld a,GRASS_BYTE
        ret

erase_all:
        call erase_player
        call erase_enemies
        ret

draw_all:
        call draw_enemies
        call draw_player
        ret

draw_player:
        ld hl,player_pat
        ld b,PLAYER_Y
        ld a,(px)
        ld c,a
        ld d,CAR_HEIGHT
        ld e,CAR_WIDTH
        call draw_pattern_screen
        ret

erase_player:
        ld b,PLAYER_Y
        ld a,(px)
        ld c,a
        ld d,CAR_HEIGHT
        ld e,CAR_WIDTH
        call restore_bg_rect
        ret

draw_enemies:
        ld ix,eys
        ld hl,lanes
        ld a,4
        ld (cntv),a
draw_enemy_loop:
        push hl
        ld a,(hl)
        call lane_to_x
        ld c,a
        ld a,(ix+0)
        ld b,a
        ld hl,enemy_pat
        ld d,CAR_HEIGHT
        ld e,CAR_WIDTH
        call draw_pattern_screen
        pop hl
        inc ix
        inc hl
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,draw_enemy_loop
        ret

erase_enemies:
        ld ix,eys
        ld hl,lanes
        ld a,4
        ld (cntv),a
erase_enemy_loop:
        push hl
        ld a,(hl)
        call lane_to_x
        ld c,a
        ld a,(ix+0)
        ld b,a
        ld d,CAR_HEIGHT
        ld e,CAR_WIDTH
        call restore_bg_rect
        pop hl
        inc ix
        inc hl
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,erase_enemy_loop
        ret

draw_pattern_screen:
        ld (patp),hl
        ld a,b
        ld (tmpy),a
        ld a,c
        ld (tmpx),a
        ld a,d
        ld (tmph),a
        ld a,e
        ld (tmpw),a
draw_pat_row:
        ld a,(tmpy)
        ld b,a
        ld a,(scrollv)
        add a,b
        ld b,a
        ld a,(tmpx)
        ld c,a
        call calc_addr_byte
        call set_vram_write
        ld hl,(patp)
        ld a,(tmpw)
        ld e,a
draw_pat_col:
        ld a,(hl)
        out (VDP_DATA),a
        inc hl
        dec e
        jr nz,draw_pat_col
        ld (patp),hl
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmph)
        dec a
        ld (tmph),a
        jr nz,draw_pat_row
        ret

restore_bg_rect:
        ld a,b
        ld (tmpy),a
        ld a,c
        ld (tmpx),a
        ld a,d
        ld (tmph),a
        ld a,e
        ld (tmpw),a
restore_row:
        ld a,(tmpy)
        ld b,a
        ld a,(scrollv)
        add a,b
        ld b,a
        ld a,(tmpx)
        ld c,a
        call calc_addr_byte
        call set_vram_write
        ld a,(tmpw)
        ld e,a
        ld a,(tmpx)
        ld c,a
restore_col:
        call bg_byte_for
        out (VDP_DATA),a
        inc c
        dec e
        jr nz,restore_col
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmph)
        dec a
        ld (tmph),a
        jr nz,restore_row
        ret

lane_to_x:
        cp 4
        ret nc
        push hl
        ld e,a
        ld d,0
        ld hl,lane_table
        add hl,de
        ld a,(hl)
        pop hl
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

set_vscroll:
        di
        ld a,(scrollv)
        out (VDP_CTRL),a
        ld a,$97
        out (VDP_CTRL),a
        ei
        ret

shutdown_vdp:
        call reset_vscroll
        call reset_vram_high
        ret

reset_vscroll:
        xor a
        out (VDP_CTRL),a
        ld a,$97
        out (VDP_CTRL),a
        ret

reset_vram_high:
        xor a
        out (VDP_CTRL),a
        ld a,$8E
        out (VDP_CTRL),a
        ret

lane_table:
        db 46,58,74,86

player_pat:
        db $EE,$55,$55,$55,$EE
        db $55,$5F,$FF,$F5,$55
        db $55,$5F,$FF,$F5,$55
        db $55,$55,$FF,$55,$55
        db $55,$FF,$FF,$FF,$55
        db $55,$FF,$FF,$FF,$55
        db $55,$55,$FF,$55,$55
        db $55,$5F,$FF,$F5,$55
        db $55,$5F,$FF,$F5,$55
        db $EE,$55,$55,$55,$EE

enemy_pat:
        db $EE,$88,$88,$88,$EE
        db $88,$8F,$FF,$F8,$88
        db $88,$8F,$FF,$F8,$88
        db $88,$88,$FF,$88,$88
        db $88,$FF,$FF,$FF,$88
        db $88,$FF,$FF,$FF,$88
        db $88,$88,$FF,$88,$88
        db $88,$8F,$FF,$F8,$88
        db $88,$8F,$FF,$F8,$88
        db $EE,$88,$88,$88,$EE
