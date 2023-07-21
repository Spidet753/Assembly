.h8300s
	
	.equ	PUTS,0x114
	.equ	GETS,0x113
	.equ	syscall,0x1FF00
	
;zacatek datoveho segmentu

	.data
pozadovana_soustava:	.space	100
prompt1:				.asciz "Zadejte požadovanou soustavu: "
uint16: 				.space	100
prompt2:				.asciz "Zadejte èíslo uint16: "


	.align 	2
par_pozadovane_soustavy:	.long	pozadovana_soustava
par_prompt1:				.long	prompt1
par_cisla_uint16:			.long	uint16
par_prompt2:				.long	prompt2
			
	.align 	1
	.space	100
stck:

;zacatek kodoveho segmentu

	.text
	.global _start
	
_start:	
	xor.l ER0,ER0  ;nulovani vsech registru
	xor.l ER1,ER1
	xor.l ER2,ER2
	xor.l ER3,ER3
	xor.l ER4,ER4
	xor.l ER5,ER5
	xor.l ER6,ER6
	xor.l ER7,ER7
		
	mov.l	#stck,ER7 				 ;inicializace zasobniku
	mov.l	#pozadovana_soustava,ER2 ;adresa prvniho bytu do ER2
	
	mov.w	#PUTS,R0
	mov.l	#par_prompt1,ER1
	jsr		@syscall
	
	mov.w	#GETS,R0
	mov.l	#par_pozadovane_soustavy,ER1
	jsr		@syscall
	
	xor.l	ER1,ER1
	mov.l 	#0x00FF4000, ER6	;nastaveni hodnoty znaku v pameti tak abychom se mohli na ni vratit pozdeji
	jsr		@pocetCifer			;zadani prvniho cisla (tedy soustavy), skok do prevedeni do hex
	
zadani_uint:
	mov.l	ER4,ER5				;presunuti vysledku pro misto
	xor.l	ER4,ER4
	xor.l	ER2,ER2
	xor.l	ER3,ER3
	
	mov.l 	#uint16, ER2		;adresa znaku opìt do ER2 jako v pøedchozím pøípadì
		
	mov.w	#PUTS,R0
	mov.l	#par_prompt2,ER1
	jsr		@syscall
		
	mov.w	#GETS,R0
	mov.l	#par_cisla_uint16,ER1
	jsr		@syscall
		
	xor.l	ER1,ER1
	
	mov.l 	#0x00FF4083, ER6	;hodnota znaku, na které se data nacházejí
	jsr		@pocetCifer
	xor.l	ER2,ER2
	xor.l	ER0,ER0
	xor.l	ER6,ER6
	jmp		@prevodDoSoustavy
		
pocetCifer:	
	mov.b	@ER2,R0L
	cmp.b	#0x0A,R0L		
	beq		navraceni		;pokud se nachazi 0x0A vime ze mame cele cislo
	inc.l	#1,ER2			;posouvi se v datech 	#0x00FF4000 - > #0x00FF4001
	inc.l 	#1,ER3			;pricitame pocet mist, pak s nim budem pracovat dal, diky nemu budem vedet pocet stovek, desitek... pro prevod
	bra		pocetCifer
	
navraceni:
	mov.l 	ER6, ER2		;nastavime opet vychozi hodnotu v pameti	
	jmp 	@prevodNaHex	;a cislo nasledne prevedeme

prevodNaHex:
	mov.b	@ER2,R0L		
	cmp.b	#0x0A,R0L		;kdyz se nachazi 0x0A vime ze jsme u konce a mame prevedeno
	beq		ukonci
	add.b	#-'0',R0L		
	or.b	R0L,R1L			;logicky or abychom videli prevedenou asci		
	inc.l	#1,ER2			;presun na dalsi hodnotu
	mov.w 	R3,E3			;pocet cifer z R3 do E3
	jsr 	@Hex		
	xor.l	ER0,ER0
	xor.l 	ER1,ER1
	bra		prevodNaHex
	
ukonci:
	rts	
	
