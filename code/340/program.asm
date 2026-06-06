; 340 raycast-style maze for MSX2 / Pasmo
;
; BASIC only loads this routine. The scene is rendered in SCREEN 5 with MSX2
; HMMV rectangle fills and page flipping. The ray marcher uses fixed-point
; coordinates and precomputed direction tables instead of BASIC SIN/COS.

CHSNS   equ $009C
CHGET   equ $009F
GTSTCK  equ $00D5
GTTRIG  equ $00D8
JIFFY   equ $FC9E

VDP_CTRL equ $99

pxlo    equ $D000
pxhi    equ $D001
pylo    equ $D002
pyhi    equ $D003
anglev  equ $D004
pagev   equ $D005
lastj   equ $D006
colv    equ $D007
rayxlo  equ $D008
rayxhi  equ $D009
rayylo  equ $D00A
rayyhi  equ $D00B
dxv     equ $D00C
dyv     equ $D00D
stepv   equ $D00E
heightv equ $D00F
topv    equ $D010
colorv  equ $D011
tmpn    equ $D012
tmpy    equ $D013
tmpx    equ $D014
tryxlo  equ $D015
tryxhi  equ $D016
tryylo  equ $D017
tryyhi  equ $D018

COLUMN_COUNT equ 32
COLUMN_WIDTH equ 4
MAX_STEPS    equ 64
VIEW_CENTER  equ 106
CEIL_COLOR   equ $11
FLOOR_COLOR  equ $44
HORIZON_COLOR equ $11

        org $D100

entry:
        ld hl,$0280
        ld (pxlo),hl
        ld hl,$0580
        ld (pylo),hl
        xor a
        ld (anglev),a
        ld (pagev),a
        ld a,(JIFFY)
        ld (lastj),a

        call draw_frame
        call set_display_page

main_loop:
        call wait_vblank
        call read_input
        or a
        jr z,continue_game
        call shutdown_vdp
        ret
continue_game:
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
        call read_char_input
        or a
        ret nz

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
        or a
        jr z,input_done

        ld c,a
        cp 7
        jr z,turn_left
        cp 6
        jr z,turn_left
        cp 8
        jr nz,check_turn_right
turn_left:
        call turn_left_step

check_turn_right:
        ld a,c
        cp 3
        jr z,turn_right
        cp 2
        jr z,turn_right
        cp 4
        jr nz,check_forward
turn_right:
        call turn_right_step

check_forward:
        ld a,c
        cp 1
        jr z,move_forward
        cp 2
        jr z,move_forward
        cp 8
        jr nz,check_backward
move_forward:
        call try_move_forward

check_backward:
        ld a,c
        cp 5
        jr z,move_backward
        cp 4
        jr z,move_backward
        cp 6
        jr nz,input_done
move_backward:
        call try_move_backward
input_done:
        xor a
        ret

quit_input:
        ld a,1
        ret

read_char_input:
        call CHSNS
        jr nz,char_ready
        xor a
        ret
char_ready:
        call CHGET
        cp $20
        jr z,quit_input
        cp $57                ; W
        jr z,char_forward
        cp $77                ; w
        jr z,char_forward
        cp 30                 ; cursor up
        jr z,char_forward
        cp $53                ; S
        jr z,char_backward
        cp $73                ; s
        jr z,char_backward
        cp 31                 ; cursor down
        jr z,char_backward
        cp $41                ; A
        jr z,char_left
        cp $61                ; a
        jr z,char_left
        cp 29                 ; cursor left
        jr z,char_left
        cp $44                ; D
        jr z,char_right
        cp $64                ; d
        jr z,char_right
        cp 28                 ; cursor right
        jr z,char_right
        xor a
        ret
char_forward:
        call try_move_forward
        xor a
        ret
char_backward:
        call try_move_backward
        xor a
        ret
char_left:
        call turn_left_step
        xor a
        ret
char_right:
        call turn_right_step
        xor a
        ret

turn_left_step:
        ld a,(anglev)
        dec a
        and 63
        ld (anglev),a
        ret

