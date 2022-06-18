;########################################################################
;ROTINA PARA COLOCAR CURSOR NA POSIÇÂO PRETENDIDA1

goto_xy	macro		POSx,POSy
		mov		ah,02h
		mov		bh,0		; numero da página
		mov		dl,POSx
		mov		dh,POSy
		int		10h   ; Set Cursor Position
endm

;########################################################################
;MOSTRA - Faz o display de uma string terminada em $

MOSTRA MACRO STR 
	MOV AH,09H
	LEA DX,STR 
	INT 21H
ENDM

;########################################################################

.8086
.model small
.stack 2048h

dseg    segment para public 'data'

		;Ficheiros
		;##########################################################################
        Erro_Open       db      'Erro ao tentar abrir o ficheiro$'
        Erro_Ler_Msg    db      'Erro ao tentar ler do ficheiro$'
        Erro_Close      db      'Erro ao tentar fechar o ficheiro$'
        FTable         	db      'TABLE.TXT',0  ; Nome do ficheiro a ir buscar / table.TXT
		HandleFich      dw      0
        car_fich        db      ?
		FMenu         	db      'MENU.TXT',0  ; Nome do ficheiro a ir buscar / MENU.TXT
        HandleMenu      dw      0
        car_Menu        db      ?
		FWORDS         	db      'WORDS.TXT',0  ; Nome do ficheiro a ir buscar / Words.TXT
		HandleWord      dw      0
        car_Word        db      ?
		Palavras		db		?
		Posicoes		db		?

		;Variaveis suporte
		;##########################################################################

		ultimo_num_aleat dw 0 		;ultimo numero aleatorio / numero aleatório
		Car1			db	32	; Guarda um caracter do Ecran 
		Car2			db	32	; Guarda um caracter do Ecran 
		Cor			db	11	; Guarda os atributos de cor do caracter / BIOS color attributes
		POSy		db	1	; a linha pode ir de [1 .. 25]
		POSx		db	2	; POSx pode ir [1..80]
		Counter		db	0	; Serve para contar repetições, colocar a zero no inicio de uso	
		Helper		dw	?	; Serve para ajudar a transportar valores, colocar valor nele antes de usar

		;Variaveis para tempo e horas
		;############################################################################

		STR12	 	DB 		"            "	; String para 12 digitos
		DDMMAAAA 	db		"                     "
		Horas		dw		0				; Vai guardar a HORA actual
		Minutos		dw		0				; Vai guardar os minutos actuais
		Segundos	dw		0				; Vai guardar os segundos actuais
		Old_seg		dw		0				; Guarda os últimos segundos que foram lidos


dseg    ends


cseg    segment para public 'code'
		assume  cs:cseg, ds:dseg

PILHA	SEGMENT PARA STACK 'STACK'
		db 2048 dup(?)
PILHA	ENDS

;########################################################################

;ROTINA PARA MANIPULAR HORAS E MINUTOS

Ler_TEMPO PROC	
 
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
	
		PUSHF
		
		MOV AH, 2CH             ; Buscar a hORAS
		INT 21H                 
		
		XOR AX,AX
		MOV AL, DH              ; segundos para al
		mov Segundos, AX		; guarda segundos na variavel correspondente
		
		POPF
		POP DX
		POP CX
		POP BX
		POP AX
 		RET 
Ler_TEMPO   ENDP 

Trata_Horas PROC
PUSHF
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX		

		CALL 	Ler_TEMPO				; Horas MINUTOS e segundos do Sistema
		
		MOV		AX, Segundos
		cmp		AX, Old_seg			; VErifica se os segundos mudaram desde a ultima leitura
		je		fim_horas			; Se a hora não mudou desde a última leitura sai.
		mov		Old_seg, AX			; Se segundos são diferentes actualiza informação do tempo 

		MOV 	bl, 10     
		div 	bl
		add 	al, 30h				; Caracter Correspondente às dezenas
		add		ah,	30h				; Caracter Correspondente às unidades
		MOV 	STR12[0],al			; 
		MOV 	STR12[1],ah
		MOV 	STR12[2],'s'		
		MOV 	STR12[3],'$'
		goto_xy	10,13
		MOSTRA	STR12 		
        					
fim_horas:		
		goto_xy	POSx,POSy			; Volta a colocar o cursor onde estava antes de actualizar as horas
		
		POPF
		POP DX		
		POP CX
		POP BX
		POP AX
		RET		
			
Trata_Horas ENDP


;########################################################################

