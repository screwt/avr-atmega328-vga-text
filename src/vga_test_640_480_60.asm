; COMPILER SETTINGS
.INCLUDE "include/m328Pdef.inc"

; INTERRUPT VECTORS
.org 0x0000                     ;set progamme origin: 0 
    rjmp SETUP

.org oc1aaddr                   ;The vectore of timer0 compare A
    rjmp TIMER_COMPARE_A


SETUP:
    .def LINE_COUNT_L =r24
    .def LINE_COUNT_H =r25
    .def COLOR_MASK =r27
    .def TMP_COUNT =r17
    .def PX_1 =r20
    .def PX_2 =r21
    .def PX_3 =r22
    .def PX_4 =r23
    .def PX_5 =r26
        
    .equ HSYNC =PINB0
    .equ VSYNC =PINB1
    .equ RED =PINC0      ; Red on      
    .equ GREEN =PINC1      ; Green on
    .equ BLUE =PINC2      ; Blue on        
        
    sbi ddrb,HSYNC ; H-SYNC PULSE arduino_PIN: 8
    sbi ddrb,VSYNC ; V-SYNC PULSE arduino_PIN: 9

    sbi ddrc,PINC0 ; RED PULSE   arduino_PIN: A0
    sbi ddrc,PINC1 ; GREEN PULSE arduino_PIN: A1
    sbi ddrc,PINC2 ; BLUE PULSE  arduino_PIN: A2
    sbi ddrc,PINC3 ; TEST LED    arduino_PIN: A3
        
    ; SET TIMER1 TO SCLK WITH RESET
    ldi r16,(1<<CS10 | 1<<WGM12)
    sts tccr1b,r16

    ; SET TIMER1 MATCH A INTERRUPT
    ldi r16,(1<<OCIE1A)
    sts timsk1,r16

    ; SET TIMER1 INTERRUPT TIME A VALUE
    ldi r16,high(499)
    sts ocr1ah,r16
    ldi r16,low(499)
    sts ocr1al,r16
        
    ; TURN ON GLOBAL INTERRUPTS
    sei

    ; clear
    clr TMP_COUNT
    clr LINE_COUNT_L 
    clr LINE_COUNT_H
    ldi COLOR_MASK, 0xff

    sbi PORTB, HSYNC      ; H-SYNC high 
    sbi PORTB, VSYNC      ; V-SYNC high 
    sbi PORTC, PINC0      ; Red on      
    sbi PORTC, PINC1      ; Green on
    cbi PORTC, PINC2      ; Blue on        

    cbi  PORTC, PINC3
MAIN:
    rjmp main        

        

; VIDEO dignal handeling
; BASE res is 640 x 480 @ 60 Hz 
; Vertical refresh 31.46875  kHz
; Pixel freq. 	25.175 MHz

; Horizontal timing (line)        
;               px      µs                 cycles for 16MHz clock (*/2)
; Front porch	16	0.63555114200596   10   (  0 -   9)
; Sync pulse	96	3.8133068520357    60   ( 10 -  69)
; Back porch	48	1.9066534260179    30   ( 70 -  99)
; Visible area	640	25.422045680238    400  (100 - 399)      
; Whole line	800	                   500  (  0 - 399)
                
; Vertical timing (frame)
;               lines   ms
; Visible area	480	12.678095238095     480 * 832 
; Front porch	9	0.23771428571429      9 * 832
; Sync pulse	2	0.052825396825397     2 * 832
; Back porch	29	0.76596825396825     29 * 832
; Whole frame	520	13.734603174603     520 * 832


       
TIMER_COMPARE_A:
    ; This is "called" every time counter 0 reach 832 !!
    ;                                    ; cycles     ; cumul

; LINE        = 400 cycles ========================================
LINE_BEGIN:                              ;;;; 10*40 = 400
    out portc,PX_1                 ; 1          ;   1
    
    out portc,PX_2                 ; 1          ;   1
                                
    out portc,PX_3                 ; 1          ;   1

    out portc,PX_4                 ; 1          ;   1

    out portc,PX_5    
    ;out portc,PX_6                 ; 1          ;   1
    
    inc TMP_COUNT                      ; 1          ;   7        
    cpi TMP_COUNT, 45                  ; 1          ;   8
    brne LINE_BEGIN                      ; 1/2        ;  10  

