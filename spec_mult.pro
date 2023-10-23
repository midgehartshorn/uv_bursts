PRO SPEC_MULT

; PATHS, FILENAMES
; ------------------------------------------------
path = '/home/miriam/Documents/MHC/Summer23/code'
sjname1 = path + '/data/iris_l2_20150206_051507_3800256196_SJI_1400_t000.fits'
specname1 = path +'/data/iris_l2_20150206_051507_3800256196_raster_t000_r00000.fits'

SJI_data1 = IRIS_SJI(sjname1)
specDATA1 = IRIS_OBJ(specname1)

obs_tag1 = '20150206'

save_path = path+'/analysis/'

; SCALE, RESOLUTION
; ------------------------------------------------
; FIRST DATASET
; ------------------------------------------------
solary1 = SJI_data1->GETYPOS()
xscale1 = specDATA1->GETDX()

xcen1 = specDATA1->GETXCEN(4) 
xfov1 = specDATA1->GETFOVX(4) 

OBJ_DESTROY, SJI_data1
OBJ_DESTROY, specDATA1

x_orig1 = xcen1 - (xfov1/2.)
RESTORE, path+'/analysis/' +obs_tag1+ '/despiked_params.sav'

RESTORE, path+'/analysis/' +obs_tag1+ '/detections.sav'
det1 = ni_yes


; RESOLUTION
xres1 = MEAN(xscale1)
yres1 = MEAN(DERIV(solary1))
; ------------------------------------------------

; FORM PARAMETER ARRAYS
; ------------------------------------------------
intensity = despiked_intens[50:250, 400:850]
doppler = despiked_dop[50:250, 400:850]
width = despiked_width[50:250, 400:850]

; DEFINE SPECIAL CHARACTERS & STRINGS, etc.
; ------------------------------------------------
angst = STRING("305B)
spec_units = '[erg s!U-1!N'+angst+'!U-1!N cm!U-2!N sr!U-1!N]'
vel_units = '[km s!U-1!N]'
si_iv = 'Si IV 1394'+angst
log_un = 'log!D10!N'

plt_char = 4
plt_thick = 3

; -----------------------------------------------
; PLOTTING PARAMETERS
; -----------------------------------------------

!p.multi=[0,3,1,0,0]
; ------------------------------------------------
; SCALE INTENSITY DATA
; ------------------------------------------------
EIS_COLORS, /INTENSITY
PLOT_IMAGE, ALOG10(intensity), MIN=2.25, MAX=5.7, $
		CHARSIZE=plt_char, CHARTHICK=plt_thick, THICK=plt_thick, $
		BACKGROUND=255, COLOR=0,XTHICK=plt_thick, YTHICK=plt_thick,$
		ORIGIN=[x_orig1, solary1[0]], SCALE=[xres1,yres1], $
		TITLE='Si IV Intensity', $
		YTITLE='Solar Y [arcsec]'
cgColorbar, COLOR='black', TITLE=log_un+' Peak Intensity '+spec_units,TLOCATION='BOTTOM', CHARSIZE=2.5, TEXTTHICK=2, POSITION=[0.06,0.12,0.31,0.15]
	;POSITION=cbpos, RANGE=[10^2.5,10^6]

; ------------------------------------------------
; SCALE DOPPLER DATA

c = 3e+5 ; speed of light in km/s
wav_exp = 1393.7894 ; expected wavelength
doppler = c * (wav_exp - doppler)/wav_exp

doppler_sort = doppler[SORT(doppler)]
doppler_sort = doppler_sort[WHERE(FINITE(doppler_sort) AND (doppler_sort GT -199))]
d_n_sort=N_ELEMENTS(doppler_sort)

; ------------------------------------------------
; PLOT DOPPLER SHIFT
EIS_COLORS, /VELOCITY
TVLCT, 0,0,0, 0 ; add black
TVLCT, 255, 255, 255, 255 ;add white
PLOT_IMAGE, (-1*doppler), BOTTOM=1, TOP=254, $
	MIN=-40, MAX=40, $
	BACKGROUND=255, COLOR=0, POSITION=pltpos, $
	ORIGIN=[x_orig1,solary1[0]], SCALE=[xres1,yres1], $
	XTITLE='Solar X [arcsec]', CHARSIZE=plt_char, CHARTHICK=plt_thick, $
	YTICKFORMAT='(A1)',$
	TITLE='Doppler Shift', THICK=plt_thick, XTHICK=plt_thick, YTHICK=plt_thick 
cgColorbar, RANGE=[-50,50 ],  COLOR='black',$
       	TITLE='Doppler Velocity' + vel_units, TLOCATION='BOTTOM', CHARSIZE=2.5, TEXTTHICK=2, POSITION=[0.40,0.12,0.64,0.15]
; ------------------------------------------------
; SCALE VELOCITY DATA
width = c * (width)/wav_exp
width_sort = width[SORT(width)]
width_sort = width_sort[WHERE(FINITE(width_sort) AND (width_sort GT -199))]
v_n_sort=N_ELEMENTS(width_sort)

	EIS_COLORS, /WIDTH
	PLOT_IMAGE, ALOG10(width), BOTTOM=1,$
	MIN=1, MAX=2, CHARSIZE=plt_char, THICK=plt_thick, CHARTHICK=plt_thick, $
		ORIGIN=[x_orig1, solary1[0]], SCALE=[xres1,yres1],POSITION=pltpos, $
		TITLE='Exponential Line Width', BACKGROUND=255, COLOR=0,$
		YTICKFORMAT='(A1)',XTHICK=plt_thick, YTHICK=plt_thick
cgColorbar, COLOR='black',TITLE='Exponential Line Width' + vel_units,$
	       	TLOCATION='BOTTOM', RANGE=[10, 100],$
	       	NEUTRALINDEX=0, CLAMP=[10, 100], CHARSIZE=2.5, TEXTTHICK=2, POSITION=[0.73,0.12,0.98,0.15]

cont = ''
READ, cont, PROMPT='Write? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
	scrncap = TVRD(TRUE=1)
	WRITE_PNG, save_path+'MULT_SPEC' +'.png', scrncap
ENDIF 
END
