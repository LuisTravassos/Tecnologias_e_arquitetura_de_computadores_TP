.8086
.model small
.stack 2048h

dseg    segment para public 'data'
        Erro_Open       db      'Erro ao tentar abrir o ficheiro$'
        Erro_Ler_Msg    db      'Erro ao tentar ler do ficheiro$'
        Erro_Close      db      'Erro ao tentar fechar o ficheiro$'
        FTable         	db      'TABLE.TXT',0  ; Nome do ficheiro a ir buscar / table.TXT
		HandleFich      dw      0
        car_fich        db      ?
		FMenu         	db      'MENU.TXT',0  ; Nome do ficheiro a ir buscar / MENU.TXT
        HandleMenu      dw      0
        car_Menu        db      ?
		
		Car			db	32	; Guarda um caracter do Ecran 
		Cor			db	11	; Guarda os atributos de cor do caracter / BIOS color attributes
		POSy		db	1	; a linha pode ir de [1 .. 25]
		POSx		db	2	; POSx pode ir [1..80]	
dseg    ends


cseg    segment para public 'code'
		assume  cs:cseg, ds:dseg


;########################################################################
;ROTINA PARA COLOCAR CURSOR NA POSIÇÂO PRETENDIDA
goto_xy	macro		POSx,POSy
		mov		ah,02h
		mov		bh,0		; numero da página
		mov		dl,POSx
		mov		dh,POSy
		int		10h   ; Set Cursor Position
endm

;########################################################################
;ROTINA PARA APAGAR ECRAN

apaga_ecran	proc
		xor		bx,bx
		mov		cx,25*80
		
apaga:	mov	byte ptr es:[bx],' '
		mov		byte ptr es:[bx+1],11   ;AQUI COLOCAS A COR!!!!!!!!
		inc		bx
		inc 	bx
		loop	apaga
		ret
apaga_ecran	endp


;########################################################################
; LE UMA TECLA	

LE_TECLA	PROC

		mov		ah,08h
		int		21h   ;Console Input Without Echo
		mov		ah,0
		cmp		al,0
		jne		SAI_TECLA
		mov		ah, 08h
		int		21h    ;Console Input Without Echo
		mov		ah,1
SAI_TECLA:	RET
LE_TECLA	endp
;########################################################################

;########################################################################
; Assinala caracter no ecran	

assinala_P	PROC


CICLO:	
		; goto_xy	POSxa,POSya	; Vai para a posição anterior do cursor
		; mov		ah, 02h
		; mov		dl, Car	; Repoe Caracter guardado 
		; int		21H		
		
		goto_xy	POSx,POSy	; Vai para nova posição
		mov 	ah, 08h
		mov		bh,0		; numero da página
		int		10h			;Read Character and Attribute at Cursor Position
		mov		Car, al		; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah		; Guarda a cor que está na posição do Cursor
		
		goto_xy	78,0		; Mostra o caractereque estava na posição do AVATAR
		mov		ah, 02h		; IMPRIME caracter da posição no canto
		mov		dl, Car	
		int		21H			;Display Output
	
		goto_xy	POSx,POSy	; Vai para posição do cursor
IMPRIME:	
		; mov		ah, 02h
		; mov		dl, 190		; Coloca AVATAR
		; int		21H	
		; goto_xy	POSx,POSy	; Vai para posição do cursor
		
		; mov		al, POSx	; Guarda a posição do cursor	
		; mov		POSxa, al
		; mov		al, POSy	; Guarda a posição do cursor
		; mov 	POSya, al
		
LER_SETA:	
		call 	LE_TECLA
		cmp		ah, 1
		je		ESTEND
		
		CMP 	AL, 27	; ESCAPE
		JE		FIM
		CMP		AL, 13
		je		ASSINALA
		jmp		LER_SETA
		
ESTEND:	cmp 	al,48h
		jne		BAIXO
		dec		POSy		;cima
		cmp 	POSy, 0
		jbe		RETURNUP
		jmp		CICLO

RETURNUP: 						;Não sai por cima do tabuleiro
		mov POSy, 1
		jmp CICLO

BAIXO:	cmp		al,50h
		jne		ESQUERDA
		inc 	POSy		;Baixo
		cmp 	POSy, 12
		jae		RETURNDOWN
		jmp		CICLO

RETURNDOWN: 						;Não sai por cima do tabuleiro
		mov POSy, 11
		jmp CICLO

ESQUERDA:
		cmp		al,4Bh
		jne		DIREITA
		dec		POSx		;Esquerda
		dec		POSx		;Esquerda
		cmp 	POSx, 0
		jbe		RETURNLEFT
		jmp		CICLO

RETURNLEFT: 						;Não sai por cima do tabuleiro
		mov POSx, 2
		jmp CICLO

DIREITA:
		cmp		al,4Dh
		jne		LER_SETA 
		inc		POSx		;Direita
		inc		POSx		;Direita
		cmp 	POSx, 26
		jae		RETURNRIGHT
		jmp		CICLO

RETURNRIGHT: 						;Não sai por cima do tabuleiro
		mov POSx, 24
		jmp CICLO



				; INT 10,9 - Write Character and Attribute at Cursor Position
				; AH = 09
				; AL = ASCII character to write
				; BH = display page  (or mode 13h, background pixel value)
				; BL = character attribute (text) foreground color (graphics)
				; CX = count of characters to write (CX >= 1)
ASSINALA:
		mov		bl, cor
		not		bl
		mov		cor, bl
		mov 	ah, 09h
		mov		al, car
		mov		bh, 0
		mov		cx, 1
		int		10h  ;Write Character and Attribute at Cursor Position
		jmp		CICLO
fim:	
		RET
assinala_P	endp
;########################################################################







;########################################################################
;ROTINA PARA IMPRIMIR FICHEIRO NO ECRAN

imp_Ficheiro	proc

		

;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,FTable
        int     21h   ;Open File Using Handle
        jc      erro_abrir
        mov     HandleFich,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai

ler_ciclo:
        mov     ah,3fh
        mov     bx,HandleFich
        mov     cx,1
        lea     dx,car_fich
        int     21h   ;Read From File or Device Using Handle
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_fich
		int		21h  ;Display Output
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleFich
        int     21h   ;Close File using Handle
        jnc     sai

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h
sai:

		ret
imp_Ficheiro	endp


;########################################################################
;ROTINA PARA IMPRIMIR FICHEIRO NO ECRAN

imp_Menu	proc

		

;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,FMenu
        int     21h
        jc      erro_abrir
        mov     HandleMenu,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai

ler_ciclo:
        mov     ah,3fh
        mov     bx,HandleMenu
        mov     cx,1
        lea     dx,car_Menu
        int     21h
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
        mov     ah,02h
		mov		dl,car_Menu
		int		21h
		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleMenu
        int     21h
        jnc     sai

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h
sai:

		ret
imp_Menu	endp


;########################################################################

Main    Proc

        mov     ax,dseg
        mov     ds,ax

			;MAIN PROCEDIMENTO
		mov		ax,0B800h
		mov		es,ax
		call 	apaga_ecran
		goto_xy	0,0
		call	imp_Ficheiro
		;call	imp_Menu
		call	assinala_P
		goto_xy	0,22

		
        mov     ah,4ch
        int     21h
Main    endp
cseg	ends
end     Main           