; H FRONT PORCH = 10 cycles  ========================================
H_FRONT_PORCH:                           ;;;; 10
    ldi r16, 0x00
    out portc, r16
    adiw LINE_COUNT_H:LINE_COUNT_L, 1    ; 2          ; 322
    clr TMP_COUNT                        ; 1          ; 323
    nop                                  ; 1          ; 324
    nop                                  ; 1          ; 325
    nop                                  ; 1          ; 326
    nop                                  ; 1          ; 326
       
        
; H SYNC PULSE  = 60 cycles  ========================================
H_SYNC_PULSE:                              ;;;; 20
    cbi portb, HSYNC                       ; 2        ;  0         ; H-SYNC low
        
    ldi PX_1, 1                             ; 1        ;  1
    ldi PX_2, 2                             ; 1        ;  2
    ldi PX_3, 4                             ; 1        ;  3
    ldi PX_4, 0
        
    ldi  r18, low(480)                     ; 1        ;  7
    ldi  r19, high(480)                    ; 1        ;  8
    cp   r18, LINE_COUNT_L                 ; 1        ;  9
    cpc  r19, LINE_COUNT_H                 ; 1        ; 10
    brne SKIP_NO_VIDEO                     ; 1/2      ; 11 ; line 480=>V-FRONT-PORCH
    nop
SKIP_NO_VIDEO:
    ldi  r18, low(489)                     ; 1        ; 12
    ldi  r19, high(489)                    ; 1        ; 13
    cp   r18, LINE_COUNT_L                 ; 1        ; 14
    cpc  r19, LINE_COUNT_H                 ; 1        ; 15
    brne SKIP_V_SYNC_PULSE                 ; 1/2      ; 17 ; line 488=>V-SYNC_PULSE
    cbi  portb, VSYNC                      ; 0/1      ;      
SKIP_V_SYNC_PULSE:
    ldi  r18, low(491)                     ; 1        ; 18
    ldi  r19, high(491)                    ; 1        ; 19
    cp   r18, LINE_COUNT_L                 ; 1        ; 20
    cpc  r19, LINE_COUNT_H                 ; 1        ; 21
    brne SKIP_V_BACK_PORCH                 ; 1/2      ; 23 ; line 490=>V-BACK---PORCH
    sbi  portb, VSYNC                      ; 0/1      ;        
SKIP_V_BACK_PORCH:
    ldi  r18, low(519)                     ; 1        ; 24
    ldi  r19, high(519)                    ; 1        ; 25
    cp   r18, LINE_COUNT_L                 ; 1        ; 26
    cpc  r19, LINE_COUNT_H                 ; 1        ; 27
    brne SKIP_END_FRAME                    ; 1/2      ; 28 ; line 520=>Frame done
END_FRAME:
    clr  LINE_COUNT_L                      ; 1        ; 29
    clr  LINE_COUNT_H                      ; 1        ; 30
    rjmp H_END_PULSE                       ; 2        ; 32
SKIP_END_FRAME:                 
    nop                                    ; 1        ; 30
    nop                                    ; 1        ; 31
    nop                                    ; 1        ; 32
H_END_PULSE:
    clr TMP_COUNT                          ; 1        ; 33
H_END_PULSE_LOOP:    
    inc TMP_COUNT                          ; 1        ; 34
    nop                                    ; 1        ; 35
    cpi TMP_COUNT,5                        ; 1        ; 36
    brne H_END_PULSE_LOOP                  ; 1/2      ; 38
    mov PX_5, LINE_COUNT_L
    lsr PX_5
    nop
    nop
    nop

        
; H BACK PORCH  = 30 cycles ========================================        
H_BACK_PORCH:                              ;;;; 30
    sbi  portb, HSYNC                           ; 2        ;  2  ; H-SYNC high
    nop
    nop
    reti                                   ; 4
