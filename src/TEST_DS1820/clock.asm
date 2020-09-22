; �������� ��������� ��� ������� ������� DS1820
; ��������� ������ ������� ��������� ����������� � ���������� ��, � ����
; ���� ���� � ���������������� ���� 9600 8N1

; ����� ***********************************************************************

; ��������������� AT90S2313
.INCLUDE	"C:\DOC\AVR\2313def.inc"

; ������� ������
.EQU Fosc = 8000000
; ����������� ���������� ����� � �������� ����� ��������� ������ ��� ���������
.EQU INACTIVE_INTERVAL = 60
; ���������� ������������ ������� ����� ����������� ��������
.EQU AUTO_SPEEDUP_COUNT = 5
; ������ �������� � ������� ������
.EQU SPEED1 = 90
; ������ �������� � ��������� ������ ������
.EQU SPEED2 = 20
; ����� � ����� ��� ��������������� ������������� �������
.EQU BRIGHT_TIME = 8

; ������� ����������� ���������� � ������� ����� �
; ������� ����������� ���������� � ����� D, ������� �������� �������
; ����������� ROW0...ROW3, ��� ROW0 - ������� ������
.EQU ROW0 = $40
.EQU ROW1 = $20
.EQU ROW2 = $10
.EQU ROW3 = $08

; ��������� *******************************************************************
.DEF	ResetType0 = r10; ��� ����������� ���� ����������� (Hard/Soft)
.DEF	ResetType1 = r2
.DEF	ResetType2 = r9  
.DEF	DIG0 = r7	; ����� ������������ �� �������� �����������
.DEF	DIG1 = r5
.DEF	DIG2 = r3
.DEF	DIG3 = r4
.DEF	Cnt1Sec = r6
.DEF	AutoCancelTime = r8
.DEF	BrightUpTimer = r29
.DEF	A = r16
.DEF	B = r17
.DEF	C = r18
.DEF	KeyTimer = r21
.DEF	ScanPos = r19
.DEF	FlashMask = r22
.DEF	ParNum = r25	; ���������: 0-����������� �������, 1-��������� �����,
			; 2-��������� �����, 3-��������� ���
.DEF	Second = r20	; ������� ����� - �������
.DEF	Minute = r26	; ������� ����� - ������
.DEF	Hour = r23	; ������� ����� - ����
.DEF	ParVal = r28
.DEF	Accel = r12
.DEF	Correction = r27 ; �������� �������� ���� ����� � �������� �� �����
.DEF	dsStep = r24

.CSEG

.ORG	0
	RJMP	Reset

; ���������� ����������, ���������� 800 ��� � ������� *************************
; ��� �������� ������ ��������� ����������� �����
.ORG	OC1addr

	PUSH	A
	IN	A,SREG
	PUSH	A
	PUSH	B
	PUSH	B

	ANDI	ParNum,$FF
	BRNE	SetupModeShow
	; ������� ������� �� Hour:Minute � DIG0:DIG1:DIG2:DIG3
	MOV	A,Minute	; ����������� ���������� � ������� ������
	MOV	B,A
	ANDI	A,$0F
	ANDI	B,$F0
	MOV	DIG3,A
	MOV	DIG2,B
	MOV	A,Hour
	MOV	B,A
	ANDI	A,$0F
	ANDI	B,$F0
	MOV	DIG1,A
	MOV	DIG0,B
	SWAP	DIG0
	CLR	FlashMask
	RJMP	L006
SetupModeShow:
	MOV	DIG0,ParNum	; ����������� ���������� � ������ ���������
	LDI	A,$0A
	MOV	DIG1,A
	MOV	A,ParVal
	MOV	B,A
	ANDI	A,$0F
	ANDI	B,$F0
	MOV	DIG3,A
	MOV	DIG2,B
	LDI	FlashMask,ROW1
L006:
	SWAP	DIG2

	; ������� �����������
	LDI	A,$FF
	OUT	PORTB,A
	IN	B,PORTD
	ANDI	B,~(ROW0 | ROW1 | ROW2 | ROW3)
	INC	ScanPos
	ANDI	ScanPos,3
	BRNE	L001
	; ������ 0   +---

	INC	Cnt1sec
	MOV	A,DIG0
	CLR	r0
	CPSE	A,r0
	ORI	B,ROW0
	RJMP	L000
