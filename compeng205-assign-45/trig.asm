
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


	;; If you need to, you can place global variables here
	
.CODE

FixedSin PROC USES ecx esi edx angle:FXPT
	local is_lz: BYTE

	;; need to check the angle first 
	mov esi, angle
	mov is_lz, BYTE PTR 0 ;; check is value should be negative

	;; if angle < 0 increase it to valid value
	increase_angle:
	cmp esi, 0
	jge reduce_angle
	add esi, TWO_PI
	jmp increase_angle

	;; if angle > 2PI decrease to valid value
	reduce_angle:
	cmp esi, TWO_PI
	jl find_sintab
	sub esi, TWO_PI
	jmp reduce_angle

	;; finding valid angle in range 0,PI_HALF
	find_sintab:
	cmp esi, PI_HALF
	jle return_index ;; in first quadrant
	cmp esi, PI
	jge larger_pi ;; in third or fourth quadrant
	mov ecx, PI
	sub ecx, esi ;; convert to first quadrant value
	mov esi, ecx
	jmp return_index

	larger_pi:
	cmp esi, PI + PI_HALF ;; check if in third quadrant
	jl less_than_3_over_2_pi
	mov is_lz, BYTE PTR 1 ;; 4th quadrant sine is negative
	mov ecx, TWO_PI
	sub ecx, esi
	mov esi, ecx
	jmp return_index

	less_than_3_over_2_pi:
	mov is_lz, BYTE PTR 1 ;; 3rd quadrant cosine is negative
	sub esi, PI ;; set to valid angle
	
	;; find valid index in SINTAB range
	return_index:
	mov eax, esi
	mov esi, PI_INC_RECIP
	mul esi
	shl edx, 16
	shr edx, 16
	mov esi, edx
	mov eax, 0
	mov ax, WORD PTR [SINTAB + esi*2]

	;; if angle should negative convert to negative value
	cmp is_lz, BYTE PTR 1
	jne non_neg
	neg eax

	non_neg:
	ret			; Don't delete this line!!!
FixedSin ENDP 
	
FixedCos PROC USES esi angle:FXPT

	mov esi, angle
	add esi, PI_HALF
	invoke FixedSin, esi
	ret			; Don't delete this line!!!	
FixedCos ENDP	
END
