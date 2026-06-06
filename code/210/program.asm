; 210 Mars 3 landing/shooter for MSX2 / Pasmo
;
; BASIC is only a loader. The game loop, input, object updates, collision, and
; SCREEN 5 bitmap VRAM writes run in Z80 ASM. Coordinates use SCREEN 5 byte-X
; positions: one X unit is two pixels.

CHSNS   equ $009C
CHGET   equ $009F
GTSTCK  equ $00D5
GTTRIG  equ $00D8
JIFFY   equ $FC9E

VDP_DATA equ $98
VDP_CTRL equ $99

px      equ $D000
py      equ $D001
bxv     equ $D002
byv     equ $D003
bf      equ $D004
ecnt    equ $D005
state   equ $D006
scnt    equ $D007
tmpx    equ $D008
tmpy    equ $D009
tmpn    equ $D00A
tmpa    equ $D00B
tmpw    equ $D00C
sd0     equ $D00D
sd1     equ $D00E
sd2     equ $D00F
sd3     equ $D010
cntv    equ $D011
lastj   equ $D012
keyv    equ $D013
seed    equ $D014
patw    equ $D015

stars   equ $D020       ; 24 structs: x-byte,y,speed
enems   equ $D068       ; 5 structs: x-byte,y,speed

STAR_COUNT       equ 24
ENEMY_COUNT      equ 5
PLAY_TOP         equ 24
PLAYER_MIN_X     equ 4
PLAYER_MAX_X     equ 36
PLAYER_MIN_Y     equ 24
PLAYER_MAX_Y     equ 200
ENEMY_DRAW_LIMIT equ 124
SCORE_Y          equ 16

        org $D100

entry:
        ld a,6
        ld (px),a
        ld a,104
        ld (py),a
        xor a
        ld (bf),a
        ld (ecnt),a
        ld (state),a
        ld (scnt),a
        ld (keyv),a
        ld (sd0),a
        ld (sd1),a
        ld (sd2),a
        ld (sd3),a
        ld a,(JIFFY)
        or 1
        ld (seed),a

        call clear_playfield
        call init_stars
        call init_enemies
        call draw_score
        call draw_all
        ld a,(JIFFY)
        ld (lastj),a

main_loop:
        call wait_vblank
        call erase_all
        call read_input
        or a
        ret nz
        call check_player_enemy
        ld a,(state)
        or a
        ret nz

        ld a,(scnt)
        inc a
        cp 2
        jr c,store_scnt
        xor a
        ld (scnt),a
        call update_stars
        jr after_star_update
store_scnt:
        ld (scnt),a
after_star_update:
        call update_bullet
        ld a,(ecnt)
        inc a
        cp 4
        jr c,store_ecnt
        xor a
        ld (ecnt),a
        call update_enemies
        jr after_enemy_update
store_ecnt:
        ld (ecnt),a
after_enemy_update:
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
        jr nz,fire_pressed
        ld a,1
        call GTTRIG
        or a
        jr z,read_stick
fire_pressed:
        call start_fire

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
        cp $51                ; Q
        jr z,quit_game
        cp $71                ; q
        jr z,quit_game
        cp $20                ; space
        jr nz,ignore_char
        call start_fire
ignore_char:
        xor a
        ret

quit_game:
        xor a
        ld (state),a
        call reset_vram_high
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

start_fire:
        ld a,(bf)
        or a
        ret nz
        ld a,(px)
        add a,4
        cp 126
        ret nc
        ld (bxv),a
        ld a,(py)
        add a,4
        ld (byv),a
        ld a,1
        ld (bf),a
        call bullet_hits_enemy
        ret

update_stars:
        ld ix,stars
        ld a,STAR_COUNT
        ld (cntv),a
star_update_loop:
        ld a,(ix+0)
        sub (ix+2)
        jr c,respawn_star
        cp 1
        jr c,respawn_star
        ld (ix+0),a
        jr next_star_update
respawn_star:
        call spawn_star
next_star_update:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,star_update_loop
        ret

update_bullet:
        ld a,(bf)
        or a
        ret z
        ld a,(bxv)
        add a,3
        cp 126
        jr c,bullet_on_screen
        xor a
        ld (bf),a
        ret
bullet_on_screen:
        ld (bxv),a
        call bullet_hits_enemy
        ret

update_enemies:
        ld ix,enems
        ld a,ENEMY_COUNT
        ld (cntv),a
enemy_update_loop:
        ld a,(ix+0)
        sub (ix+2)
        jr c,respawn_enemy
        cp 1
        jr c,respawn_enemy
        ld (ix+0),a
        cp ENEMY_DRAW_LIMIT
        jr nc,next_enemy_update

        ld a,(py)
        sub (ix+1)
        jr nc,enemy_y_abs_ready
        neg
enemy_y_abs_ready:
        cp 8
        jr nc,check_enemy_bullet
        ld a,(px)
        sub (ix+0)
        jr nc,enemy_x_abs_ready
        neg
enemy_x_abs_ready:
        cp 4
        jr nc,check_enemy_bullet
        call crash_game
        ret

check_enemy_bullet:
        ld a,(bf)
        or a
        jr z,next_enemy_update
        ld a,(byv)
        sub (ix+1)
        jr nc,enemy_bullet_y_ready
        neg
enemy_bullet_y_ready:
        cp 10
        jr nc,next_enemy_update
        ld a,(bxv)
        sub (ix+0)
        jr nc,enemy_bullet_x_ready
        neg
enemy_bullet_x_ready:
        cp 8
        jr nc,next_enemy_update
        call hit_enemy
        jr next_enemy_update

respawn_enemy:
        call spawn_enemy
next_enemy_update:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,enemy_update_loop
        ret

bullet_hits_enemy:
        ld ix,enems
        ld a,ENEMY_COUNT
        ld (cntv),a
bullet_hit_loop:
        ld a,(ix+0)
        cp ENEMY_DRAW_LIMIT
        jr nc,next_bullet_enemy
        ld a,(byv)
        sub (ix+1)
        jr nc,bullet_y_abs_ready
        neg
bullet_y_abs_ready:
        cp 10
        jr nc,next_bullet_enemy
        ld a,(bxv)
        sub (ix+0)
        jr nc,bullet_x_abs_ready
        neg
bullet_x_abs_ready:
        cp 8
        jr nc,next_bullet_enemy
        call hit_enemy
        ld a,1
        ret
next_bullet_enemy:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,bullet_hit_loop
        xor a
        ret

check_player_enemy:
        ld ix,enems
        ld a,ENEMY_COUNT
        ld (cntv),a
player_enemy_loop:
        ld a,(ix+0)
        cp ENEMY_DRAW_LIMIT
        jr nc,next_player_enemy
        ld a,(py)
        sub (ix+1)
        jr nc,player_y_abs_ready
        neg
player_y_abs_ready:
        cp 8
        jr nc,next_player_enemy
        ld a,(px)
        sub (ix+0)
        jr nc,player_x_abs_ready
        neg
player_x_abs_ready:
        cp 4
        jr nc,next_player_enemy
        call crash_game
        ret
next_player_enemy:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,player_enemy_loop
        ret

hit_enemy:
        call draw_enemy_crash
        call enemy_hit_flash
        call erase_enemy_crash
        xor a
        ld (bf),a
        call add_score_10
        call draw_score
        call spawn_enemy
        ret

enemy_hit_flash:
        ld b,2
enemy_hit_wait:
        push bc
        call wait_vblank
        pop bc
        djnz enemy_hit_wait
        ret

crash_game:
        ld a,1
        ld (state),a
        call draw_crash
        call reset_vram_high
        ret

add_score_10:
        ld a,(sd2)
        inc a
        cp 10
        jr c,store_tens
        xor a
        ld (sd2),a
        ld a,(sd1)
        inc a
        cp 10
        jr c,store_hundreds
        xor a
        ld (sd1),a
        ld a,(sd0)
        inc a
        cp 10
        jr c,store_thousands
        xor a
store_thousands:
        ld (sd0),a
        ret
store_hundreds:
        ld (sd1),a
        ret
store_tens:
        ld (sd2),a
        ret

draw_all:
        call draw_stars
        call draw_enemies
        call draw_bullet
        call draw_player
        ret

erase_all:
        call erase_stars
        call erase_bullet
        call erase_enemies
        call erase_player
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
        xor a
        ld e,128
        call write_run
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        jr clear_playfield_loop

draw_stars:
        ld ix,stars
        ld a,STAR_COUNT
        ld (cntv),a
star_draw_loop:
        ld a,(ix+2)
        cp 1
        jr z,slow_star_color
        ld a,$FF
        jr star_color_ready
slow_star_color:
        ld a,$77
star_color_ready:
        ld b,(ix+1)
        ld c,(ix+0)
        call write_byte_xy
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,star_draw_loop
        ret

erase_stars:
        ld ix,stars
        ld a,STAR_COUNT
        ld (cntv),a
