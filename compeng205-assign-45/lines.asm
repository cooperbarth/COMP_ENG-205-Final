; #########################################################################
;
;   lines.asm - Assembly file for CompEng205 Assignment 2
;	Cooper
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA

	;; If you need to, you can place global variables here
	
.CODE

;; This code is super gross but I was in a hurry
;; I present to thee: "Abuse of esi"

DrawLine PROC USES esi x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD

	LOCAL delta_x:SDWORD, delta_y:SDWORD
	LOCAL inc_x:SDWORD, inc_y:SDWORD
	LOCAL error:SDWORD, prev_error:SDWORD
	LOCAL curr_x:DWORD, curr_y:DWORD

	;; Take the absolute value of x1-x0
	ABS_X:
	mov esi, x1
	mov delta_x, esi
	mov esi, x0
	sub delta_x, esi
	jge ABS_Y
	neg delta_x
	
	;; Take the absolute value of y1-y0
	ABS_Y:
	mov esi, y1
	mov delta_y, esi
	mov esi, y0
	sub delta_y, esi
	jge SET_INC_X
	neg delta_y

	;; If statement to set inc_x
	SET_INC_X:
	mov inc_x, 1
	mov esi, x1
	cmp x0, esi
	jl SET_INC_Y
	neg inc_x

	;; If statement to set inc_y
	SET_INC_Y:
	mov inc_y, 1
	mov esi, y1
	cmp y0, esi
	jl SET_ERROR
	neg inc_y

	;; If statement to set error
	SET_ERROR:
	mov esi, delta_y
	cmp delta_x, esi
	jle SET_ERROR_ELSE

	mov esi, delta_x
	mov error, esi
	jmp SET_ERROR_DIVIDE

	SET_ERROR_ELSE:
	mov esi, delta_y
	mov error, esi
	neg error

	SET_ERROR_DIVIDE:
	sar error, 1

	;; Set curr_x and curr_y
	SET_CURR:
	mov esi, x0
	mov curr_x, esi
	mov esi, y0
	mov curr_y, esi

	;; Draw the first pixel
	invoke DrawPixel, curr_x, curr_y, color

	;; While loop conditions
	LOOP_START:
	mov esi, x1
	cmp curr_x, esi
	jne LOOP_BODY
	mov esi, y1
	cmp curr_y, esi
	jne LOOP_BODY
	jmp LOOP_END

	;; Start while loop
	LOOP_BODY:

	;; Draw pixel
	invoke DrawPixel, curr_x, curr_y, color

	;; Record last error
	mov esi, error
	mov prev_error, esi

	;; delta_x if statement
	mov esi, delta_x
	neg esi
	cmp prev_error, esi
	jle DELTA_Y_IF

	mov esi, delta_y
	sub error, esi
	mov esi, inc_x
	add curr_x, esi

	;; delta_y if statement
	DELTA_Y_IF:
	mov esi, delta_y
	cmp prev_error, esi
	jge LOOP_START

	mov esi, delta_x
	add error, esi
	mov esi, inc_y
	add curr_y, esi

	;; Restart loop
	jmp LOOP_START
	
	;; End while loop
	LOOP_END:

	ret
DrawLine ENDP

END
