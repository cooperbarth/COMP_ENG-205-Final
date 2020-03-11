; #########################################################################
;
;   blit.inc - Includes for CompEng205 Assignment 3
;
;
; #########################################################################

_EECS205BITMAP STRUCT
 dwWidth      DWORD  ?
 dwHeight     DWORD  ?
 bTransparent BYTE   ?
              BYTE   3 DUP(?)
 lpBytes      DWORD  ?
_EECS205BITMAP ENDS

EECS205BITMAP TYPEDEF _EECS205BITMAP

_Sprite STRUCT
	x DWORD ?
	y DWORD ?
	vX DWORD 0
	vY DWORD 0
	rotation FXPT 0
	bitmapPtr DWORD ?
_Sprite ENDS

Sprite TYPEDEF _Sprite

EXTERNDEF ScreenBitsPtr:DWORD

BasicBlit PROTO STDCALL ptrBitmap:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD

RotateBlit PROTO STDCALL ptrBitmap:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT

ClearSprite PROTO STDCALL ptrBitmap:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT
