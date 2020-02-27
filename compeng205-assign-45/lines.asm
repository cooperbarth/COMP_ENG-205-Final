; #########################################################################
;
;   lines.asm - Assembly file for CompEng205 Assignment 2
;
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
	

;; Don't forget to add the USES the directive here
;;   Place any registers that you modify (either explicitly or implicitly)
;;   into the USES list so that caller's values can be preserved
	
;;   For example, if your procedure uses only the eax and ebx registers
;;      DrawLine PROC USES eax ebx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
DrawLine PROC USES ecx ebx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
	;; Feel free to use local variables...declare them here
	;; For example:
	;; 	LOCAL foo:DWORD, bar:DWORD
	
	;; Place your code here
LOCAL currx:DWORD, curry:DWORD, deltax:DWORD, dy:DWORD, incx:DWORD, incy:DWORD, error:DWORD
start:
	mov ecx, x1
	sub ecx, x0
	cmp ecx, 0
	jge absxcheck
	neg ecx
absxcheck:
	mov deltax, ecx
setupdy:
	mov ecx, y1
	sub ecx, y0
	cmp ecx, 0
	jge absycheck
	neg ecx
absycheck:
	mov dy, ecx

initincx:
	mov ecx, x0
	cmp ecx, x1
	jl incxone
	mov incx, -1
	jmp initincy
incxone:
	mov incx, 1

initincy:
	mov ecx, y0
	cmp ecx, y1
	jl inityone
	mov incy, -1
	jmp initerror
inityone:
	mov incy, 1

initerror:
	mov ecx, deltax
	cmp ecx, dy
	jg errorgetsdx
	mov esi, dy
	sar esi, 1
	neg esi
	mov error, esi
	jmp initloop
errorgetsdx:
	sar ecx, 1
	mov error, ecx	

initloop:
	mov ecx, x0
	mov currx, ecx
	mov ecx, y0
	mov curry, ecx
	invoke DrawPixel, currx, curry, color
	jmp evalloop

	;; While loop body
drawloop:
	invoke DrawPixel, currx, curry, color	
	mov ecx, error ; using ecx for prev_error
	neg deltax
	cmp ecx, deltax
	jle nexterrorcheck
	mov ebx, error
	sub ebx, dy
	mov error, ebx
	mov ebx, currx
	add ebx, incx
	mov currx, ebx
nexterrorcheck:
	neg deltax
	cmp ecx, dy
	jge evalloop
	mov ebx, error
	add ebx, deltax
	mov error, ebx
	mov ebx, curry
	add ebx, incy
	mov curry, ebx

;; Evaluation condition
evalloop:
	mov ecx, x1
	cmp currx, ecx
	jne drawloop
	mov ecx, y1
	cmp curry, ecx
	jne drawloop

	ret        	;;  Don't delete this line...you need it
DrawLine ENDP




END
