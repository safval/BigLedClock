; ��������� �����

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
; ����� ����� ������ ����������� �����-�����������
.EQU TEMPERATURE_AUTOSWICH_TIME = 5

; ������� ����������� ���������� � ������� ����� �
; ������� ����������� ���������� � ����� D, ������� �������� �������
; ����������� ROW0...ROW3, ��� ROW0 - ������� ������
.EQU ROW0 = $40
.EQU ROW1 = $20
.EQU ROW2 = $10
.EQU ROW3 = $08

; ��������� � ��� *************************************************************
;.DEF	ResetType0 = r10; ��� ����������� ���� ����������� (Hard/Soft)
;.DEF	ResetType1 = r2
;.DEF	ResetType2 = r9  
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
.DEF	TrmMode = r24   ; ���������� ��� ���������� �������� ����������.
			; ������� ��� - ����� (0-�����, 1-�����������), 6
			; ������� ��� - ���������� � �������� ����� ��
			; ������������ ������

; ���������� � SRAM ***********************************************************
.EQU	Temperature = $60
.EQU	ResetType0 = $61; ��� ����������� ���� ����������� (Hard/Soft)
.EQU	ResetType1 = $62
.EQU	ResetType2 = $63  
.EQU	Temperature_sign = $64
.CSEG

; ������ ��������� ************************************************************
.ORG	0
	RJMP	Reset

; ���������� ���������� ������� 1, ���������� ��� � ������� *******************
.ORG	OVF1addr
	RJMP	Int1s

; ���������� ���������� ������� 0, ���������� 800 ��� � ������� ***************
.ORG	OVF0addr
	RJMP	Int800

.ORG	$100
Int800:
	PUSH	A
	IN	A,SREG
	PUSH	A
	PUSH	B
	PUSH	C

	LDI	A,217
	OUT	TCNT0,A

	ANDI	ParNum,$FF
	BRNE	SetupModeShow

	SBRC	TrmMode,7
	RJMP	TermoModeShow
	
	; ����������� ���������� � ������� ������ *****************************
	MOV	A,Minute	; ������� ������� �� Hour:Minute
	MOV	B,A		; � DIG0:DIG1:DIG2:DIG3
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
	SWAP	DIG2
	RJMP	L006

TermoModeShow:
	; ����������� ���������� � ����������� ********************************
	CLR	FlashMask
	LDS	A,Temperature_sign
	MOV	DIG0,A
	CPI	A,$0B
	BREQ	L27LB
	LDS	A,Temperature	; ������������� �����������
	ANDI	A,$F0
	BREQ	L27LB
	SWAP	A		; ����������� �����������
	MOV	DIG1,A		; => ������� � ������� ["-"][��� �����]["C"]
	LDS	A,Temperature
	ANDI	A,$0F
	MOV	DIG2,A
	LDI	A,$0C
	MOV	DIG3,A		; ������ "�"
	RJMP	L006
L27LB:               		; ����������� �� -9 �� +99
	; => ������� � ������� [��� ����� ��� ������ �����]["C"]
	LDS	A,Temperature	; ������� ������ ������������� �����������
	ANDI	A,$F0
	BREQ	L27L�
	SWAP	A
	MOV	DIG0,A
L27L�:	LDS	A,Temperature	; ������� ������ �����������
	ANDI	A,$0F
	MOV	DIG1,A
	LDI	A,$0C
	MOV	DIG2,A		; ������ "�"
	LDI	A,$0B
	MOV	DIG3,A		; ������ " "
	RJMP	L006

	; ����������� ���������� � ������ ��������� ***************************
SetupModeShow:
	MOV	DIG0,ParNum
	LDI	A,$0A
	MOV	DIG1,A
	MOV	A,ParVal
	MOV	B,A
	ANDI	A,$0F
	ANDI	B,$F0
	MOV	DIG3,A
	MOV	DIG2,B
	LDI	FlashMask,ROW1
	SWAP	DIG2
L006:

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

	CPI	ScanPos,1
	BRNE	L27L4D
	MOV	A,Cnt1sec
	CPI	A,100
	BRCC	L27L4D
	ANDI	ParNum,$FF
	BRNE	L27L4D
	SBRC	TrmMode,7
	RJMP	L27L4D
	LDI	A,0b00100000
	OR	r0,A
L27L4D:

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

	; ���������� Cnt1sec ���������� �� 0 �� 200 ������ �������
	LDI	B,200
	CPSE	Cnt1sec,B
	RJMP	EndInterrupt
	CLR	Cnt1sec
	RJMP	EndInterrupt


; ��������� ���������� ********************************************************
Int1s:
	PUSH	A
        LDI	A,$85	; E1
        OUT	TCNT1H,A
        LDI	A,$ED	; 7C
        OUT	TCNT1L,A
	IN	A,SREG
	PUSH	A
	PUSH	B
	PUSH	C

	; ���� ������� ��� ������������ ������ ����������� �����/�����������
	DEC	TrmMode
	MOV	A,TrmMode
	ANDI	A,$3F
	BRNE	L27L4A
	INC	TrmMode
	LDI	A,$80
	EOR	TrmMode,A
	ORI	TrmMode,TEMPERATURE_AUTOSWICH_TIME
L27L4A:

;	; �������� ������� ��������������� ������ �� ������ ��������
;	INC	AutoCancelTime
;	LDI	A,INACTIVE_INTERVAL
;	CP	A,AutoCancelTime
;	BRNE	L015
;	TST	Hour	; ���� ����� 0:00 - �������� �� ����������
;	BRNE	L13G3A	; ������� ��� ���������� �������� ����� �����������
;	TST	Minute
;	BREQ	L015
;	CLR	Second	; v3
;L13G3A:	CLR	ParNum
;L015:

	; ���������� �������� ������
	INC	Second		; ���������� ������
	CPI	Second,60
	BRNE	EndInterrupt
	CLR	Second

	INC	Minute		; ���������� ��������� ������� �����
	MOV	A,Minute
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	EndInterrupt
	SUBI	Minute,-6
	CPI	Minute,$60	; ���������� �������� ������� �����
	BRNE	EndInterrupt
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
	RJMP	EndInterrupt

L005A:	INC	Hour		; ���������� ��������� ������� �����
	CPI	BrightUpTimer,0	
	BREQ	L13G3B		; ���������� ������� �� ��������� �������
	DEC	BrightUpTimer
L13G3B:	MOV	A,Hour
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	EndInterrupt
	SUBI	Hour,-6         ; ���������� �������� ������� �����

EndInterrupt:
	POP	C
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
	MOV	Correction,ParVal
	CLR	A		; ���������� ��� � EEPROM
	OUT	EEAR,A
	OUT	EEDR,Correction
	SBI	EECR,2
	SBI	EECR,1
	CLR	Second
	CLR	ParNum
	LDI	TrmMode,$5

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

	; ��������� ������� 0
	LDI	A,$04	; �������� 256
	OUT	TCCR0,A

	; ��������� ������� 1
	LDI	A,$04	; �������� 256
	OUT	TCCR1B,A
;	LDI	A,$7A
;	OUT	OCR1AH,A; ����� ��� 31250
;	LDI	A,$12
;	OUT	OCR1AL,A

	; ���������� ���������� ��������
	LDI	A,$82
	OUT	TIMSK,A


	LDS	A,ResetType0		; �������� ������� �����������
	CPI	A,$37
	BRNE	HardwareReset
	LDS	A,ResetType1
	CPI	A,$12
	BRNE	HardwareReset
	LDS	A,ResetType2
	CPI	A,$F5
	BREQ	SoftwareReset
HardwareReset:
	LDI	A,$37
	STS	ResetType0,A
	LDI	A,$12
	STS	ResetType1,A
	LDI	A,$F5
	STS	ResetType2,A
	
	CLR	Second		; ��������� ����������
	CLR	Minute
	CLR	Hour
	CLR	ParVal
	CLR	BrightUpTimer
	CLR	A		; ������ ��� �� EEPROM
	OUT	EEAR,A
	SBI	EECR,0
	IN	Correction,EEDR
	CPI	Correction,$FF
	BRNE	L27L4E
	LDI	Correction,$50
L27L4E:	CLR	AutoCancelTime
	LDI	ParNum,1

SoftwareReset:
	SEI

	; ��������� ���������� ���������� ��� ���������� ���� �����������
	LDI	A,$80
	OUT	ACSR,A

	; ������������� ���������


	; ������ � �������� ����������� ***************************************
	RJMP	DS_CONV_T
DS_LBL:
	RCALL	ResetPrecence
	BRTC	L10LA
	LDI	TrmMode,$3F	; ���� ������� 1820 ��� - ���������� �����
	LDI	B,1
	LDI	C,0
	RJMP	LLL

L10LA:

	; ������� Skip ROM
	LDI	B,$CC
	RCALL	dsSendByte

	; ������� Read Scrathcpad
	LDI	B,$BE
	RCALL	dsSendByte
	RCALL	dsGetByte
	MOV	A,B
	PUSH	B
	RCALL	dsGetByte
	MOV	A,B

	; ������������ ������� ����� �����������
	POP	A
	SWAP	A
	SWAP	B
	ANDI	A,$0F
	ANDI	B,$F0
	OR	A,B

	; ���� ������������� �����������
	LDI	B,$0B	; " "
	SBRC	A,7
	LDI	B,$0A	; "-"	; ��� ����������� ���������� �����
	STS	Temperature_sign,B
	SBRC	A,7
	NEG	A		; ������ ����� �������������

	; BCD �������������� ����� � ������������
	CLR	B
L016E:	CPI	A,10
	BRCS	L016D
	SUBI	A,10
	SUBI	B,-$10
	RJMP	L016E
L016D:	ADD	A,B
	STS	Temperature,A

	SBRC	TrmMode,5	; ���� ������ ��������� ����� ������
	LDI	TrmMode,$9E	; ���������� ����������� � ������� 30 ������

	; ������ ��������� ����������� � �������, �������� ����� 750 ��
DS_CONV_T:
	RCALL	ResetPrecence
	BRTS	DS_LBL

	; ������� Skip ROM
	LDI	B,$CC
	RCALL	dsSendByte

	; ������� Convert T
	LDI	B,$44
	RCALL	dsSendByte

	; �������� �������� �� 2 �
	LDI	B,12
	LDI	C,0
LLL:	LDI	A,$20
	OUT	MCUCR,A	; ��������� ��������������� � ����� Idle
	SLEEP		; ���������� ���������� ����� 1.25 ��

;;;	RJMP	LLL	; �������

	DEC	C
	BRNE	LLL	; ����� �� ����� ������ 0.32 c
	DEC	B
	BRNE	LLL

	RJMP	DS_LBL


; �������
; �������� ����� A � ��� ���� **************************************************
;uartSendByte:
;	SBIS		USR,5
;	RJMP		uartSendByte
;	OUT		UDR,A
;	RET	


CharTable:
.DB	0b11010111,0b10000001,0b11001110,0b11001011,0b10011001,0b01011011,0b01011111,0b11000001,0b11011111,0b11011011,0b00001000,0b00000000,0b01010110
;       0         1           2           3          4          5          6          7           8         9          -         " "         C

.EXIT
 