L001:
	CPI	ScanPos,1
	BRNE	L002
	; ������ 1   -+--
	MOV	A,DIG1
	ORI	B,ROW1
	RJMP	L000
L002:
	CPI	ScanPos,2
	BRNE	L003
	; ������ 2   --+-
	MOV	A,DIG2
	ORI	B,ROW2
	RJMP	L000
L003:
	; ������ 3   ---+
	MOV	A,DIG3
	ORI	B,ROW3
L000:

	; ���������� ����������� �������� ��������
	COM	FlashMask
	SBRS	Cnt1sec,5
	AND	B,FlashMask
	COM	FlashMask

	; �������������� ������ ������� � ��� ���������� ���
	LDI	ZH,HIGH(CharTable*2)	; r0 = CharTable[A]
	LDI	ZL,LOW(CharTable*2)
	ADD	ZL,A
	CLR	A
	ADC	ZH,A
	LPM
	COM	r0
	OUT	PORTB,r0
	OUT	PORTD,B

	; ��������� ������� �� ������
	ANDI	ScanPos,3     ; ������������ ������ ������ 4-� ���������
	BRNE	L009
	CPI	KeyTimer,SPEED1
	BRNE	L012
	; ����� ���������� - ������� ����������� ������� �� ������
	SBIS	PIND,0
	RCALL	Key0Pressed
	SBIS	PIND,1
	RCALL	Key1Pressed
	CLR	KeyTimer
	INC	Accel	      ; ���� ������ ������ 5 ������� - �������� ������
	LDI	B,AUTO_SPEEDUP_COUNT
	CP	Accel,B
;;	CPI	Accel,AUTO_SPEEDUP_COUNT
	BRNE	L012
	DEC	Accel         
	LDI	KeyTimer,SPEED1-SPEED2
L012:	SBIC	PIND,0	      ; ���� ������ ������ ���� ������ KeyTimer++
	SBIS	PIND,1	      ; ���� �� ������, �� KeyTimer=0
	RJMP	L010
	LDI	KeyTimer,SPEED1
	CLR	Accel
	RJMP	L009
L010:	INC	KeyTimer
	CLR	AutoCancelTime
L009:

	CPI	BrightUpTimer,0	; ���� ����� ��������� �������
	BREQ	L12G3B		; ��������� �������������� �������� � 
	CLR	A		; ��������� ���������� �� ������ �� ����������
L12G3C:	NOP
	LDI	B,$FF
	DEC	A
	BRNE	L12G3C
	OUT	PORTB,B
L12G3B:


	; ��������� ����� ������� ���������� 1 ��� � �������
	LDI	B,200
	CPSE	Cnt1sec,B
	RJMP	L005
	CLR	Cnt1sec

;	; ������ � �������� ����������� ***************************************
;	INC	dsStep
;	CPI	dsStep,1
;	BRNE	L10LA
;	RCALL	ResetPrecence
;	BRTC	L10LEnd
;	LDI	A,'E'
;	RCALL	uartSendByte
;	DEC	dsStep
;	RJMP	L10LEnd
;L10LA:
;	CPI	dsStep,2
;	BRNE	L10LB
;	; ������� Read ROM
;	LDI	A,$33
;	RCALL	dsSendByte
;
;	RCALL	dsGetByte
;	MOV	A,B
;	RCALL	uartSendByte
;
;	RJMP	L10LEnd
;L10LB:
;	CLR	dsStep
;
;L10LEnd:

	; �������� ������� ��������������� ������ �� ������ ��������
	INC	AutoCancelTime
	LDI	A,INACTIVE_INTERVAL
	CP	A,AutoCancelTime
	BRNE	L015
	TST	Hour	; ���� ����� 0:00 - �������� �� ����������
	BRNE	L13G3A	; ������� ��� ���������� �������� ����� �����������
	TST	Minute
	BREQ	L015
	CLR	Second	; v3
