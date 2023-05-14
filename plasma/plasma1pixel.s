; 1 pixel plasma

OpenLibrary	EQU	-552
CloseLibrary	EQU	-414
AllocRaster	EQU	-492
FreeRaster	EQU	-498
LoadView	EQU	-222
BltClear	EQU	-300
InitBitMap	EQU	-390
InitRastPort	EQU	-198
Text		EQU	-60
TextLength	EQU	-54
Move		EQU	-240
Forbid		EQU	-132
Permit		EQU	-138
Disable		EQU	-120
Enable		EQU	-126

actiview	EQU	34

PLASMA_HEIGHT	EQU	160
			
		SECTION	code,CODE_C

coppersplit	move.l	4.w,a6
		jsr	Forbid(a6)
		jsr	Disable(a6)

		lea	gfx(pc),a1
		moveq	#0,d0
		jsr	OpenLibrary(a6)
	
		lea	gfxbase(pc),a0
		move.l	d0,(a0)
		beq.w	.quit
		move.l	d0,a6
		lea	oldview(pc),a0
		move.l	actiview(a6),(a0)

		;move.l	#320,d0
		;move.l	#2,d1
		;jsr	AllocRaster(a6)
		;move.l	d0,bitplane
		;beq.w	.closegfx

		suba.l	a1,a1
		jsr	LoadView(a6)

		;----
		
		lea	$dff000.l,a5
		bsr.w	copper_setup
		bsr.w	make_plasma
		;bsr.w	v_blit_plasma
		;bsr.w	h_blit_plasma

		pea	copper_list(pc)
		move.l	(sp)+,$84(a5)
		
		lea	interrupt(pc),a0
		move.w	$1c(a5),d0
		ori.w	#$c000,d0
		move.w	d0,(a0)+
		move.l	$6c.w,(a0)+
		move.l	$74.w,(a0)+
		move.l	#$7fff7fff,$9a(a5)

		pea	level3_int(pc)
		move.l	(sp)+,$6c.w
		move.w	#%1100000000100000,$9a(a5)

		;----

.wlmb		btst.b	#6,$bfe001
		bne.b	.wlmb

		lea	interrupt(pc),a0
		move.l	#$7fff7fff,$9a(a5)
		move.w	(a0)+,$9a(a5)
		move.l	(a0)+,$6c.w
		move.l	(a0)+,$74.w
				
		;---- exit

		;move.l	bitplane(pc),a0
		;move.l	#320,d0
		;move.l	#2,d1
		;jsr	FreeRaster(a6)

		move.l	oldview(pc),a1
		jsr	LoadView(a6)

.closegfx	move.l	4.w,a6
		move.l	gfxbase(pc),a1
		jsr	CloseLibrary(a6)

.quit		move.l	4.w,a6
		jsr	Enable(a6)
		jsr	Permit(a6)
		rts

		;----

interrupt	ds.w	1
		ds.l	2
oldview		ds.l	1
gfxbase		ds.l	1
gfx		dc.b	'graphics.library',0
	
		even

		;----

level3_int	movem.l	d0-a6,-(sp)
		bsr.w	draw_plasma
		movem.l	(sp)+,d0-a6
		move.w	#%100000,$9c(a5)
		rte

		;----

copper_setup	lea	plasma(pc),a0
		move.l	#(($4001!60)<<16)!$fffe,d0
		move.l	#$1020003,d1
		move.l	#$1820f00,d2
		move.l	#$1800f00,d3
		move.l	#$1800000,d4
		move.w	#PLASMA_HEIGHT-1,d7
.loop		move.l	d0,(a0)+
		move.l	d1,(a0)+
		REPT	38/2
		move.l	d2,(a0)+
		move.l	d3,(a0)+
		ENDR
		move.l	d4,(a0)+
		addi.l	#$1000000,d0	
		dbf	d7,.loop

		lea	bpl_ptr(pc),a0
		lea	bitmap,a1
		move.l	a1,d0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)

		rts

		;----

make_plasma	lea	sincos(pc),a0
		lea	plasma_data(pc),a1
		move.w	#(PLASMA_HEIGHT*2)-1,d7
		moveq	#0,d5
.loop		move.w	#38-1,d6
		moveq	#0,d4

.blue		move.w	d4,d0
		move.w	d5,d1
		andi.w	#511,d0
		andi.w	#511,d1
		add.w	d0,d0
		add.w	d1,d1
		move.w	(a0,d0.w),d2	
		move.w	(a0,d1.w),d3		
		ext.l	d2
		ext.l	d3
		asl.l	#3,d2
		asl.l	#3,d3
		add.l	d2,d2
		add.l	d3,d3
		swap	d2
		swap	d3
		addq.w	#8,d2
		addq.w	#8,d3
		add.w	d3,d2		
		asr.w	#1,d2	
		andi.w	#$f,d2
		move.w	d2,(a1)