;ROTINA PARA CRIAR NUMERO ALEATORIO

CalcAleat proc near

	sub	sp,2
	push	bp
	mov	bp,sp
	push	ax
	push	cx
	push	dx	
	mov	ax,[bp+4]
	mov	[bp+2],ax

	mov	ah,00h
	int	1ah

	add	dx,ultimo_num_aleat
	add	cx,dx	
	mov	ax,65521
	push	dx
	mul	cx
	pop	dx
	xchg	dl,dh
	add	dx,32749
	add	dx,ax

	mov	ultimo_num_aleat,dx

	mov	[BP+4],dx

	pop	dx
	pop	cx
	pop	ax
	pop	bp
	ret
CalcAleat endp

;########################################################################
;ROTINA PARA APAGAR ECRAN

apaga_ecran	proc
		xor		bx,bx
		mov		cx,25*80
		
apaga:	mov	byte ptr es:[bx], ' '
		mov		byte ptr es:[bx+1],15   ;AQUI COLOCAS A COR DAS LETRAS!!!!!!!!
		inc		bx
		inc 	bx
		loop	apaga
		ret
apaga_ecran	endp


;#############################################################################
;ROTINA PARA MUDAR COR

muda_cor	proc
		xor		bx,bx
		mov		cx,25*80
		
muda:	
		mov al, es:[bx]
		cmp al,'#'
		jne next
		mov		byte ptr es:[bx+1],3   ;AQUI COLOCAS A COR DOS CARDINAIS!!!!!!!!
next:	
		inc bx
		inc bx
		loop 	muda
fim:
		ret
		
muda_cor	endp

;########################################################################
; LE UMA TECLA	
LE_TECLA_TABELA	PROC
sem_tecla:
		call Trata_Horas
		MOV	AH,0BH
		INT 21h
		cmp AL,0
		je	sem_tecla
		
		MOV	AH,08H
		INT	21H
		MOV	AH,0
		CMP	AL,0
		JNE	SAI_TECLA
		MOV	AH, 08H
		INT	21H
		MOV	AH,1
SAI_TECLA:	
		RET
LE_TECLA_TABELA	ENDP

LE_TECLA_MENU PROC
		MOV	AH,08H
		INT	21H
		MOV	AH,0
		CMP	AL,0
		JNE	SAI_TECLA
		MOV	AH, 08H
		INT	21H
		MOV	AH,1
SAI_TECLA:	
		RET
LE_TECLA_MENU	ENDP
;########################################################################

;########################################################################
; Assinala caracter na tabela no ecran	

assinala_P	PROC
		push ax
		push bx
		push cx
		push dx

		xor ax, ax
		xor bx, bx
		xor cx, cx
		xor dx, dx

		mov POSx, 2
		mov POSy, 1

CICLO:	
		mov 	ah, 08h
		mov		bh,0		; numero da página
		int		10h			; Read Character and Attribute at Cursor Position
		;mov		Car1, al	; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah		; Guarda a cor que está na posição do Cursor
		
		goto_xy	78,0		; Mostra o caractereque estava na posição do AVATAR
		mov		ah, 02h		; IMPRIME caracter da posição no canto
		mov		dl, Car1	
		int		21H			; Display Output
		goto_xy	POSx,POSy	; Vai para posição do cursor
		
LER_SETA:	

		call 	LE_TECLA_TABELA
		cmp		ah, 1
		je		ESTEND
		CMP 	AL, 27	; ESCAPE
		JE		FIM
		CMP		AL, 13
		je		ASSINALA
		jmp		LER_SETA
		
ESTEND:	
		cmp 	al,48h
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
		mov 	ah, 08h
		mov		bh,0		; numero da página
		int		10h			; Read Character and Attribute at Cursor Position
		mov		Car1, al		; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah		; Guarda a cor que está na posição do Cursor


		mov		bl, cor
		not		bl
		mov		cor, bl
		mov 	ah, 09h
		mov		al, Car1
		mov		bh, 0
		mov		cx, 1
		int		10h  ;Write Character and Attribute at Cursor Position
		jmp		CICLO

fim:	
		pop 	dx
		pop cx
		pop bx
		pop ax
		RET
assinala_P	endp
;########################################################################



;########################################################################
; Assinala caracter no menu no ecran	

assinala_Menu	PROC
		mov POSx, 29
		mov POSy, 3

