# MSX 画面描画高速化メモ

MSXPen 上でMSX BASIC、MSX1、MSX2の画面描画を速くするための実用メモ。
文字画面のBASICゲーム、`SCREEN 1` のMSX1グラフィックス/ASM版、`SCREEN 5` のMSX2グラフィックス/ASM版を分けて扱う。

## 文字版: SCREEN 0 BASIC

MSXPen 上の MSX BASIC で、文字ベースのゲームを動かすときの実用メモ。
特に `SCREEN 0:WIDTH 40` の文字画面を前提にする。

### 1. ループ中で `CLS` しない

毎フレーム `CLS` すると、画面全体を消してから描き直すことになり、操作不能なほど遅くなる。
`CLS` は初期化時だけにして、ゲーム中は必要な文字だけを消す。

悪い例:

```basic
100 CLS
110 LOCATE X,Y:PRINT "A";
120 GOTO 100
```

良い例:

```basic
100 LOCATE OX,OY:PRINT " ";
110 LOCATE X,Y:PRINT "A";
120 OX=X:OY=Y:GOTO 100
```

### 2. 静的な背景は最初に1回だけ描く

道路、枠、説明文など、動かないものは最初に描いて終わりにする。
ゲーム中に毎回描き直すのは、プレイヤー、敵、得点など変化したものだけにする。

`140` の車ゲームでは、道路の縦線を毎フレーム描くのをやめたことで改善した。

### 3. 差分描画にする

動くキャラクタは、前回位置を消して新しい位置だけ描く。
複数オブジェクトでは、前回座標を配列に保存しておく。

```basic
100 PX=X:PY=Y
110 X=X+1
120 LOCATE PX,PY:PRINT " ";
130 LOCATE X,Y:PRINT "o";
```

消した場所に葉や障害物など別の文字があった場合は、空白ではなく元の文字を復元する。

### 4. 表示は `PRINT` より `VPOKE` 中心にする

文字画面で1文字だけ書き換えるなら、`VPOKE` でVRAMへ直接書く方が扱いやすく、カーソル移動やスクロールの副作用も避けやすい。
`PRINT` はタイトル、スコア、説明文、意図的なスクロールに限り、ゲーム中のキャラクタ表示は `VPOKE` を中心にする。

このリポジトリの `SCREEN 0:WIDTH 40` では、文字位置を次のように扱っている。

```basic
A=Y*40+X
VPOKE A,111 ' o
VPOKE A,32  ' space
```

よく使う文字コード:

```text
32  space
43  +
64  @
66  B
86  V
111 o
```

`VPOKE` はVRAMへ1バイト書く命令。MSX Wiki の説明でも、VRAMの指定アドレスへ値を書き込む命令として説明されている。

### 5. 当たり判定は `VPEEK` で画面を読む

敵や障害物との当たり判定を、配列の総当たりだけで行うと遅くなる。
文字画面にゲーム状態がそのまま描かれているなら、移動先のVRAMを `VPEEK` で読めばよい。

```basic
A=NY*40+NX
C=VPEEK(A)
IF C=66 THEN 900 ' B: bird
IF C=43 THEN 300 ' +: leaf
```

この方法では、画面上の文字が当たり判定の表にもなる。
ただし、敵、葉、壁などを文字コードで区別しておく必要がある。

### 6. 右下端への `PRINT` を避ける

`LOCATE 39,23:PRINT ...` のように右下端へ出力すると、文字画面がスクロールすることがある。
スクロールさせたい処理なら利用できるが、ゲーム中のキャラクタ描画では事故になりやすい。

安全策:

```basic
IF X<1 THEN X=1 ELSE IF X>38 THEN X=38
IF Y<3 THEN Y=3 ELSE IF Y>22 THEN Y=22
```

`VPOKE` ならカーソル位置を動かさないので、この問題を避けやすい。

### 7. スクロールを使える場面では使う

炎や雪のように画面全体が一方向へ流れるだけなら、個別に全部消して描くより、1行を追加してスクロールさせる方が自然で軽い場合がある。