turn_right_step:
        ld a,(anglev)
        inc a
        and 63
        ld (anglev),a
        ret

try_move_forward:
        ld a,(anglev)
        call load_move_delta
        jr try_move_common

try_move_backward:
        ld a,(anglev)
        call load_move_delta
        ld a,(dxv)
        neg
        ld (dxv),a
        ld a,(dyv)
        neg
        ld (dyv),a

try_move_common:
        ld hl,(pxlo)
        ld a,(dxv)
        call add_signed_a_to_hl
        ld (tryxlo),hl
        ld hl,(pylo)
        ld a,(dyv)
        call add_signed_a_to_hl
        ld (tryylo),hl

        ld a,(tryxhi)
        ld b,a
        ld a,(tryyhi)
        ld c,a
        call cell_is_wall
        or a
        ret nz

        ld hl,(tryxlo)
        ld (pxlo),hl
        ld hl,(tryylo)
        ld (pylo),hl
        ret

load_move_delta:
        ld e,a
        ld d,0
        ld hl,move_dx_table
        add hl,de
        ld a,(hl)
        ld (dxv),a
        ld hl,move_dy_table
        add hl,de
        ld a,(hl)
        ld (dyv),a
        ret

draw_frame:
        call clear_scene
        xor a
        ld (colv),a
draw_column_loop:
        ld a,(colv)
        cp COLUMN_COUNT
        ret z
        call trace_column
        call draw_column
        ld a,(colv)
        inc a
        ld (colv),a
        jr draw_column_loop

clear_scene:
        ld b,0
        ld c,0
        ld d,105
        ld e,128
        ld a,CEIL_COLOR
        call hmmv_rect

        ld b,105
        ld c,0
        ld d,2
        ld e,128
        ld a,HORIZON_COLOR
        call hmmv_rect

        ld b,107
        ld c,0
        ld d,105
        ld e,128
        ld a,FLOOR_COLOR
        call hmmv_rect
        ret

trace_column:
        ld hl,(pxlo)
        ld (rayxlo),hl
        ld hl,(pylo)
        ld (rayylo),hl

        ld a,(colv)
        ld e,a
        ld d,0
        ld hl,ray_offset_table
        add hl,de
        ld a,(hl)
        ld b,a
        ld a,(anglev)
        add a,b
        and 63
        call load_ray_delta

        ld a,1
        ld (stepv),a
trace_loop:
        ld hl,(rayxlo)
        ld a,(dxv)
        call add_signed_a_to_hl
        ld (rayxlo),hl
        ld hl,(rayylo)
        ld a,(dyv)
        call add_signed_a_to_hl
        ld (rayylo),hl

        ld a,(rayxhi)
        ld b,a
        ld a,(rayyhi)
        ld c,a
        call cell_is_wall
        or a
        jr nz,trace_hit

        ld a,(stepv)
        cp MAX_STEPS
        jr nc,trace_hit
        inc a
        ld (stepv),a
        jr trace_loop

trace_hit:
        ld a,(stepv)
        ld e,a
        ld d,0
        ld hl,height_table
        add hl,de
        ld a,(hl)
        ld (heightv),a
        ld hl,shade_table
        add hl,de
        ld a,(hl)
        ld (colorv),a
        ret

load_ray_delta:
        ld e,a
        ld d,0
        ld hl,ray_dx_table
        add hl,de
        ld a,(hl)
        ld (dxv),a
        ld hl,ray_dy_table
        add hl,de
        ld a,(hl)
        ld (dyv),a
        ret

draw_column:
        ld a,(heightv)
        srl a
        ld b,a
        ld a,VIEW_CENTER
        sub b
        ld (topv),a

        ld a,(colv)
        add a,a
        add a,a
        ld c,a
        ld a,(topv)
        ld b,a
        ld a,(heightv)
        ld d,a
        ld e,COLUMN_WIDTH
        ld a,(colorv)
        call hmmv_rect
        ret

