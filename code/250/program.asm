; 250 gravity shooter for MSX2 / Pasmo
;
; BASIC is only a loader and game-over screen. This keeps 178 below 179's
; smooth-scroll technique: objects move individually in SCREEN 5 byte-X coords.

CHSNS   equ $009C
CHGET   equ $009F
GTSTCK  equ $00D5
GTTRIG  equ $00D8
JIFFY   equ $FC9E

VDP_DATA equ $98
VDP_CTRL equ $99

px      equ $D000
py      equ $D001
fieldv  equ $D002
state   equ $D003
lastj   equ $D004
seed    equ $D005
cntv    equ $D006
tmpx    equ $D007
tmpy    equ $D008
tmpw    equ $D009
tmpc    equ $D00A
scorel  equ $D00B
scoreh  equ $D00C
bstep   equ $D00D
lstep   equ $D00E
ldirv   equ $D00F

bullets equ $D020       ; 13 structs: x-byte,y,speed
lasers  equ $D047       ; 4 structs: x-byte,y,speed

BULLET_COUNT equ 13
LASER_COUNT  equ 4

PLAY_TOP     equ 18
PLAYER_MIN_X equ 3
PLAYER_MAX_X equ 44
PLAYER_MIN_Y equ 26
PLAYER_MAX_Y equ 200
LASER_WIDTH  equ 12
LASER_LIMIT  equ 117

BACK_BYTE   equ $11
PLAYER_BYTE equ $FF
BULLET_BYTE equ $EE
LASER_BYTE  equ $88
FIELD_BYTE  equ $AA
CRASH_BYTE  equ $66

        org $D100

entry:
        ld a,8
        ld (px),a
        ld a,104
        ld (py),a
        xor a
        ld (fieldv),a
        ld (state),a
        ld (scorel),a
        ld (scoreh),a
        ld (bstep),a
        ld (lstep),a
        ld a,(JIFFY)
        or 1
        ld (seed),a

        call clear_playfield
        call init_bullets
        call init_lasers
        call draw_all
        ld a,(JIFFY)
        ld (lastj),a

main_loop:
        call wait_vblank
        call erase_all
        call read_input
        or a
        jr z,continue_game
        call reset_vram_high
        ret
continue_game:
        call update_field
        call draw_player
        call update_bullets
        ld a,(state)
        or a
        ret nz
        call update_lasers
        ld a,(state)
        or a
        ret nz
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
        call read_char_key
        or a
        ret nz

        xor a
        call GTTRIG
        or a
        jr nz,field_pressed
        ld a,1
        call GTTRIG
        or a
        jr z,read_stick
field_pressed:
        call start_field

read_stick:
        xor a
        call GTSTCK
        or a
        jr nz,got_stick
        ld a,1
        call GTSTCK
got_stick:
        or a
        ret z
        ld c,a
        call move_from_stick
        xor a
        ret

read_char_key:
        call CHSNS
        jr nz,char_ready
        xor a
        ret
char_ready:
        call CHGET
        cp $51
        jr z,quit_game
        cp $71
        jr z,quit_game
        cp $20
        jr nz,ignore_char
        call start_field
ignore_char:
        xor a
        ret
quit_game:
        xor a
        ld (state),a
        ld a,1
        ret

move_from_stick:
        ld a,c
        cp 1
        jr z,move_up
        cp 2
        jr z,move_up
        cp 8
        jr nz,check_down
move_up:
        ld a,(py)
        cp PLAYER_MIN_Y+2
        jr nc,move_up_step
        ld a,PLAYER_MIN_Y
        ld (py),a
        jr check_down
move_up_step:
        sub 2
        ld (py),a

check_down:
        ld a,c
        cp 5
        jr z,move_down
        cp 4
        jr z,move_down
        cp 6
        jr nz,check_left
move_down:
        ld a,(py)
        cp PLAYER_MAX_Y-1
        jr c,move_down_step
        ld a,PLAYER_MAX_Y
        ld (py),a
        jr check_left
move_down_step:
        add a,2
        ld (py),a

