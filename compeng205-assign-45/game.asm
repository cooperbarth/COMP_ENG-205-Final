; #########################################################################
;
;   game.asm - Assembly file for CompEng205 Assignment 4/5
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
include game.inc
include keys.inc

include C:\masm32\include\masm32.inc
includelib C:\masm32\lib\masm32.lib
	
.DATA

;; Constants to track screen size
SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480

;; Set max asteroids
;; MAX_ASTEROIDS = 50
MAX_ASTEROIDS = 1

;;  Increment to rotate HIM on each frame
ROTATE_INC = 6433

;; Tracking the last mouse status
MOUSE_PRESSED DWORD 0

;; Tracking last relevant key pressed
KEY_PRESSED DWORD -1

;; Our hero
HIM Sprite <>

;; Keep track of asteroids
ASTEROIDS Sprite 50 DUP (<>)
ASTEROID_COUNT DWORD 0

.CODE

GameInit PROC USES ebx ecx
	;; Set random seed
	rdtsc
	INVOKE nseed, eax

	;; Draw the background
	INVOKE DrawStarField

	;; Draw the main character
	mov ebx, SCREEN_WIDTH
	shr ebx, 1
	mov ecx, SCREEN_HEIGHT
	shr ecx, 1
	INVOKE BasicBlit, OFFSET Fighter, ebx, ecx

	;; Initialize HIM
	mov HIM.x, ebx
	mov HIM.y, ecx
	mov HIM.vX, 0
	mov HIM.vY, 0
	mov HIM.rotation, 0

	;; Save sprite for HIM
	lea ebx, Fighter
	mov HIM.bitmapPtr, ebx

	ret
GameInit ENDP

GamePlay PROC USES ebx
	;; Move all asteroid sprites
	INVOKE MoveAsteroids

	;; Check mouse state

	;; If the state hasn't changed, do nothing
	mov ebx, MouseStatus.buttons
	cmp ebx, MOUSE_PRESSED
	je HANDLE_KEY_PRESS

	;; If nothing is pressed, it was released
	cmp ebx, 0
	je HANDLE_RELEASE

	;; If left click is down, it was just pressed
	cmp ebx, 1
	je HANDLE_CLICK

	HANDLE_CLICK:
	INVOKE SpawnAsteroid

	HANDLE_RELEASE:
	mov [MOUSE_PRESSED], ebx

	HANDLE_KEY_PRESS:
	;; Check if no keys are pressed
	mov ebx, KeyPress
	cmp ebx, 0
	je DONE

	;; Check if left or right is pressed
	cmp ebx, VK_LEFT
	je CLEAR_BITMAP_HIM
	cmp ebx, VK_RIGHT
	je CLEAR_BITMAP_HIM
	jmp DONE

	CLEAR_BITMAP_HIM:
	;; Clear current bitmap
	INVOKE ClearSprite, HIM.bitmapPtr, HIM.x, HIM.y, HIM.rotation

	;; Figure out which way to rotate him
	cmp ebx, VK_LEFT
	je ROTATE_LEFT
	cmp ebx, VK_RIGHT
	je ROTATE_RIGHT
	jmp DONE

	;; Rotate left
	ROTATE_LEFT:
	sub HIM.rotation, ROTATE_INC
	jmp ROTATE_HIM

	;; Rotate right
	ROTATE_RIGHT:
	add HIM.rotation, ROTATE_INC

	ROTATE_HIM:
	INVOKE RotateBlit, HIM.bitmapPtr, HIM.x, HIM.y, HIM.rotation

	DONE:
	ret
GamePlay ENDP