star_erase_loop:
        xor a
        ld b,(ix+1)
        ld c,(ix+0)
        call write_byte_xy
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,star_erase_loop
        ret

draw_bullet:
        ld a,(bf)
        or a
        ret z
        ld a,$FF
        push af
        ld a,(byv)
        ld b,a
        ld a,(bxv)
        ld c,a
        pop af
        ld e,3
        call write_run
        ret

erase_bullet:
        ld a,(bf)
        or a
        ret z
        xor a
        push af
        ld a,(byv)
        ld b,a
        ld a,(bxv)
        ld c,a
        pop af
        ld e,3
        call write_run
        ret

draw_enemies:
        ld ix,enems
        ld a,ENEMY_COUNT
        ld (cntv),a
enemy_draw_loop:
        ld a,(ix+0)
        cp ENEMY_DRAW_LIMIT
        jr nc,next_enemy_draw
        ld hl,enemy_pat
        ld b,(ix+1)
        ld c,(ix+0)
        ld d,8
        ld e,4
        call draw_pattern
next_enemy_draw:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,enemy_draw_loop
        ret

draw_enemy_crash:
        ld hl,crash_pat
        ld b,(ix+1)
        ld c,(ix+0)
        ld d,8
        ld e,4
        call draw_pattern
        ret

erase_enemies:
        ld ix,enems
        ld a,ENEMY_COUNT
        ld (cntv),a
enemy_erase_loop:
        ld a,(ix+0)
        cp ENEMY_DRAW_LIMIT
        jr nc,next_enemy_erase
        ld hl,blank_4x8
        ld b,(ix+1)
        ld c,(ix+0)
        ld d,8
        ld e,4
        call draw_pattern
next_enemy_erase:
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,enemy_erase_loop
        ret

erase_enemy_crash:
        ld hl,blank_4x8
        ld b,(ix+1)
        ld c,(ix+0)
        ld d,8
        ld e,4
        call draw_pattern
        ret

draw_player:
        ld hl,player_pat
        ld a,(py)
        ld b,a
        ld a,(px)
        ld c,a
        ld d,8
        ld e,4
        call draw_pattern
        ret

erase_player:
        ld hl,blank_4x8
        ld a,(py)
        ld b,a
        ld a,(px)
        ld c,a
        ld d,8
        ld e,4
        call draw_pattern
        ret

draw_crash:
        ld hl,crash_pat
        ld a,(py)
        ld b,a
        ld a,(px)
        ld c,a
        ld d,8
        ld e,4
        call draw_pattern
        ret

draw_score:
        call clear_score
        ld hl,sd0
        ld c,2
        ld b,4
score_loop:
        push bc
        push hl
        ld a,(hl)
        call draw_digit
        pop hl
        pop bc
        inc hl
        inc c
        inc c
        djnz score_loop
        ret

clear_score:
        ld a,SCORE_Y
        ld (tmpy),a
        ld a,5
        ld (tmpn),a
clear_score_loop:
        ld a,(tmpy)
        ld b,a
        ld c,2
        xor a
        ld e,10
        call write_run
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr nz,clear_score_loop
        ret

draw_digit:
        ld (tmpa),a
        ld a,c
        ld (tmpx),a
        ld a,(tmpa)
        ld l,a
        ld h,0
        add hl,hl
        push hl
        add hl,hl
        add hl,hl
        pop de
        add hl,de
        ld de,digit_table
        add hl,de
        ld a,SCORE_Y
        ld (tmpy),a
        ld a,5
        ld (tmpn),a
digit_row_loop:
        push hl
        ld a,(tmpy)
        ld b,a
        ld a,(tmpx)
        ld c,a
        call calc_bitmap_addr
        call set_vram_write
        pop hl
        ld a,(hl)
        out (VDP_DATA),a
        inc hl
        ld a,(hl)
        out (VDP_DATA),a
        inc hl
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr nz,digit_row_loop
        ret

init_stars:
        ld ix,stars
        ld a,STAR_COUNT
        ld (cntv),a
init_star_loop:
        call spawn_star
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,init_star_loop
        ret

init_enemies:
        ld ix,enems
        ld a,ENEMY_COUNT
        ld (cntv),a
init_enemy_loop:
        call spawn_enemy
        inc ix
        inc ix
        inc ix
        ld a,(cntv)
        dec a
        ld (cntv),a
        jr nz,init_enemy_loop
        ret

spawn_star:
        push bc
        ld b,120
        call rand_mod
        add a,4
        ld (ix+0),a
        ld b,184
        call rand_mod
        add a,PLAY_TOP
        ld (ix+1),a
        ld b,2
        call rand_mod
        inc a
        ld (ix+2),a
        pop bc
        ret

