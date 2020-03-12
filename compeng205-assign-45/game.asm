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

include \masm32\include\user32.inc
;; include \masm32\lib\user32.lib
;;include \masm32\include\windows.inc
;;include \masm32\include\winmm.inc
;;include \masm32\lib\winmm.lib

include C:\masm32\include\masm32.inc
includelib C:\masm32\lib\masm32.lib
	
.DATA

;; Constants to track screen size
SCREEN_WIDTH DWORD 640
SCREEN_HEIGHT DWORD 480

;; Tracks if the game is over
GAME_OVER DWORD 0
PLAYER_1_WON DWORD 0
GAME_OVER_MSG BYTE "Game Over", 0
PLAYER_1_WINS_MSG BYTE "Player 1 Wins!", 0
PLAYER_2_WINS_MSG BYTE "Player 2 Wins!", 0

;;  Directions the rocket can face
UP = 0
RIGHT = 102943
DOWN = 205886
LEFT = 308829

;; Tracking the last mouse status
MOUSE_PRESSED DWORD 0

;; Tracking last relevant key pressed
KEY_PRESSED DWORD -1

;; Keep track of whether the game is paused
PAUSED DWORD 0

;; Keeps track of the current score
scoreStr BYTE "Score: %d", 0
asteroidsStr BYTE "Asteroids Remaining: %d", 0
missilesStr BYTE "Missiles Remaining: %d", 0
outStr BYTE 256 DUP(0)
SCORE DWORD 0

;; Our hero
HIM Sprite <>

;; Keep track of asteroids
MAX_ASTEROIDS =100
ASTEROIDS Sprite 100 DUP (<>)
ASTEROID_COUNT DWORD 0

;; Keep track of missiles
MAX_MISSILES = 100
MISSILES Sprite 100 DUP (<>)
MISSILE_COUNT DWORD 0

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
	INVOKE RotateBlit, OFFSET Fighter, ebx, ecx, 0

	;; Initialize HIM
	mov ebx, SCREEN_WIDTH
	shr ebx, 1
	mov ecx, SCREEN_HEIGHT
	shr ecx, 1
	mov HIM.x, ebx
	mov HIM.y, ecx
	mov HIM.enabled, 1

	;; Save sprite for HIM
	lea ebx, Fighter
	mov HIM.bitmapPtr, ebx

	;; Draw the scores
	INVOKE DrawScores

	DONE:
	ret
GameInit ENDP

GamePlay PROC USES ebx
	CHECK_GAME_OVER:
	cmp GAME_OVER, 0
	je CHECK_FOR_PAUSE
	INVOKE BlackStarField
	mov ebx, SCREEN_WIDTH
	shr ebx, 1
	sub ebx, 50
	mov ecx, SCREEN_HEIGHT
	shr ecx, 1
	sub ecx, 25
	INVOKE DrawStr, OFFSET GAME_OVER_MSG, ebx, ecx, 0ffh
	add ecx, 20
	sub ebx, 20
	cmp PLAYER_1_WON, 0
	je PLAYER_2_WINNER
	INVOKE DrawStr, OFFSET PLAYER_1_WINS_MSG, ebx, ecx, 0ffh
	jmp DONE
	PLAYER_2_WINNER:
	INVOKE DrawStr, OFFSET PLAYER_2_WINS_MSG, ebx, ecx, 0ffh
	jmp DONE

	;; Handles pausing the game
	CHECK_FOR_PAUSE:
	mov ebx, KeyPress
	cmp ebx, VK_BACK ;; Check for backspace
	je DONE

	;; Clear score text
	INVOKE ClearScores

	;; Move all asteroid and missile sprites
	MOVE_SPRITES:
	INVOKE MoveAsteroids
	INVOKE MoveMissiles

	;; Redraw Scores
	INVOKE DrawScores

	;; Check mouse state
	CHECK_MOUSE_STATE:

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
	;; Check if no keys are pressed or duplicate
	mov ebx, KeyPress
	cmp ebx, KEY_PRESSED
	mov ecx, KEY_PRESSED
	je DONE
	mov KEY_PRESSED, ebx
	cmp ebx, 0
	je DONE

	;; Handle Key Presses
	CHECK_LEFT:
	cmp ebx, VK_LEFT
	jne CHECK_RIGHT
	INVOKE RotateLeft

	CHECK_RIGHT:
	cmp ebx, VK_RIGHT
	jne CHECK_SHOOT
	INVOKE RotateRight

	CHECK_SHOOT:
	cmp ebx, VK_SPACE
	je SHOOT
	jmp DONE

	SHOOT:
	INVOKE SpawnMissile
	jmp DONE

	DONE:
	ret