`130` の炎は、下端に新しい行を `PRINT` して上へスクロールさせる方式にした。
ただし、これは画面全体が動く演出に向いている場合だけ使う。

### 8. スネーク型の胴体は循環バッファにする

胴体配列を毎フレーム全部ずらすと遅い。

遅い例:

```basic
FOR I=L-1 TO 1 STEP -1
X(I)=X(I-1):Y(I)=Y(I-1)
NEXT I
```

スネーク型では、尾の位置だけ消し、頭の位置だけ追加する。
配列は循環バッファとして使い、先頭位置 `T` と長さ `L` で管理する。

```basic
OX=X(T):OY=Y(T):VPOKE OY*40+OX,32
T=T+1:IF T>MX THEN T=0
H=T+L-1:IF H>MX THEN H=H-MX-1
X(H)=NX:Y(H)=NY:VPOKE NY*40+NX,111
```

`180` の芋虫ゲームではこの方法に変更した。

芋虫の体を毎回全部調べるのも遅い。
頭の移動先が自分の体かどうかは、体の配列を総当たりするより、移動先を `VPEEK` して `o` があるか読む方が軽い。

```basic
A=NY*40+NX
IF VPEEK(A)=111 THEN 900 ' o: own body
```

### 9. 座標からVRAM番地を毎回計算しない

`Y*40+X` を何度も計算すると、BASICではそれだけで重くなる。
動くキャラクタは、座標 `X`,`Y` だけでなくVRAM番地 `A` も持つとよい。

```basic
A=Y*40+X
REM right
X=X+1:A=A+1
REM left
X=X-1:A=A-1
REM up
Y=Y-1:A=A-40
REM down
Y=Y+1:A=A+40
```

行ごとの先頭番地を配列にしておく方法もある。

```basic
FOR Y=0 TO 23:YA(Y)=Y*40:NEXT Y
A=YA(Y)+X
```

### 10. 全部を毎フレーム動かさない

BASICでは、複数の敵や背景を毎フレーム動かすとすぐ重くなる。
重要度の低いものは2フレームに1回、3フレームに1回だけ動かす。

```basic
C=C+1:IF C<2 THEN 100
C=0
REM 敵を動かす
```

### 11. 入力は `INKEY$` より `STICK`/`STRIG` に寄せる

ゲームのカーソルキー操作は `INKEY$` だけより `STICK(0)` が向いている。
`STICK(0)` はカーソルキー、`STICK(1)` はジョイスティック1を読む。
ボタンやトリガ入力は `STRIG` に寄せる。

```basic
K=STICK(0):IF K=0 THEN K=STICK(1)
IF K=3 THEN X=X+1
IF K=7 THEN X=X-1
IF STRIG(0) THEN 900
```

MSX Wiki の `STICK()` でも、`0` がカーソルキー、`1` と `2` がジョイスティックとして説明されている。

`INKEY$` は文字入力や終了キーの補助には便利だが、移動を毎フレーム読む処理の中心にしない。

### 12. 浮動小数を避け、`DEFINT A-Z` で整数化する

座標、添字、スコアなどは整数で十分。
`DEFINT A-Z` を入れると、変数を整数として扱える。

```basic
25 DEFINT A-Z
```

MSX BASIC のスネーク系リストでも、速度改善案として `DEFINT A-Z` が挙げられている。

### 13. 変数名の先頭2文字に注意する

MSX BASIC では長い変数名を使っても、先頭2文字が同じだと同じ変数として扱われることがある。
これは速度以前にバグの原因になる。

避ける例:

```basic
OEL=1:OEY=20
```

`OEL` と `OEY` が衝突し、配列添字が壊れることがある。
短くても先頭2文字が違う名前を使う。

### 14. それでも遅い場合

BASICだけで限界が来たら、次の順で検討する。

1. `LOCATE`/`PRINT` を `VPOKE` に置き換える
2. 配列総当たりを `VPEEK` に置き換える
3. 座標計算を減らし、VRAM番地を持つ
4. 動かすオブジェクト数や更新頻度を減らす
5. スプライトを使う
6. Z80アセンブリへ移す

### 文字版の参照

- [MSX Wiki: VPOKE](https://www.msx.org/wiki/VPOKE)
- [MSX Wiki: VPEEK](https://www.msx.org/wiki/VPEEK)
- [MSX Wiki: STICK()](https://www.msx.org/wiki/STICK%28%29)
- [MSX Wiki: STRIG()](https://www.msx.org/wiki/STRIG%28%29)
- [MSX Resource Center: MSX BASIC game listing](https://www.msx.org/forum/msx-talk/general-discussion/msx-basic-game-listing)

## グラフィックス版: SCREEN 1 ASM

`260` のように、MSX1で滑らかなスクロール風表現を作るための実用メモ。
前提は `SCREEN 1`、Z80 ASM、TMS9918Aのパターンテーブルとスプライトを使う構成である。

MSX1にはMSX2のような汎用スクロールレジスタがない。
画面全体を毎フレームずらすのではなく、名前テーブルをほぼ固定し、少数のパターンとスプライト属性だけを垂直帰線ごとに書き換える。

### 1. 画面全体を動かさない

MSX1で背景全体をスクロールさせようとすると、VRAMの読み書きが多すぎる。
特に画面全体の名前テーブルやパターンを毎フレーム移動する方式は重い。

`260` では、道路、路肩、車線のタイル番号を名前テーブルに置いたままにする。
動いて見える部分だけ、パターン定義を1ドットずつ変える。

```text
name table:     ほぼ固定。道路、車線、路肩のタイル番号を並べておく
pattern table:  車線や路肩の数パターンだけを毎フレーム書き換える
sprite table:   自車と敵車の座標だけを毎フレーム書き換える
```

### 2. パターン再定義で1ドット単位に見せる

`SCREEN 1` のタイルは8x8ドットなので、名前テーブルだけを動かすと8ドット単位の動きになる。
1ドット単位に見せるには、タイル番号を動かすのではなく、タイルの8行データをずらして書き換える。

`260` では、中央車線と路肩に2つずつパターンを用意し、上半分・下半分を切り替える。
8ドット進んだらタイル番号の位相を入れ替え、オフセットを0に戻す。
これで見た目は1ドットずつ流れ続ける。

```asm
        ld hl,240*8       ; pattern 240 の定義位置
        call set_vram_write
        ld a,(offv)       ; 0..7 のドットオフセット
        ld c,a
        call write_center_a
        call write_center_b
```

### 3. VRAMはASMで連続書き込みする

BASICの `VPOKE` は1バイトずつの命令呼び出しになるため、毎フレーム数十バイトを書く処理には向かない。
Z80 ASMではVDPの制御ポート `$99` にVRAMアドレスを書き、データポート `$98` へ連続して `OUT` する。
VDP側のVRAMアドレスは自動で進む。

```asm
VDP_DATA equ $98
VDP_CTRL equ $99

set_vram_write:
        di
        ld a,l
        out (VDP_CTRL),a
        ld a,h
        and $3F
        or $40
        out (VDP_CTRL),a
        ei
        ret

write_loop:
        ld a,(hl)
        out (VDP_DATA),a
        inc hl
        djnz write_loop
```

重要なのは、VRAMアドレス設定を1回だけ行い、その後は連続した `OUT (VDP_DATA),a` でまとめて書くこと。
`260` ではパターン定義、スプライト属性、初期化時の名前テーブル塗りつぶしをこの形にしている。

### 4. 垂直帰線に同期する

VDPへの書き込みは表示中でもできるが、ちらつきや不均一な動きが出やすい。
MSX BIOSの `JIFFY` は垂直帰線割り込みで増えるので、前回値から変わるまで待てば1フレーム単位で更新できる。

```asm
JIFFY equ $FC9E

wait_vblank:
        ld a,(lastj)
wait_loop:
        ld b,a
        ld a,(JIFFY)
        cp b
        jr z,wait_loop
        ld (lastj),a
        ret
```

この待ちをメインループの先頭に置く。
入力、パターン更新、敵車更新、スプライト属性更新を1フレームに1回だけ行う。

### 5. 動く物体はスプライトに分ける

背景のスクロール風表現はパターン再定義で作る。
自車や敵車のようにピクセル単位で動くものは、背景に描かずスプライトにする。

MSX1のスプライト属性テーブルは、各スプライトにつき `Y, X, pattern, color` の4バイトで並ぶ。
毎フレーム、必要なスプライト分だけ連続書き込みすると軽い。

```asm
SATTBL equ $1B00

        ld hl,SATTBL
        call set_vram_write
        ld a,(y)
        out (VDP_DATA),a
        ld a,(x)
        out (VDP_DATA),a
        ld a,pattern
        out (VDP_DATA),a
        ld a,color
        out (VDP_DATA),a
```

MSX1では同じ水平ラインに5枚目のスプライトを置くと欠ける。
敵を多く出す場合はY座標をずらすか、同一ラインに集中しない配置にする。
`260` では敵車を4台に抑え、レーンごとのY位置を分散させている。

### 6. BASICはローダーに限定する

滑らかなスクロールが目的なら、BASIC側で毎フレーム処理しない。
BASICは機械語の読み込み、`DEFUSR`、終了後の表示だけを担当する。

```basic
50 A=&HD100:FOR I=0 TO 753:READ B:POKE A+I,B:NEXT I
60 DEFUSR=&HD100:D=USR(0)
```

ゲームループ、VRAM更新、入力処理、当たり判定はASM側に置く。
これでBASICの命令解釈コストを避けられる。

### 7. 入力もASM側で読む

毎フレームの入力判定もBASICに戻さない。
MSX BIOSの `GTSTCK` と `GTTRIG` をASMから呼ぶ。

```asm
GTSTCK  equ $00D5
GTTRIG  equ $00D8

        xor a
        call GTTRIG
        or a
        ret nz

        xor a
        call GTSTCK
```

カーソルキーとジョイスティックを両方見る場合は、`GTSTCK` の引数を `0`、必要なら `1` に変えて読む。
`260` では移動、終了判定ともにASM側で処理している。

### グラフィックス版の参照

- [MSX Wiki: Texas Instruments TMS9918](https://www.msx.org/wiki/Texas_Instruments_TMS9918)

## MSX2グラフィックス版: SCREEN 5 ASM

`210` のように、MSX2向けにビットマップ画面をASMで直接描くときの実用メモ。
前提は `SCREEN 5`、Z80 ASM、V9938のVRAMアドレス指定を使う構成である。

### 1. 座標系をSCREEN 5のバイト単位に寄せる

`SCREEN 5` は256x212ドット・16色で、VRAM上では1バイトに横2ピクセルが入る。
細かいドット単位の色分けが不要なら、X座標を「2ピクセルで1単位」のバイト座標として持つと軽い。

```text
screen x pixel:  0..255
byte x:          0..127
VRAM address:    y * 128 + byte_x
```

`210` では星、敵機、弾、自機をすべてこのバイト座標で管理している。
描画と当たり判定の座標系が同じになり、BASICの文字座標より滑らかに動かせる。

### 2. V9938ではR#14も設定してVRAMへ書く

`SCREEN 5` のVRAMアドレスは16KBを越えるため、MSX1のように下位14bitだけを設定する書き込みでは足りない。
V9938のレジスタ14にVRAMアドレスの高位ビットを入れてから、通常のVRAM書き込みアドレスを設定する。

```asm
VDP_DATA equ $98
VDP_CTRL equ $99

set_vram_write:
        di
        ld a,h
        rlca
        rlca
        and 3
        out (VDP_CTRL),a
        ld a,$8E       ; V9938 R#14
        out (VDP_CTRL),a
        ld a,l
        out (VDP_CTRL),a
        ld a,h
        and $3F
        or $40
        out (VDP_CTRL),a
        ei
        ret
```

BASICに戻る前や終了前には、R#14を0へ戻しておくと、後続のBASIC描画や別ルーチンのVRAMアクセスが安全になる。

```asm
reset_vram_high:
        xor a
        out (VDP_CTRL),a
        ld a,$8E
        out (VDP_CTRL),a
        ret
```

### 3. 画面全体ではなくプレイフィールドだけ消す

毎フレーム全画面を消すと重い。
初期化時も、ゲームで使う範囲だけを行単位で消すとよい。

`210` では上部のスコア表示を残し、プレイフィールドだけを1行128バイトの連続書き込みで消している。

```asm
        ld b,y
        ld c,0
        xor a
        ld e,128
        call write_run
```

横方向に連続した弾やパネルも同じ `write_run` で描ける。
VRAMアドレス設定を1回だけ行い、データポートへ同じ値を連続して出す。

### 4. 小さい物体は固定パターンをソフトウェアスプライトとして描く

敵機や自機をビットマップ背景へ描く場合は、4x8バイト程度の固定パターンを用意し、描画時にVRAMへコピーする。
消去時は同じ大きさのゼロパターンを書けばよい。

```asm
draw_pattern:
        ; HL = pattern, B = y, C = byte_x, D = height, E = width bytes
        ; 1行ずつVRAMアドレスを設定してEバイトを書き込む
```

これはハードウェアスプライトより自由に色を置けるが、背景を上書きする。
星のような背景点と重なる場合は、毎フレーム「背景を消す、物体を消す、状態更新、背景を描く、物体を描く」の順序を揃える。

### 5. 描画順で見え方を決める

ビットマップへ直接描く場合、後から描いたものが上に見える。
`210` では星、敵機、弾、自機の順に描く。

```asm
draw_all:
        call draw_stars
        call draw_enemies
        call draw_bullet
        call draw_player
        ret
```

弾を敵機より後に描くと、命中直前に弾が敵機へ重なっても見える。
自機を最後に描くと、星や敵機を消した後でも自機が隠れにくい。

### 6. 当たり判定は見た目より少し広げる

`SCREEN 5` のバイト座標では、X方向の1単位が2ピクセルになる。
また、弾や敵機のパターンには余白がある。
完全一致だけで判定すると、見た目では当たっているのに外れたように見える。

`210` では弾と敵機の衝突を、Y方向10ドット未満、X方向8バイト未満のように少し広めに取る。

```asm
        ld a,(byv)
        sub (ix+1)
        jr nc,y_abs_ready
        neg
y_abs_ready:
        cp 10
        jr nc,no_hit
```

描画に使う座標系と同じ座標系で判定し、プレイヤーが見て納得できる幅へ調整する。

### 7. 命中やクラッシュは短い停止で見せる

敵機に弾が当たった瞬間にすぐ再出現させると、命中したか分かりにくい。
命中位置にクラッシュパターンを描き、`JIFFY` 同期待ちで1、2フレームだけ止めると、処理は軽いまま手応えが出る。

```asm
enemy_hit_flash:
        ld b,2
wait_hit:
        push bc
        call wait_vblank
        pop bc
        djnz wait_hit
        ret
```

待ちを長くしすぎると操作感が悪くなる。
短い演出にして、すぐゲームループへ戻す。

### 8. グラフィック画面の文字はGRP:へ出す

`SCREEN 5` では通常の `LOCATE`/`PRINT` だけでは期待した場所に文字が出ないことがある。
グラフィック画面に確実に文字を出したい場合は、BASIC側で `GRP:` を開き、`PRESET` と `PRINT #1` を使う。

```basic
25 OPEN "GRP:" FOR OUTPUT AS #1
30 PRESET (0,0):PRINT #1,"MARS 3 MSX2"
90 LINE (64,80)-(191,124),1,BF
100 PRESET (88,88):PRINT #1,"GAME OVER"
110 PRESET (88,98):PRINT #1,"SCORE ";S
120 PRESET (76,114):PRINT #1,"PRESS RETURN"
150 CLOSE #1:SCREEN 0:END
```

BASICをローダーに限定していても、ゲーム終了後のスコアや案内表示はこの方法で十分扱える。