L13G3A:	CLR	ParNum
L015:

	; ���������� �������� ������
	INC	Second		; ���������� ������
	CPI	Second,60
	BRNE	L005
	CLR	Second

	INC	Minute		; ���������� ��������� ������� �����
	MOV	A,Minute
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	L005
	SUBI	Minute,-6
	CPI	Minute,$60	; ���������� �������� ������� �����
	BRNE	L005
	CLR	Minute

	CPI	Hour,$23	; �������� �� ������� ����� �������
	BRNE	L005A
	CLR	Hour

	MOV	Second,Correction	; �������������� Correction �� BCD
	ANDI	Second,$0F		; ������� � ������� � ������ � Second
	MOV	A,Correction
	SWAP	A
	ANDI	A,$0F
	LDI	B,10
L011:	ADD	Second,A
	DEC	B
	BRNE	L011
	LDI	A,50
	SUB	Second,A

	RJMP	L005

L005A:	INC	Hour		; ���������� ��������� ������� �����
	CPI	BrightUpTimer,0	
	BREQ	L13G3B		; ��������� ������� �� ��������� �������
	DEC	BrightUpTimer
L13G3B:	MOV	A,Hour
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	L005
	SUBI	Hour,-6         ; ���������� �������� ������� �����
L005:	POP	C
	POP	B
	POP	A
	OUT	SREG,A
	POP	A
	RETI



; ������� ����������� ��� ��������� ������� �� ������ 0
Key0Pressed:
	INC	ParNum		; ������� ��������� ���������� ���������
	CPI	ParNum,1
	BRNE	L013
	MOV	ParVal,Hour	; ���������� � ���������� �����
	RJMP	L008
L013:
	CPI	ParNum,2
	BRNE	L014
	MOV	Hour,ParVal	; ���������� � ���������� �����
	MOV	ParVal,Minute
	RJMP	L008
L014:
	CPI	ParNum,3
	BRNE	L016
	MOV	Minute,ParVal	; ���������� � ���������� ���
	MOV	ParVal,Correction
	RJMP	L008
L016:	
	CPI	ParNum,4
	BRNE	L016C
	MOV	Correction,ParVal
	CLR	A		; ���������� ��� � EEPROM
	OUT	EEAR,A
	OUT	EEDR,Correction
	SBI	EECR,2
	SBI	EECR,1

	RCALL	GetTemperature

	; �������� ��������� �� �����������
	CPI		A,-127
	BRNE	L23K4A
	LDI	ParVal,$AA	; ������� "--", ���� ������ 
	RJMP	L008
L23K4A:

	; BCD �������������� ����� � ������������
	CLR	B
L016E:	CPI	A,10
	BRCS	L016D
	SUBI	A,10
	SUBI	B,-$10
	RJMP	L016E
L016D:	ADD	A,B
	MOV	ParVal,A

L016B:	
	RJMP	L008

L016C:
	CPI	ParNum,5
	BRNE	L016A
	SET
	RCALL	SetLine
	RJMP	L008

L016A:	CLR	ParNum
	CLR	Second

L008:	RET

; ������� ����������� ��� ��������� ������� �� ������ 1
Key1Pressed:
	CPI	ParNum,0
	BRNE	L12G3A		; ������ ������ � ������ ��������
	CPI	BrightUpTimer,0	; ������������ �������
	LDI	BrightUpTimer,0
	BRNE	L12G3A
	LDI	BrightUpTimer,BRIGHT_TIME
L12G3A:	INC	ParVal		; ���������� ParVal � BCD ����������
	MOV	A,ParVal	; � ����������� �� 99
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	L007
	SUBI	ParVal,-$06
	CPI	ParVal,$A0
	BRNE	L007
	CLR	ParVal
L007:
	CPI	ParNum,1	; ����������� ������������ �������� ����������
	BRNE	L007A
	CPI	ParVal,$24	; ���� ����� 24, ��������
	BRNE	L007B
	CLR	ParVal
	RJMP	L007B
L007A:	CPI	ParNum,2
	BRNE	L007B
	CPI	ParVal,$60	; ���� ������ 60, ��������
	BRNE	L007B
	CLR	ParVal
	RJMP	L007B