GamePlay ENDP

ClearScores PROC USES ebx
	push SCORE
	push offset scoreStr
	push offset outStr
	call wsprintf
	add esp, 12
	INVOKE DrawStr, OFFSET outStr, 15, 20, 000h

	mov ebx, MAX_ASTEROIDS
	sub ebx, ASTEROID_COUNT
	push ebx
	push offset asteroidsStr
	push offset outStr
	call wsprintf
	add esp, 12
	INVOKE DrawStr, OFFSET outStr, 15, 390, 000h

	mov ebx, MAX_MISSILES
	sub ebx, MISSILE_COUNT
	push ebx
	push OFFSET missilesStr
	push OFFSET outStr
	call wsprintf
	add esp, 12
	INVOKE DrawStr, OFFSET outStr, 15, 410, 000h

	ret
ClearScores ENDP

DrawScores PROC USES ebx
	push SCORE
	push OFFSET scoreStr
	push OFFSET outStr
	call wsprintf
	add esp, 12
	INVOKE DrawStr, OFFSET outStr, 15, 20, 0ffh

	mov ebx, MAX_ASTEROIDS
	sub ebx, ASTEROID_COUNT
	push ebx
	push OFFSET asteroidsStr
	push OFFSET outStr
	call wsprintf
	add esp, 12
	INVOKE DrawStr, OFFSET outStr, 15, 390, 0ffh

	mov ebx, MAX_MISSILES
	sub ebx, MISSILE_COUNT
	push ebx
	push OFFSET missilesStr
	push OFFSET outStr
	call wsprintf
	add esp, 12
	INVOKE DrawStr, OFFSET outStr, 15, 410, 0ffh

	ret
DrawScores ENDP

RotateLeft PROC USES ebx ecx
	;; Clear current bitmap
	mov ebx, SCREEN_WIDTH
	shr ebx, 1
	mov ecx, SCREEN_HEIGHT
	shr ecx, 1
	INVOKE ClearSprite, HIM.bitmapPtr, ebx, ecx, HIM.rotation

	cmp HIM.rotation, UP
	je SET_TO_LEFT
	cmp HIM.rotation, LEFT
	je SET_TO_DOWN
	cmp HIM.rotation, DOWN
	je SET_TO_RIGHT

	;; Set the ship's new rotation
	SET_TO_UP:
	mov HIM.rotation, UP
	jmp ROTATE

	SET_TO_RIGHT:
	mov HIM.rotation, RIGHT
	jmp ROTATE

	SET_TO_DOWN:
	mov HIM.rotation, DOWN
	jmp ROTATE

	SET_TO_LEFT:
	mov HIM.rotation, LEFT

	ROTATE:
	;; Draw the new sprite
	INVOKE RotateBlit, HIM.bitmapPtr, ebx, ecx, HIM.rotation

	ret
RotateLeft ENDP

RotateRight PROC USES ebx ecx
	;; Clear current bitmap
	mov ebx, SCREEN_WIDTH
	shr ebx, 1
	mov ecx, SCREEN_HEIGHT
	shr ecx, 1
	INVOKE ClearSprite, HIM.bitmapPtr, ebx, ecx, HIM.rotation

	cmp HIM.rotation, UP
	je SET_TO_RIGHT
	cmp HIM.rotation, RIGHT
	je SET_TO_DOWN
	cmp HIM.rotation, DOWN
	je SET_TO_LEFT

	;; Set the ship's new rotation
	SET_TO_UP:
	mov HIM.rotation, UP
	jmp ROTATE

	SET_TO_RIGHT:
	mov HIM.rotation, RIGHT
	jmp ROTATE

	SET_TO_DOWN:
	mov HIM.rotation, DOWN
	jmp ROTATE

	SET_TO_LEFT:
	mov HIM.rotation, LEFT

	ROTATE:
	;; Draw the new sprite
	INVOKE RotateBlit, HIM.bitmapPtr, ebx, ecx, HIM.rotation

	ret
RotateRight ENDP

