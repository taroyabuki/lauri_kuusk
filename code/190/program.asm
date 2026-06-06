; 190 pioneer scrap collector drawing helpers for MSX SCREEN 2 / Pasmo
;
; BASIC keeps the game logic and input. This routine updates small bitmap
; rectangles directly in SCREEN 2 VRAM.

VDP_DATA equ $98
VDP_CTRL equ $99

cmd     equ $D000
argx    equ $D001
argy    equ $D002
rx1     equ $D003
ry1     equ $D004
rx2     equ $D005
ry2     equ $D006
colorv  equ $D007
modev   equ $D008
curxb   equ $D009
cury    equ $D00A
startb  equ $D00B
endb    equ $D00C
maskv   equ $D00D

BG_COLOR equ 1
RED      equ 8
WHITE    equ 15
BROWN    equ 6
SCRAP    equ 11
ENEMY    equ 13

        org $D100

entry:
        ld a,(cmd)
        cp 1
        jp z,draw_player
        cp 2
        jp z,erase_player
        cp 3
        jp z,draw_enemy
        cp 4
        jp z,erase_enemy
        cp 5
        jp z,draw_scrap
        ret

draw_player:
        ld a,(argx)
        sub 4
        ld (rx1),a
        ld a,(argy)
        sub 12
        ld (ry1),a
        ld a,(argx)
        add a,4
        ld (rx2),a
        ld a,(argy)
        sub 9
        ld (ry2),a
        ld a,RED
        call draw_rect

        ld a,(argx)
        sub 3
        ld (rx1),a
        ld a,(argy)
        sub 8
        ld (ry1),a
        ld a,(argx)
        add a,3
        ld (rx2),a
        ld a,(argy)
        dec a
        ld (ry2),a
        ld a,WHITE
        call draw_rect

        ld a,(argx)
        sub 5
        ld (rx1),a
        ld a,(argy)
        ld (ry1),a
        ld a,(argx)
        add a,5
        ld (rx2),a
        ld a,(argy)
        add a,5
        ld (ry2),a
        ld a,WHITE
        call draw_rect

        ld a,(argx)
        sub 5
        ld (rx1),a
        ld a,(argy)
        add a,2
        ld (ry1),a
        ld a,(argx)
        add a,5
        ld (rx2),a
        ld a,(argy)
        add a,3
        ld (ry2),a
        ld a,RED
        call draw_rect

        ld a,(argx)
        sub 4
        ld (rx1),a
        ld a,(argy)
        add a,6
        ld (ry1),a
        ld a,(argx)
        add a,4
        ld (rx2),a
        ld a,(argy)
        add a,11
        ld (ry2),a
        ld a,BROWN
        jp draw_rect

erase_player:
        ld a,(argx)
        sub 6
        ld (rx1),a
        ld a,(argy)
        sub 13
        ld (ry1),a
        ld a,(argx)
        add a,6
        ld (rx2),a
        ld a,(argy)
        add a,12
        ld (ry2),a
        jp clear_rect

draw_enemy:
        ld a,(argx)
        sub 2
        ld (rx1),a
        ld a,(argy)
        sub 5
        ld (ry1),a
        ld a,(argx)
        add a,2
        ld (rx2),a
        ld a,(argy)
        sub 4
        ld (ry2),a
        ld a,ENEMY
        call draw_rect

        ld a,(argx)
        sub 5
        ld (rx1),a
        ld a,(argy)
        sub 3
        ld (ry1),a
        ld a,(argx)
        add a,5
        ld (rx2),a
        ld a,(argy)
        add a,3
        ld (ry2),a
        ld a,ENEMY
        call draw_rect

        ld a,(argx)
        sub 2
        ld (rx1),a
        ld a,(argy)
        add a,4
        ld (ry1),a
        ld a,(argx)
        add a,2
        ld (rx2),a
        ld a,(argy)
        add a,5
        ld (ry2),a
        ld a,ENEMY
        jp draw_rect

