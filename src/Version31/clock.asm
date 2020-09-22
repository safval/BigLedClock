; Программа часов

; Схема ***********************************************************************

; микроконтроллер AT90S2313
.INCLUDE	"C:\DOC\AVR\2313def.inc"

; частота кварца
.EQU Fosc = 8000000
; максимально допустимое время в секундах между нажатиями клавиш при настройке
.EQU INACTIVE_INTERVAL = 60
; количество автоповторов нажатия перед увеличением скорости
.EQU AUTO_SPEEDUP_COUNT = 5
; период повторов в обычном режиме
.EQU SPEED1 = 90
; период повторов в ускореном режиме режиме
.EQU SPEED2 = 20
; время в часах для автоматического востановления яркости
.EQU BRIGHT_TIME = 8
; время смены режима отображения время-температура
.EQU TEMPERATURE_AUTOSWICH_TIME = 5

; сегмены индикаторов подключены к выводам порта В
; разряды индикаторов подключены к порту D, порядок разрядов задаетя
; константами ROW0...ROW3, где ROW0 - старший разряд
.EQU ROW0 = $40
.EQU ROW1 = $20
.EQU ROW2 = $10
.EQU ROW3 = $08

; Перменные в РОН *************************************************************
;.DEF	ResetType0 = r10; Для определения типа перезапуска (Hard/Soft)
;.DEF	ResetType1 = r2
;.DEF	ResetType2 = r9  
.DEF	DIG0 = r7	; Цифры отображаемые на разрядах индикаторах
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
.DEF	ParNum = r25	; состояние: 0-отображение времени, 1-установка часов,
			; 2-установка минут, 3-установка ЦПХ
.DEF	Second = r20	; текущее вермя - секунды
.DEF	Minute = r26	; текущее вермя - минуты
.DEF	Hour = r23	; текущее вермя - часы
.DEF	ParVal = r28
.DEF	Accel = r12
.DEF	Correction = r27 ; Цифровая поправка хода часов в секундах за сутки
.DEF	TrmMode = r24   ; Переменная для управления режимами термометра.
			; Старший бит - режим (0-время, 1-температура), 6
			; младших бит - оставшееся в секундах время до
			; переключения режима

; Переменные в SRAM ***********************************************************
.EQU	Temperature = $60
.EQU	ResetType0 = $61; Для определения типа перезапуска (Hard/Soft)
.EQU	ResetType1 = $62
.EQU	ResetType2 = $63  
.EQU	Temperature_sign = $64
.CSEG

; Начало программы ************************************************************
.ORG	0
	RJMP	Reset

; Обработчик прерывания таймера 1, вызывается раз в секунду *******************
.ORG	OVF1addr
	RJMP	Int1s

; Обработчик прерывания таймера 0, вызывается 800 раз в секунду ***************
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
	
	; отображение информации в обычном режиме *****************************
	MOV	A,Minute	; перенос времени из Hour:Minute
	MOV	B,A		; в DIG0:DIG1:DIG2:DIG3
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
	; отображение информации о температуре ********************************
	CLR	FlashMask
	LDS	A,Temperature_sign
	MOV	DIG0,A
	CPI	A,$0B
	BREQ	L27LB
	LDS	A,Temperature	; отрицательная температура
	ANDI	A,$F0
	BREQ	L27LB
	SWAP	A		; двухзначаня температура
	MOV	DIG1,A		; => выводим в формате ["-"][две цифры]["C"]
	LDS	A,Temperature
	ANDI	A,$0F
	MOV	DIG2,A
	LDI	A,$0C
	MOV	DIG3,A		; Символ "С"
	RJMP	L006
L27LB:               		; температура от -9 до +99
	; => выводим в формате [две цифры или пробел цифра]["C"]
	LDS	A,Temperature	; старший разряд положительной температуры
	ANDI	A,$F0
	BREQ	L27LС
	SWAP	A
	MOV	DIG0,A
