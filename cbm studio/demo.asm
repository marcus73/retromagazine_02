
;/*
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;*/

mem_schermo=1424; 1024+40*10
chrout=$ffd2

COUNTER0 = $ff
COUNTER1 = $ff
; 10 SYS (4096)

*=$0801

        BYTE    $0E, $08, $0A, $00, $9E, $20, $28,  $34, $30, $39, $36, $29, $00, $00, $00

;* = $0801                    ;   // BASIC start address (#2049)
; BasicUpstart(codice)

*=$1000 ; "codice"
codice

        lda #$00        ;// inizializzazione sound
        tax             ;// 
        tay             ;//       
        jsr $4000       ;// address of inizialization subroutine
         
        sei             ;// disabilita IRQ

        lda #%0111111   ;// 
        sta $dc0d       ;// Interrupt control and status register
                        ;// Bit #0: 1 = Enable interrupts generated by timer A underflow.
                        ;// Bit #1: 1 = Enable interrupts generated by timer B underflow.
                        ;// Bit #2: 1 = Enable TOD alarm interrupt.
                        ;// Bit #3: 1 = Enable interrupts generated by a byte having been received/sent via serial shift register.
                        ;// Bit #4: 1 = Enable interrupts generated by positive edge on FLAG pin.

        sta $dd0d       ;// Interrupt control and status register
                        ;// Bit #0: 1 = Enable non-maskable interrupts generated by timer A underflow.
                        ;// Bit #1: 1 = Enable non-maskable interrupts generated by timer B underflow.
                        ;// Bit #2: 1 = Enable TOD alarm non-maskable interrupt.
                        ;// Bit #3: 1 = Enable non-maskable interrupts generated by a byte having been received/sent via serial shift register.
                        ;// Bit #4: 1 = Enable non-maskable interrupts generated by positive edge on FLAG pin.

        lda #$01        ;//
        sta $d01a       ;//Interrupt control register
                        ;// Bit #0: 1 = Raster interrupt enabled.


        lda #$1b
        ldx #$c8        ;// Default value for $d016
        ;ldy #%00010100 ;  
        ldy #%00011000  ; rispetto alla versione originale della Intro i Bits 1-3 (100), puntano alla locazione $2000 ove è sistuato il character memory
        sta $d011       ;// Raster line to generate interrupt at (bit #8)
        stx $d016       ;// Screen control register #2       
        sty $d018       ;// Memory setup register
                        ;// Bits #1-#3 pointer to character memory %100, 2: $1000-$17FF, 4096-6143.  
                        ;// Bits #4-#7 Pointer to screen memory %0001, 1: $0400-$07FF, 1024-2047.        
                     

        lda #<irq
        ldx #>irq
        ldy #$fa        ; setto il play della musica nel basso dello schermo
        sta $0314       ;// modifica il vettore per l'esecuzione 
        stx $0315       ;// della routine di servizio IRQ alla locazione -irq-
        sty $d012       ;// Raster line to generate interrupt at (bit #0-#7)

        lda $dc0d       ;// reset per eventuali interrupts rilevati
        lda $dd0d       ;// reset per eventuali interrupts rilevati
        asl $d019       ;// Acknowledge raster interrupt
        
        cli             ;// abilita IRQ

        jsr scr_init            ;// imposta schermo, riproducendo il testo "RetroMagazine" tra due barre orizzontali piene
        
main
        ldx COUNTER0                    
        lda sinusTable0,x       ;//Recupera il nuovo valore di linea raster
        cmp $D012               ;//dalla relativa tabella, con indice COUNTER0, e lo confronta con l'attuale...
        bne no_barra0
        sei                     ;//disabilita le interruzioni
        jsr fai_barra0          ;//se corrispondente, crea barra raster tipo "0"
        cli                     ;//riabilita le interruzioni

no_barra0
        ldx COUNTER1
        lda sinusTable1,x       ;Recupera il nuovo valore di linea raster 
        cmp $D012               ;dalla relativa tabella, con indice COUNTER1, e lo confronta con l'attuale...
        bne no_barra1
        sei                     ;disabilita le interruzioni
        jsr fai_barra1          ;se corrispondente, crea barra raster tipo "1" 
        cli                     ;riabilita le interruzioni

no_barra1

        jmp main


scr_init

                lda #$00
                sta $d020                                       ; Bordo NERO
                sta $d021                                       ; Schermo NERO
                
                lda #147                                        ; Pulisce lo schermo video, 
                jsr chrout                                      ; chiamando la famigerata routine kernal chrout con argomento 147 (codice carattere x clear screen)
        
                ldx #00
s0
                lda #$71                                        ;// Riempie la memoria video con il valore $71 (#143) e $72 (#144)
                sta $0400,x                                     ;// che corrisponde al carattere 'muro'...
                sta $0500,x                                     ;//
                lda #$72
                sta $0600,x                                     ;//
                sta $06e8,x                                     ;//
                                
                lda #$01                                        ;// Setta il colore dello schermo al valore '01'
                sta $d800,x                                     ;// ovvero BIANCO
                sta $d900,x                                     ;//
                sta $da00,x                                     ;//
                sta $dae8,x                                     ;//

                inx                                             ;// Incrementa x
                bne s0                                          ;// torna su...


                ldx #39
                lda #$03
s1
                sta $0400,x
                sta $0400+40,x
                sta $0400+80,x
                sta $0400+120,x
                sta $0400+160,x
                sta $0400+200,x
                
                sta $0400+800,x
                sta $0400+840,x
                sta $0400+880,x
                sta $0400+920,x
                sta $0400+960,x
                sta $0400+1000,x
                dex
                bpl s1
                        
                ;// DISEGNA BARRA SUPERIORE
                ldx #39
                lda #$70
s2              sta mem_schermo-40,x
                sta mem_schermo-200,x
                dex
                bpl s2

                ;// DISEGNA SCRITTA RETROMAGAZINE
                ldx #0
ancora
                lda map_data,x
                sta mem_schermo,x
                inx
                cpx #40*6
                bne ancora
        
                ;// DISEGNA BARRA INFERIORE
                ldx #39
                lda #$70
s3             sta mem_schermo+240,x
                sta mem_schermo+400,x
                dex
                bpl s3

                rts
;}

;//================================================================================================================
fai_barra0

        ldy #10                 ;//Tempo di attesa
idle1   dey                     ;//per minimizzare il "tremolio"
        bne idle1               ;//all'inizio dell'effetto

;//------------------------------------------------------------------
;// Ciclo per stampare la barra raster '0'
;//------------------------------------------------------------------
        ldx #00

loop   lda colorBar0           ;//Assegna colore al bordo schermo
        sta $d020              ;//ed all'interno schermo
        sta $d021

        ldy #08                ;//Tempo di attesa 
idle2   dey                     ;//per minimizzare
        bne idle2              ;//il tremolio alla fine dell'effetto
                               ;//e rendere la barra piÃ¹ spessa...

        inx                    ; //
        cpx #09                ; //
        bne loop               ; //

;//------------------------------------------------------------------
;// Fine del ciclo 
;//------------------------------------------------------------------

        lda #00                 ;// Assegna il colore #00 (NERO)
        sta $d020               ;// al bordo
        sta $d021               ;// ed allo schermo video

        inc COUNTER0

        rts
;}
;//================================================================================================================

fai_barra1

        ldy #10                 ;//Tempo di attesa
idle1a  dey                      ;//per minimizzare il "tremolio"
        bne idle1a               ;//all'inizio dell'effetto

;//------------------------------------------------------------------
;// Ciclo per stampare la barra raster '1'
;//------------------------------------------------------------------
        ldx #00

loop1   lda colorBar1           ;//Assegna colore al bordo schermo
        sta $d020              ;//ed all'interno schermo
        sta $d021

        ldy #08                ; //Tempo di attesa 
idle2a  dey                     ;//per minimizzare
        bne idle2a              ; //il tremolio alla fine dell'effetto
                               ; //e rendere la barra piÃ¹ spessa...

        inx                    ;//
        cpx #09                ;//
        bne loop1               ;//

        
;//------------------------------------------------------------------
;// Fine del ciclo
;//------------------------------------------------------------------

        lda #00                 ;// Assegna il colore #00 (NERO)
        sta $d020               ;// al bordo
        sta $d021               ;// ed allo schermo video

        inc COUNTER1

        rts
;}
;//================================================================================================================

irq

        asl $d019       ;// Acknowledge raster interrupt
        ;inc $d020
        jsr $4003       ;// address of play-sound subroutine
        ;dec $d020
        jmp $ea31       ;// salta alla normale routine di servizio IRQ


*=$3000 ;dati 

colorBar0
 byte $02

colorBar1
 byte $06

sinusTable0
 BYTE           $96,$98,$9A,$9D,$9F,$A1,$A3,$A6,$A8
          BYTE           $AA,$AC,$AE,$B1,$B3,$B5,$B7,$B9,$BB
          BYTE           $BD,$BF,$C1,$C3,$C5,$C7,$C9,$CB,$CC
          BYTE           $CE,$D0,$D2,$D3,$D5,$D7,$D8,$DA,$DB
          BYTE           $DC,$DE,$DF,$E0,$E2,$E3,$E4,$E5,$E6
          BYTE           $E7,$E8,$E9,$EA,$EB,$EB,$EC,$ED,$ED
          BYTE           $EE,$EE,$EF,$EF,$EF,$F0,$F0,$F0,$F0
          BYTE           $F0,$F0,$F0,$F0,$F0,$EF,$EF,$EF,$EE
          BYTE           $EE,$ED,$ED,$EC,$EB,$EA,$EA,$E9,$E8
          BYTE           $E7,$E6,$E5,$E4,$E3,$E1,$E0,$DF,$DD
          BYTE           $DC,$DB,$D9,$D8,$D6,$D4,$D3,$D1,$CF
          BYTE           $CE,$CC,$CA,$C8,$C6,$C4,$C2,$C0,$BE
          BYTE           $BC,$BA,$B8,$B6,$B4,$B2,$B0,$AE,$AC
          BYTE           $A9,$A7,$A5,$A3,$A0,$9E,$9C,$9A,$97
          BYTE           $95,$93,$91,$8F,$8C,$8A,$88,$86,$83
          BYTE           $81,$7F,$7D,$7B,$79,$76,$74,$72,$70
          BYTE           $6E,$6C,$6A,$68,$66,$64,$63,$61,$5F
          BYTE           $5D,$5B,$5A,$58,$56,$55,$53,$52,$50
          BYTE           $4F,$4E,$4C,$4B,$4A,$49,$48,$46,$45
          BYTE           $44,$44,$43,$42,$41,$40,$40,$3F,$3F
          BYTE           $3E,$3E,$3D,$3D,$3D,$3C,$3C,$3C,$3C
          BYTE           $3C,$3C,$3C,$3C,$3D,$3D,$3D,$3E,$3E
          BYTE           $3F,$3F,$40,$40,$41,$42,$43,$44,$44
          BYTE           $45,$46,$48,$49,$4A,$4B,$4C,$4E,$4F
          BYTE           $50,$52,$53,$55,$57,$58,$5A,$5B,$5D
          BYTE           $5F,$61,$63,$64,$66,$68,$6A,$6C,$6E
          BYTE           $70,$72,$74,$76,$79,$7B,$7D,$7F,$81
          BYTE           $83,$86,$88,$8A,$8C,$8F,$91,$93,$95
          BYTE           $98,$9A,$9C,$9E


sinusTable1
  BYTE           $F0,$F0,$F0,$F0,$F0,$EF,$EF,$EF,$EE
          BYTE           $EE,$ED,$ED,$EC,$EB,$EB,$EA,$E9,$E8
          BYTE           $E7,$E6,$E5,$E4,$E3,$E2,$E0,$DF,$DE
          BYTE           $DC,$DB,$D9,$D8,$D6,$D5,$D3,$D1,$D0
          BYTE           $CE,$CC,$CA,$C9,$C7,$C5,$C3,$C1,$BF
          BYTE           $BD,$BB,$B9,$B7,$B5,$B2,$B0,$AE,$AC
          BYTE           $AA,$A8,$A5,$A3,$A1,$9F,$9C,$9A,$98
          BYTE           $96,$93,$91,$8F,$8D,$8A,$88,$86,$84
          BYTE           $82,$7F,$7D,$7B,$79,$77,$75,$73,$71
          BYTE           $6F,$6D,$6B,$69,$67,$65,$63,$61,$5F
          BYTE           $5D,$5C,$5A,$58,$57,$55,$54,$52,$51
          BYTE           $4F,$4E,$4D,$4B,$4A,$49,$48,$47,$46
          BYTE           $45,$44,$43,$42,$41,$40,$40,$3F,$3F
          BYTE           $3E,$3E,$3D,$3D,$3D,$3C,$3C,$3C,$3C
          BYTE           $3C,$3C,$3C,$3C,$3D,$3D,$3D,$3E,$3E
          BYTE           $3E,$3F,$40,$40,$41,$42,$43,$43,$44
          BYTE           $45,$46,$47,$49,$4A,$4B,$4C,$4D,$4F
          BYTE           $50,$52,$53,$55,$56,$58,$59,$5B,$5D
          BYTE           $5F,$60,$62,$64,$66,$68,$6A,$6C,$6E
          BYTE           $70,$72,$74,$76,$78,$7A,$7C,$7F,$81
          BYTE           $83,$85,$87,$8A,$8C,$8E,$90,$93,$95
          BYTE           $97,$99,$9C,$9E,$A0,$A2,$A5,$A7,$A9
          BYTE           $AB,$AD,$B0,$B2,$B4,$B6,$B8,$BA,$BC
          BYTE           $BE,$C0,$C2,$C4,$C6,$C8,$CA,$CC,$CD
          BYTE           $CF,$D1,$D3,$D4,$D6,$D7,$D9,$DA,$DC
          BYTE           $DD,$DF,$E0,$E1,$E2,$E4,$E5,$E6,$E7
          BYTE           $E8,$E9,$E9,$EA,$EB,$EC,$EC,$ED,$EE
          BYTE           $EE,$EE,$EF,$EF,$EF,$F0,$F0,$F0,$F0
          BYTE           $F0,$F0,$F0,$F0



*=$2000 ;"charset_data"
incbin "retromagazine_demo.bin"

map_data
 byte $00,$01,$02,$03,$03,$03,$03,$03,$03,$03,$03,$04,$03,$05,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
 byte $06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f,$10,$11,$12,$13,$14,$15,$00,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f,$20,$21,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
 byte $06,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
 byte $06,$3f,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f,$50,$51,$52,$53,$54,$55,$39,$56,$57,$58,$59,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
 byte $5a,$5b,$5c,$5d,$5e,$03,$5f,$60,$03,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$5f,$6d,$5d,$5d,$6e,$6f,$61,$67,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
 byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03

*=$4000 ;"music"
incbin "retromagfin.sid",126  ;//// rimuove headers non necessari