check_left:
        ld a,c
        cp 7
        jr z,move_left
        cp 6
        jr z,move_left
        cp 8
        jr nz,check_right
move_left:
        ld a,(px)
        cp PLAYER_MIN_X+1
        jr nc,move_left_step
        ld a,PLAYER_MIN_X
        ld (px),a
        jr check_right
move_left_step:
        dec a
        ld (px),a

check_right:
        ld a,c
        cp 3
        jr z,move_right
        cp 2
        jr z,move_right
        cp 4
        ret nz
move_right:
        ld a,(px)
        cp PLAYER_MAX_X
        ret nc
        inc a
        ld (px),a
        ret

start_field:
        ld a,28
        ld (fieldv),a
        ret

update_field:
        ld a,(fieldv)
        or a
        ret z
        dec a
        ld (fieldv),a
        ret

init_bullets:
        ld ix,bullets
        ld a,BULLET_COUNT
        ld (cntv),a
init_bullet_loop:
        call spawn_bullet
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,init_bullet_loop
        ret

init_lasers:
        ld ix,lasers
        ld a,LASER_COUNT
        ld (cntv),a
init_laser_loop:
        call spawn_laser
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,init_laser_loop
        ret

spawn_bullet:
        call rand8
        and 31
        add a,120
        ld (ix+0),a
        call rand_y
        ld (ix+1),a
        call rand8
        and 1
        inc a
        ld (ix+2),a
        ret

spawn_laser:
        call rand8
        and 31
        add a,116
        ld (ix+0),a
        call rand_y
        ld (ix+1),a
        ld a,1
        ld (ix+2),a
        ret

rand_y:
        call rand8
        and 127
        add a,32
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

update_bullets:
        ld a,(bstep)
        xor 1
        ld (bstep),a
        ld (tmpw),a
        ld ix,bullets
        ld a,BULLET_COUNT
        ld (cntv),a
bullet_update_loop:
        ld a,(tmpw)
        or a
        jr z,bullet_check_only
        ld a,(ix+0)
        sub (ix+2)
        jr c,bullet_passed
        cp 2
        jr c,bullet_passed
        ld (ix+0),a
        call pull_bullet_if_field
        call check_bullet_hit
        ld a,(state)
        or a
        ret nz
        jr next_bullet_update
bullet_check_only:
        call check_bullet_hit
        ld a,(state)
        or a
        ret nz
        jr next_bullet_update
bullet_passed:
        call add_score_1
        call spawn_bullet
next_bullet_update:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,bullet_update_loop
        ret

pull_bullet_if_field:
        ld a,(fieldv)
        or a
        ret z
        ld a,(ix+0)
        ld b,a
        ld a,(px)
        cp b
        ret nc
        add a,34
        cp b
        ret c
        ld a,(ix+1)
        ld b,a
        ld a,(py)
        cp b
        jr z,store_bullet_y
        jr c,bullet_pull_up
        inc b
        jr store_bullet_y_b
bullet_pull_up:
        dec b
store_bullet_y_b:
        ld a,b
store_bullet_y:
        ld (ix+1),a
        ret

check_bullet_hit:
        ld a,(ix+0)
        cp 126
        ret nc
        ld a,(py)
        sub (ix+1)
        jr nc,bullet_abs_y_ready
        neg
bullet_abs_y_ready:
        cp 7
        ret nc
        ld a,(px)
        sub (ix+0)
        jr nc,bullet_abs_x_ready
        neg
bullet_abs_x_ready:
        cp 4
        ret nc
        call crash_game
        ret

update_lasers:
        ld a,(lstep)
        xor 1
        ld (lstep),a
        ld (tmpw),a
        ld ix,lasers
        ld a,LASER_COUNT
        ld (cntv),a
laser_update_loop:
        ld a,(tmpw)
        or a
        jr z,laser_check_only
        ld a,(ix+0)
        sub (ix+2)
        jr c,laser_passed
        cp 2
        jr c,laser_passed
        ld (ix+0),a
        call bend_laser_if_field
        call check_laser_hit
        ld a,(state)
        or a
        ret nz
        jr next_laser_update