CICLO:	
		; goto_xy	POSxa,POSya	; Vai para a posição anterior do cursor
		; mov		ah, 02h
		; mov		dl, Car	; Repoe Caracter guardado 
		; int		21H		
		
		
		goto_xy	POSx,POSy	; Vai para nova posição
		mov 	ah, 08h
		mov		bh,0		; numero da página
		int		10h			; Read Character and Attribute at Cursor Position
		mov		Car2, al		; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah		; Guarda a cor que está na posição do Cursor
		
		;goto_xy	78,0		; Mostra o caractereque estava na posição do AVATAR
		;mov		ah, 02h		; IMPRIME caracter da posição no canto
		;mov		dl, Car	
		;int		21H			;Display Output
	
		;goto_xy	POSx,POSy	; Vai para posição do cursor
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
		call 	LE_TECLA_MENU
		cmp		ah, 1
		je		ESTEND
		
		CMP 	AL, 27	; ESCAPE
		JE		FIM
		CMP		AL, 13  ; ENTER
		je		ASSINALA
		jmp		LER_SETA
		
ESTEND:	cmp 	al,48h
		jne		BAIXO
		dec		POSy		;cima
		dec		POSy
		dec		POSy
		dec		POSy
		dec		POSy
		cmp 	POSy, -2
		jbe		RETURNUP
		jmp		CICLO

RETURNUP: 						;Não sai por cima do tabuleiro
		mov POSy, 3
		jmp CICLO

BAIXO:	cmp		al,50h
		jne		LER_SETA 		;É só para andar para cima e para baixo
		inc 	POSy		;Baixo
		inc 	POSy
		inc 	POSy
		inc 	POSy
		inc 	POSy
		cmp 	POSy, 18
		jae		RETURNDOWN
		jmp		CICLO

RETURNDOWN: 						;Não sai por cima do tabuleiro
		mov POSy, 13
		jmp CICLO


ASSINALA:
		cmp POSy, 3
		je 		fim
		cmp POSy, 8
		je		SAIR
		cmp POSy, 13
		je		SAIR
		jmp		CICLO

SAIR:
		call 	apaga_ecran
		goto_xy	0,0
		mov     ah,4ch
        int     21h

fim:	
		RET
assinala_Menu	endp
;########################################################################

;########################################################################
;ROTINA PARA IMPRIMIR Palavras NO ECRAN

imp_Palavras	proc

		push	ax
		push	bx
		push	cx
		push	dx
		mov Counter, 0
		mov Helper, 0

;abre tabela
        mov     ah,3dh
        mov     al,0
        lea     dx,FWORDS
        int     21h   ;Open File Using Handle
        jc      erro_abrir
        mov     HandleWord,ax
        jmp     ler_ciclo

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai

ler_ciclo:
		xor 	ax, ax
		xor		bx, bx
		xor		dx, dx
		xor 	cx, cx

        mov     ah,3fh
        mov     bx,HandleWord
        mov     cx,1
        lea     dx,car_Word
        int     21h   ;Read From File or Device Using Handle
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
		mov		dl, car_Word

		cmp		Counter, 0
		je		PrimeiroX
		cmp		Counter, 1
		je		SegundoX

		cmp		Counter, 2
		je		PrimeiroY
		cmp		Counter, 3
		je		SegundoY
		cmp		Counter, 4
		je		Contas
		cmp		Counter, 5
		je 		Direction

		

PrimeiroX:
		xor 	ax,ax
		sub		dl, 30h
		mov		al, 10
		mul		dl			;AX tem o primeiro valor

		inc 	Counter
		mov		Helper, ax
		jmp 	ler_ciclo

SegundoX:
		mov		ax, Helper
		sub		dl, 30h
		add		al, dl			
		adc		ah, 0         ;AX tem o valor total

		inc 	Counter
		mov		Posx, al
		jmp 	ler_ciclo

PrimeiroY:
		xor 	ax,ax
		sub		dl, 30h
		mov		al, 10
		mul		dl			;AX tem o primeiro valor

		inc 	Counter
		mov		Helper, ax
		jmp 	ler_ciclo

SegundoY:
		mov		ax, Helper
		sub		dl, 30h
		add		al, dl			
		adc		ah, 0         ;AX tem o valor total

		inc 	Counter
		mov		Posy, al
		jmp 	ler_ciclo

Contas:
		;Contas

		xor 	ax, ax
		xor 	bx, bx

		mov 	al, Posy
		mov 	bx, 160
		mul 	bx		;ax tem o valor de Py

		mov		bx, ax

		xor 	ax, ax
		mov		al, 2
		mul		Posx      ;ax tem o valor de Px

		add 	ax, bx
		mov		Helper, ax

		inc 	Counter
		jmp 	ler_ciclo

