; 300 MSX2 singing computer PSG DAC voice player
;
; MSX2 has the same three-channel PSG as MSX1.  This version uses
; channel A as a crude 4-bit DAC by disabling tone/noise and updating the
; volume register at audio rate.  The packed sample is a short generated
; speech phrase, quantized to PSG volume levels: MA MI MU ME MO.

PSG_ADDR     equ $A0
PSG_DATA     equ $A1
SAMPLE_DELAY equ 61

        org $D100

entry:
        call init_psg
        ld hl,voice_data
        ld de,voice_end-voice_data

play_loop:
        ld a,d
        or e
        jr z,player_done
        ld a,(hl)
        inc hl
        ld c,a
        and $F0
        rrca
        rrca
        rrca
        rrca
        call output_sample
        ld a,c
        and $0F
        call output_sample
        dec de
        jr play_loop

player_done:
        call silence
        ret

init_psg:
        ld a,7
        ld e,$BF
        call psg_write
        ld a,9
        ld e,0
        call psg_write
        ld a,10
        ld e,0
        call psg_write
        ld a,8
        ld e,0
        call psg_write
        ret

output_sample:
        push af
        ld a,8
        out (PSG_ADDR),a
        pop af
        out (PSG_DATA),a
        ld b,SAMPLE_DELAY
sample_wait:
        djnz sample_wait
        ret

silence:
        ld a,8
        ld e,0
        call psg_write
        ld a,9
        ld e,0
        call psg_write
        ld a,10
        ld e,0
        call psg_write
        ret

psg_write:
        out (PSG_ADDR),a
        ld a,e
        out (PSG_DATA),a
        ret

voice_data:
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$A9,$99,$AA,$BB,$CC,$CB,$BB
        db $BB,$BB,$AA,$AA,$AB,$BB,$BB,$BB,$BB,$BB,$BB,$A9,$99,$9A,$BB,$CC
        db $CC,$BB,$BB,$BA,$AA,$AA,$AB,$BB,$BB,$BB,$BB,$CB,$BB,$A8,$89,$99
        db $BC,$CC,$CC,$CB,$BB,$AA,$AA,$AA,$AB,$BB,$BB,$BB,$BC,$BB,$BB,$98
        db $89,$9A,$BC,$CC,$CC,$BB,$BB,$AA,$AA,$AA,$AB,$BB,$BB,$BB,$BC,$BB
        db $BA,$98,$99,$9A,$CC,$CC,$CC,$BB,$BB,$AA,$AA,$AA,$AB,$BB,$BB,$BB
        db $BC,$BB,$BA,$88,$99,$9B,$CC,$CC,$CC,$BB,$BA,$AA,$AA,$AA,$BB,$BB
        db $BB,$BB,$CB,$BB,$B9,$89,$99,$AB,$CC,$CC,$CB,$BB,$BA,$AA,$AA,$AA
        db $BB,$BB,$BB,$BC,$CB,$BB,$98,$89,$8A,$BC,$CC,$CC,$CB,$BB,$AA,$AA
        db $AA,$AB,$BB,$BB,$BB,$CB,$AA,$CB,$80,$00,$CD,$C8,$CE,$D8,$8B,$BA
        db $99,$AB,$BA,$AB,$BC,$A5,$BD,$D2,$7D,$D8,$00,$0C,$EC,$3C,$ED,$99
        db $AB,$BA,$9A,$BB,$AB,$BB,$BA,$7B,$DD,$03,$DD,$80,$00,$DE,$B0,$CD
        db $DA,$9A,$BB,$BA,$AB,$BA,$BC,$BA,$99,$CD,$C0,$5E,$E7,$00,$0E,$E9
        db $0C,$DD,$B9,$9B,$BB,$AA,$AB,$BB,$BA,$9A,$BD,$D8,$0C,$ED,$00,$0B
        db $ED,$08,$DD,$CA,$8A,$BB,$BA,$AA,$BB,$BB,$99,$AC,$DC,$00,$EE,$90
        db $00,$EE,$B0,$BD,$DB,$99,$AB,$BB,$AA,$BB,$BB,$A9,$AB,$DD,$80,$CE
        db $C0,$00,$BE,$D0,$8D,$DC,$A9,$AB,$BB,$AA,$AB,$BB,$BA,$9A,$CD,$C0
        db $0D,$EA,$00,$0D,$EC,$0B,$DD,$CA,$9A,$BB,$BA,$AB,$BB,$BB,$A9,$AC
        db $DC,$00,$DE,$A0,$00,$DE,$C0,$BD,$DB,$A9,$AB,$BB,$BA,$AB,$BB,$BA
        db $9A,$BC,$D9,$0C,$ED,$00,$0B,$ED,$67,$CD,$CA,$9A,$BB,$BB,$AA,$BB
        db $BB,$BA,$9A,$BD,$C0,$0D,$EB,$00,$0D,$EC,$1A,$DD,$BA,$9A,$BB,$BB
        db $AA,$BB,$BB,$BA,$AB,$CD,$B0,$9D,$D7,$00,$7D,$DA,$6C,$DC,$BA,$AB
        db $BB,$BB,$AB,$BB,$BB,$AA,$AB,$CC,$90,$CD,$C0,$00,$BE,$D7,$9C,$CC
        db $B9,$AB,$BB,$BB,$AB,$BB,$BB,$AA,$AB,$CC,$74,$DD,$B0,$00,$CD,$C7
        db $AC,$CC,$AA,$AB,$BB,$BB,$BB,$BB,$BB,$AA,$AB,$CC,$85,$CD,$B0,$00
        db $CD,$C8,$9C,$CC,$BA,$AB,$BB,$BB,$BB,$BB,$BB,$AB,$BB,$CC,$87,$CD
        db $C7,$00,$9D,$DB,$8A,$CC,$BB,$BA,$AB,$BB,$AA,$BC,$BA,$AB,$BB,$BB
        db $A9,$BD,$DB,$30,$7C,$DC,$BA,$BB,$BB,$BB,$AA,$BB,$BB,$AB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BC,$BB,$BA,$98,$99,$9B,$CC,$CC,$CC,$BB,$BB
        db $AA,$AA,$AA,$AB,$BB,$BB,$BB,$BC,$BB,$BB,$98,$89,$9A,$BC,$CC,$CC
        db $BB,$BB,$BA,$AA,$AA,$AA,$BB,$BB,$BB,$BB,$CB,$BB,$A8,$89,$99,$BC
        db $CC,$CC,$CB,$BB,$BB,$AA,$AA,$AA,$BB,$BB,$BB,$BB,$BC,$BB,$BA,$88
        db $99,$9B,$CC,$CC,$CC,$BB,$BB,$BA,$AA,$AA,$AA,$BB,$BB,$BB,$BB,$CB
        db $BB,$B9,$89,$99,$AB,$CC,$CC,$CB,$BB,$BB,$AA,$AA,$AA,$AB,$BB,$BB
        db $BB,$BB,$CB,$BB,$A8,$89,$99,$BC,$CC,$CC,$CB,$BB,$BB,$AA,$AA,$AA
        db $BB,$BB,$BB,$AA,$CC,$A8,$CD,$A0,$00,$8D,$DA,$AD,$DB,$6A,$CB,$AA
        db $AA,$BB,$BB,$AA,$BC,$B7,$8D,$DA,$0C,$DB,$00,$0B,$EC,$4B,$ED,$A7
        db $AC,$BA,$9B,$BA,$BB,$BA,$BC,$C9,$5A,$DD,$00,$DE,$90,$00,$DE,$90
        db $CE,$D8,$3B,$CB,$8A,$BB,$AB,$CA,$8C,$DB,$07,$DE,$C0,$8E,$D0,$00
        db $BE,$D0,$6D,$EC,$06,$CC,$98,$BC,$AA,$BC,$99,$CC,$80,$AD,$D6,$0C
        db $EC,$00,$0D,$EB,$0A,$DD,$A0,$9C,$C8,$9B,$BA,$AC,$B9,$AC,$C4,$3C
        db $DD,$00,$DE,$A0,$00,$EE,$80,$CD,$D8,$0B,$CB,$9A,$BB,$AB,$CB,$9B
        db $CB,$08,$DD,$C0,$6E,$E7,$00,$AE,$D5,$4C,$DC,$74,$BC,$B9,$BB,$AA
        db $BB,$AA,$CC,$A0,$AD,$DA,$09,$ED,$10,$0C,$ED,$66,$CD,$C7,$7B,$CB
        db $AA,$BB,$AB,$BA,$AB,$CA,$5A,$DD,$B0,$7D,$D9,$00,$8E,$DA,$5B,$DD
        db $B7,$AB,$BA,$AB,$BA,$AB,$BA,$BC,$BA,$8B,$DC,$90,$AD,$D8,$00,$AD
        db $DB,$6B,$DD,$B9,$9B,$BA,$AB,$BB,$BB,$BB,$BB,$BA,$9A,$CD,$A4,$8C
        db $DB,$00,$0D,$DC,$98,$BD,$CB,$9A,$BB,$BA,$AB,$BB,$BB,$BB,$BA,$AB
        db $CC,$B7,$8C,$DD,$90,$08,$DD,$DA,$8A,$CC,$CB,$AA,$AB,$BB,$BA,$BB
        db $BB,$AA,$BC,$CC,$A8,$9B,$DD,$B1,$00,$AD,$DD,$B9,$9A,$BC,$CB,$AA
        db $AA,$BB,$BB,$BA,$AB,$BC,$CB,$98,$9C,$DD,$C9,$00,$3B,$DD,$DB,$A9
        db $AB,$BC,$BB,$AA,$AB,$BB,$BA,$AB,$BC,$CB,$A8,$9B,$CD,$DB,$70,$06
        db $BD,$DD,$CA,$99,$AB,$BB,$BB,$AA,$BB,$BA,$AB,$BC,$CB,$B9,$99,$BC
        db $DD,$C8,$00,$2A,$CD,$DC,$BA,$99,$AB,$BB,$BB,$BA,$AA,$AB,$BB,$BB
        db $BA,$A9,$AB,$CC,$CC,$A7,$13,$8B,$CC,$CC,$BB,$AA,$AA,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$AA,$AA,$BB,$CC,$CB,$A8,$88,$AB,$CC,$CC,$BB,$AA
        db $AA,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BC,$BB,$BA
        db $98,$99,$9B,$CC,$CC,$CC,$BB,$BB,$BB,$AA,$AA,$AA,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$B9,$89,$99,$AB,$CC,$CC,$CB,$BB,$BB,$BA,$AA,$AA,$AA
        db $BB,$BB,$BB,$BB,$BB,$CB,$BB,$A9,$89,$99,$BC,$CC,$CC,$CB,$BB,$BB
        db $BA,$AA,$AA,$AB,$BB,$BB,$BB,$BB,$BB,$CB,$BB,$A8,$89,$99,$BC,$CC
        db $CC,$BB,$BB,$BB,$BA,$AA,$AA,$AB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$98
        db $99,$9A,$BC,$CC,$CC,$BB,$BB,$BB,$AA,$AA,$AA,$AB,$BB,$BB,$BB,$BB
        db $BC,$BB,$BA,$88,$99,$9B,$CC,$CC,$CB,$BB,$BA,$AB,$AA,$AB,$BA,$AB
        db $BB,$BB,$CB,$BC,$CB,$AB,$94,$57,$68,$BC,$CD,$DC,$CC,$BA,$AA,$AA
        db $AA,$BB,$BB,$BB,$BA,$AB,$BB,$CC,$CB,$BA,$00,$00,$7B,$CD,$DD,$DC
        db $BA,$99,$9A,$AB,$BB,$BB,$BB,$BA,$AA,$99,$BC,$CD,$DC,$B6,$00,$00
        db $AC,$DE,$DD,$CA,$76,$79,$BB,$BB,$BA,$AB,$BC,$CB,$A8,$76,$AC,$CD
        db $DD,$C4,$00,$00,$BD,$EE,$DD,$B8,$53,$7A,$BC,$CB,$BA,$AB,$BC,$CC
        db $B9,$75,$8B,$CD,$DD,$C9,$00,$00,$9C,$DE,$ED,$C9,$52,$59,$BC,$CC
        db $BA,$AA,$BC,$CC,$BA,$86,$6A,$BD,$DD,$DC,$30,$00,$0B,$DD,$ED,$DB
        db $85,$57,$AB,$BC,$BB,$AA,$BB,$BC,$BB,$98,$79,$BC,$DD,$DC,$B0,$00
        db $04,$BD,$DE,$DC,$B9,$77,$8A,$BB,$BB,$BB,$BB,$BB,$BB,$BA,$98,$9B
        db $BC,$DD,$CC,$70,$00,$0A,$CD,$DD,$DC,$A8,$78,$9A,$BB,$BB,$BB,$BB
        db $BB,$BB,$AA,$99,$AB,$CD,$DC,$CB,$40,$00,$6B,$CD,$DD,$CB,$A9,$89
        db $AA,$BB,$BB,$BB,$BB,$BB,$BB,$AA,$9A,$AB,$CD,$CC,$CA,$20,$00,$9C
        db $CD,$DD,$CB,$A9,$99,$AA,$BB,$BB,$BB,$BB,$BB,$BB,$AA,$AA,$BB,$CC
        db $CC,$B8,$34,$46,$BC,$CC,$DC,$BB,$AA,$9A,$AB,$BB,$BB,$BB,$BB,$BB
        db $BA,$AA,$BB,$BC,$CC,$CB,$A8,$77,$79,$BC,$CC,$CC,$BB,$AA,$AA,$AB
        db $BB,$BB,$BB,$BB,$BB,$AA,$BB,$BB,$BC,$CB,$BB,$A9,$88,$9A,$BB,$CC
        db $CC,$BB,$BB,$AA,$AA,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$98,$99,$9A,$BC,$CC,$CC,$BB,$BB,$BB,$AA,$AA,$AA
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$A9,$99,$99,$BC,$CC,$CC,$BB
        db $BB,$BB,$BA,$AA,$AA,$AB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$A9,$89
        db $99,$BC,$CC,$CC,$BB,$BB,$BB,$BA,$AA,$AA,$AB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$98,$99,$9A,$BC,$CC,$CC,$BB,$BB,$BB,$BA,$AA,$AA,$AB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$B9,$89,$99,$AB,$CC,$CC,$CB,$BB,$BB
        db $BB,$AA,$AA,$AA,$AB,$BB,$CC,$BB,$AA,$AB,$CC,$CB,$93,$00,$8B,$CD
        db $DC,$CB,$AA,$AB,$BB,$BB,$AA,$AA,$AB,$BC,$BB,$A9,$9A,$BC,$DD,$CB
        db $80,$00,$09,$CD,$DD,$DC,$B9,$75,$78,$AB,$BC,$CC,$CB,$BA,$88,$89
        db $BC,$DD,$DD,$CA,$10,$00,$0A,$CD,$DD,$DC,$BA,$75,$57,$9A,$BC,$CC
        db $CB,$A9,$98,$9A,$BC,$DD,$DC,$B9,$00,$00,$5A,$CD,$DD,$DC,$BA,$86
        db $67,$9A,$BC,$CC,$CB,$AA,$99,$AA,$BC,$CD,$DC,$BA,$60,$00,$6A,$CD
        db $DD,$DC,$CB,$98,$88,$9A,$BB,$BC,$BB,$BA,$AA,$AA,$BB,$CC,$CC,$CB
        db $A8,$52,$58,$AB,$CD,$DC,$CC,$BA,$99,$9A,$AB,$BB,$BB,$BB,$BB,$AA
        db $AB,$BB,$CC,$CC,$BB,$A9,$87,$89,$BB,$CC,$CC,$CB,$BA,$AA,$AA,$AA
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$AA,$99,$9A,$AB,$BC,$CC
        db $CB,$BB,$BA,$AA,$AA,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BA
        db $A9,$9A,$AB,$BB,$CC,$CC,$BB,$BB,$AA,$AA,$AB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B9,$89,$99,$AB,$CC,$CC,$CB,$BB
        db $BB,$BA,$AA,$AA,$AB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BA,$99,$99
        db $AB,$BC,$CC,$CB,$BB,$BB,$BB,$BB,$AA,$AB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BA,$89,$99,$AB,$CC,$CC,$CB,$BB,$BB,$BA,$AA,$AA,$AB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BA,$99,$A9,$AB,$BC,$CC,$CB,$BB,$BB
        db $BB,$BB,$AA,$AA,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BA,$89,$99,$AB
        db $CC,$CC,$CB,$BB,$BB,$BB,$AA,$AA,$AA,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$B9,$99,$99,$BB,$BC,$CC,$BB,$BB,$BB,$BB,$BA,$AA,$AB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$A9,$99,$99,$BC,$CC,$CC,$BB,$BB,$BB,$BA
        db $AA,$AA,$AB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$A9,$9A,$99,$BB,$BC
        db $CC,$BB,$BB,$BB,$BB,$BA,$AA,$AB,$BB,$BB,$BB,$BB,$BC,$BA,$AB,$BC
        db $D9,$00,$08,$DD,$CC,$BA,$BC,$CB,$A9,$9A,$BB,$BB,$BB,$BB,$BA,$9A
        db $BC,$CC,$AA,$AB,$CD,$B2,$00,$6C,$DC,$CB,$AB,$CC,$BB,$A9,$AB,$BB
        db $BB,$BB,$BB,$AA,$AB,$CC,$A9,$AA,$CD,$C6,$00,$0B,$DD,$CB,$BA,$BC
        db $CB,$A9,$9A,$BB,$BB,$BB,$BB,$AA,$AB,$CC,$A9,$AA,$CD,$C7,$00,$0B
        db $DD,$CB,$BA,$BC,$CB,$AA,$AB,$BB,$BB,$BB,$BB,$AA,$BC,$CC,$99,$99
        db $CE,$C0,$00,$0C,$ED,$CB,$AA,$BC,$CB,$AA,$AB,$BB,$BB,$BB,$BB,$AA
        db $BC,$CB,$AA,$9A,$DD,$C0,$00,$0C,$ED,$BB,$AA,$BC,$CA,$AA,$BB,$BA
        db $BB,$BB,$BB,$AA,$BC,$CB,$9A,$8A,$DE,$C0,$00,$0D,$ED,$BB,$AA,$BC
        db $CA,$AA,$BB,$BA,$BB,$BB,$BB,$BA,$AC,$CB,$AA,$99,$CE,$D6,$00,$0B
        db $ED,$CA,$BA,$BC,$CB,$AA,$AB,$BA,$BB,$BB,$BB,$BA,$AB,$CC,$BA,$A8
        db $9D,$EC,$00,$00,$CE,$DC,$AB,$AB,$CC,$BA,$AA,$BB,$AA,$BB,$BB,$BB
        db $BA,$AB,$CC,$AA,$A7,$AD,$DB,$00,$00,$CE,$DB,$AB,$BB,$CC,$BA,$AA
        db $BB,$AA,$BB,$BB,$BB,$BA,$AA,$CC,$BA,$A8,$6C,$ED,$90,$00,$7D,$ED
        db $AA,$BB,$BC,$CB,$AA,$AB,$BA,$AB,$BB,$BB,$BB,$AA,$AC,$CB,$AA,$97
        db $BD,$DA,$00,$03,$DE,$DA,$AB,$BB,$CC,$BA,$AA,$BB,$BA,$BB,$BA,$BB
        db $BB,$AA,$BC,$CA,$AA,$69,$DE,$C0,$00,$0B,$EE,$C9,$AB,$BB,$CC,$A9
        db $AB,$BB,$AA,$BB,$BB,$BB,$BA,$AB,$CC,$BA,$B9,$6B,$DD,$A0,$00,$3D
        db $ED,$A9,$BB,$BB,$CB,$AA,$AB,$BB,$AB,$BB,$AA,$BB,$BA,$AA,$CC,$BA
        db $BA,$19,$DE,$C0,$00,$0B,$EE,$C8,$AB,$BB,$CC,$B9,$AA,$BB,$AA,$BB
        db $BB,$BB,$BB,$AA,$AB,$CB,$BB,$A7,$6C,$ED,$80,$00,$6D,$ED,$A9,$BB
        db $BB,$CB,$AA,$AB,$BB,$AA,$BB,$BA,$AB,$BB,$AA,$AB,$CC,$BB,$B7,$0C
        db $ED,$A0,$00,$0C,$EE,$B7,$AB,$BB,$CC,$BA,$AA,$BB,$BA,$BB,$BB,$AB
        db $BB,$BA,$AB,$CC,$BB,$BA,$69,$DE,$C6,$00,$08,$DE,$DA,$9B,$BA,$BB
        db $BB,$AA,$BB,$BA,$AB,$BB,$AA,$BB,$BB,$AA,$BC,$BA,$AB,$95,$BD,$EB
        db $00,$00,$AD,$ED,$9A,$BB,$AB,$CC,$B9,$AB,$BB,$AA,$BB,$BA,$AB,$BB
        db $AA,$BC,$CB,$AA,$B9,$8B,$DD,$B4,$00,$09,$DD,$DA,$AB,$BA,$AB,$CB
        db $AA,$BB,$BB,$AB,$BB,$BA,$AB,$BB,$AA,$BC,$CB,$AA,$BA,$8B,$DD,$C6
        db $00,$06,$CE,$DC,$AA,$BA,$9A,$BC,$BA,$AB,$BB,$BA,$BB,$BB,$AA,$BB
        db $BA,$AB,$BC,$BA,$AB,$A9,$AC,$DD,$A4,$00,$2A,$DD,$DB,$AB,$BA,$9B
        db $BB,$BA,$AB,$BB,$BA,$BB,$BB,$AA,$BB,$BA,$AB,$BC,$BA,$AB,$BA,$9C
        db $DD,$C7,$00,$07,$CD,$DC,$AA,$BA,$99,$BC,$BB,$AA,$BB,$BA,$AB,$BB
        db $BA,$AB,$BB,$BA,$BB,$CB,$AA,$AB,$AA,$BC,$DC,$A5,$55,$5A,$CD,$DB
        db $AB,$BA,$AA,$BB,$BB,$AA,$BB,$BB,$AB,$BB,$BB,$AB,$BB,$BA,$AB,$BB
        db $BA,$AA,$BA,$9B,$CD,$CA,$44,$42,$8C,$DD,$CA,$AB,$BA,$AA,$BB,$BB
        db $AB,$BB,$BB,$AB,$BB,$BB,$AB,$BB,$BB,$AB,$BB,$BB,$AA,$BB,$AA,$BD
        db $DC,$86,$76,$7A,$CD,$DB,$AB,$BA,$AA,$BB,$BB,$BA,$BB,$BB,$BA,$BB
        db $BB,$BA,$BB,$BB,$AA,$BB,$BB,$BA,$AB,$BA,$AC,$DD,$C8,$56,$66,$AC
        db $DD,$CA,$BB,$AA,$AA,$BB,$BB,$AB,$BB,$BB,$AB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB
        db $BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$BB,$B0
voice_end:
