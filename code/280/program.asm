; 280 square-table multiply visual demo for MSX2 / Pasmo
;
; Builds floor(n*n/4) for n=0..510, then uses the identity
; ab=((a+b)^2-(a-b)^2)/4 to draw a SCREEN 5 multiplication texture.
; $D00A selects mode: 0 visual demo, 1 benchmark loop.

VDP_DATA equ $98
VDP_CTRL equ $99

prod    equ $D002       ; word: sample product result
sumv    equ $D004       ; word: checksum of all drawn products
loopv   equ $D006       ; word: benchmark loop count
tmpx    equ $D008
tmpy    equ $D009
modev   equ $D00A
cnt     equ $D00B
cur     equ $D00D
delta   equ $D00F
tog     equ $D011
bcnt    equ $D012       ; word: generated table byte count
rowf    equ $D014
rowcnt  equ $D015
colcnt  equ $D016
bytev   equ $D017

table   equ $D800       ; 511 words, kept away from the loaded code

PLAY_TOP    equ 24
PLAY_HEIGHT equ 168
BACK_BYTE   equ $11

        org $D100

entry:
        ld a,(modev)
        cp 1
        jp z,bench_table
        call init_table
        ld b,37
        ld c,123
        call mul_table
        ld (prod),hl
        call clear_playfield
        call draw_demo
        call reset_vram_high
        ret

; Input: B=a, C=b. Output: HL=a*b.
mul_table:
        ld a,b
        add a,c
        ld l,a
        ld h,0
        jr nc,sum_ready
        inc h
sum_ready:
        add hl,hl
        ld de,table
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)

        ld a,b
        sub c
        jr nc,diff_ready
        neg
diff_ready:
        ld l,a
        ld h,0
        add hl,hl
        ld bc,table
        add hl,bc
        ld a,e
        sub (hl)
        ld e,a
        inc hl
        ld a,d
        sbc a,(hl)
        ld d,a
        ex de,hl
        ret

bench_table:
        ld hl,0
        ld (sumv),hl
        ld a,1
        ld (tmpx),a
        ld a,7
        ld (tmpy),a
bench_loop:
        ld hl,(loopv)
        ld a,h
        or l
        ret z

        ld a,(tmpx)
        ld b,a
        ld a,(tmpy)
        ld c,a
        call mul_table

        ex de,hl
        ld hl,(sumv)
        add hl,de
        ld (sumv),hl

        ld a,(tmpx)
        add a,17
        ld (tmpx),a
        ld a,(tmpy)
        add a,29
        ld (tmpy),a

        ld hl,(loopv)
        dec hl
        ld (loopv),hl
        jr bench_loop

init_table:
        ld hl,511
        ld (cnt),hl
        ld hl,0
        ld (cur),hl
        ld (delta),hl
        ld (bcnt),hl
        xor a
        ld (tog),a
        ld hl,table
init_loop:
        ld de,(cur)
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl

        push hl
        ld hl,(bcnt)
        inc hl
        inc hl
        ld (bcnt),hl

        ld hl,(cur)
        ld de,(delta)
        add hl,de
        ld (cur),hl

        ld a,(tog)
        or a
        jr nz,no_delta_inc
        ld hl,(delta)
        inc hl
        ld (delta),hl
no_delta_inc:
        xor 1
        ld (tog),a

        ld hl,(cnt)
        dec hl
        ld (cnt),hl
        ld a,h
        or l
        pop hl
        jr nz,init_loop
        ret

clear_playfield:
        ld a,PLAY_TOP
        ld (tmpy),a
clear_row:
        ld a,(tmpy)
        cp 196
        ret nc
        ld b,a
        ld c,0
        ld a,BACK_BYTE
        ld e,128
        call write_run
        ld a,(tmpy)
        inc a
        ld (tmpy),a
        jr clear_row

draw_demo:
        ld hl,0
        ld (sumv),hl
        ld a,PLAY_TOP
        ld (tmpy),a
        xor a
        ld (rowf),a
        ld a,PLAY_HEIGHT
        ld (rowcnt),a
draw_row:
        ld a,(tmpy)
        ld b,a
        ld c,0
        call calc_addr_byte
        call set_vram_write
        xor a
        ld (tmpx),a
        ld a,128
        ld (colcnt),a
draw_col:
        ld a,(tmpx)
        add a,a
        ld b,a
        ld a,(rowf)
        add a,32
        ld c,a
        call mul_table
        push hl
        ld de,(sumv)
        add hl,de
        ld (sumv),hl
        pop hl
        call product_to_byte
        out (VDP_DATA),a
        ld a,(tmpx)
        inc a
        ld (tmpx),a
        ld a,(colcnt)
        dec a
        ld (colcnt),a
        jr nz,draw_col

        ld a,(tmpy)
        inc a
        ld (tmpy),a
        ld a,(rowf)
        inc a
        ld (rowf),a
        ld a,(rowcnt)
        dec a
        ld (rowcnt),a
        jr nz,draw_row
        ret

product_to_byte:
        ld a,h
        and $0F
        rlca
        rlca
        rlca
        rlca
        ld e,a
        ld a,l
        rrca
        rrca
        rrca
        rrca
        and $0F
        or e
        ret

write_run:
        ld (bytev),a
        ld a,e
        ld (colcnt),a
        call calc_addr_byte
        call set_vram_write
        ld a,(colcnt)
        ld e,a
        ld a,(bytev)
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
