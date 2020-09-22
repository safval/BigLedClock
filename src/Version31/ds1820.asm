; Фукнции для работы с датчиком температуры ***********************************
; Команды нижнего уровня протокола микросхемы DS1820. *************************
; (C) 2004-2005 Валентин Сафонников valentin@mne.ru ***************************
; http://svv.on.ufanet.ru *****************************************************
; *****************************************************************************


; задержка на указаное в регистре А число микросекунд *************************
; функция только при работе с кварцем 8 МГц
; точность не хуже 5%
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

; выбор состояния линии подключеной к микросхеме DS1820 ***********************
; Микросхема DS1820 подключена к выводу PD.2
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


; чтение одного байта (В) из микросхемы ***************************************
; мл. бит принимается первым
; USE:	A,B,C
dsGetByte:
	LDI	C,8
	CLR	B
ReadNextSlot:
	LSR	B
	CLI
	CLT
	RCALL	SetLine		; нулевой импульс длиной более 1 мкс
	LDI	A,3
	RCALL	Delay_us
	SET
	RCALL	SetLine		; ожидание до 15 мкс для чтения бита от микросхемы
	LDI	A,10
	RCALL	Delay_us
	SBIC	PIND,2
	ORI	B,$80
	SEI
	RCALL	SetLine		; единичный импульс 60 мкс для окончания цикла чтения бита
	LDI	A,75
	RCALL	Delay_us
	DEC	C
	BRNE	ReadNextSlot
	RET



; отправка одного байта (В) в микросхему (DS1820.pdf стр. 18) *****************
; USE:	A,B,C
dsSendByte:
	LDI	C,8
L6I4A:
	CLI
	CLT
	RCALL	SetLine		; нулевой импульс длиной:
	LDI	A,5		; 1...15 (5) мкс для записи единицы
	SBRS	B,0		; 60..120 (90) мкс для записи нуля 
	LDI	A,90
	RCALL	Delay_us
	SET
	RCALL	SetLine		; единичный импульс для синхронизации
	SEI
	LDI	A,90
	SBRS	B,0
	LDI	A,5
	RCALL	Delay_us
	LSR	B
	DEC	C
	BRNE	L6I4A
	RET


; проверка наличия хотя бы одной микросхемы на шине ***************************
; если микросхема найдена, на выходе из функции T=0, не найдена T=1
; USE: A
ResetPrecence:
	SET
	RCALL	SetLine		; установка единицы на шине
	LDI	A,255
	RCALL	Delay_us
	SBIS	PIND,2		; проверка единицы, если ноль - выходим с Т=1
	RET
	CLI
	CLT
	RCALL	SetLine		; отправка RESET PULSE в шину
	LDI	A,190		; нулевой импульс длиной от 480 до 960 мкс
	RCALL	Delay_us
	LDI	A,190
	RCALL	Delay_us
	LDI	A,190
	RCALL	Delay_us
	SET
	RCALL	SetLine		; ожидание PRESENCE PULSE, он приходит через
	LDI	A,100		; 15...60 мкс, его длительность 60...240 мкс
	RCALL	Delay_us
	IN	A,PIND		; должен быть ноль - ответ микросхемы
	BST	A,2
	SEI
	LDI	A,250		; ждем окончание PRESENCE PULSE 
	RCALL	Delay_us
	RET

; *****************************************************************************
; Измерение и чтение температуры с микросхемы *********************************
; Функция возвращает температуру в градусах в регистре А, или -127 при ошибке
;GetTemperature:
;
;	; перезапуск микросхемы
;	RCALL	ResetPrecence
;	BRTS	L6I4Err
;
;	; Команда Skip ROM
;	LDI	A,$CC
;	RCALL	dsSendByte
;
;	; Команда Convert T
;	LDI	A,$44
;	RCALL	dsSendByte
;
;	; ожидание завершения измерения температуры
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
;	; перезапуск микросхемы
;	RCALL	ResetPrecence
;	BRTS	L6I4Err
;
;	; Команда Skip ROM
;	LDI	A,$CC
;	RCALL	dsSendByte
;
;	; Команда Read Scratchpad
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
;	; возвращаем температуру в регистре А
;	POP	A
;	RET
;
;L6I4Err:
;	; выход при обнаружении ошибки
;	LDI	A,-127
;	RET
