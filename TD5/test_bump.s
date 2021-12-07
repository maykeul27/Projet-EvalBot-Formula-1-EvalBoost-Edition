		AREA    |.text|, CODE, READONLY
PWM_BASE		EQU		0x040028000 	   ;BASE des Block PWM p.1138
PWMENABLE		EQU		PWM_BASE+0x008	   ; p1145

;Block PWM0 pour sorties PWM0 et PWM1 (moteur 1)
PWM0CTL			EQU		PWM_BASE+0x040 ;p1167
PWM0LOAD		EQU		PWM_BASE+0x050
PWM0CMPA		EQU		PWM_BASE+0x058
PWM0CMPB		EQU		PWM_BASE+0x05C
PWM0GENA		EQU		PWM_BASE+0x060
PWM0GENB		EQU		PWM_BASE+0x064

;Block PWM1 pour sorties PWM1 et PWM2 (moteur 2)
PWM1CTL			EQU		PWM_BASE+0x080 
PWM1LOAD		EQU		PWM_BASE+0x090
PWM1CMPA		EQU		PWM_BASE+0x098
PWM1CMPB		EQU		PWM_BASE+0x09C
PWM1GENA		EQU		PWM_BASE+0x0A0
PWM1GENB		EQU		PWM_BASE+0x0A4
 
; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIOF EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)
	
GPIO_PORTE_BASE		EQU		0x40024000
	
GPIO_PORTD_BASE		EQU		0x40007000

GPIO_I_PUR   		EQU 	0x00000510
	
BROCHE0_1		   		EQU 	0x03
	
BROCHE0		   		EQU 	0x01
	
BROCHE1		   		EQU 	0x02

; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN   		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; PIN select
BROCHE4_5				EQU		0x30		; led1 sur broche 4
	
BROCHE6_7			EQU 	0xC0

BROCHE2_3            EQU        0x3C        ; led1 & led2 sur broche 2 et 3
	
BROCHE6				EQU 	0x40
	
BROCHE7				EQU 	0x80

; blinking frequency
DUREE   			EQU     0x001FFFFF	; Random Value
	
DUREE1   			EQU     0x002FFFFF

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
		
		
		; ;; Enable the Port F peripheral clock by setting bit 5 (0x20 == 0b10000000)		(p291 datasheet de lm3s9B96.pdf)
		; ;;														(GPIO::876543210)
		ldr r6, = SYSCTL_PERIPH_GPIOF  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO F où sont branchés les leds (0x20 == 0b100000)
		; ;;														 									 (GPIO::FEDCBA)
        str r0, [r6]
		
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
     
		; allumer la led broche 4 (PIN4)
		mov r3, BROCHE4_5       					;; Allume portF broche 4 : 00010000
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; @data Register = @base + (mask<<2) ==> LED1

		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 
		
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION LED ETHERNET

        ldr r5, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE2_3
        str r0, [r5]

        ldr r5, = GPIO_PORTF_BASE+GPIO_O_DEN    ;; Enable Digital Function 
        ldr r0, = BROCHE2_3
        str r0, [r5]

        ldr r5, = GPIO_PORTF_BASE+GPIO_O_DR2R    ;; Choix de l'intensité de sortie (2mA)
        ldr r0, = BROCHE2_3
        str r0, [r5]

        ;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED
		
		ldr r7, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1		
        str r0, [r7]
		
		ldr r7, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1	
        str r0, [r7]     
		
		
		;----------------------------------------------
		
		ldr r8, = GPIO_PORTD_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE6_7		
        str r0, [r8]
		
		ldr r8, = GPIO_PORTD_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE6_7	
        str r0, [r8]     
		
		  ;; @data Register = @base + (mask<<2) ==> Switcher
		
		str r3, [r6]
		ldr r4, =0x00000F
loop1
        str r2, [r6]    						;; Eteint LED car r2 = 0x00      
        ldr r1, = DUREE 						;; pour la duree de la boucle d'attente1 (wait1)

wait5	subs r1, #1
        bne wait5

        str r3, [r6]  							;; Allume portF broche 4 : 00010000 (contenu de r3)
        ldr r1, = DUREE							;; pour la duree de la boucle d'attente2 (wait2)

wait9   subs r1, #1
        bne wait9
		 
		subs r4, #5
		CMP r4, #1
		BLE debut
		B loop1
         
debut		
		BL	MOTEUR_INIT	 
		
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
loop		  		   
		
		; Activer les deux moteurs droit et gauche
			
		BL	MOTEUR_DROIT_ARRIERE	   
		BL	MOTEUR_GAUCHE_ARRIERE
		
;-----------------------------------------------------------------------------------
		
ROTATION
		;Au moment de faire les rotations, pour pouvoir écouter les autres ports, à chaque fois qu'on rentre dans le wait faires clignoter les leds
		; peut être mettre un compteur dans cette boucle pour ne pas activer les leds a chaque fois et faire une crise d'épilepsie 
bump_gauche
		ldr r8, = GPIO_PORTE_BASE + (BROCHE0<<2)
		ldr r14, [r8]
		CMP r14,#0x00
		BNE bump_droit

		ldr r9, = GPIO_PORTE_BASE + (BROCHE1<<2)
		ldr r10,[r9]
		CMP r10,#0x00
		BNE init_gauche
		B inter
		
bump_droit
		ldr r8, = GPIO_PORTE_BASE + (BROCHE1<<2) ;bumper droit
		ldr r14, [r8]
		CMP r14, #0x00
		BNE loop

		ldr r9, = GPIO_PORTE_BASE + (BROCHE0<<2)
		ldr r10,[r9]
		CMP r10,#0x00
		BNE init_droit
		B inter
		
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
		
;------------------------------------------------------------------------------------------------
inter
		BL	MOTEUR_DROIT_OFF
		BL	MOTEUR_GAUCHE_OFF
		BL WAIT
		
ReadState3
		ldr r8, = GPIO_PORTD_BASE + (BROCHE6<<2)    ;essayer un intermediaire!!!!!!!!!!!!!!!!!!!!
		ldr r10, [r8]
		CMP r10,#0x00
		BNE ReadState4
		B win

ReadState4
		ldr r8, = GPIO_PORTD_BASE + (BROCHE7<<2)
		ldr r10, [r8]
		CMP r10,#0x00
		BNE ReadState2
		B lost

ReadState2
		ldr r7, = GPIO_PORTE_BASE + (BROCHE0_1<<2)
		ldr r11,[r7]
		CMP r11,#0x00
		BNE ReadState3
		
		BL WAIT
		BL WAIT
		BL WAIT
		BL WAIT
		
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		
		BL	MOTEUR_DROIT_AVANT
		BL	MOTEUR_GAUCHE_AVANT
		BL WAIT
		BL WAIT
		BL WAIT
		BL WAIT
		BL WAIT
		BL WAIT
		BL WAIT
		BL WAIT
		BL WAIT
		
		B loop1
		
win		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
 
loop2
		
		BL MOTEUR_DROIT_AVANT
		BL MOTEUR_GAUCHE_ARRIERE				      
        ldr r1, = DUREE 						

wait1	subs r1, #1
        bne wait1

        BL MOTEUR_DROIT_ARRIERE
		BL MOTEUR_GAUCHE_AVANT								
        ldr r1, = DUREE				

wait2   subs r1, #1
        bne wait2

        b loop2
		
