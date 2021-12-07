
;; RK - Evalbot (Cortex M3 de Texas Instrument)
; programme - Pilotage 2 Moteurs Evalbot par PWM tout en ASM (Evalbot tourne sur lui même)


		AREA    |.text|, CODE, READONLY
		; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)

; The GPIODATA register is the data register
GPIO_PORTD_BASE		EQU		0x40007000		; GPIO Port D (APB) base: 0x4000.7000 (p416 datasheet de lm3s9B92.pdf)

GPIO_PORTE_BASE		EQU		0x40024000

; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up -> impulsion
GPIO_I_PUR   		EQU 	0x00000510  ; GPIO Pull-Up (p432 datasheet de lm3s9B92.pdf)

; Broches select
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5

BROCHE6				EQU 	0x40		; bouton poussoir 1

BROCHE0				EQU     0x01 				;Bumper_gauhce
BROCHE1				EQU     0x02 				;Bumper_droit
BROCHE0_1			EQU 	0x03				;Les deux bumpers
PWM_BASE			EQU		0x040028000 	   ;BASE des Block PWM p.1138
PWM0CMPA			EQU		PWM_BASE+0x058
PWM1CMPA			EQU		PWM_BASE+0x098 

   

; blinking frequency
DUREE   			EQU     0x002FFFFF
		ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche


__main	

		; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO D et F où sont branchés les leds (0x28 == 0b101000)
		; ;;														 									      (GPIO::FEDCBA)
        str r0, [r6] ; ajout le périphérique GPIO dans la clock
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
	
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED

        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE4_5 	
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE4_5		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
        ldr r0, = BROCHE4_5			
        str r0, [r6]
		
		mov r2, #0x000       					;; pour eteindre LED
     
		; allumer la led broche 4 (BROCHE4_5)
		mov r3, #BROCHE4_5		;; Allume LED1&2 portF broche 4&5 : 00110000
		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; @data Register = @base + (mask<<2) ==> LED1
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 

		
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Switcher 1

        ldr r7, = GPIO_PORTD_BASE+GPIO_I_PUR    ;; Pul_up 
        ldr r0, = BROCHE6
        str r0, [r7]

        ldr r7, = GPIO_PORTD_BASE+GPIO_O_DEN    ;; Enable Digital Function 
        ldr r0, = BROCHE6
        str r0, [r7]

        ldr r7, = GPIO_PORTD_BASE + (BROCHE6<<2)  	
		
		
		
		ldr r8, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1		
        str r0, [r8]
		
		ldr r8, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1
        str r0, [r8]     
		

		
		; Configure les PWM + GPIO
		BL	MOTEUR_INIT
		;; BL Branchement vers un lien (sous programme)
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r3, [r6]
   
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration Switcher
		
		
switch1
	
		ldr r12, [r7]
		CMP r12,#0x00
		BNE switch1
			   		   
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_ARRIERE
		
		; Avancement pendant une période (deux WAIT)
		BL	WAIT	; BL (Branchement vers le lien WAIT); possibilité de retour à la suite avec (BX LR)
		BL	WAIT
		

clignotement
 
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r2, [r6]    						;; Eteint LED car r2 = 0x00      
        ldr r1, = DUREE
wait1
		subs r1, #1
		bne wait1
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
        str r3, [r6]  							;; Allume LED1&2 portF broche 4&5 : 00110000 (contenu de r3)
        ldr r1, = DUREE	
		;; Boucle d'attente
wait2 	subs r1,#1
		bne wait2
		
		b clignotement
WAIT	ldr r1, =0xAFFFFF 
								;; pour la duree de la boucle d'attente2 (wait2)
ROTATION
		;Au moment de faire les rotations, pour pouvoir écouter les autres ports, à chaque fois qu'on rentre dans le wait faires clignoter les leds
		; peut être mettre un compteur dans cette boucle pour ne pas activer les leds a chaque fois et faire une crise d'épilepsie 
bump_gauche
		ldr r8, = GPIO_PORTE_BASE + (BROCHE0<<2)
		ldr r14, [r8]
		CMP r14,#0x00
		BNE bump_droit
		b init_gauche
		
bump_droit
		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2) ;bumper droit
		ldr r14, [r8]
		CMP r14, #0x00
		BNE bump_gauche
		b init_droit
init_gauche
		ldr	r6, =PWM0CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
		mov	r0, #0x180; vitesse de la roue droite
		str	r0, [r6]
		BL	MOTEUR_DROIT_AVANT   ;fait tourner une roue dans l'autre sens moins vite pour tourner
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r2, [r6]    						;; Eteint LED car r2 = 0x00 
		ldr r6, = GPIO_PORTF_BASE + (0x10<<2)
		str r3, [r6]
		BL	TEMP

rotation_gauche
		ldr	r6, =PWM0CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
		mov	r0, #0x50
		str	r0, [r6]
		BL	MOTEUR_DROIT_ARRIERE
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r3, [r6]	;; Eteint LED car r2 = 0x00
		CMP r14,#0x00
		BNE bump_gauche
		b	rotation_gauche

init_droit
		ldr	r6, =PWM1CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
		mov	r0, #0x180; vitesse de la roue droite
		str	r0, [r6]
		BL	MOTEUR_GAUCHE_AVANT   ;fait tourner une roue dans l'autre sens moins vite pour tourner
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r2, [r6]    						;; Eteint LED car r2 = 0x00 
		ldr r6, = GPIO_PORTF_BASE + (0x20<<2)
		str r3, [r6]
		BL	TEMP
		
rotation_droite
		ldr	r6, =PWM1CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
		mov	r0, #0x50
		str	r0, [r6]
		BL	MOTEUR_GAUCHE_ARRIERE
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r3, [r6]
		CMP r14,#0x00
		BNE bump_droit
		b	rotation_droite

TEMP	ldr r1, =0xEFFFF
wait6	subs r1, #1
        bne wait6
		bne ROTATION
		;; retour à la suite d u lien de branchement
		BX	LR
		NOP
        END