laser_check_only:
        call check_laser_hit
        ld a,(state)
        or a
        ret nz
        jr next_laser_update
laser_passed:
        call add_score_5
        call spawn_laser
next_laser_update:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,laser_update_loop
        ret

bend_laser_if_field:
        ld a,(fieldv)
        or a
        ret z
        ld a,(ix+0)
        ld b,a
        ld a,(px)
        cp b
        ret nc
        add a,44
        cp b
        ret c
        ld a,(ix+1)
        ld b,a
        ld a,(py)
        cp b
        jr c,laser_bend_down
        dec b
        jr clamp_laser_y
laser_bend_down:
        inc b
clamp_laser_y:
        ld a,b
        cp PLAYER_MIN_Y
        jr nc,laser_min_ok
        ld a,PLAYER_MIN_Y
laser_min_ok:
        cp PLAYER_MAX_Y
        jr c,store_laser_y
        ld a,PLAYER_MAX_Y
store_laser_y:
        ld (ix+1),a
        ret

check_laser_hit:
        ld a,(ix+0)
        cp LASER_LIMIT
        ret nc
        ld d,a
        ld a,(px)
        add a,4
        cp d
        ret c
        ld a,d
        add a,LASER_WIDTH
        ld d,a
        ld a,(px)
        cp d
        ret nc
        ld a,(py)
        sub (ix+1)
        jr nc,laser_abs_y_ready
        neg
laser_abs_y_ready:
        cp 7
        ret nc
        call crash_game
        ret

crash_game:
        ld a,1
        ld (state),a
        ld a,CRASH_BYTE
        call draw_player_shape_color
        call reset_vram_high
        ret

add_score_1:
        ld hl,(scorel)
        inc hl
        ld (scorel),hl
        ret

add_score_5:
        ld hl,(scorel)
        ld de,5
        add hl,de
        ld (scorel),hl
        ret

draw_all:
        call draw_bullets
        call draw_lasers
        call draw_field
        call draw_player
        ret

erase_all:
        call erase_field
        call erase_player
        call erase_bullets
        call erase_lasers
        ret

draw_bullets:
        ld ix,bullets
        ld a,BULLET_COUNT
        ld (cntv),a
draw_bullet_loop:
        ld a,(ix+0)
        cp 126
        jr nc,next_draw_bullet
        ld a,BULLET_BYTE
        call draw_bullet_shape
next_draw_bullet:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,draw_bullet_loop
        ret

erase_bullets:
        ld ix,bullets
        ld a,BULLET_COUNT
        ld (cntv),a
erase_bullet_loop:
        ld a,(ix+0)
        cp 126
        jr nc,next_erase_bullet
        ld a,BACK_BYTE
        call draw_bullet_shape
next_erase_bullet:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,erase_bullet_loop
        ret

draw_bullet_shape:
        ld b,(ix+1)
        ld c,(ix+0)
        ld e,2
        push af
        call write_run
        inc b
        pop af
        ld e,2
        call write_run
        ret

draw_lasers:
        ld ix,lasers
        ld a,LASER_COUNT
        ld (cntv),a
draw_laser_loop:
        ld a,(ix+0)
        cp LASER_LIMIT
        jr nc,next_draw_laser
        ld a,LASER_BYTE
        call draw_laser_shape
next_draw_laser:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,draw_laser_loop
        ret

erase_lasers:
        ld ix,lasers
        ld a,LASER_COUNT
        ld (cntv),a
erase_laser_loop:
        ld a,(ix+0)
        cp LASER_LIMIT
        jr nc,next_erase_laser
        ld a,BACK_BYTE
        call draw_laser_shape
next_erase_laser:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,erase_laser_loop
        ret

draw_laser_shape:
        ld (tmpc),a
        call laser_bend_dir
        or a
        jr nz,draw_laser_slant
        ld a,(tmpc)
        ld b,(ix+1)
        ld c,(ix+0)
        ld e,LASER_WIDTH
        call write_run
        ret