lost

		ldr r6, = PWM0CTL
		mov	r0, #2		;Mode up-down-up-down, pas synchro
        str r0, [r6]	
		
		ldr r6, =PWM0GENA ;en decomptage, qd comparateurA = compteur => sortie pwmA=0
						;en comptage croissant, qd comparateurA = compteur => sortie pwmA=1
		mov	r0,	#0x0B0 	;0B0=10110000 => ACTCMPBD=00 (B down:rien), ACTCMPBU=00(B up rien)
		str r0, [r6]	;ACTCMPAD=10 (A down:pwmA low), ACTCMPAU=11 (A up:pwmA high) , ACTLOAD=00,ACTZERO=00  
		
		ldr r6, =PWM0GENB;en comptage croissant, qd comparateurB = compteur => sortie pwmA=1
		mov	r0,	#0x0B00	;en decomptage, qd comparateurB = compteur => sortie pwmB=0
		str r0, [r6]	
	;Config Compteur, comparateur A et comparateur B
  	;;#define PWM_PERIOD (ROM_SysCtlClockGet() / 16000),
	;;en mesure : SysCtlClockGet=0F42400h, /16=0x3E8, 
	;;on divise par 2 car moteur 6v sur alim 12v
		ldr	r6, =PWM0LOAD ;PWM0LOAD=periode/2 =0x1F4
		mov r0,	#0x1F4
		str	r0,[r6]
		
		ldr	r6, =PWM0CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
		mov	r0, #0x192
		str	r0, [r6]  
		
		ldr	r6, =PWM0CMPB ;PWM0CMPB recoit meme valeur. (rapport cyclique depend de CMPA)
		mov	r0,	#0x1F4	
		str	r0,	[r6]
		
	;Control PWM : active PWM Generator 0 (p1167): Enable+up/down + Enable counter debug mod
		ldr	r6, =PWM0CTL 
		ldr	r0, [r6]	
		ORR	r0,	r0,	#0x07
		str	r0,	[r6]

	;;-----------PWM2 pour moteur 2 connecté à PH0
	;;PWM1block produit PWM2 et PWM3 output
		;;Config Modes PWM2 + mode GenA + mode GenB
		ldr r6, = PWM1CTL
		mov	r0, #2		;Mode up-down-up-down, pas synchro
        str r0, [r6]	;*(int *)(0x40028000+0x040)=2;
		
		ldr r6, =PWM1GENA ;en decomptage, qd comparateurA = compteur => sortie pwmA=0
						;en comptage croissant, qd comparateurA = compteur => sortie pwmA=1
		mov	r0,	#0x0B0 	;0B0=10110000 => ACTCMPBD=00 (B down:rien), ACTCMPBU=00(B up rien)
		str r0, [r6]	;ACTCMPAD=10 (A down:pwmA low), ACTCMPAU=11 (A up:pwmA high) , ACTLOAD=00,ACTZERO=00  
		
 		;*(int *)(0x40028000+0x060)=0x0B0; //
		ldr r6, =PWM1GENB	;*(int *)(0x40028000+0x064)=0x0B00;
		mov	r0,	#0x0B00	;en decomptage, qd comparateurB = compteur => sortie pwmB=0
		str r0, [r6]	;en comptage croissant, qd comparateurB = compteur => sortie pwmA=1
	;Config Compteur, comparateur A et comparateur B
  	;;#define PWM_PERIOD (ROM_SysCtlClockGet() / 16000),
	;;en mesure : SysCtlClockGet=0F42400h, /16=0x3E8, 
	;;on divise par 2 car moteur 6v sur alim 12v
		;*(int *)(0x40028000+0x050)=0x1F4; //PWM0LOAD=periode/2 =0x1F4
		ldr	r6, =PWM1LOAD
		mov r0,	#0x1F4
		str	r0,[r6]
		
		ldr	r6, =PWM1CMPA ;Valeur rapport cyclique : pour 10% => 1C2h si clock = 0F42400
		mov	r0,	0x192
		str	r0, [r6]  ;*(int *)(0x40028000+0x058)=0x01C2;
		
		ldr	r6, =PWM1CMPB ;PWM0CMPB recoit meme valeur. (CMPA depend du rapport cyclique)
		mov	r0,	#0x1F4	; *(int *)(0x40028000+0x05C)=0x1F4; 
		str	r0,	[r6]
		
		;Control PWM : active PWM Generator 0 (p1167): Enable+up/down + Enable counter debug mod
		ldr	r6, =PWM1CTL 
		ldr	r0, [r6]	;*(int *) (0x40028000+0x40)= *(int *)(0x40028000+0x40) | 0x07;
		ORR	r0,	r0,	#0x07
		str	r0,	[r6]
		
		
		BL MOTEUR_DROIT_ON
		BL MOTEUR_GAUCHE_ON
		
		BL MOTEUR_DROIT_AVANT
		BL MOTEUR_GAUCHE_ARRIERE

		
WAIT	ldr r1, =0x0FFFFF 
wait3	subs r1, #1
        bne wait3
		
		;; retour à la suite du lien de branchement
		BX	LR     
		
		nop		
        END 