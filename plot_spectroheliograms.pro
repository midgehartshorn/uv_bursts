PRO PLOT_SPECTROHELIOGRAMS

; PATHS, FILENAMES
; ------------------------------------------------
obs_tag = '20140805'
path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'
sjname = path + 'iris_l2_20140805_133003_3883108846_SJI_1400_t000.fits'
specname = path +'iris_l2_20140805_133003_3883108846_raster_t000_r00000.fits'

lambda = 1394
SJI_data = IRIS_SJI(sjname)
specDATA = IRIS_OBJ(specname)


save_path = path+ 'img/'

PRINT, 'Observation Date: ', obs_tag

; SCALE, RESOLUTION
; ------------------------------------------------
winid = specDATA->GETWINDX(lambda)
solary = SJI_data->GETYPOS()
xscale = specDATA->GETDX()

xcen = specDATA->GETXCEN(4) 
xfov = specDATA->GETFOVX(4) 

OBJ_DESTROY, SJI_data
OBJ_DESTROY, specDATA

x_orig = xcen - (xfov/2.)
print, x_orig
print, solary
;STOP
RESTORE, path+'/despiked_params.sav'

RESTORE, path+'/detections.sav'

;bin_mask=MAKE_ARRAY(1096,400)
;bin_arr=ARRAY_INDICES(bin_mask, ni_yes)
;bin_mask[bin_arr]=1

;bin_mask=TRANSPOSE(bin_mask)

; RESOLUTION
xres = MEAN(xscale)
yres = MEAN(DERIV(solary))
; ------------------------------------------------

; FORM PARAMETER ARRAYS
; ------------------------------------------------
intensity = TRANSPOSE(despiked_intens)
doppler = TRANSPOSE(despiked_dop)
width = TRANSPOSE(despiked_width)

; DEFINE SPECIAL CHARACTERS & STRINGS, etc.
; ------------------------------------------------
angst = STRING("305B)

pltpos = [0.15,0.15,0.83, 0.9]
cbpos = [0.9,0.15, 0.93, 0.9]
spec_units = '[erg s!U-1!N'+angst+'!U-1!N cm!U-2!N sr!U-1!N]'
vel_units = '[km s!U-1!N]'
si_iv = 'Si IV 1394'+angst
log_un = 'log!D10!N'

obs_date = obs_tag

plt_char = 3
plt_thick = 4
cb_char = 0.85 * plt_char


cutout_x = [-300,-220]
cutout_y = [125, 175]

!p.multi=[0,1,1,0,0]
; ------------------------------------------------
; SCALE INTENSITY DATA
intens_sort = intensity[SORT(intensity)]
intens_sort = intens_sort[WHERE(FINITE(intens_sort) AND (intens_sort GT -199))]
n_sort=N_ELEMENTS(intens_sort)

print, 'Int: ', intens_sort[n_sort*0.01], intens_sort[n_sort*0.99]
PRINT, 'Int: ', ALOG10(intens_sort[n_sort*0.01]), ALOG10(intens_sort[n_sort*0.99])

cont = ''
READ, cont, PROMPT='Plot intensity percentile scaling? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
; ------------------------------------------------
; PLOT INTENSITY
PRINT, MINMAX(intensity)
READ, intens_min, PROMPT='Set intensity lower percentile (e.g. 0.01): '
READ, intens_max, PROMPT='Set intensity upper percentile (e.g. 0.99): '
EIS_COLORS, /INTENSITY
;TVLCT, 0,0,255, 254 ; add blue
name = STRING(FORMAT='(I03)',intens_min*100)+'_' +STRING(FORMAT='(I03)',intens_max*100)
WAIT, 1
WINDOW,  RETAIN=2
PLOT_IMAGE, intensity, $
	MIN=intens_sort[n_sort*intens_min], MAX=intens_sort[n_sort*intens_max],$
	ORIGIN=[x_orig,solary[0]], SCALE=[xres,yres], $
	POSITION=pltpos,  XTHICK=plt_thick, YTHICK=plt_thick, XSTYLE=1, YSTYLE=1,$
	BACKGROUND=255, COLOR=0, $ 
	YTITLE='Solar Y [arcsec]', XTITLE='Solar X [arcsec]', CHARSIZE=plt_char, CHARTHICK=plt_thick, $
	TITLE='Si IV 1394'+angst+' Peak Intensity', /NORMAL 

cgColorbar, /VERTICAL, /RIGHT, COLOR='black', RANGE=[intens_sort[n_sort*intens_min], intens_sort[n_sort*intens_max]],$
       	TCHARSIZE=cb_char, TEXTTHICK=cb_char, CHARSIZE=2, CHARTHICK=2, $
	YTHICK=cb_char,XTHICK=cb_char, TITLE='Peak Intensity '+spec_units, TLOCATION='LEFT', POSITION=cbpos
cont = ''
READ, cont, PROMPT='Write? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
	scrncap = TVRD(TRUE=1)
	WRITE_PNG, save_path+'INTENS_PERC_'+name+'_white.png', scrncap
ENDIF ELSE BEGIN
ENDELSE
ENDIF ELSE BEGIN
ENDELSE


cont = ''
READ, cont, PROMPT='Plot intensity logarithmic scaling? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
PRINT, ALOG10(MIN(intensity)), ALOG10(MAX(intensity))
READ, int_log_min, PROMPT='Set intensity lower log (e.g. 2.5): '
READ, int_log_max, PROMPT='Set intensity upper log (e.g. 6): '
WAIT, 1
	WINDOW,  RETAIN=2
EIS_COLORS, /INTENSITY
	PLOT_IMAGE, ALOG10(intensity), MIN=int_log_min, MAX=int_log_max, $
		CHARSIZE=plt_char,CHARTHICK=plt_thick, THICK=plt_thick, POSITION=pltpos, BACKGROUND=255, COLOR=0,$
		ORIGIN=[x_orig, solary[0]], SCALE=[xres,yres], $
		TITLE='Si IV 1394'+angst+' Intensity', $
		YTITLE='Solar Y [arcsec]', XTITLE='Solar X [arcsec]'
cgColorbar, /VERTICAL, /RIGHT, COLOR='black', TITLE=log_un+' Peak Intensity '+spec_units,TLOCATION='LEFT', $
       	TCHARSIZE=cb_char, TEXTTHICK=cb_char, CHARSIZE=2, CHARTHICK=2, $
	POSITION=cbpos, RANGE=[10^int_log_min,10^int_log_max]
cont = ''
READ, cont, PROMPT='Write? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
	scrncap = TVRD(TRUE=1)
	name = STRING(FORMAT='(I03)',int_log_min*100)+'_' +STRING(FORMAT='(I03)',int_log_max*100)
	WRITE_PNG, save_path+'INTENS_LOG_'+name+'_white.png', scrncap
ENDIF ELSE BEGIN
ENDELSE
ENDIF


; ------------------------------------------------
; SCALE DOPPLER DATA

c = 3e+5 ; speed of light in km/s
wav_exp = 1393.7894 ; expected wavelength
doppler = c * (wav_exp - doppler)/wav_exp

doppler_sort = doppler[SORT(doppler)]
doppler_sort = doppler_sort[WHERE(FINITE(doppler_sort) AND (doppler_sort GT -199))]
d_n_sort=N_ELEMENTS(doppler_sort)

print, 'Dop: ', doppler_sort[d_n_sort*0.01], doppler_sort[d_n_sort*0.99]
PRINT, 'Dop: ', ALOG10(doppler_sort[d_n_sort*0.01]), ALOG10(doppler_sort[d_n_sort*0.99])
;PRINT, 'Range of sorted values:', MINMAX(doppler_sort)

cont = ''
READ, cont, PROMPT='Plot doppler? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
; ------------------------------------------------
; PLOT DOPPLER SHIFT
PRINT, MINMAX(doppler)
READ, dop_max, PROMPT='Set absolute value of doppler max (e.g. 50): '
WAIT, 1
WINDOW,  RETAIN=2
EIS_COLORS, /VELOCITY
TVLCT, 0,0,0, 0 ; add black
TVLCT, 255, 255, 255, 255 ;add white
PLOT_IMAGE, (-1*doppler), BOTTOM=1, TOP=254, $
	MIN=(-1* dop_max), MAX=dop_max, $
	BACKGROUND=255, COLOR=0, POSITION=pltpos, $
	ORIGIN=[x_orig,solary[0]], SCALE=[xres,yres], $
	YTITLE='Solar Y [arcsec]', XTITLE='Solar X [arcsec]', CHARSIZE=plt_char, $
	TITLE=si_iv+' Doppler Shift', THICK=plt_thick, CHARTHICK=plt_thick,XTHICK=plt_thick, YTHICK=plt_thick 
cgColorbar, RANGE=[(-1*(dop_max+10)), dop_max+10], /VERTICAL, /RIGHT, COLOR='black',$
       	TCHARSIZE=cb_char, TEXTTHICK=cb_char, CHARSIZE=2, CHARTHICK=2, $
	CLAMP=[-1*(dop_max+10), (dop_max+10)], NEUTRALINDEX=0, $
       	TITLE='Doppler Velocity' + vel_units, TLOCATION='LEFT',  POSITION=cbpos
cont = ''
READ, cont, PROMPT='Write? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
	scrncap = TVRD(TRUE=1)
	name = 'abs_'+ STRING(FORMAT='(I03)',dop_max)
	WRITE_PNG, save_path+'DOP_' +name+'.png', scrncap
ENDIF 
ENDIF 

; ------------------------------------------------
; SCALE VELOCITY DATA
width = c * (width)/wav_exp
width_sort = width[SORT(width)]
width_sort = width_sort[WHERE(FINITE(width_sort) AND (width_sort GT -199))]
v_n_sort=N_ELEMENTS(width_sort)

print, 'Wid: ', width_sort[v_n_sort*0.01], width_sort[v_n_sort*0.99]
PRINT, 'Wid: ', ALOG10(width_sort[v_n_sort*0.01]), ALOG10(width_sort[v_n_sort*0.99])
;PRINT, 'Range of sorted values:', MINMAX(width_sort)

cont = ''
READ, cont, PROMPT='Plot width percentile scaling? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
; ------------------------------------------------
; PLOT VELOCITY/EXPONENTIAL LINE WIDTHS
PRINT, MINMAX(width)

READ, wid_min, PROMPT='Set width lower percentile (e.g. 0.01): '
min_width=width_sort[v_n_sort*wid_min]
READ, wid_max, PROMPT='Set width upper percentile (e.g. 0.99): '
max_width=width_sort[v_n_sort*wid_max]
WAIT, 1
WINDOW,  RETAIN=2
EIS_COLORS, /WIDTH
PLOT_IMAGE, width,MIN=min_width, MAX=max_width, ORIGIN=[x_orig,solary[0]], SCALE=[xres,yres], $
	YTITLE='Solar Y [arcsec]', XTITLE='Solar X [arcsec]', CHARSIZE=plt_char, CHARTHICK=plt_thick,THICK=plt_thick, $
	TITLE=si_iv+' Exponential Line Width', POSITION=pltpos, BACKGROUND=255, COLOR=0 
cgColorbar, /VERTICAL, /RIGHT,  COLOR='black', TITLE='Exponential Line Width '+vel_units,$
       	TCHARSIZE=cb_char, TEXTTHICK=cb_char, CHARSIZE=2, CHARTHICK=2, $
	TLOCATION='LEFT', RANGE=[min_width,max_width], $
	;NEUTRALINDEX=0, CLAMP=[min_width,max_width], $
	POSITION=cbpos
cont = ''
READ, cont, PROMPT='Write? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
	scrncap = TVRD(TRUE=1)
	name = STRING(FORMAT='(I03)',wid_min*100)+'_' +STRING(FORMAT='(I03)',wid_max*100)
	WRITE_PNG, save_path+'WIDTH_PERC_'+name+'_white.png', scrncap
ENDIF
ENDIF ELSE BEGIN
ENDELSE


cont = ''
READ, cont, PROMPT='Plot width logarithmic scaling? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
PRINT, MINMAX(width)
PRINT, ALOG10(MIN(width)), ALOG10(MAX(width))
READ, wlog_min, PROMPT='Set width lower log (e.g. 0): '
READ, wlog_max, PROMPT='Set width upper log (e.g. 1): '
	WAIT, 1
	WINDOW, 0, RETAIN=2
	EIS_COLORS, /WIDTH
	PLOT_IMAGE, ALOG10(width), BOTTOM=1,$
	MIN=wlog_min, MAX=wlog_max, CHARSIZE=plt_char, CHARTHICK=plt_thick,THICK=plt_thick, $
		ORIGIN=[x_orig, solary[0]], SCALE=[xres,yres],POSITION=pltpos, $
		TITLE=si_iv+' Exponential Line Width', BACKGROUND=255, COLOR=0,$
		YTITLE='Solar Y [arcsec]', XTITLE='Solar X [arcsec]'
	cgColorbar, /VERTICAL, /RIGHT, COLOR='black',TITLE='Exponential Line Width' + vel_units,$
	       	TLOCATION='LEFT', RANGE=[10^wlog_min,10^wlog_max],$
	       	NEUTRALINDEX=0, CLAMP=[10^wlog_min,10^wlog_max],$
       		TCHARSIZE=cb_char, TEXTTHICK=cb_char, CHARSIZE=2, CHARTHICK=2, $
		POSITION=cbpos
cont = ''
READ, cont, PROMPT='Write? (y/n)'
IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN
	scrncap = TVRD(TRUE=1)
	name = STRING(FORMAT='(I03)',wlog_min*100)+'_' +STRING(FORMAT='(I03)',wlog_max*100)
	WRITE_PNG, save_path+'WIDTH_LOG_' +name+'_white.png', scrncap
ENDIF
ENDIF

END