pricteniHexu:			
	dec.w 	#1,R3			;snizime pocet celkovych cyklu ktery probehnou	
	add.w 	R1,R4			;prictem novou hodnotu k drivejsim	
	rts		
		
Hex:
	mov.w 	#0x0A,E1		;do E1 pridame 0x0A kterym budeme nasobit			
	dec.w 	#1,E3			;odecitame kazdym pruchodem		
	cmp.w 	#0x00,E3		
	beq 	pricteniHexu
	mulxu.w E1,ER1			;pronasobime a dostaneme hexadecimalni hodnotu cifry
	bra		Hex
	
prevodDoSoustavy:
	divxu.w R5,ER4
	mov.w 	E4, R3					;unint_16 delime soustavou a zbytek si presuneme do R3 pro dalsi praci s nim
	jsr		@presun					;presun slouzi pro presun dat do dalsiho registru pokud je zaplnen
	jsr 	@inverze				;prehoz zbytku z ER3 do ER1 opacne
	xor.w	E4,E4					;procisteni zbytku
	xor.w	E3,E3
	cmp.w	R5,R4					;pokud je uint mensi nez soustava, staci uz pouze prevest posledni zbytek
	blt 	prevedPosledniVysledek
	bra		prevodDoSoustavy	

inverze:
	inc.l	#1,ER6		;zde si uchovavam pocet inverzi k urceni konecneho poctu cislic
	shll.l	#2,ER3		;registr posuneme o 16 bitu doleva a presuneme data do R0L, takhle budem opakovat kazdy cyklus
	shll.l	#2,ER3		;problemem tohoto zpusobu je ze nam umozni pouze ulozeni 6 cisel
	mov.b	R3L, R0L	
	shll.l 	#2,ER0		;zde posuneme doleva jeste ER0 pro misto na data
	shll.l	#2,ER0	
	mov.b	R6H,R0L		;prepis prazdnymi daty 
	shlr.l	#2,ER3
	shlr.l	#2,ER3		;nasledne posunuti doprava ER3 o pouzita data
	shlr.l	#2,ER3
	shlr.l	#2,ER3
	rts

presun:
	cmp.l	#6,ER6		
	beq		presun2		;pri 6 presuneme prvni registr do druheho, pri C druhy do tretiho a prvni do druheho
	cmp.l	#0x0C,ER6
	beq		presun3
	rts
	
presun2:			
	mov.l	ER0,ER1
	xor.l	ER0,ER0
	rts	

presun3:
	mov.l	ER1,ER2
	mov.l	ER0,ER1
	xor.l	ER0,ER0
	rts
	
prevedPosledniVysledek:
	mov.w 	R4, R3						
	jsr		@presun			;musime osetrit i situaci kdy k presunu dojde u posledniho zbytku
	jsr		@inverze
	shlr.l	#2,ER0			;po poslednim presunu vratime na spravnou pozici
	shlr.l	#2,ER0
	shlr.l	#2,ER0
	shlr.l	#2,ER0
	jsr		@kontrolaNul	;a odstranime nuly ktere tam nepatri pro lepsi praci s registry
	
	mov.b	R6L,R5L			
	mov.b	R6L,R5H			;cislo si ulozime do dvou registru, jeden budem odecitat pro
	cmp.b	#0x0C,R5H		;zjisteni spravnyho poctu cifer, R5H je na specialni pripady
	beq		kontrola
	cmp.b	#0x6,R5H		;C a 6 jsou specialni pripady kdy se s registrama pracuje jinak
	beq		kontrola
	jmp		@obracenyPrevodDoRegistru
	
kontrola:
	dec.w	#1,R5			;v techto pripadech odecteme cislo bez presunuti do jineho registru aby nevznikly problemy v usporadani
	jsr		@inverze
	bra		obracenyPrevodDoRegistru

	
kontrolaNul:				;kontroluje vsechny registry, pripadne odstrani nuly a ulozi
	jsr		@odstranNulu
	mov.l	ER0, ER3 		;ER3 je prvnim registrem
	mov.l	ER1, ER0
	jsr 	@odstranNulu
	mov.l	ER0,ER4			;ER4 je druhym registrem
	mov.l	ER2,ER0
	jsr		@odstranNulu
	mov.l	ER0,ER2  		;ER2 je poslednim registrem
	xor.l	ER0,ER0
	xor.l	ER1,ER1
	rts
	
