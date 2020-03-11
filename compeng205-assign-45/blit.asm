; #########################################################################
;
;   blit.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc

.DATA

	NUM_COLUMNS = 640
	NUM_ROWS = 480
	
.CODE

DrawPixel PROC USES ebx x:DWORD, y:DWORD, color:DWORD
	; Bounds checks
	cmp x, 639
	jg DONE
	cmp x, 0
	jl DONE
	cmp y, 479
	jg DONE
	cmp y, 0
	jl DONE

	; Get color address (ScreenBitsPtr + 640 * y + x)
	mov eax, y
	mov ebx, 640
	mul ebx
	add eax, x
	add eax, ScreenBitsPtr

	; Draw the pixel
	mov ebx, color
	mov BYTE PTR [eax], bl

	DONE:
	ret
DrawPixel ENDP

BasicBlit PROC USES ebx ecx edx edi esi ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD

	LOCAL x: DWORD, y: DWORD
	LOCAL x_0:DWORD, y_0:DWORD
	LOCAL h:DWORD, w:DWORD
	LOCAL t:BYTE, colorBytes:DWORD

	; Initialize local variables
	mov x, 0
	mov y, 0
	mov ecx, ptrBitmap
	mov edx, (EECS205BITMAP PTR [ecx]).dwHeight
	mov h, edx
	mov edx, (EECS205BITMAP PTR [ecx]).dwWidth
	mov w, edx
	mov al, (EECS205BITMAP PTR [ecx]).bTransparent
	mov t, al
	mov edx, (EECS205BITMAP PTR [ecx]).lpBytes
	mov colorBytes, edx

	; Set initial x-coordinate (xcenter - dwidth / 2)
	mov ecx, w
	sar ecx, 1
	dec ecx ;; Prevent rounding error
	mov ebx, xcenter
	sub ebx, ecx
	mov x_0, ebx ; Store initial X coord

	; Set initial y-coordinate (ycenter - dheight / 2)
	mov ecx, h
	sar ecx, 1
	dec ecx ;; Prevent rounding error
	mov ebx, ycenter
	sub ebx, ecx
	mov y_0, ebx ; Store initial Y coord
	
	jmp OUTER_LOOP_COND

	LOOP_BODY:
	; Bounds checks are handled in DrawPixel

	; Calculate y * w + x
	mov eax, y
	mul w
	add eax, x

	; Get color byte
	mov edi, colorBytes
	mov dl, BYTE PTR [eax + edi]

	; Check for transparency
	cmp dl, t
	je INNER_LOOP_COND

	; Draw pixel
	mov esi, x
	add esi, x_0
	mov ebx, y
	add ebx, y_0
	INVOKE DrawPixel, esi, ebx, dl

	INNER_LOOP_COND:
	inc x ; Move to the next column
	mov edi, x
	cmp edi, w ; Loop again if x < w
	jl LOOP_BODY
	inc y ; Move to the next row if we didn't jump

	OUTER_LOOP_COND:
	and x, 0 ; Reset x coordinate
	mov edi, y
	cmp edi, h ; Run body if y < h
	jl LOOP_BODY

	ret
BasicBlit ENDP

RotateBlit PROC USES ebx ecx edx lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT

	LOCAL sina:FXPT, cosa:FXPT
	LOCAL halfsin:FXPT, halfcos:FXPT
	LOCAL h:DWORD, w:DWORD
	LOCAL t:BYTE, colorBytes:DWORD
	LOCAL shiftX:FXPT, shiftY:FXPT
	LOCAL dstWidth:DWORD, dstHeight:DWORD
	LOCAL dstX:DWORD, dstY:DWORD
	LOCAL srcX:FXPT, srcY:FXPT

	; Call sin and cosine functions
	mov ebx, angle
	INVOKE FixedSin, ebx
	mov sina, eax
	INVOKE FixedCos, ebx
	mov cosa, eax

	; Initialize local variables
	mov ecx, lpBmp
	mov edx, (EECS205BITMAP PTR [ecx]).dwHeight
	mov h, edx
	mov edx, (EECS205BITMAP PTR [ecx]).dwWidth
	mov w, edx
	mov al, (EECS205BITMAP PTR [ecx]).bTransparent
	mov t, al
	mov edx, (EECS205BITMAP PTR [ecx]).lpBytes
	mov colorBytes, edx

	; Initialize sin/2 and cos/2
	mov eax, sina
	sar eax, 1
	mov halfsin, eax
	mov eax, cosa
	sar eax, 1
	mov halfcos, eax

	; Calculate shiftX
	mov eax, w
	imul halfcos
	sar eax, 16 ; Convert to fixed point
	mov shiftX, eax

	mov eax, h
	imul halfsin
	sar eax, 16 ; Convert to fixed point
	sub shiftX, eax

	; Calculate shiftY
	mov eax, h
	imul halfcos
	sar eax, 16 ; Convert to fixed point
	mov shiftY, eax

	mov eax, w
	imul halfsin
	sar eax, 16 ; Convert to fixed point
	add shiftY, eax

	; Calculate dst width and height
	mov ebx, w
	add ebx, h
	mov dstWidth, ebx
	mov dstHeight, ebx

	; Initialize dstX
	mov dstX, ebx
	neg dstX

	; Start the main loop
	jmp OUTER_COND

	BODY:
	; Calculate srcX
	mov eax, dstX
	imul cosa
	sar eax, 16
	mov srcX, eax
	mov eax, dstY
	imul sina
	sar eax, 16
	add srcX, eax

	; Calculate srcY
	mov eax, dstY
	imul cosa
	sar eax, 16
	mov srcY, eax
	mov eax, dstX
	imul sina
	sar eax, 16
	sub srcY, eax

	; First round of IF checks
	cmp srcX, 0 ; Skip further calculations if srcX < 0
	jl INC_INNER_LOOP
	mov ebx, w
	cmp srcX, ebx
	jge INC_INNER_LOOP ; Skip further calculations if srcX >= w
	cmp srcY, 0
	jl INC_INNER_LOOP ; Skip further calculations if srcY < 0
	mov ebx, h
	cmp srcY, ebx
	jge INC_INNER_LOOP ; Skip further calculations if srcY >= h

	; Calculate srcY * w + srcX
	mov eax, srcY
	mul w
	add eax, srcX

	; Get the bitmap pixel
	xor edx, edx
	mov ecx, eax
	add ecx, colorBytes
	mov dl, BYTE PTR [ecx]

	; Check for transparency
	cmp dl, t
	je INC_INNER_LOOP

	; Draw Pixel
	mov ebx, xcenter
	add ebx, dstX
	sub ebx, shiftX
	mov ecx, ycenter
	add ecx, dstY
	sub ecx, shiftY
	INVOKE DrawPixel, ebx, ecx, dl

	INC_INNER_LOOP:
	; Increment dstY
	inc dstY

	INNER_COND:
	mov ebx, dstY
	cmp ebx, dstHeight
	jl BODY
	inc dstX ; Increment if didn't loop

	OUTER_COND:
	; Initialize dstY
	mov ebx, dstHeight
	neg ebx
	mov dstY, ebx
	; Comparison
	mov ebx, dstX
	cmp ebx, dstWidth
	jl BODY
	
	ret
