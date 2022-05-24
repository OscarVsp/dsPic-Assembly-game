;
; Task4.asm
;
; Created: 18-02-22 14:34:12
; Author : Oscar
;

.INCLUDE "m328pdef.inc"

.ORG 0x0000					
RJMP init					;Start execution at init
.ORG 0x0012
RJMP Buzzer					;Timer 2: Buzzer
.ORG 0x001a                 
RJMP updateGame             ;Timer 1: Game update
.ORG 0x0020                 
RJMP updateDisplay			;Timer 0: Display update



init:
	BSET 7                  ;Enable Interrupt Globally
;Timer 0 for the screen
    LDI R17,0x04            ;Prescale 256
	LDI R19,0x30			;Initial value at 48 -> 150Hz in real world
    OUT TCCR0B,R17
    OUT TCNT0,R19
;Timer 1 for game update
    LDI R17,0x04            ;Prescale 256
	LDI R25,0xc0			;Overflow High
	LDI R24,0xf0			;Overflow Low
    STS TCCR1B,R17
	STS TCNT1H,R25
	STS TCNT1L,R24			;Real world frequency: ~3Hz
;Timer 2 for buzzer
    LDI R17,0x04            ;Prescale 64
	LDI R19,0xB9			;Initial value at 185
    STS TCCR2B,R17
    STS TCNT2,R19
;BUZZER
    SBI DDRB,1              
    SBI PORTB,1             
;Leds
	SBI DDRC,2				
	SBI PORTC,2				
	SBI DDRC,3				
	SBI PORTC,3	
;Keyboard
	LDI R16,0x0F
	OUT DDRD,R16
	LDI R16,0xFF
	OUT PORTD,R16
;SCREEN
	SBI DDRB,5				
	SBI PORTB,5				
	SBI DDRB,3				
	SBI PORTB,3				
	SBI DDRB,4				
	SBI PORTB,4
;Inital value for layer width
	LDI R21, 0x04			
	
gameSetup:
	SBI PORTC,2					;Clear gameover led
;Erase Screenbuffer and prebuffer
	LDI R17,0x00
	LDI ZL,0x00				
	LDI ZH,0x01				
	LDI R16,94				;Counter to 80+14 bytes for ScreenBuffer + PreBuffer
	WriteClearBuffer:
		ST Z+,R17
		DEC R16
		BRNE WriteClearBuffer
;Create player at center of playerbuffer
	LDI ZL,0x5e				
	LDI ZH,0x01
	LDI R16,6
	WriteClearPlayer1:
		ST Z+,R17
		DEC R16
		BRNE WriteClearPlayer1
	LDI R18,0b00001100
	ST Z+,R18
	ST Z+,R18
	LDI R16,6
	WriteCleanPlayer2:
		ST Z+,R17
		DEC R16
		BRNE WriteCleanPlayer2
;Set the Level Table pointer
	LDI ZL, low(LevelTable<<1)
	LDI ZH, high(LevelTable<<1)
;Set the layer width counter
	MOV R23,R21
;Clear the buzzer duration counter
	LDI R22,0x00
;Enable interrupt for timer 0 (screen) and 1 (game) but not timer 2 (buzzer)
	LDI R18,0x01            
	STS TIMSK0,R18
	STS TIMSK1,R18
	LDI R18,0x00
    STS TIMSK2,R18

main:
;Check if setting button is pressed
	LDI R16,0xff
	;First row
	OUT PORTD,R16
	CBI PORTD,3
	NOP
	NOP
	NOP
	NOP
	SBIS PIND,7
		RJMP gameSetup
	SBIS PIND,5
		RJMP increaseSpeed
	SBIS PIND,4
		RJMP decreaseSpeed
	;Second row
	OUT PORTD,R16
	CBI PORTD,2
	NOP
	NOP
	NOP
	NOP
	SBIS PIND,5
		RJMP increaseWidth
	SBIS PIND,4
		RJMP decreaseWidth
	
;Check is the game is not over
	LDS R17,TIMSK1
	CPI R17,0
	SBRS R17,0
		RJMP nothing

;Check if controlle button is pressed
	;Third row
	OUT PORTD,R16
	CBI PORTD,1
	NOP
	NOP
	NOP
	SBIS PIND,5
		RJMP moveTop
	;Fourth row
	OUT PORTD,R16
	CBI PORTD,0
	NOP
	NOP
	NOP
	SBIS PIND,6
		RJMP moveRight
	SBIS PIND,5
		RJMP moveBottom
	SBIS PIND,4
	RJMP moveLeft
nothing:
;If nothing pressed, clear LED 3
	SBI PORTC,3
	RJMP main

;Buttons Action
	increaseSpeed:
		SBIS PINC,3
			RJMP main
	
		LDI R16,0x08
		ADD R25,R16
		CPI R25,0xf0
		BRLO nocarryinc
			LDI R25,0xf0
			RJMP main
		nocarryinc:
		CBI PORTC,3
		RJMP main

	decreaseSpeed:
		SBIS PINC,3
			RJMP main
		SUBI R25,8
		CPI R25,0x10
		BRSH nocarrydec
			LDI R25,0x10
			RJMP main
		nocarrydec:
		CBI PORTC,3
		RJMP main
	
	increaseWidth:
		SBIS PINC,3
			RJMP main
		INC R21
		CPI R21,16
		BRLO nooverinc
			LDI R21,16
			RJMP main
		nooverinc:
		CBI PORTC,3
		RJMP main

	decreaseWidth:
		SBIS PINC,3
			RJMP main
		DEC R21
		CPI R21,1
		BRSH nonegdec
			LDI R21,0x01
			RJMP main
		nonegdec:
		CBI PORTC,3
		RJMP main
	
	moveLeft:
		SBIS PINC,3
			RJMP main
		CBI PORTC,3
		LDI XL,0x6c				
		LDI XH,0x01				
		LD R17,-X
		LDI XL,0x5e				
		LDI XH,0x01				
		LDI R16,14
		loopMoveRight:
			LD R18,X
			ST X+,R17
			MOV R17,R18
			DEC R16
			BRNE loopMoveRight
		RJMP main;

	moveRight:
		SBIS PINC,3
			RJMP main
		CBI PORTC,3
		LDI XL,0x5e				
		LDI XH,0x01				
		LD R17,X
		LDI XL,0x6c				
		LDI XH,0x01				
		LDI R16,14
		loopMoveLeft:
			LD R18,-X
			ST X,R17
			MOV R17,R18
			DEC R16
			BRNE loopMoveLeft
		RJMP main

	moveBottom:
		SBIS PINC,3
			RJMP main
		CBI PORTC,3
		LDI XL,0x5e				
		LDI XH,0x01				
		LDI R16,14
		LDI R18,0				
		loopCheckBottom:
			CLC
			LD R17,X+
			ROL R17
			BRCC carryClearBottom
				INC R18
			carryClearBottom:
			DEC R16
			BRNE loopCheckBottom
		TST R18
		BREQ rolBottom
			RJMP main
		rolBottom:
		LDI R16,14
		loopMoveBottom:
			CLC
			LD R17,-X
			ROL R17
			ST X,R17
			DEC R16
			BRNE loopMoveBottom
		RJMP main


	moveTop:
		SBIS PINC,3
			RJMP main
		CBI PORTC,3
		LDI XL,0x5e				
		LDI XH,0x01				
		LDI R16,14
		LDI R18,0				
		loopCheckTop:
			CLC
			LD R17,X+
			ROR R17
			BRCC carryClearTop
				INC R18
			carryClearTop:
			DEC R16
			BRNE loopCheckTop
		TST R18
		BREQ rolTop
			RJMP main
		rolTop:
		LDI R16,14
		loopMoveTop:
			CLC
			LD R17,-X
			ROR R17
			ST X,R17
			DEC R16
			BRNE loopMoveTop
		RJMP main

;TIMER 1
updateGame:
;Clear interrupt
	SBI TIFR1,TOV1		
	STS TCNT1H,R25
	STS TCNT1L,R24
;Store registers and SREG taht will be used locally
	PUSH R16
	PUSH R17
	PUSH R18
	PUSH R19
	PUSH R26
	PUSH R27
	PUSH R28
	PUSH R29
	IN R16,SREG
	PUSH R16
	
;Check if a new layer should be load from Level Table to Prebuffer (depending on the layer width)
	DEC R23
	BRNE ShiftBuffer
		LDI XL,0x50				
		LDI XH,0x01				
		LDI R16,2
	LoadLayerLoop:
			LPM R17,Z+		
			LDI R18,7					;Counter to only read the 7 MSB bit
		writePreBufferBytes:		
				ROL R17
				BRCC ZerosBytes
				LDI R19,0xff
				RJMP WriteToPreBuffer
			ZerosBytes:
				LDI R19,0x00
			WriteToPreBuffer:
				ST X+,R19
				DEC R18
				BRNE writePreBufferBytes
			DEC R16
			BRNE LoadLayerLoop
		MOV R23,R21	

shiftBuffer:
;Shift the game content and copy the prebuffer to the first row of the screenbuffer
	LDI XL,0x00			;ScreenBufferPointer
	LDI XH,0x01
	LDI YL,0x50			;PreBufferPointer
	LDI YH,0x01

	LDI R16,14			;Counter for each column
	columnLoopShift:
		LD R18,Y+
        CLC
		ROR R18
		LDI R17,5		;Row counter
		rowLoopShift:
			LD R18,X
			ROL R18
			ST X+,R18
			DEC R17
			BRNE rowLoopShift
		DEC R16
		BRNE columnLoopShift

;Retrieve stored register and SREG
	POP R16
	OUT SREG,R16
	POP R29
	POP R28
	POP R27
	POP R26
	POP R19
	POP R18
	POP R17
	POP R16
	reti

;TIMER 
updateDisplay:
;Store registers and SREG that will be used locally
	PUSH R16
	PUSH R17
	PUSH R18
	PUSH R19
	PUSH R20
	PUSH R21
	PUSH R26
	PUSH R27
	IN R16,SREG
	PUSH R16
;Clear interrupt
	SBI TIFR0,TOV0		;Clear interrupt flag
	LDI R16,0x30       ;Initial value at 220 -> 880Hz
    OUT TCNT0,R16
;Update the display
	LDI XL,0x4B				;ScreenBuffer pointer
	LDI XH,0x01
	LDI YL,0x6d				;Player pointer
	LDI YH,0x01
	LDI R21,0				;Game state (00 = running, ff = game over)
	LDI R16,0x01			;Shifting bytes for the active colum
	displayLoop:
		LDI R17,5				;Counter for the column (end after 5 iteration)
		columnLoop1:
			LDI R18,0x08			;Counter for the 8 bits shifting
			LD R19,-X				;Load the 8 bits from the pointer address
			CPI R17,5
			BRNE wordLoop1
				LD R20,-Y
				AND R20,R19
				BREQ noCollision1
					LDI R21,0xff	;Game over
			noCollision1:
				LD R20,Y
				OR R19,R20
			wordLoop1:
				CBI PORTB,3
				ROL R19
				BRCC CarryIs01
					SBI PORTB,3
				CarryIs01:		
				CBI PORTB,5			;Rising egde of PB5 to shift the register
				SBI PORTB,5		
				DEC R18				;Dec the counter of the 8 shifts
				BRNE wordLoop1		
			DEC R17
			BRNE columnLoop1
		SBIW XH:XL,30				;Offset to match the electronic layout (see report)
		SBIW YH:YL,6
		LDI R17,5
		columnLoop2:
			LDI R18,0x08			;counter for the 8 bits shifting
			LD R19,-X				;Load the 8 bits from the pointer address
			CPI R17,5
			BRNE wordLoop2
				LD R20,-Y
				AND R20,R19
				BREQ noCollision2
					LDI R21,0xff			;Game over
			noCollision2:
				LD R20,Y
				OR R19,R20
			wordLoop2:
				CBI PORTB,3
				ROL R19
				BRCC CarryIs02
					SBI PORTB,3
				CarryIs02:		
				CBI PORTB,5			;Rising egde of PB5 to shift the register
				SBI PORTB,5	
				DEC R18 			;Dec the counter of the 8 shifts
				BRNE wordLoop2		
			DEC R17
			BRNE columnLoop2
		ADIW XH:XL,35
		ADIW YH:YL,7
		LDI R17,0x8 		;counter for the row
		CLC
		rowLoop:
			CBI PORTB,3
			ROR R16
			BRCC CarryIsNull
				SBI PORTB,3
			CarryIsNull:
			CBI PORTB,5
			SBI PORTB,5
			DEC R17
			BRNE rowLoop
		SBI PORTB,4
		LDI R17,255		
		delay:
		NOP
		NOP
        NOP
		DEC R17
		BRNE delay
		CBI PORTB,4
		TST R16        
		BREQ endUpdateDisplay
			RJMP displayLoop
endUpdateDisplay:
	CPI R21,0
	BREQ endDisplay

;IF game is over
stoppedGame:
	;Turn led 2 and buzzer on the first time the game is over (if led 2 is clear before)
	SBIC PINC,2
		LDI R22,0xFF
		LDI R21,1			;Start buzzer
		STS TIMSK2,R21
		CBI PORTC,2			;Turn LED2 Off
		LDI R21,0
		STS TIMSK1,R21		;Stop game update
	;Turn buzzer of when the duration register is 0
	CPI R22,0
	BRNE endDisplay
		LDI R21,0
		STS TIMSK2,R21
endDisplay:		
	POP R16
	OUT SREG,R16
	POP R27
	POP R26
	POP R21
	POP R20
	POP R19
	POP R18
	POP R17
	POP R16
	reti


