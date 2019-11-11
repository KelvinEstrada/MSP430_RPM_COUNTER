;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file

;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.
	.sect ".sysmem"
Cantidad	.word 0
x			.word 0
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

; For FRAM devices, at start up, the GPO power-on default
; high-impedance mode needs to be disabled to activate previously
; configured port settings. This can be done by clearing the LOCKLPM5
; bit in PM5CTL0 register
  bic.b #LOCKLPM5, PM5CTL0	; Not needed for MSP430G2553

SetupP1:
    bic.b #BIT3|BIT7, &P2SEL1
    bic.b #BIT3|BIT7, &P2SEL0
	bic.b #BIT3|BIT7,&P2DIR
	bic.b #BIT7,&P1DIR				; P1.7 as input
  	bis.b #BIT0|BIT1, &P1DIR       	; P1.0 & P1.1 as output
  	bic.b #BIT0|BIT1, &P1OUT		; LED off
  	bis.b #BIT3|BIT7, &P2REN		; select internal resistor
  	bis.b #BIT3|BIT7, &P2OUT		; make it pull-up
  	bis.b #BIT3|BIT7, &P2IE       	; enable PB interrupt
  	bic.b #BIT3|BIT7, &P2IFG
  	bic.b #BIT7, &P1IFG
  	bis.b #BIT7,&P1IE
  	bic.b #BIT7, &P1IES				; Enable Low/High interrupt
  	;bic.b #BIT7, &P1REN			; select internal resistor

SetupTA:
	bis.w   #CCIE,&TA0CCTL0         ; TACCR0 interrupt enabled
    mov.w   #8192,&TA0CCR0
    bis.w   #TASSEL_1+ID_3+MC_1,&TA0CTL
    nop
    bis.w #GIE,SR
	nop
;-------------------------------------------------------------------------------
TIMER0_A0_ISR		;ISR for TA0CCR0
;-------------------------------------------------------------------------------
    bic.b #BIT0, &P2IFG
    mov x, Cantidad
    clr x
    reti

;--------------------------------------------------------
; P1.7 Interrupt Service Routine
;--------------------------------------------------------
PIN_ISR
	bic.b #BIT7,&P1IFG  			; clear int . flag
  	inc x
 	reti
;---------------
;Buttons interrupts service routine
;---------------
PBISR
  	bic.b #BIT3, &P2IFG   			; clear interrupt flag P2.3
  	bic.b #BIT7, &P2IFG   			; clear interrupt flag P2.7
	xor.b #1,&P1OUT       			; Toggle LED
Setup:
	clr R10
	clr R11
	clr R12
	bis.b #1, &P1DIR				;P1.0 as output
	bic.b #BIT0, P1OUT 				;toggle LED off
	mov Cantidad,R5
	mov #60, R4
	mov R5, R6
Multi:
	dec R4
	jz CalculaCentenas
	add R6, R5
	jmp Multi
;Procede a calcular el digito de las centenas
;R10 guardara el digito de las centenas
CalculaCentenas:
	mov R5, R6
	sub #100, R5
	cmp #0, R5
	jl	CalculaDecenas
	add #1, R10
	jmp CalculaCentenas
;Procede a calcular el digito de las decenas
;R11 guardara el digito de las decenas
CalculaDecenas:
	mov R6, R7
	sub #10, R6
	cmp #0, R6
	jl CalculaUnidades
	add #1, R11
	jmp CalculaDecenas
;Procede a calcular el digito de las unidades
;R12 guardara el digito de las unidades
CalculaUnidades:
	sub #1, R7
	cmp #0, R7
	jl In						;Obliga al sistema a que en el momento se presione P2.3 entre con la luz
	add #1, R12
	jmp CalculaUnidades
DisplayCentenas:
		bit.b #BIT7, &P2IN		;Al presionar el boton, se activa el display del resultado de las centenas
		jnz DisplayCentenas
		clrz					; Limpiar flag Z
In		xor.b #1,&P1OUT 		; Toggle P1.0
		mov #15, R9				; Tiempo para Separación de digitos
Brinco	mov #65535,R8
		call #Delay				; Loop para aumentar duración de luz
		dec R9
		jnz Brinco				; Si R9 no es cero volvemos
		mov R10, R5				; Movemos valor de centena a nuevo registro
		xor.b #1,&P1OUT 		; Toggle P1.0
		call #Wait				; Espacio entre luz
		cmp #0, R5				; Comparar con cero para crear un loop especifico con "0"
		jz DisplayDecenas		; Si el digito es 0 brinca al proximo digito
		call #DISPLAY
DisplayDecenas:
		nop
		bit.b #BIT7, &P2IN		;Al presionar el boton, se activa el display del resultado de las decenas
		jnz In
		clrz
In2		xor.b #1,&P1OUT 		; Toggle P1.0
		mov #15, R9
Brinco1	mov #65535,R8
		call #Delay
		dec R9
		jnz Brinco1
		mov R11, R5
		xor.b #1,&P1OUT 		; Toggle P1.0
		call #Wait
		cmp #0, R5
		jz DisplayUnidades
		call #DISPLAY
DisplayUnidades:
		nop
		bit.b #BIT7, &P2IN		;Al presionar el boton, se activa el display del resultado de las unidades
		jnz In2
		clrz
In3		xor.b #1,&P1OUT 		; Toggle P1.0
		mov #15, R9
Brinco2	mov #65535,R8
		call #Delay
		dec R9
		jnz Brinco2
		mov R12, R5
		xor.b #1,&P1OUT 		; Toggle P1.0
		call #Wait
		cmp #0, R5
		jz DisplayCentenas
		call #DISPLAY
		bit.b #BIT7, &P2IN
		jz In
		jmp In3
; ----------
; Subroutine Wait
; -----------
DISPLAY:
		clrn
		dec R5
		jn stop
		xor.b #BIT1,&P1OUT 		; Toggle P1.0
		call #Wait
		xor.b #BIT1,&P1OUT 		; Toggle P1.0
Wait:
		clrz
		mov #65535,R15 			; Delay to R15
L1:
		dec R15 				; Decrement R15
		jz DISPLAY 				; Delay over ?
		jmp L1
stop	ret

Delay:
		dec R8
		jnz Delay
		ret
End		reti

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   RESET_VECTOR        ; MSP430 RESET Vector
            .short  RESET
            .sect   TIMER0_A0_VECTOR 	; Timer A0 ISR
			.short  TIMER0_A0_ISR
   			.sect 	PORT2_VECTOR		; P2 Vector for PB
    		.short  PBISR
    		.sect	PORT1_VECTOR
    		.short  PIN_ISR
            .end
