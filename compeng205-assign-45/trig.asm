; #########################################################################
;
;   trig.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include trig.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943           	;;  PI / 2
PI =  205887	                ;;  PI 
TWO_PI	= 411774                ;;  2 * PI
PI_INC_RECIP =  5340353        	;;  Use reciprocal to find the table entry for a given angle
	                        ;;              (It is easier to use than divison would be)
	
.CODE

FixedSin PROC USES ebx ecx edx edi angle:FXPT
	LOCAL negative:BYTE

	mov edx, angle
	mov negative, 0; Placeholder to mark negative angles

	; Make sure angle is >=0
	CHECK_NEG:
	cmp edx, 0
	jge CHECK_LARGE
	add edx, TWO_PI
	jmp CHECK_NEG

	; Make sure angle is <2pi
	CHECK_LARGE:
	cmp edx, TWO_PI
	jl BODY
	sub edx, TWO_PI
	jmp CHECK_LARGE

	BODY:
	; Check for edx < pi / 2
	FIRST_QUAD:
	cmp edx, PI_HALF
	jle LOOKUP

	; Check for pi/2 <= edx < pi
	SECOND_QUAD:
	cmp edx, PI
	jge GTE_PI
	; Change edx to PI - edx
	mov ebx, PI
	sub ebx, edx
	mov edx, ebx
	jmp LOOKUP

	; Handle 3rd and 4th quadrants
	GTE_PI:
	mov negative, 1 ; mark negative sin value
	cmp edx, PI + PI_HALF ; check whether in 3rd or 4th quadrant
	jge FOURTH_QUAD

	THIRD_QUAD:
	sub edx, PI ; reflect into first quadrant
	jmp LOOKUP

	FOURTH_QUAD:
	mov ecx, TWO_PI
	sub ecx, edx
	mov edx, ecx ; reflect into 1st quadrant

	; Look up sin value
	LOOKUP:
	mov eax, edx
	mov ecx, PI_INC_RECIP
	mul ecx
	shl edx, 16
	shr edx, 16

	; Get value from lookup table
	mov eax, 0
	mov ax, WORD PTR [SINTAB + 2 * edx]

	; Negate return value if angle was > pi
	cmp negative, 0
	je DONE
	neg eax

	DONE:
	ret
FixedSin ENDP
	
FixedCos PROC USES edx angle:FXPT
	mov edx, angle
	add edx, PI_HALF ; cos(a) = sin(a + pi/2)
	INVOKE FixedSin, edx
	ret
FixedCos ENDP	
END