spawn_enemy:
        push bc
        ld b,24
        call rand_mod
        add a,124
        ld (ix+0),a
        ld b,176
        call rand_mod
        add a,PLAY_TOP
        ld (ix+1),a
        ld b,2
        call rand_mod
        inc a
        ld (ix+2),a
        pop bc
        ret

rand_mod:
        ld c,b
        call rnd8
rand_mod_loop:
        cp c
        jr c,rand_mod_done
        sub c
        jr rand_mod_loop
rand_mod_done:
        ret

rnd8:
        ld a,(seed)
        add a,73
        rrca
        ld b,a
        ld a,(JIFFY)
        xor b
        or 1
        ld (seed),a
        ret

write_byte_xy:
        ld (tmpa),a
        call calc_bitmap_addr
        call set_vram_write
        ld a,(tmpa)
        out (VDP_DATA),a
        ret

write_run:
        ld (tmpa),a
        ld a,e
        ld (tmpw),a
        call calc_bitmap_addr
        call set_vram_write
        ld a,(tmpw)
        ld b,a
        ld a,(tmpa)
write_run_loop:
        out (VDP_DATA),a
        djnz write_run_loop
        ret

draw_pattern:
        ld a,c
        ld (tmpx),a
        ld a,b
        ld (tmpy),a
        ld a,d
        ld (tmpn),a
        ld a,e
        ld (patw),a
draw_pattern_row:
        push hl
        ld a,(tmpy)
        ld b,a
        ld a,(tmpx)
        ld c,a
        call calc_bitmap_addr
        call set_vram_write
        pop hl
        ld a,(patw)
        ld (tmpw),a
draw_pattern_byte:
        ld a,(hl)
        out (VDP_DATA),a
        inc hl
        ld a,(tmpw)
        dec a
        ld (tmpw),a
        jr nz,draw_pattern_byte
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(tmpn)
        dec a
        ld (tmpn),a
        jr nz,draw_pattern_row
        ret

; SCREEN 5: address = y * 128 + xbyte.
calc_bitmap_addr:
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
        ld a,$8E               ; V9938 R#14: high VRAM address bits
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
        db $00,$0F,$00,$00
        db $0F,$FF,$00,$00
        db $FF,$FF,$F0,$00
        db $FF,$FF,$FF,$F0
        db $FF,$FF,$FF,$F0
        db $FF,$FF,$F0,$00
        db $0F,$FF,$00,$00
        db $00,$0F,$00,$00

enemy_pat:
        db $00,$00,$60,$00
        db $00,$66,$66,$00
        db $06,$66,$66,$00
        db $66,$66,$66,$60
        db $66,$66,$66,$60
        db $06,$66,$66,$00
        db $00,$66,$66,$00
        db $00,$00,$60,$00

crash_pat:
        db $F0,$00,$00,$0F
        db $0F,$00,$00,$F0
        db $00,$FF,$FF,$00
        db $00,$FF,$FF,$00
        db $00,$FF,$FF,$00
        db $00,$FF,$FF,$00
        db $0F,$00,$00,$F0
        db $F0,$00,$00,$0F

blank_4x8:
        db $00,$00,$00,$00
        db $00,$00,$00,$00
        db $00,$00,$00,$00
        db $00,$00,$00,$00
        db $00,$00,$00,$00
        db $00,$00,$00,$00
        db $00,$00,$00,$00
        db $00,$00,$00,$00

digit_table:
        db $FF,$FF,$F0,$0F,$F0,$0F,$F0,$0F,$FF,$FF
        db $00,$F0,$0F,$F0,$00,$F0,$00,$F0,$0F,$FF
        db $FF,$F0,$00,$0F,$FF,$F0,$F0,$00,$FF,$FF
        db $FF,$F0,$00,$0F,$0F,$F0,$00,$0F,$FF,$F0
        db $F0,$0F,$F0,$0F,$FF,$FF,$00,$0F,$00,$0F
        db $FF,$FF,$F0,$00,$FF,$F0,$00,$0F,$FF,$F0
        db $0F,$FF,$F0,$00,$FF,$F0,$F0,$0F,$0F,$F0
        db $FF,$FF,$00,$0F,$00,$F0,$0F,$00,$0F,$00
        db $0F,$F0,$F0,$0F,$0F,$F0,$F0,$0F,$0F,$F0
        db $0F,$F0,$F0,$0F,$0F,$FF,$00,$0F,$FF,$F0