Direction:
		cmp		dl, 31h
		je		horizontal
		cmp		dl, 32h
		je		vertical
		cmp		dl, 33h
		je		diagonal

horizontal:
		xor 	ax, ax
		xor		bx, bx
		xor		dx, dx
		xor 	cx, cx

        mov     ah,3fh
        mov     bx,HandleWord
        mov     cx,1
        lea     dx,car_Word
        int     21h   ;Read From File or Device Using Handle
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
		mov		dl, car_Word

		cmp		dl, 24h
		je		reset

		mov 	bx, Helper
		mov		byte ptr es:[bx], dl
		inc		Helper
		inc		Helper
		inc		Helper
		inc		Helper

		jmp		horizontal

vertical:
		xor 	ax, ax
		xor		bx, bx
		xor		dx, dx
		xor 	cx, cx

        mov     ah,3fh
        mov     bx,HandleWord
        mov     cx,1
        lea     dx,car_Word
        int     21h   ;Read From File or Device Using Handle
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
		mov		dl, car_Word

		cmp		dl, 24h
		je		reset

		mov 	bx, Helper
		mov		byte ptr es:[bx], dl

		mov		ax, 160
		add		Helper, ax

		jmp		vertical

diagonal:
		xor 	ax, ax
		xor		bx, bx
		xor		dx, dx
		xor 	cx, cx

        mov     ah,3fh
        mov     bx,HandleWord
        mov     cx,1
        lea     dx,car_Word
        int     21h   ;Read From File or Device Using Handle
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
		mov		dl, car_Word

		cmp		dl, 24h
		je		reset

		mov 	bx, Helper
		mov		byte ptr es:[bx], dl

		mov		ax, 164
		add		Helper, ax

		jmp		diagonal

reset:
		mov		Counter, 0
		mov		Helper, 0

		mov     ah,3fh
        mov     bx,HandleWord
        mov     cx,1
        lea     dx,car_Word
        int     21h   ;Read From File or Device Using Handle
		jc		erro_ler
		cmp		ax,0		;EOF?
		je		fecha_ficheiro
		mov		dl, car_Word

		jmp		ler_ciclo

erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleWord
        int     21h   ;Close File using Handle
        jnc     sai

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h

sai:	
		pop 	dx
		pop 	cx
		pop 	bx
		pop 	ax
		ret
imp_Palavras	endp


;########################################################################
;ROTINA PARA IMPRIMIR letras random NO ECRAN

imp_Letras	proc

		push	ax
		push	bx
		push	cx
		push	dx
		mov POSx, 2
		mov POSy, 1
		mov Counter, 0

ler_ciclo:
		call	CalcAleat
		pop	ax ; vai buscar 'a pilha o numero aleatorio

		goto_xy	POSx,POSy
        
		mov		dl, al
		cmp 	dl, 41h
		jb		ler_ciclo
		cmp 	dl, 5Ah
		ja		ler_ciclo
		mov     ah,02h
		int		21h  ;Display Output
		inc 	Counter
		cmp 	Counter, 12
		je		IncPy
		jmp		IncPx

IncPx:
		inc 	POSx
		inc 	Posx
		jmp		ler_ciclo

IncPy:
		cmp 	PosY, 11
		je 		sai
		mov 	Counter, 0
		mov 	Posx, 2
		inc 	POSY
		jmp		ler_ciclo


sai:
		pop 	dx
		pop 	cx
		pop 	bx
		pop 	ax
		ret
imp_Letras	endp


;########################################################################
;ROTINA PARA IMPRIMIR Tabela NO ECRAN

imp_Ficheiro	proc

		

;abre tabela
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
;ROTINA PARA IMPRIMIR menu NO ECRAN

imp_Menu	proc

		

;abre menu
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
enterMenu:
		call 	apaga_ecran
		goto_xy	0,0
		call	imp_Menu
		call 	muda_cor
		call	assinala_Menu
		call 	apaga_ecran
		goto_xy	0,0

		call	imp_Ficheiro
		call	imp_Letras
		call	imp_Palavras
		call 	muda_cor
		call	assinala_P
		;jmp 	enterMenu
		
		call 	apaga_ecran
		goto_xy	0,0
        mov     ah,4ch
        int     21h
Main    endp
cseg	ends
end     Main           

;para ESC FICHEIRO -> MENU não podemos entrar infinitamente nas funções
;main -> função -> main (sempre)
;main -> função -> função -> main (errado)