erase_enemy:
        ld a,(argx)
        sub 6
        ld (rx1),a
        ld a,(argy)
        sub 6
        ld (ry1),a
        ld a,(argx)
        add a,6
        ld (rx2),a
        ld a,(argy)
        add a,6
        ld (ry2),a
        jp clear_rect

draw_scrap:
        ld a,(argx)
        sub 3
        ld (rx1),a
        ld a,(argy)
        sub 3
        ld (ry1),a
        ld a,(argx)
        add a,3
        ld (rx2),a
        ld a,(argy)
        add a,3
        ld (ry2),a
        ld a,SCRAP
        jp draw_rect

draw_rect:
        add a,a
        add a,a
        add a,a
        add a,a
        or BG_COLOR
        ld (colorv),a
        ld a,1
        ld (modev),a
        jp fill_rect

clear_rect:
        xor a
        ld (modev),a

fill_rect:
        ld a,(rx1)
        srl a
        srl a
        srl a
        ld (startb),a
        ld a,(rx2)
        srl a
        srl a
        srl a
        ld (endb),a
        ld a,(ry1)
fill_row:
        ld (cury),a
        ld a,(startb)
        ld (curxb),a
fill_byte:
        call make_mask
        ld a,(curxb)
        ld c,a
        ld a,(cury)
        call calc_addr
        ld a,(maskv)
        call process_byte
        ld a,(curxb)
        ld b,a
        ld a,(endb)
        cp b
        jr z,next_row
        ld a,b
        inc a
        ld (curxb),a
        jr fill_byte
next_row:
        ld a,(cury)
        ld b,a
        ld a,(ry2)
        cp b
        ret z
        ld a,b
        inc a
        jr fill_row

make_mask:
        ld a,$FF
        ld (maskv),a
        ld a,(curxb)
        ld b,a
        ld a,(startb)
        cp b
        jr nz,mask_end
        ld a,(rx1)
        and 7
        ld e,a
        ld d,0
        ld hl,start_masks
        add hl,de
        ld a,(hl)
        ld (maskv),a
mask_end:
        ld a,(curxb)
        ld b,a
        ld a,(endb)
        cp b
        ret nz
        ld a,(rx2)
        and 7
        ld e,a
        ld d,0
        ld hl,end_masks
        add hl,de
        ld a,(maskv)
        and (hl)
        ld (maskv),a
        ret

calc_addr:
        ld b,a
        and $F8
        ld h,0
        ld l,a
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,c
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        add hl,de
        ld a,b
        and 7
        ld e,a
        ld d,0
        add hl,de
        ret

process_byte:
        ld (maskv),a
        di
        push hl
        call set_read_addr
        in a,(VDP_DATA)
        ld b,a
        ld a,(modev)
        or a
        jr z,process_clear
        ld a,(maskv)
        or b
        jr process_got
process_clear:
        ld a,(maskv)
        cpl
        and b
process_got:
        ld c,a
        pop hl
        push hl
        call set_write_addr
        ld a,c
        out (VDP_DATA),a
        ld a,(modev)
        or a
        jr z,process_done
        pop hl
        ld de,$2000
        add hl,de
        call set_write_addr
        ld a,(colorv)
        out (VDP_DATA),a
        ei
        ret
process_done:
        pop hl
        ei
        ret

set_read_addr:
        ld a,l
        out (VDP_CTRL),a
        ld a,h
        and $3F
        out (VDP_CTRL),a
        ret

set_write_addr:
        ld a,l
        out (VDP_CTRL),a
        ld a,h
        and $3F
        or $40
        out (VDP_CTRL),a
        ret

start_masks:
        db $FF,$7F,$3F,$1F,$0F,$07,$03,$01
end_masks:
        db $80,$C0,$E0,$F0,$F8,$FC,$FE,$FF