SpawnAsteroid PROC USES ebx ecx edx esi
	LOCAL asteroidPtr:DWORD
	LOCAL x:DWORD, y:DWORD

	;; Do nothing if too many sprites
	cmp ASTEROID_COUNT, MAX_ASTEROIDS
	mov ebx, ASTEROID_COUNT
	jge DONE

	;; HACK FOR NOW - Spawn at fixed spot
	mov edx, SCREEN_WIDTH
	shr edx, 1
	INVOKE BasicBlit, OFFSET Asteroid, edx, 0
	jmp SAVE_SPRITE

	;; Randomly decide which side to spawn on
	INVOKE nrandom, 2
	cmp eax, 1
	je LEFT_RIGHT

	TOP_BOTTOM:
	;; Get x-coordinate to draw
	INVOKE nrandom, SCREEN_WIDTH
	mov esi, eax
	mov x, eax

	;; Decide whether to draw on top or bottom
	INVOKE nrandom, 2
	cmp eax, 1
	je PAINT_BOTTOM

	;; Paint on top
	PAINT_TOP:
	mov y, 0
	INVOKE BasicBlit, OFFSET Asteroid, esi, 0
	jmp SAVE_SPRITE

	;; Paint on bottom
	PAINT_BOTTOM:
	mov y, [SCREEN_HEIGHT]
	INVOKE BasicBlit, OFFSET Asteroid, esi, SCREEN_HEIGHT
	jmp SAVE_SPRITE

	LEFT_RIGHT:
	;; Get y-coordinate to draw
	INVOKE nrandom, SCREEN_HEIGHT
	mov esi, eax
	mov y, eax

	;; Decide whether to draw on left or right
	INVOKE nrandom, 2
	cmp eax, 1
	je PAINT_RIGHT

	;; Paint on left
	PAINT_LEFT:
	mov x, 0
	INVOKE BasicBlit, OFFSET Asteroid, 0, esi
	jmp SAVE_SPRITE

	;; Paint on right
	PAINT_RIGHT:
	mov x, SCREEN_WIDTH
	INVOKE BasicBlit, OFFSET Asteroid, SCREEN_WIDTH, esi

	SAVE_SPRITE:
	;; Get current asteroid
	mov ebx, SIZEOF Sprite
	imul ebx, ASTEROID_COUNT
	lea ecx, ASTEROIDS
	add ebx, ecx
	mov asteroidPtr, ebx

	;; Create and save asteroid sprite
	;; mov edx, [x]
	;; mov (Sprite PTR [ebx]).x, edx ;; Set x
	mov edx, SCREEN_WIDTH
	shr edx, 1
	mov (Sprite PTR [ebx]).x, edx ;; HACK
	;; mov edx, [y]
	;; mov (Sprite PTR [ebx]).y, edx ;; Set y
	mov (Sprite PTR [ebx]).y, 0 ;; HACK
	mov (Sprite PTR [ebx]).vX, 0 ;; Set vX ;; TODO: Make this move towards HIM
	mov (Sprite PTR [ebx]).vY, 1 ;; Set vY
	mov (Sprite PTR [ebx]).rotation, 0 ;; Set rotation
	lea ecx, Asteroid
	mov (Sprite PTR [ebx]).bitmapPtr, ecx ;; Set bitmap

	;; Mark that we added another asteroid
	inc ASTEROID_COUNT
	
	DONE:
	ret
SpawnAsteroid ENDP

MoveAsteroids PROC USES ebx ecx edx
	LOCAL x:DWORD, y:DWORD, vX:DWORD, vY:DWORD, bitmapPtr:DWORD
	LOCAL count:DWORD, address:DWORD, endAddr:DWORD

	;; Initialization
	lea ecx, ASTEROIDS
	mov address, ecx
	lea ecx, ASTEROID_COUNT
	mov ecx, [ecx]
	mov count, ecx
	imul ecx, 24
	add ecx, address
	mov endAddr, ecx

	jmp COND

	BODY:

	;; HACK FOR NOW - Fix this later
	lea ebx, ASTEROIDS
	mov edx, (Sprite PTR [ebx]).x
	mov x, edx
	mov edx, (Sprite PTR [ebx]).y
	mov y, edx
	mov edx, (Sprite PTR [ebx]).vX
	mov vX, edx
	mov edx, (Sprite PTR [ebx]).vY
	mov vY, edx

	;; Save fields
	;mov edx, (Sprite PTR [address]).x
	;mov x, edx
	;mov edx, (Sprite PTR [address]).y
	;mov y, edx
	;mov edx, (Sprite PTR [address]).vX
	;mov vX, edx
	;mov edx, (Sprite PTR [address]).vY
	;mov vY, edx
	lea edx, Asteroid ;;Correct
	mov bitmapPtr, edx

	;; Clear old asteroid sprite
	INVOKE ClearSprite, bitmapPtr, x, y, 0

	;; Calculate & save new sprite position
	mov edx, x
	add edx, vX
	;; mov (Sprite PTR [address]).x, edx
	mov (Sprite PTR [ebx]).x, edx
	mov x, edx
	mov ecx, [y]
	add ecx, vY
	;; mov (Sprite PTR [address]).y, ecx
	mov (Sprite PTR [ebx]).y, ecx
	mov y, ecx

	;; Check for collision
	INVOKE CheckIntersect, x, y, bitmapPtr, HIM.x, HIM.y, HIM.bitmapPtr
	cmp eax, 1
	jne DRAW
	dec ASTEROID_COUNT
	jmp INCREMENT

	;; Draw new sprite
	DRAW:
	INVOKE BasicBlit, bitmapPtr, x, y

	;; Move to next asteroid
	INCREMENT:
	mov ecx, SIZEOF Sprite
	add address, ecx

	COND:
	mov ebx, address
	cmp ebx, endAddr
	jl BODY

	ret