.green		move.w	d4,d0
		sub.w	d5,d0
		andi.w	#511,d0
		add.w	d0,d0
		move.w	(a0,d0.w),d2
		ext.l	d2
		asl.l	#3,d2
		add.l	d2,d2
		swap	d2
		addq.w	#8,d2
		andi.w	#$f,d2
		lsl.w	#4,d2
		or.w	d2,(a1)

.red		move.w	d4,d0
		add.w	d5,d0
		andi.w	#511,d0
		add.w	d0,d0
		move.w	(a0,d0.w),d2
		ext.l	d2
		asl.l	#3,d2
		add.l	d2,d2
		swap	d2
		addq.w	#8,d2
		andi.w	#$f,d2
		lsl.w	#8,d2
		or.w	d2,(a1)

.next		addi.w	#32,d4
		lea	2(a1),a1
		dbf	d6,.blue
		addi.w	#4,d5
		dbf	d7,.loop
		rts

		;----

draw_plasma	move.l	#%0000100111110000<<16,$40(a5)
		move.l	#-1,$44(a5)
		move.l	#4-2,$64(a5)
		move.w	#%1000010001000000,$96(a5)
		
		lea	plasma+10-164(pc),a1
		lea	plasma_buffer-(38*2),a2
		lea	sincos(pc),a3

		move.w	#(38<<6)!1,d0
		move.w	x_angle(pc),d1
		move.w	#511,d2
		moveq	#7,d3
		move.w	#PLASMA_HEIGHT-1,d7

.hloop		lea	164(a1),a1
		lea	38*2(a2),a2
		addq.w	#8,d1
		and.w	d2,d1
		move.w	d1,d4
		add.w	d4,d4
		move.w	(a3,d4.w),d4
		ext.l	d4
		asl.l	#3,d4
		add.l	d4,d4
		swap	d4
		move.w	d4,d5
		and.w	d3,d4
		addq.w	#3,d4
		move.w	d4,-4(a1)
		asr.w	#3,d5
		add.w	d5,d5
		neg.w	d5
		lea	(a2,d5.w),a0
		movem.l	a0/a1,$50(a5)
		move.w	d0,$58(a5)
		dbf	d7,.hloop

		;----

		move.l	#(((38*2)-2)<<16)!(38*2)-2),$64(a5)

		lea	plasma_buffer-2,a1
		lea	plasma_data-2(pc),a2
		lea	38*50*2(a2),a2
		lea	sincos(pc),a3
	
		move.w	#(PLASMA_HEIGHT<<6)!1,d0
		move.w	y_angle(pc),d1
		move.w	#511,d2
		move.w	#38-1,d7

.vloop		lea	2(a1),a1
		lea	2(a2),a2
		addi.w	#20,d1
		and.w	d2,d1
		move.w	d1,d3
		add.w	d3,d3
		move.w	(a3,d3.w),d3
		ext.l	d3
		asl.l	#5,d3
		add.l	d3,d3
		swap	d3
		muls.w	#38*2,d3
		lea	(a2,d3.l),a0		
		movem.l	a0/a1,$50(a5)
		move.w	d0,$58(a5)
		dbf	d7,.vloop

		addi.w	#10,x_angle
		addi.w	#3,y_angle

		rts

x_angle		ds.w	1
y_angle		ds.w	1

		;----

copper_list	dc.w	$180,0
		dc.w	$182,0
		dc.w	$1a2,0
		dc.w	$8e,$2c81
		dc.w	$90,$2cc1
		dc.w	$92,$38
		dc.w	$94,$d0-8
bpl_ptr		dc.w	$e0,0,$e2,0
		dc.w	$100,$200
		dc.w	$102,3
		dc.w	$104,%111111
		dc.w	$108,-38
		dc.w	$10a,0
		dc.w	$3f01,$ff00
		dc.w	$100,$1200
		dc.w	$140,65
		dc.w	$142,%1111111100000011	
		dc.w	$146,0
		dc.w	$144,-1
		dc.w	$148,209
		dc.w	$14a,%1111111100000011	
		dc.w	$14e,0
		dc.w	$14c,-1

plasma		ds.b	(164*PLASMA_HEIGHT)
		dc.w	$100,$200
		dc.l	-2

		;----

sincos		incbin	sincos
bitmap		dcb.w	38/2,$ff00
plasma_data	dcb.l	(38/2)*PLASMA_HEIGHT*2,$f0000f
plasma_buffer	dcb.l	(38/2)*PLASMA_HEIGHT*2,$f0000f	