RotateBlit ENDP

;; Just rotateBlit but painting it black
ClearSprite PROC USES ebx ecx edx lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT
	LOCAL sina:FXPT, cosa:FXPT
	LOCAL halfsin:FXPT, halfcos:FXPT
	LOCAL h:DWORD, w:DWORD
	LOCAL shiftX:FXPT, shiftY:FXPT
	LOCAL dstWidth:DWORD, dstHeight:DWORD
	LOCAL dstX:DWORD, dstY:DWORD
	LOCAL srcX:FXPT, srcY:FXPT

	; Call sin and cosine functions
	mov ebx, angle
	INVOKE FixedSin, ebx
	mov sina, eax
	INVOKE FixedCos, ebx
	mov cosa, eax

	; Initialize local variables
	mov ecx, lpBmp
	mov edx, (EECS205BITMAP PTR [ecx]).dwHeight
	mov h, edx
	mov edx, (EECS205BITMAP PTR [ecx]).dwWidth
	mov w, edx

	; Initialize sin/2 and cos/2
	mov eax, sina
	sar eax, 1
	mov halfsin, eax
	mov eax, cosa
	sar eax, 1
	mov halfcos, eax

	; Calculate shiftX
	mov eax, w
	imul halfcos
	sar eax, 16 ; Convert to fixed point
	mov shiftX, eax

	mov eax, h
	imul halfsin
	sar eax, 16 ; Convert to fixed point
	sub shiftX, eax

	; Calculate shiftY
	mov eax, h
	imul halfcos
	sar eax, 16 ; Convert to fixed point
	mov shiftY, eax

	mov eax, w
	imul halfsin
	sar eax, 16 ; Convert to fixed point
	add shiftY, eax

	; Calculate dst width and height
	mov ebx, w
	add ebx, h
	mov dstWidth, ebx
	mov dstHeight, ebx

	; Initialize dstX
	mov dstX, ebx
	neg dstX

	; Start the main loop
	jmp OUTER_COND

	BODY:
	; Calculate srcX
	mov eax, dstX
	imul cosa
	sar eax, 16
	mov srcX, eax
	mov eax, dstY
	imul sina
	sar eax, 16
	add srcX, eax

	; Calculate srcY
	mov eax, dstY
	imul cosa
	sar eax, 16
	mov srcY, eax
	mov eax, dstX
	imul sina
	sar eax, 16
	sub srcY, eax

	; First round of IF checks
	cmp srcX, 0 ; Skip further calculations if srcX < 0
	jl INC_INNER_LOOP
	mov ebx, w
	cmp srcX, ebx
	jge INC_INNER_LOOP ; Skip further calculations if srcX >= w
	cmp srcY, 0
	jl INC_INNER_LOOP ; Skip further calculations if srcY < 0
	mov ebx, h
	cmp srcY, ebx
	jge INC_INNER_LOOP ; Skip further calculations if srcY >= h

	; Calculate srcY * w + srcX
	mov eax, srcY
	mul w
	add eax, srcX

	; Draw Pixel
	mov ebx, xcenter
	add ebx, dstX
	sub ebx, shiftX
	mov ecx, ycenter
	add ecx, dstY
	sub ecx, shiftY
	INVOKE DrawPixel, ebx, ecx, 0

	INC_INNER_LOOP:
	; Increment dstY
	inc dstY

	INNER_COND:
	mov ebx, dstY
	cmp ebx, dstHeight
	jl BODY
	inc dstX ; Increment if didn't loop

	OUTER_COND:
	; Initialize dstY
	mov ebx, dstHeight
	neg ebx
	mov dstY, ebx
	; Comparison
	mov ebx, dstX
	cmp ebx, dstWidth
	jl BODY
	
	ret
ClearSprite ENDP

END