odstranNulu:
	cmp.b  	#0x00,R0L 	;pokud jsou 2 nuly po sobe, odtranime
	beq		odstran
	rts	
	
odstran:
	shlr.l	#2,ER0  	;nuly odtranime posunutim
	shlr.l	#2,ER0
	shlr.l	#2,ER0
	shlr.l	#2,ER0
	rts	
	
obracenyPrevodDoRegistru:	;nyni mame vysledne hodnoty, ale otocene, pokud je chceme v registrech prehledne, musime je jeste upravit
	jsr		@prehod1		
	jsr		@prehod2		;opet rozlisujeme 6 a C abychom vedeli kdy prehodit data do jineho registru
	cmp.b	#0,R5L	
	beq		posledniUprava	;pokud je R5L presunuli jsme vsechna potrebna data a staci pouze upravit registry	
	dec.w	#1,R5
	jsr		@inverze
	bra		obracenyPrevodDoRegistru
	
prehod1:
	cmp.b	#0x0C,R5L
	beq		_prehod1		
	rts
	
_prehod1:
	mov.l	ER4,ER3
	mov.l	ER0,ER4 	;ER4 ma prvni cast prevodu
	xor.l	ER0,ER0
	rts
			
prehod2:
	cmp.b	#0x6,R5L
	beq		_prehod2
	rts

_prehod2:
	cmp.b	#0x0C,R5H   ;musime jeste rozlisit pripad kdy je cislic min jak 13 (bude rozdeleni jen do dvou registru)
	ble		_prehod1
	mov.l	ER2,ER3
	mov.l	ER0,ER2		;ER2 ma druhou cast
	xor.l	ER0,ER0		;v ER0 je ta posledni cast
	rts	

posledniUprava:
	jsr		@kontrolaPoradi	
	mov.l	ER2,ER1
	mov.l	ER0,ER2			;srovname data do spravnych registru pro kontrolu nul
	mov.l	ER4,ER0
	jsr		@kontrolaNul	;opet odstranime nuly
	mov.l	ER4,ER1
	mov.l	ER3,ER0			;a nyni presuneme do prvnich tri registru pro prehlednost
	xor.l	ER4,ER4
	xor.l	ER3,ER3
	jmp		@Preusporadani	
	
kontrolaPoradi:			;presuneme data protoze jinak by prostredni registr u vyjimky byl nulovy a cisla by nesedela
	cmp.b	#0x0C,R5H
	ble		prohod
	rts
	
prohod:	
	mov.l 	ER0,ER2
	xor.l	ER0,ER0
	rts	
	
Preusporadani:			;Pøedá 32-bitù do R1 a 16-bitù do R2
	cmp.b 	#0x0D,R5H	;pokud je cisel 12 a mene je to jednodussi, staci presunout 
	blt		jednoduchePreusporadani
	mov.w	E2,R3	
	mov.b	R1L,R3H		;z druheho registru presuneme R1L do prvnich bytu posledniho registru
	mov.w	R3,E2
	shlr.l	#2,ER1
	shlr.l	#2,ER1		;pote o R1L zkratime druhy registru
	shlr.l	#2,ER1
	shlr.l	#2,ER1
	mov.w	R0,E1		;a do nej hodime prvni registr tak abychom meli vysledek prehledne ve dvou registrech
	xor.l	ER0,ER0
	xor.l	ER3,ER3
	xor.l	ER5,ER5
	jmp		@konec
	
jednoduchePreusporadani:	;pøedá 32-bitù do ER1
	mov.w	E1,R3	
	mov.b	R0L,R3H
	mov.w	R3,E1
	xor.l	ER3,ER3
	xor.l	ER5,ER5	
	xor.l	ER0,ER0
	jmp		@konec		
			
konec:	
	jmp		@konec		;Výsledek se uloží do ER1, když je potøeba, nachází se zaèátek výsledku v ER0 a pokraèuje v ER1,ER2	
	