L007B:
	RET

.INCLUDE	"ds1820.asm"

; ���� � ��������� ************************************************************
Reset:
	; ������������� ��������� ����� ��������� ���������
	LDI	A,LOW(RAMEND)
	OUT	SPL,A
	; ��������� ���������� ������ ����� ������ B � D
	LDI	A, ROW0 | ROW1 | ROW2 | ROW3
	OUT	DDRD,A
	LDI	A,$FF
	OUT	PORTB,A
	OUT	DDRB,A
	; ��������� ������� � ��� ����������
;	LDI	A,$40	; �������
;	OUT	TIMSK,A
;	LDI	A,$0A
;	OUT	TCCR1B,A
;	LDI	A,HIGH(Fosc/8/800)
;	OUT	OCR1AH,A
;	LDI	A,LOW(Fosc/8/800)
;	OUT	OCR1AL,A


	LDI	A,51	; �������
	OUT	UBRR,A
	LDI	A,8
	OUT	UCR,A	; RXCIE TXCIE UDRIE RXEN TXEN CHR9 RXB8 TXB8


	LDI	A,$37		; �������� ������� �����������
	CP	ResetType0,A
	BRNE	HardwareReset
	LDI	A,$12
	CP	ResetType1,A
	BRNE	HardwareReset
	LDI	A,$F5
	CP	ResetType2,A
	BREQ	SoftwareReset
HardwareReset:
	LDI	A,$37
	MOV	ResetType0,A
	LDI	A,$12
	MOV	ResetType1,A
	LDI	A,$F5
	MOV	ResetType2,A
	CLR	Second		; ��������� ����������
	CLR	Minute
	CLR	Hour
	CLR	ParVal
	CLR	BrightUpTimer
	CLR	A		; ������ ��� �� EEPROM
	OUT	EEAR,A
	SBI	EECR,0
	IN	Correction,EEDR
	CLR	AutoCancelTime
	LDI	ParNum,1

SoftwareReset:

	SEI





; ��������� ���������� ���������� ��� ���������� ���� �����������
	LDI	A,$80
	OUT	ACSR,A
; ��������� ��������������� � ����� Idle
; ������������� ���������, ��� ��������� �������� ����� ���������� � ����������
LoopForever:






	; ������ � �������� ����������� ***************************************
	; �������
	RJMP	DS_CONV_T

DS_LBL:
	RCALL	ResetPrecence
	BRTC	L10LA
	LDI	A,$7F
	RCALL	uartSendByte
	LDI	A,$7F
	RCALL	uartSendByte
	RJMP	L10LEnd
L10LA:

	; ������� Skip ROM
	LDI	B,$CC
	RCALL	dsSendByte

	; ������� Read Scrathcpad
	LDI	B,$BE
	RCALL	dsSendByte

	RCALL	dsGetByte
	MOV	A,B
	RCALL	uartSendByte

	RCALL	dsGetByte
	MOV	A,B
	RCALL	uartSendByte

DS_CONV_T:
	RCALL	ResetPrecence

	; ������� Skip ROM
	LDI	B,$CC
	RCALL	dsSendByte

	; ������� Convert T
	LDI	B,$44
	RCALL	dsSendByte


L10LEnd:
	; �������� �������� �� �������
	LDI	B,16
	LDI	C,0
LLL:	LDI	A,250
	RCALL	Delay_us
	DEC	C
	BRNE	LLL
	DEC	B
	BRNE	LLL

	RJMP	DS_LBL









	LDI	A,$20
	OUT	MCUCR,A
	SLEEP
	RJMP	LoopForever

; �������
; �������� ����� A � ��� ���� **************************************************
uartSendByte:
	SBIS		USR,5
	RJMP		uartSendByte
	OUT		UDR,A
	RET	


CharTable:
.DB	0b11010111,0b10000001,0b11001110,0b11001011,0b10011001,0b01011011,0b01011111,0b11000001,0b11011111,0b11011011,0b00001000
;       0         1           2           3          4          5          6          7           8         9          -

.EXIT
 