L27LС:	LDS	A,Temperature	; младший разряд температуры
	ANDI	A,$0F
	MOV	DIG1,A
	LDI	A,$0C
	MOV	DIG2,A		; Символ "С"
	LDI	A,$0B
	MOV	DIG3,A		; Символ " "
	RJMP	L006

	; отображение информации в режиме настройки ***************************
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

	; гашение индикаторов
	LDI	A,$FF
	OUT	PORTB,A
	IN	B,PORTD
	ANDI	B,~(ROW0 | ROW1 | ROW2 | ROW3)
	INC	ScanPos
	ANDI	ScanPos,3
	BRNE	L001
	; разряд 0   +---

	INC	Cnt1sec
	MOV	A,DIG0
	CLR	r0
	CPSE	A,r0
	ORI	B,ROW0
	RJMP	L000
L001:
	CPI	ScanPos,1
	BRNE	L002
	; разряд 1   -+--
	MOV	A,DIG1
	ORI	B,ROW1
	RJMP	L000
L002:
	CPI	ScanPos,2
	BRNE	L003
	; разряд 2   --+-
	MOV	A,DIG2
	ORI	B,ROW2
	RJMP	L000
L003:
	; разряд 3   ---+
	MOV	A,DIG3
	ORI	B,ROW3
L000:

	; отключение отображения мигающих символов
	COM	FlashMask
	SBRS	Cnt1sec,5
	AND	B,FlashMask
	COM	FlashMask

	; преобразование номера символа в его сегментный код
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

	; обработка нажатий на кнопки
	ANDI	ScanPos,3     ; обрабатываем только каждое 4-е обращение
	BRNE	L009
	CPI	KeyTimer,SPEED1
	BRNE	L012
	; время подходящее - вызваем обработчики нажатий на кнопки
	SBIS	PIND,0
	RCALL	Key0Pressed
	SBIS	PIND,1
	RCALL	Key1Pressed
	CLR	KeyTimer
	INC	Accel	      ; если прошло больше 5 нажатий - ускоряем повтор
	LDI	B,AUTO_SPEEDUP_COUNT
	CP	Accel,B
;;	CPI	Accel,AUTO_SPEEDUP_COUNT
	BRNE	L012
	DEC	Accel         
	LDI	KeyTimer,SPEED1-SPEED2
L012:	SBIC	PIND,0	      ; если нажата хотябы одна кнопка KeyTimer++
	SBIS	PIND,1	      ; если не нажата, то KeyTimer=0
	RJMP	L010
	LDI	KeyTimer,SPEED1
	CLR	Accel
	RJMP	L009
L010:	INC	KeyTimer
	CLR	AutoCancelTime
L009:

	CPI	BrightUpTimer,0	; если режим пониженой яркости
	BREQ	L12G3B		; выполняем дополнительную задержку и 
	CLR	A		; отключаем индикаторы до выхода из прерывания
L12G3C:	NOP
	LDI	B,$FF
	DEC	A
	BRNE	L12G3C
	OUT	PORTB,B
L12G3B:

	; переменная Cnt1sec изменяется от 0 до 200 каждую секунду
	LDI	B,200
	CPSE	Cnt1sec,B
	RJMP	EndInterrupt
	CLR	Cnt1sec
	RJMP	EndInterrupt


; Секундное прерывание ********************************************************
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

	; счет времени для переключения режима отображения время/температура
	DEC	TrmMode
	MOV	A,TrmMode
	ANDI	A,$3F
	BRNE	L27L4A
	INC	TrmMode
	LDI	A,$80
	EOR	TrmMode,A
	ORI	TrmMode,TEMPERATURE_AUTOSWICH_TIME
L27L4A:

;	; проверка времени автоматического выхода из режима настроек
;	INC	AutoCancelTime
;	LDI	A,INACTIVE_INTERVAL
;	CP	A,AutoCancelTime
;	BRNE	L015
;	TST	Hour	; если время 0:00 - возврата не произойдет
;	BRNE	L13G3A	; сделано для блокировки возврата после перезапуска
;	TST	Minute
;	BREQ	L015
;	CLR	Second	; v3
;L13G3A:	CLR	ParNum
;L015:

	; увеличение счетчика времни
	INC	Second		; увеличение секунд
	CPI	Second,60
	BRNE	EndInterrupt
	CLR	Second

	INC	Minute		; увеличение младьшего разряда минут
	MOV	A,Minute
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	EndInterrupt
	SUBI	Minute,-6
	CPI	Minute,$60	; увеличение старшего разряда минут
	BRNE	EndInterrupt
	CLR	Minute

	CPI	Hour,$23	; проверка на переход через полночь
	BRNE	L005A
	CLR	Hour

	MOV	Second,Correction	; преобразование Correction из BCD
	ANDI	Second,$0F		; формата в обычный и запись в Second
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

L005A:	INC	Hour		; увеличение младьшего разряда часов
	CPI	BrightUpTimer,0	
	BREQ	L13G3B		; уменьшение времени до изменения яркости
	DEC	BrightUpTimer
L13G3B:	MOV	A,Hour
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	EndInterrupt
	SUBI	Hour,-6         ; увеличение старшего разряда часов

EndInterrupt:
	POP	C
	POP	B
	POP	A
	OUT	SREG,A
	POP	A
	RETI



; Функция вызываетеся для обработки нажатия на кнопку 0
Key0Pressed:
	INC	ParNum		; перебор доступных параметнов настройки
	CPI	ParNum,1
	BRNE	L013
	MOV	ParVal,Hour	; подготовка к обновлению часов
	RJMP	L008
L013:
	CPI	ParNum,2
	BRNE	L014
	MOV	Hour,ParVal	; подготовка к обновлению минут
	MOV	ParVal,Minute
	RJMP	L008
L014:
	CPI	ParNum,3
	BRNE	L016
	MOV	Minute,ParVal	; подготовка к обновлению ЦПХ
	MOV	ParVal,Correction
	RJMP	L008
L016:	
	MOV	Correction,ParVal
	CLR	A		; сохранение ЦПХ в EEPROM
	OUT	EEAR,A
	OUT	EEDR,Correction
	SBI	EECR,2
	SBI	EECR,1
	CLR	Second
	CLR	ParNum
	LDI	TrmMode,$5

L008:	RET

; Функция вызываетеся для обработки нажатия на кнопку 1
Key1Pressed:
	CPI	ParNum,0
	BRNE	L12G3A		; кнопка нажата в режиме ожидания
	CPI	BrightUpTimer,0	; переключение яркости
	LDI	BrightUpTimer,0
	BRNE	L12G3A
	LDI	BrightUpTimer,BRIGHT_TIME
L12G3A:	INC	ParVal		; увеличение ParVal с BCD коррекцией
	MOV	A,ParVal	; и ограниченем до 99
	ANDI	A,$0F
	CPI	A,$0A
	BRNE	L007
	SUBI	ParVal,-$06
	CPI	ParVal,$A0
	BRNE	L007
	CLR	ParVal
L007:
	CPI	ParNum,1	; ограничение максимальных значений параметров
	BRNE	L007A
	CPI	ParVal,$24	; если часов 24, обнуляем
	BRNE	L007B
	CLR	ParVal
	RJMP	L007B
L007A:	CPI	ParNum,2
	BRNE	L007B
	CPI	ParVal,$60	; если секунд 60, обнуляем
	BRNE	L007B
	CLR	ParVal
	RJMP	L007B
L007B:
	RET

.INCLUDE	"ds1820.asm"

