; #########################################################################
;
;   stars.asm - Assembly file for CompEng205 Assignment 1
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include stars.inc

include C:\masm32\include\masm32.inc
includelib C:\masm32\lib\masm32.lib

.DATA

SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480
STAR_COUNT = 75

.CODE

DrawStarField PROC USES ebx esi
	mov esi, STAR_COUNT

	BODY:
	INVOKE nrandom, SCREEN_WIDTH
	mov ebx, eax

	INVOKE nrandom, SCREEN_HEIGHT
	INVOKE DrawStar, ebx, eax

	COND:
	dec esi
	jnz BODY

	ret
DrawStarField endp

END