cell_is_wall:
        ld a,b
        cp 8
        jr nc,cell_wall
        ld a,c
        cp 8
        jr nc,cell_wall
        add a,a
        add a,a
        add a,a
        add a,b
        ld e,a
        ld d,0
        ld hl,map_data
        add hl,de
        ld a,(hl)
        ret
cell_wall:
        ld a,1
        ret

add_signed_a_to_hl:
        ld e,a
        add a,a
        sbc a,a
        ld d,a
        add hl,de
        ret

flip_page:
        ld a,(pagev)
        xor 1
        ld (pagev),a
        ret

; HMMV rectangle fill in SCREEN 5 byte-X coordinates.
; A=color, B=y, C=byte_x, D=height, E=width bytes.
hmmv_rect:
        push af
        ld a,d
        ld (tmpn),a
        ld a,e
        ld (tmpx),a
        ld a,b
        ld (tmpy),a
        ld a,c
        ld (colorv),a
        call wait_vdp_cmd
        di
        ld a,(colorv)
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
        ld a,(tmpx)
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

map_data:
        db 1,1,1,1,1,1,1,1
        db 1,0,0,0,0,0,0,1
        db 1,0,1,1,0,0,0,1
        db 1,0,0,1,0,0,0,1
        db 1,0,0,1,1,1,0,1
        db 1,0,0,0,0,0,0,1
        db 1,0,0,0,1,0,0,1
        db 1,1,1,1,1,1,1,1

ray_offset_table:
        db -10,-9,-9,-8,-7,-7,-6,-5,-5,-4,-4,-3,-2,-2,-1,0
        db 0,1,2,2,3,4,4,5,5,6,7,7,8,9,9,10

ray_dx_table:
        db 32,32,31,31,30,28,27,25,23,20,18,15,12,9,6,3
        db 0,-3,-6,-9,-12,-15,-18,-20,-23,-25,-27,-28,-30,-31,-31,-32
        db -32,-32,-31,-31,-30,-28,-27,-25,-23,-20,-18,-15,-12,-9,-6,-3
        db 0,3,6,9,12,15,18,20,23,25,27,28,30,31,31,32

ray_dy_table:
        db 0,3,6,9,12,15,18,20,23,25,27,28,30,31,31,32
        db 32,32,31,31,30,28,27,25,23,20,18,15,12,9,6,3
        db 0,-3,-6,-9,-12,-15,-18,-20,-23,-25,-27,-28,-30,-31,-31,-32
        db -32,-32,-31,-31,-30,-28,-27,-25,-23,-20,-18,-15,-12,-9,-6,-3

move_dx_table:
        db 32,32,31,31,30,28,27,25,23,20,18,15,12,9,6,3
        db 0,-3,-6,-9,-12,-15,-18,-20,-23,-25,-27,-28,-30,-31,-31,-32
        db -32,-32,-31,-31,-30,-28,-27,-25,-23,-20,-18,-15,-12,-9,-6,-3
        db 0,3,6,9,12,15,18,20,23,25,27,28,30,31,31,32

move_dy_table:
        db 0,3,6,9,12,15,18,20,23,25,27,28,30,31,31,32
        db 32,32,31,31,30,28,27,25,23,20,18,15,12,9,6,3
        db 0,-3,-6,-9,-12,-15,-18,-20,-23,-25,-27,-28,-30,-31,-31,-32
        db -32,-32,-31,-31,-30,-28,-27,-25,-23,-20,-18,-15,-12,-9,-6,-3

height_table:
        db 180,180,156,136,122,110,100,90,84,78,72,68,64,60,56,54
        db 52,50,46,44,44,42,40,38,36,36,34,34,32,32,30,30
        db 28,28,28,26,26,26,24,24,24,22,22,22,22,22,20,20
        db 20,20,20,18,18,18,18,18,18,16,16,16,16,16,16,16
        db 14

shade_table:
        db $EE,$EE,$EE,$EE,$EE,$EE,$EE,$EE,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC
        db $66,$66,$66,$66,$66,$66,$66,$66,$44,$44,$44,$44,$44,$44,$44,$44
        db $44,$44,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
        db $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
        db $11