;Timer 2
Buzzer:
	PUSH R16
	PUSH R17
	SBI TIFR2,TOV2			;Clear the overflow bit (by setting it, yeah it's stupid)
	SBI PINB,1				;Inverse the pin of the buzzer
	LDI R16,0xB9			;Initial value at 185
	STS TCNT2,R16
	DEC R22
	POP R17
	POP R16
	reti

	



LevelTable:
;db 0bxxxxxxx0,0bxxxxxxx0
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11111000,0b00011110
.db 0b11111100,0b00001110
.db 0b11111110,0b00000110
.db 0b11111110,0b00000110
.db 0b11111100,0b00001110
.db 0b11111000,0b00011110
.db 0b11110000,0b00111110
.db 0b11100000,0b01111110
.db 0b11000000,0b11111110
.db 0b10000010,0b11111110
.db 0b00000110,0b11111110
.db 0b00000110,0b11111110
.db 0b10000010,0b11111110
.db 0b11000000,0b11111110
.db 0b11100000,0b01111110
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11111000,0b00011110
.db 0b11111100,0b00001110
.db 0b11111110,0b00000110
.db 0b11111110,0b00000110
.db 0b11111100,0b00001110
.db 0b11111000,0b00011110
.db 0b11110000,0b00111110
.db 0b11100000,0b01111110
.db 0b11000000,0b11111110
.db 0b10000010,0b11111110
.db 0b00000110,0b11111110
.db 0b00000110,0b11111110
.db 0b10000010,0b11111110
.db 0b11000000,0b11111110
.db 0b11100000,0b01111110
.db 0b11110000,0b00111110
.db 0b11100000,0b00011110
.db 0b11000000,0b00001110
.db 0b10000000,0b00000110
.db 0b10000010,0b10000010
.db 0b10000010,0b10000010
.db 0b11000000,0b11000000
.db 0b10000010,0b10000010
.db 0b00000110,0b00000110
.db 0b10000010,0b10000010
.db 0b10000000,0b00000110
.db 0b11000000,0b00001110
.db 0b11100000,0b00011110
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11111000,0b00011110
.db 0b11111100,0b00001110
.db 0b11111110,0b00000110
.db 0b11111110,0b00000110
.db 0b11111100,0b00001110
.db 0b11111000,0b00011110
.db 0b11110000,0b00111110
.db 0b11100000,0b01111110
.db 0b11000000,0b11111110
.db 0b10000010,0b11111110
.db 0b00000110,0b11111110
.db 0b00000110,0b11111110
.db 0b10000010,0b11111110
.db 0b11000000,0b11111110
.db 0b11100000,0b01111110
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11111000,0b00011110
.db 0b11111100,0b00001110
.db 0b11111110,0b00000110
.db 0b11111110,0b00000110
.db 0b11111100,0b00001110
.db 0b11111000,0b00011110
.db 0b11110000,0b00111110
.db 0b11100000,0b01111110
.db 0b11000000,0b11111110
.db 0b10000010,0b11111110
.db 0b00000110,0b11111110
.db 0b00000110,0b11111110
.db 0b10000010,0b11111110
.db 0b11000000,0b11111110
.db 0b11100000,0b01111110
.db 0b11110000,0b00111110
.db 0b11100000,0b00011110
.db 0b11000000,0b00001110
.db 0b10000000,0b00000110
.db 0b10000010,0b10000010
.db 0b10000010,0b10000010
.db 0b11000000,0b11000000
.db 0b10000010,0b10000010
.db 0b00000110,0b00000110
.db 0b10000010,0b10000010
.db 0b10000000,0b00000110
.db 0b11000000,0b00001110
.db 0b11100000,0b00011110
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11111000,0b00011110
.db 0b11111100,0b00001110
.db 0b11111110,0b00000110
.db 0b11111110,0b00000110
.db 0b11111100,0b00001110
.db 0b11111000,0b00011110
.db 0b11110000,0b00111110
.db 0b11100000,0b01111110
.db 0b11000000,0b11111110
.db 0b10000010,0b11111110
.db 0b00000110,0b11111110
.db 0b00000110,0b11111110
.db 0b10000010,0b11111110
.db 0b11000000,0b11111110
.db 0b11100000,0b01111110
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11110000,0b00111110
.db 0b11111000,0b00011110
.db 0b11111100,0b00001110
.db 0b11111110,0b00000110
.db 0b11111110,0b00000110
.db 0b11111100,0b00001110
.db 0b11111000,0b00011110
.db 0b11110000,0b00111110
.db 0b11100000,0b01111110
.db 0b11000000,0b11111110
.db 0b10000010,0b11111110
.db 0b00000110,0b11111110
.db 0b00000110,0b11111110
.db 0b10000010,0b11111110
.db 0b11000000,0b11111110
.db 0b11100000,0b01111110
.db 0b11110000,0b00111110
.db 0b11110000,0b00011110
.db 0b11100000,0b00001110
.db 0b11000000,0b00000110
.db 0b10000000,0b00000010
.db 0x00,0x00
.db 0x00,0x00
.db 0b00111000,0b00111000		;GG
.db 0b01000100,0b01000100
.db 0b01100100,0b01100100
.db 0b00000100,0b00000100
.db 0b00111000,0b00111000
.db 0x00,0x00
.db 0x00,0x00
.db 0xff,0xff
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
.db 0x00,0x00
