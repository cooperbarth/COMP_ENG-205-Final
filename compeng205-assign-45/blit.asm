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

	;; If you need to, you can place global variables here
	
.CODE

DrawPixel PROC USES ebx edi x:DWORD, y:DWORD, color:DWORD
	
	;; check that x and y cords are in range
	cmp x, 0
	jl finished
	cmp y, 0 
	jl finished
	cmp x, 639
	jg finished
	cmp y, 479
	jg finished

	;; find coordinate -- [ptr +x+y*640]
	mov eax, y
	mov edi, 640
	mul edi
	add eax, x
	add eax, ScreenBitsPtr

	;; Add required color to pixel
	mov ebx, color
	mov BYTE PTR [eax], bl

	finished:
	ret 			; Don't delete this line!!!
DrawPixel ENDP

BasicBlit PROC USES ecx ebx edx edi esi ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
	local w: DWORD, h: DWORD, x_cord: DWORD, y_cord: DWORD, lpb: DWORD, transp: BYTE

	mov ecx, ptrBitmap

	;; Storing width for future calculations
	mov ebx, (EECS205BITMAP PTR [ecx]).dwWidth
	mov w, ebx 
	
	;; x_cord = xcenter - dwWdith/2
	sar ebx, 1
	mov edx, xcenter
	sub edx, ebx
	mov x_cord, edx

	;; Storing height for future calculation
	mov ebx, (EECS205BITMAP PTR [ecx]).dwHeight
	mov h, ebx

	;; calculating y_cord = ycenter - dwHeight/2
	sar ebx, 1
	mov edx, ycenter
	sub edx, ebx
	mov y_cord, edx

	;; Storing pixel color for tranparency check
	mov ebx, 0
	mov bl, (EECS205BITMAP PTR [ecx]).bTransparent
	mov transp, bl 

	;; Storing LPBytes for further calculations
	mov ebx, (EECS205BITMAP PTR [ecx]).lpBytes
	mov lpb, ebx

	;; initialize values for nested loops
	;; y = esi --> counter for loop 1, and x = edi --> counter for loop 2
	mov esi, 0
	mov edi, 0
	jmp eval_ycord
	
	body:
	;; calculate index first
	mov eax, esi
	mul w
	add eax, edi

	;; Retrieve color at that index
	mov ebx, lpb
	mov edx, 0
	mov dl, BYTE PTR [ebx + eax]

	;; check if current coord is transparent
	cmp dl, transp
	je eval_xcord

	; DrawPixel
	mov ecx, x_cord
	add ecx, edi
	mov ebx, y_cord
	add ebx, esi
	invoke DrawPixel, ecx, ebx, dl

	;; check for inner loop
	eval_xcord:
	inc edi
	cmp edi, h
	jl body

	;; increment outer loop (loop on y-cord)
	inc esi

	;; check for outer loop
	eval_ycord:
	mov edi, 0
	cmp esi, h
	jl body

	ret 			
BasicBlit ENDP

RotateBlit PROC USES esi edi ebx ecx ebx eax lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT
	local cosa: FXPT, sina: FXPT, shiftx: FXPT, shifty: FXPT
	local halfsin: FXPT, halfcos: FXPT
	local dstwh: DWORD, n_dstwh: DWORD, color: BYTE
	local srcX: FXPT, srcY: FXPT
	local dstX: DWORD, dstY: DWORD
	local w: DWORD, h: DWORD, lpb: DWORD, xcord: DWORD, ycord: DWORD

	mov esi, lpBmp

	;; find sine and cosine angles
	invoke FixedCos, angle
	mov cosa, eax
	invoke FixedSin, angle
	mov sina, eax

	;; initialize half angles
	mov ecx, sina
	shr ecx, 1
	mov halfsin, ecx
	mov ecx, cosa
	shr ecx, 1
	mov halfcos, ecx

	;; Storing initial values
	mov eax, (EECS205BITMAP PTR [esi]).dwWidth
	mov w, eax
	mov eax, (EECS205BITMAP PTR [esi]).dwHeight
	mov h, eax
	xor eax, eax
	mov al, (EECS205BITMAP PTR [esi]).bTransparent
	mov color, al
	mov eax, (EECS205BITMAP PTR [esi]).lpBytes
	mov lpb, eax

	;; calculating shiftX
	mov eax, w
	imul halfcos
	sar eax, 16
	mov shiftx, eax
	mov eax, h
	imul halfsin
	sar eax, 16
	sub shiftx, eax 

	;; calculating shiftY
	mov eax, h
	imul halfcos
	sar eax, 16
	mov shifty, eax
	mov eax, w
	imul halfsin
	sar eax, 16
	add shifty, eax

	;; initialize dstheight = dstwidth = width + height
	mov edx, w
	add edx, h
	mov dstwh, edx
	mov n_dstwh, edx
	neg n_dstwh

	;; initialize counters dstX and dstY for loops
	mov edi, n_dstwh
	mov dstX, edi
	jmp xeval

	;; body of outer loop --> reset dstY
	xloop:
	mov ecx, n_dstwh
	mov dstY, ecx

	;; body of inner loop
	yloop:

	;; calculate srcX
	mov eax, dstX
	imul cosa
	sar eax, 16
	mov srcX, eax
	mov eax, dstY
	imul sina
	sar eax, 16
	add srcX, eax
	
	;;calculate srcY
	mov eax, dstY
	imul cosa
	sar eax, 16
	mov srcY, eax
	mov eax, dstX
	imul sina
	sar eax, 16
	sub srcY, eax

	;;check if srcX and srcY are valid
	cmp srcX, 0
	jl yinc
	cmp srcY, 0
	jl yinc
	mov ebx, w
	cmp srcX, ebx
	jge yinc
	mov ebx, h
	cmp srcY, ebx
	jge yinc

	;; calculate index to check for pixel
	mov eax, srcY
	mul w
	add eax, srcX
	mov ecx, eax
	add ecx, lpb

	;; check if pixel is transparent
	xor edx, edx
	mov dl, BYTE PTR [ecx]
	cmp dl, color
	je yinc

	;; calc x_cord to draw
	mov eax, xcenter
	add eax, dstX
	sub eax, shiftx
	mov xcord, eax

	;;calc ycord to draw
	mov eax, ycenter
	add eax, dstY
	sub eax, shifty
	mov ycord, eax

	invoke DrawPixel, xcord, ycord, dl
	
	yinc:
	inc dstY

	yeval:
	mov ecx, dstY
	cmp ecx, dstwh
	jl yloop
	inc dstX

	xeval:
	mov edi, dstX
	cmp edi, dstwh
	jl xloop

	ret 			; Don't delete this line!!!		
RotateBlit ENDP

END
