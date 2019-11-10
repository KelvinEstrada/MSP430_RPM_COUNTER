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
Cantidad	.word 3
x			.word 1
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
	bic.b #LOCKLPM5, PM5CTL0 ; Not needed for G2553
Setup:
	clr R10
	clr R11
	clr R12
	bis.b #1, &P1DIR	;P1.0 as output
	bic.b #BIT0, P1OUT ;toggle LED off
	bic.b #00001000b, &P2DIR ; P2.3 as input
	bis.b #00001000b, &P2REN ; select internal res
	bis.b #00001000b, &P2OUT ; make it pull-up
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
	jl DisplayCentenas
	add #1, R12
	jmp CalculaUnidades
DisplayCentenas:
	bit.b #00001000b, &P2IN		;Al presionar el boton, se activa el display del resultado
	jnz DisplayCentenas
	clrz
	xor.b #1,&P1OUT ; Toggle P1.0
	mov #15, R9
Brinco:
	mov #65535,R8
	call #Delay
	dec R9
	jnz Brinco
	mov R10, R5
	xor.b #1,&P1OUT ; Toggle P1.0
	call #Wait
	cmp #0, R5
	jz DisplayDecenas
	call #DISPLAY
DisplayDecenas:
	bit.b #00001000b, &P2IN		;Al presionar el boton, se activa el display del resultado
	jnz DisplayDecenas
	clrz
	xor.b #1,&P1OUT ; Toggle P1.0
	mov #15, R9
Brinco1:
	mov #65535,R8
	call #Delay
	dec R9
	jnz Brinco1
	mov R11, R5
	xor.b #1,&P1OUT ; Toggle P1.0
	call #Wait
	cmp #0, R5
	jz DisplayUnidades
	call #DISPLAY
DisplayUnidades:
	bit.b #00001000b, &P2IN		;Al presionar el boton, se activa el display del resultado
	jnz DisplayUnidades
	clrz
	xor.b #1,&P1OUT ; Toggle P1.0
	mov #15, R9
Brinco2:
	mov #65535,R8
	call #Delay
	dec R9
	jnz Brinco2
	mov R12, R5
	xor.b #1,&P1OUT ; Toggle P1.0
	call #Wait
	cmp #0, R5
	jz DisplayCentenas
	call #DISPLAY
	jmp DisplayCentenas
; ----------
; Subroutine Wait
; -----------
DISPLAY:
	clrn
	dec R5
	jn stop
	xor.b #1,&P1OUT ; Toggle P1.0
	call #Wait
	xor.b #1,&P1OUT ; Toggle P1.0
Wait:
	clrz
	mov #65535,R15 ; Delay to R15
L1:
	dec R15 ; Decrement R15
	jz DISPLAY ; Delay over ?
	jmp L1
stop	ret
Delay:
	dec R8
	jnz Delay
	ret
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
			.end