SpawnAsteroid PROC USES ebx ecx edx esi
	LOCAL x:DWORD, y:DWORD
	LOCAL vX: DWORD, vY:DWORD

	;; Do nothing if too many sprites
	cmp ASTEROID_COUNT, MAX_ASTEROIDS
	mov ebx, ASTEROID_COUNT
	jge DONE

	;; Decide whether to draw on top-bottom or left-right
	INVOKE nrandom, 2
	cmp eax, 1
	je LEFT_RIGHT

	TOP_BOTTOM:
	;; Set x coordinate to the middle of the screen
	mov ecx, SCREEN_WIDTH
	shr ecx, 1
	mov x, ecx ;; Set x coordinate to 0

	;; Decide whether to draw on top or bottom
	INVOKE nrandom, 2
	cmp eax, 1
	je PAINT_BOTTOM

	;; Paint on top
	PAINT_TOP:
	mov y, 0
	mov vX, 0
	mov vY, 2
	INVOKE BasicBlit, OFFSET Asteroid, x, 0
	jmp SAVE_SPRITE

	;; Paint on bottom
	PAINT_BOTTOM:
	mov ecx, SCREEN_HEIGHT
	mov y, ecx
	sub y, 50
	mov vX, 0
	mov vY, -2
	INVOKE BasicBlit, OFFSET Asteroid, x, y
	jmp SAVE_SPRITE

	LEFT_RIGHT:
	;; Set y coordinate to the middle of the screen
	mov ecx, SCREEN_HEIGHT
	shr ecx, 1
	mov y, ecx ;; Set y coordinate to 0

	;; Decide whether to draw on left or right
	INVOKE nrandom, 2
	cmp eax, 1
	je PAINT_RIGHT

	;; Paint on left
	PAINT_LEFT:
	mov x, 0
	mov vX, 2
	mov vY, 0
	INVOKE BasicBlit, OFFSET Asteroid, x, y
	jmp SAVE_SPRITE

	;; Paint on right
	PAINT_RIGHT:
	mov ecx, SCREEN_WIDTH
	mov x, ecx
	sub x, 50  ;; Adjust for asteroid width
	mov vX, -2
	mov vY, 0
	INVOKE BasicBlit, OFFSET Asteroid, x, y
	jmp SAVE_SPRITE

	;; Save sprite in memory
	SAVE_SPRITE:

	;; Get index to save current asteroid
	mov ebx, SIZEOF Sprite
	imul ebx, ASTEROID_COUNT
	lea ecx, ASTEROIDS
	add ebx, ecx

	;; Redraw count
	INVOKE ClearScores
	inc ASTEROID_COUNT
	INVOKE DrawScores

	;; Check if the game is over
	cmp ASTEROID_COUNT, MAX_ASTEROIDS
	jl CONTINUE
	mov PLAYER_1_WON, 1
	mov GAME_OVER, 1

	CONTINUE:
	;; Save position of asteroid sprite
	mov edx, x
	mov (Sprite PTR [ebx]).x, edx ;; Set x
	mov edx, y
	mov (Sprite PTR [ebx]).y, edx ;; Set y

	;; Save velocity fields of asteroid
	mov ecx, vX
	mov (Sprite PTR [ebx]).vX, ecx ;; Set vX
	mov ecx, vY
	mov (Sprite PTR [ebx]).vY, ecx ;; Set vY
	lea ecx, Asteroid
	mov (Sprite PTR [ebx]).bitmapPtr, ecx ;; Set bitmap
	mov (Sprite PTR [ebx]).enabled, 1 ;; enable the sprite

	DONE:
	ret
SpawnAsteroid ENDP