draw_laser_slant:
        ld (ldirv),a
        ld a,(ix+1)
        ld (tmpy),a
        ld a,(ix+0)
        ld (tmpx),a
        call draw_laser_segment
        call draw_laser_segment
        call draw_laser_segment
        call draw_laser_segment
        ret

draw_laser_segment:
        ld a,(tmpy)
        ld b,a
        ld a,(tmpx)
        ld c,a
        ld a,(tmpc)
        ld e,3
        call write_run
        ld a,(tmpx)
        add a,3
        ld (tmpx),a
        ld a,(ldirv)
        ld b,a
        ld a,(tmpy)
        add a,b
        ld (tmpy),a
        ret

laser_bend_dir:
        ld a,(fieldv)
        or a
        ret z
        ld a,(ix+0)
        ld b,a
        ld a,(px)
        cp b
        jr nc,laser_no_bend
        add a,44
        cp b
        jr c,laser_no_bend
        ld b,(ix+1)
        ld a,(py)
        cp b
        jr c,laser_dir_down
        ld a,255
        or a
        ret
laser_dir_down:
        ld a,1
        or a
        ret
laser_no_bend:
        xor a
        ret

draw_player:
        ld a,PLAYER_BYTE
        jr draw_player_shape_color

erase_player:
        ld a,(py)
        ld (tmpy),a
        ld a,8
        ld (cntv),a
erase_player_row:
        ld a,(tmpy)
        ld b,a
        ld a,(px)
        ld c,a
        ld a,BACK_BYTE
        ld e,4
        call write_run
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,erase_player_row
        ret

draw_player_shape_color:
        ld hl,player_pat
        ld a,(py)
        ld b,a
        ld a,(px)
        ld c,a
        ld d,8
        ld e,4
        call draw_pattern_color
        ret

draw_field:
        ld a,(fieldv)
        or a
        ret z
        ld a,FIELD_BYTE
        jr field_common

erase_field:
        ld a,(fieldv)
        or a
        ret z
        ld a,BACK_BYTE

field_common:
        ld (tmpc),a
        ld hl,field_offsets
        ld a,12
        ld (cntv),a
field_loop:
        ld a,(px)
        add a,(hl)
        inc hl
        cp 1
        jr c,field_skip_y
        cp 126
        jr nc,field_skip_y
        ld c,a
        ld a,(py)
        add a,(hl)
        inc hl
        cp PLAY_TOP
        jr c,field_next
        cp 210
        jr nc,field_next
        ld b,a
        ld a,(tmpc)
        push hl
        call write_byte_xy
        pop hl
        jr field_next
field_skip_y:
        inc hl
field_next:
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,field_loop
        ret

draw_pattern_color:
        ld (tmpc),a
pattern_row:
        push de
        push bc
pattern_col:
        ld a,(hl)
        inc hl
        or a
        jr z,pattern_skip
        push hl
        push de
        push bc
        ld a,(tmpc)
        call write_byte_xy
        pop bc
        pop de
        pop hl
pattern_skip:
        inc c
        dec e
        jr nz,pattern_col
        pop bc
        pop de
        inc b
        dec d
        jr nz,pattern_row
        ret

clear_playfield:
        ld a,PLAY_TOP
        ld (tmpy),a
clear_playfield_loop:
        ld a,(tmpy)
        cp 212
        ret nc
        ld b,a
        ld c,0
        ld a,BACK_BYTE
        ld e,128
        call write_run
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        jr clear_playfield_loop

write_byte_xy:
        push af
        call calc_addr_byte
        call set_vram_write
        pop af
        out (VDP_DATA),a
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

reset_vram_high:
        xor a
        out (VDP_CTRL),a
        ld a,$8E
        out (VDP_CTRL),a
        ret

player_pat:
        db 0,1,1,0
        db 1,1,1,0
        db 1,1,1,1
        db 1,1,1,1
        db 1,1,1,1
        db 1,1,1,0
        db 0,1,1,0
        db 0,1,0,0

field_offsets:
        db -8,0,-6,-6,0,-10,6,-6,8,0,6,6
        db 0,10,-6,6,-10,0,10,0,-4,-9,4,-9
