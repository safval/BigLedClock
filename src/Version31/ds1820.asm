; ������� ��� ������ � �������� ����������� ***********************************
; ������� ������� ������ ��������� ���������� DS1820. *************************
; (C) 2004-2005 �������� ���������� valentin@mne.ru ***************************
; http://svv.on.ufanet.ru *****************************************************
; *****************************************************************************


; �������� �� �������� � �������� � ����� ����������� *************************
; ������� ������ ��� ������ � ������� 8 ���
; �������� �� ���� 5%
; USE:	A
Delay_us:
	NOP
	NOP
	NOP
	NOP
	NOP
	DEC	A
	BRNE	Delay_us
	RET

; ����� ��������� ����� ����������� � ���������� DS1820 ***********************
; ���������� DS1820 ���������� � ������ PD.2
; USE:	A
SetLine:
	IN	A,DDRD
	ANDI	A,$FB
	BRTS	SL1
	ORI	A,$04
	CBI	PORTD,2
SL1:
	OUT	DDRD,A
	RET


; ������ ������ ����� (�) �� ���������� ***************************************
; ��. ��� ����������� ������
; USE:	A,B,C
dsGetByte:
	LDI	C,8
	CLR	B
ReadNextSlot:
	LSR	B
	CLI
	CLT
	RCALL	SetLine		; ������� ������� ������ ����� 1 ���
	LDI	A,3
	RCALL	Delay_us
	SET
	RCALL	SetLine		; �������� �� 15 ��� ��� ������ ���� �� ����������
	LDI	A,10
	RCALL	Delay_us
	SBIC	PIND,2
	ORI	B,$80
	SEI
	RCALL	SetLine		; ��������� ������� 60 ��� ��� ��������� ����� ������ ����
	LDI	A,75
	RCALL	Delay_us
	DEC	C
	BRNE	ReadNextSlot
	RET



; �������� ������ ����� (�) � ���������� (DS1820.pdf ���. 18) *****************
; USE:	A,B,C
dsSendByte:
	LDI	C,8
L6I4A:
	CLI
	CLT
	RCALL	SetLine		; ������� ������� ������:
	LDI	A,5		; 1...15 (5) ��� ��� ������ �������
	SBRS	B,0		; 60..120 (90) ��� ��� ������ ���� 
	LDI	A,90
	RCALL	Delay_us
	SET
	RCALL	SetLine		; ��������� ������� ��� �������������
	SEI
	LDI	A,90
	SBRS	B,0
	LDI	A,5
	RCALL	Delay_us
	LSR	B
	DEC	C
	BRNE	L6I4A
	RET


; �������� ������� ���� �� ����� ���������� �� ���� ***************************
; ���� ���������� �������, �� ������ �� ������� T=0, �� ������� T=1
; USE: A
ResetPrecence:
	SET
	RCALL	SetLine		; ��������� ������� �� ����
	LDI	A,255
	RCALL	Delay_us
	SBIS	PIND,2		; �������� �������, ���� ���� - ������� � �=1
	RET
	CLI
	CLT
	RCALL	SetLine		; �������� RESET PULSE � ����
	LDI	A,190		; ������� ������� ������ �� 480 �� 960 ���
	RCALL	Delay_us
	LDI	A,190
	RCALL	Delay_us
	LDI	A,190
	RCALL	Delay_us
	SET
	RCALL	SetLine		; �������� PRESENCE PULSE, �� �������� �����
	LDI	A,100		; 15...60 ���, ��� ������������ 60...240 ���
	RCALL	Delay_us
	IN	A,PIND		; ������ ���� ���� - ����� ����������
	BST	A,2
	SEI
	LDI	A,250		; ���� ��������� PRESENCE PULSE 
	RCALL	Delay_us
	RET

; *****************************************************************************
; ��������� � ������ ����������� � ���������� *********************************
; ������� ���������� ����������� � �������� � �������� �, ��� -127 ��� ������
;GetTemperature:
;
;	; ���������� ����������
;	RCALL	ResetPrecence
;	BRTS	L6I4Err
;
;	; ������� Skip ROM
;	LDI	A,$CC
;	RCALL	dsSendByte
;
;	; ������� Convert T
;	LDI	A,$44
;	RCALL	dsSendByte
;
;	; �������� ���������� ��������� �����������
;	CLI
;	LDI	B,30
;L016G:	LDI	C,255
;L016F:	LDI	A,255
;	RCALL	Delay_us
;	DEC	C
;	BRNE	L016F
;	DEC	B
;	BRNE	L016G
;	SEI
;
;
;L6I4ConvCompl:
;	; ���������� ����������
;	RCALL	ResetPrecence
;	BRTS	L6I4Err
;
;	; ������� Skip ROM
;	LDI	A,$CC
;	RCALL	dsSendByte
;
;	; ������� Read Scratchpad
;	LDI	A,$BE
;	RCALL	dsSendByte
;
;	RCALL	dsGetByte
;	PUSH	B
;	RCALL	dsGetByte
;	RCALL	dsGetByte
;	RCALL	dsGetByte
;	RCALL	dsGetByte
;	RCALL	dsGetByte
;	RCALL	dsGetByte
;	RCALL	dsGetByte
;	RCALL	dsGetByte
;	RCALL	ResetPrecence
;
;	; ���������� ����������� � �������� �
;	POP	A
;	RET
;
;L6I4Err:
;	; ����� ��� ����������� ������
;	LDI	A,-127
;	RET