SpawnMissile PROC USES ebx ecx edx esi
	LOCAL x:DWORD, y:DWORD, vX:DWORD, vY:DWORD

	;; Do nothing if too many sprites
	cmp MISSILE_COUNT, MAX_MISSILES
	mov ebx, MISSILE_COUNT
	jge DONE
	
	;; Draw missile based on ship rotation
	mov ebx, HIM.x
	mov ecx, HIM.y

	;; Decide where to draw the missile
	cmp HIM.rotation, RIGHT
	je DRAW_RIGHT
	cmp HIM.rotation, DOWN
	je DRAW_DOWN
	cmp HIM.rotation, LEFT
	je DRAW_LEFT

	DRAW_UP:
	sub ecx, 25
	mov vX, 0
	mov vY, -10
	jmp DRAW_MISSILE

	DRAW_RIGHT:
	add ebx, 25
	mov vX, 10
	mov vY, 0
	jmp DRAW_MISSILE

	DRAW_DOWN:
	add ecx, 25
	mov vX, 0
	mov vY, 10
	jmp DRAW_MISSILE

	DRAW_LEFT:
	sub ebx, 25
	mov vX, -10
	mov vY, 0

	DRAW_MISSILE:
	mov x, ebx
	mov y, ecx
	INVOKE BasicBlit, OFFSET Missile, x, y

	;; Save sprite in memory
	SAVE_SPRITE:
	;; Get index to save current missile
	mov ebx, SIZEOF Sprite
	imul ebx, MISSILE_COUNT
	lea ecx, MISSILES
	add ebx, ecx

	;; Save position of missile Sprite
	mov edx, x
	mov (Sprite PTR [ebx]).x, edx ;; Set x
	mov edx, y
	mov (Sprite PTR [ebx]).y, edx ;; Set y

	;; Save velocity fields of missile
	mov ecx, vX
	mov (Sprite PTR [ebx]).vX, ecx ;; Set vX
	mov ecx, vY
	mov (Sprite PTR [ebx]).vY, ecx ;; Set vY

	;; Set other fields of missile
	lea ecx, Missile
	mov (Sprite PTR [ebx]).bitmapPtr, ecx ;; Set bitmap
	mov (Sprite PTR [ebx]).enabled, 1 ;; enable the sprite

	;; Mark that we added another missile & redraw scores
	INVOKE ClearScores
	inc MISSILE_COUNT
	INVOKE DrawScores
	cmp MISSILE_COUNT, MAX_MISSILES
	jl DONE
	mov GAME_OVER, 1
	
	DONE:
	ret
SpawnMissile ENDP

MoveAsteroids PROC USES ebx ecx edx
	LOCAL x:DWORD, y:DWORD, vX:DWORD, vY:DWORD, bitmapPtr:DWORD
	LOCAL count:DWORD, address:DWORD, endAddr:DWORD

	;; Store address of ASTEROIDS
	lea ecx, ASTEROIDS
	mov address, ecx

	;; Find the end of the array
	mov edx, MAX_ASTEROIDS
	mov count, edx
	imul edx, SIZEOF Sprite
	add edx, address
	mov endAddr, edx

	;; Start the loop
	jmp COND

	BODY:
	;; Check if the sprite is enabled
	cmp (Sprite PTR [ebx]).enabled, 0
	je INCREMENT

	;; Save fields
	mov edx, (Sprite PTR [ebx]).x
	mov x, edx
	mov edx, (Sprite PTR [ebx]).y
	mov y, edx
	mov edx, (Sprite PTR [ebx]).vX
	mov vX, edx
	mov edx, (Sprite PTR [ebx]).vY
	mov vY, edx
	lea edx, Asteroid
	mov bitmapPtr, edx

	;; Clear old asteroid sprite
	INVOKE ClearSprite, bitmapPtr, x, y, 0

	;; Calculate & save new sprite position
	mov edx, x
	add edx, vX
	mov (Sprite PTR [ebx]).x, edx
	mov x, edx
	mov edx, y
	add edx, vY
	mov (Sprite PTR [ebx]).y, edx
	mov y, edx

	;; Check for collision
	INVOKE CheckIntersect, x, y, bitmapPtr, HIM.x, HIM.y, HIM.bitmapPtr
	cmp eax, 1
	jne DRAW

	;; Collision occurred
	dec ASTEROID_COUNT
	mov (Sprite PTR [ebx]).enabled, 0

	;; Decrease score
	sub SCORE, 10

	;; Game over if you have -25 points or less
	cmp SCORE, -25
	jg INCREMENT
	mov GAME_OVER, 1
	jmp INCREMENT

	;; Draw new sprite
	DRAW:
	INVOKE BasicBlit, bitmapPtr, x, y

	;; Move to next asteroid
	INCREMENT:
	mov ecx, SIZEOF Sprite
	add address, ecx

	COND:
	;; ebx holds the current address
	mov ebx, address
	cmp ebx, endAddr
	jl BODY

	ret
MoveAsteroids ENDP