; Вход в программу ************************************************************
Reset:
	; инициализация указателя стека начальным значением
	LDI	A,LOW(RAMEND)
	OUT	SPL,A

	; настройка направленя работы линий портов B и D
	LDI	A, ROW0 | ROW1 | ROW2 | ROW3
	OUT	DDRD,A
	LDI	A,$FF
	OUT	PORTB,A
	OUT	DDRB,A

	; настройка таймера 0
	LDI	A,$04	; делитель 256
	OUT	TCCR0,A

	; настройка таймера 1
	LDI	A,$04	; делитель 256
	OUT	TCCR1B,A
;	LDI	A,$7A
;	OUT	OCR1AH,A; сброс при 31250
;	LDI	A,$12
;	OUT	OCR1AL,A

	; разрешение прерывания таймеров
	LDI	A,$82
	OUT	TIMSK,A


	LDS	A,ResetType0		; проверка причины перезапуска
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
	
	CLR	Second		; обнуление переменных
	CLR	Minute
	CLR	Hour
	CLR	ParVal
	CLR	BrightUpTimer
	CLR	A		; чтение ЦПХ из EEPROM
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

	; выключаем аналоговый компаратор для уменьшения тока потребления
	LDI	A,$80
	OUT	ACSR,A

	; инициализация завершена


	; Работа с датчиком температуры ***************************************
	RJMP	DS_CONV_T
DS_LBL:
	RCALL	ResetPrecence
	BRTC	L10LA
	LDI	TrmMode,$3F	; если датчика 1820 нет - показываем время
	LDI	B,1
	LDI	C,0
	RJMP	LLL

L10LA:

	; Команда Skip ROM
	LDI	B,$CC
	RCALL	dsSendByte

	; Команда Read Scrathcpad
	LDI	B,$BE
	RCALL	dsSendByte
	RCALL	dsGetByte
	MOV	A,B
	PUSH	B
	RCALL	dsGetByte
	MOV	A,B

	; Отбрасывание дробной части температуры
	POP	A
	SWAP	A
	SWAP	B
	ANDI	A,$0F
	ANDI	B,$F0
	OR	A,B

	; Учет отрицательной температуры
	LDI	B,$0B	; " "
	SBRC	A,7
	LDI	B,$0A	; "-"	; при отображении показываем минус
	STS	Temperature_sign,B
	SBRC	A,7
	NEG	A		; делаем число положительным

	; BCD преобразование байта с температурой
	CLR	B
L016E:	CPI	A,10
	BRCS	L016D
	SUBI	A,10
	SUBI	B,-$10
	RJMP	L016E
L016D:	ADD	A,B
	STS	Temperature,A

	SBRC	TrmMode,5	; Если первое измерение после ошибки
	LDI	TrmMode,$9E	; показываем температуру в течении 30 секунд

	; Запуск изменения температуры в датчике, занимает около 750 мс
DS_CONV_T:
	RCALL	ResetPrecence
	BRTS	DS_LBL

	; Команда Skip ROM
	LDI	B,$CC
	RCALL	dsSendByte

	; Команда Convert T
	LDI	B,$44
	RCALL	dsSendByte

	; Задержка примерно на 2 с
	LDI	B,12
	LDI	C,0
LLL:	LDI	A,$20
	OUT	MCUCR,A	; переводим микроконтроллер в режим Idle
	SLEEP		; прерывания вызываются через 1.25 мс

;;;	RJMP	LLL	; отладка

	DEC	C
	BRNE	LLL	; выход из цикла каждые 0.32 c
	DEC	B
	BRNE	LLL

	RJMP	DS_LBL


; отладка
; Отправка байта A в СОМ порт **************************************************
;uartSendByte:
;	SBIS		USR,5
;	RJMP		uartSendByte
;	OUT		UDR,A
;	RET	


CharTable:
.DB	0b11010111,0b10000001,0b11001110,0b11001011,0b10011001,0b01011011,0b01011111,0b11000001,0b11011111,0b11011011,0b00001000,0b00000000,0b01010110
;       0         1           2           3          4          5          6          7           8         9          -         " "         C

.EXIT
 