MoveAsteroids ENDP

CheckIntersect PROC USES ebx ecx edx oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP
	LOCAL TopLeftOneX:DWORD, TopLeftOneY:DWORD, BottomRightOneX:DWORD, BottomRightOneY:DWORD
	LOCAL TopLeftTwoX:DWORD, TopLeftTwoY:DWORD, BottomRightTwoX:DWORD, BottomRightTwoY:DWORD

	;; MARK: Calculate oneBitmap coordinates

	;; Store oneBitmap
	mov edx, oneBitmap

	;; Calculate oneBitmap.width / 2
	mov ebx, (EECS205BITMAP PTR [edx]).dwWidth
	shr ebx, 1
	
	;; Calculate oneBitmap.height / 2
	mov ecx, (EECS205BITMAP PTR [edx]).dwHeight
	shr ecx, 1

	;; Calculate left x coordinate
	mov eax, oneX
	sub eax, ebx
	mov TopLeftOneX, eax

	;; Calculate right x coordinate
	mov eax, oneX
	add eax, ebx
	mov BottomRightOneX, eax

	;; Calculate top y coordinate
	mov eax, oneY
	sub eax, ecx
	mov TopLeftOneY, eax

	;; Calculate bottom y coordinate
	mov eax, oneY
	add eax, ecx
	mov BottomRightOneY, eax

	;; MARK: Calculate twoBitmap coordinates

	;; Store twoBitmap
	mov edx, twoBitmap

	;; Calculate twoBitmap.width / 2
	mov ebx, (EECS205BITMAP PTR [edx]).dwWidth
	shr ebx, 1
	
	;; Calculate twoBitmap.height / 2
	mov ecx, (EECS205BITMAP PTR [edx]).dwHeight
	shr ecx, 1

	;; Calculate left x coordinate
	mov eax, twoX
	sub eax, ebx
	mov TopLeftTwoX, eax

	;; Calculate right x coordinate
	mov eax, twoX
	add eax, ebx
	mov BottomRightTwoX, eax

	;; Calculate top y coordinate
	mov eax, twoY
	sub eax, ecx
	mov TopLeftTwoY, eax

	;; Calculate bottom y coordinate
	mov eax, twoY
	add eax, ecx
	mov BottomRightTwoY, eax

	;; MARK: Calculate overlap

	;; Set initial return value to 0
	mov eax, 0

	;; Check for horizontal overlap (if either of these conditions are true, no overlap)
	mov ebx, TopLeftOneX
	cmp ebx, BottomRightTwoX
	jl CHECK_VERTICAL
	mov ebx, TopLeftTwoX
	cmp ebx, BottomRightOneX
	jl CHECK_VERTICAL

	CHECK_VERTICAL:
	;; Check for vertical overlap (if either of these conditions are true, no overlap)
	mov ebx, TopLeftOneY
	cmp ebx, BottomRightTwoY
	jg DONE
	mov ebx, TopLeftTwoY
	cmp ebx, BottomRightOneY
	jg DONE

	;; If we haven't jumped yet, there's an overlap
	mov eax, 1

	DONE:
	ret
CheckIntersect ENDP

END