MoveMissiles PROC USES ebx ecx edx
	LOCAL x:DWORD, y:DWORD, vX:DWORD, vY:DWORD, bitmapPtr:DWORD
	LOCAL count:DWORD, address:DWORD, endAddr:DWORD

	;; Store address of MISSILES
	lea ecx, MISSILES
	mov address, ecx

	;; Find the end of the array
	mov edx, MAX_MISSILES
	mov count, edx
	imul edx, SIZEOF Sprite
	add edx, address
	mov endAddr, edx

	;; Start the loop
	jmp COND

	BODY:
	;; Check if the sprite is enabled
	cmp (Sprite PTR [ebx]).enabled, 0
	je INCREMENT

	;; Save fields
	mov edx, (Sprite PTR [ebx]).x
	mov x, edx
	mov edx, (Sprite PTR [ebx]).y
	mov y, edx
	mov edx, (Sprite PTR [ebx]).vX
	mov vX, edx
	mov edx, (Sprite PTR [ebx]).vY
	mov vY, edx
	lea edx, Missile
	mov bitmapPtr, edx

	;; Clear old missile sprite
	INVOKE ClearSprite, bitmapPtr, x, y, 0

	;; Calculate & save new sprite position
	mov edx, x
	add edx, vX
	mov (Sprite PTR [ebx]).x, edx
	mov x, edx
	mov edx, y
	add edx, vY
	mov (Sprite PTR [ebx]).y, edx
	mov y, edx

	;; Check for collision with asteroids
	mov ecx, ASTEROID_COUNT
	lea esi, ASTEROIDS
	jmp COND_INNER

	BODY_ASTEROID:
	;; Check if the sprite is enabled
	cmp (Sprite PTR [esi]).enabled, 0
	je INCREMENT_ASTEROID

	;; Check for collision
	INVOKE CheckIntersect, x, y, bitmapPtr, (Sprite PTR [esi]).x, (Sprite PTR [esi]).y, (Sprite PTR [esi]).bitmapPtr
	cmp eax, 1
	je COLLISION

	;; Move to next asteroid
	INCREMENT_ASTEROID:
	add esi, SIZEOF Sprite ;; move to next sprite address
	dec ecx

	COND_INNER:
	;; ecx holds the # of asteroids we have left to check
	cmp ecx, 0
	jle DRAW
	jmp BODY_ASTEROID

	;; Collision occurred
	COLLISION:
	mov (Sprite PTR [ebx]).enabled, 0
	mov (Sprite PTR [esi]).enabled, 0

	;; Clear sprites
	INVOKE ClearSprite, (Sprite PTR [esi]).bitmapPtr, (Sprite PTR [esi]).x, (Sprite PTR [esi]).y, 0
	INVOKE ClearSprite, bitmapPtr, x, y, 0

	;; Increment Score
	inc SCORE

	jmp INCREMENT

	;; Draw new sprite
	DRAW:
	INVOKE BasicBlit, bitmapPtr, x, y

	;; Move to next missile
	INCREMENT:
	mov ecx, SIZEOF Sprite
	add address, ecx

	COND:
	;; ebx holds the current address
	mov ebx, address
	cmp ebx, endAddr
	jl BODY

	ret
MoveMissiles ENDP

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
	cmp eax, 0
	jl SET_LEFT_0
	mov TopLeftOneX, eax
	jmp RIGHT_X
	SET_LEFT_0:
	mov TopLeftOneX, 0

	RIGHT_X:
	;; Calculate right x coordinate
	mov eax, oneX
	add eax, ebx
	mov BottomRightOneX, eax

	;; Calculate top y coordinate
	mov eax, oneY
	sub eax, ecx
	cmp eax, 0
	jl SET_TOP_0
	mov TopLeftOneY, eax
	jmp BOTTOM_Y
	SET_TOP_0:
	mov TopLeftOneY, 0

	BOTTOM_Y:
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
	cmp eax, 0
	jge SET_TWO_X
	mov TopLeftTwoX, 0
	jmp RIGHT_X_2
	SET_TWO_X:
	mov TopLeftTwoX, eax

	RIGHT_X_2:
	;; Calculate right x coordinate
	mov eax, twoX
	add eax, ebx
	mov BottomRightTwoX, eax

	;; Calculate top y coordinate
	mov eax, twoY
	sub eax, ecx
	cmp eax, 0
	jge SET_TWO_Y
	mov TopLeftTwoY, 0
	jmp BOTTOM_Y_2
	SET_TWO_Y:
	mov TopLeftTwoY, eax

	BOTTOM_Y_2:
	;; Calculate bottom y coordinate
	mov eax, twoY
	add eax, ecx
	mov BottomRightTwoY, eax

	;; MARK: Calculate overlap

	;; Set initial return value to 0
	mov eax, 0

	;; Check for horizontal overlap (if either of these conditions are true, we have to keep checking)
	mov ebx, TopLeftOneX
	cmp ebx, BottomRightTwoX
	jg DONE
	mov ebx, TopLeftTwoX
	cmp ebx, BottomRightOneX
	jg DONE

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
