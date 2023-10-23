PRO RADIO_CAL
; A program to convert spectral units from DN to physical units and perfom 
; SGF fitting
; (E_photon * DN2PHOT_SG)/(A_eff * Pix_xy * Pix_lambda * t_exp * W_slit)
; ------------------------------------------------
; CHANGE THESE

lambda = 1394
fname = 'iris_l2_20141212_194504_3800104096_raster_t000_r00001.fits'
sjname = 'iris_l2_20141212_194504_3800104096_SJI_1400_t000.fits'
rastnum = 'r1'
obs_tag = '2014-12-12'
date = obs_tag+'T00:00:00.000'

obs_tag = REPSTR(obs_tag, '-', '')
print, obs_tag
; -----------------------------------------------
path = '/run/media/midge/SamsungSSD/data/'+ obs_tag +'/'
fname = path +fname
sjname = path +sjname

; -----------------------------------------------

specDATA = IRIS_OBJ(fname)
winid = specDATA->GETWINDX(lambda)
linid=specDATA->GETLINE_ID(winid)
data = specDATA->GETVAR(winid,/LOAD)
wav = specDATA->GETLAM(winid)
T_exp = specDATA->GETEXP()

solary = specDATA->GETYPOS()
solarx = specDATA->GETXPOS()
OBJ_DESTROY,specDATA
PRINT, 'Destroyed SPEC Object'
SJI_data = IRIS_SJI(sjname)

yscale = SJI_data->YSCALE()
OBJ_DESTROY,SJI_data
PRINT, 'Destroyed SJI Object'
; ------------------------------------------------

img = data[*,*,*]

linid=obs_tag+ '_' +REPSTR(linid, ' ', '_')

; ------------------------------------------------
; EXPECTED WAVELENGTH

; mean profile
mean_prof = MEAN(MEAN(data, DIMENSION=2), DIMENSION=2)

; truncate profile to avoid influence of overscan
trunc = WHERE((wav LT 1395.3) AND (wav GT 1392.7))

wav_trunc = wav[trunc]
mean_prof_trunc = mean_prof[trunc]

;WINDOW, 0 
;PLOT, wav_trunc, mean_prof_trunc 

yfit = MPFITPEAK(wav_trunc, mean_prof_trunc, centroid, NTERMS=4)

; wav_0 is expected wavelength
wav_0 = centroid[1]
; ------------------------------------------------
; DN2PHOT_SG
iresp = IRIS_GET_RESPONSE(date)
dn2phot = iresp.DN2PHOT_SG[0]

; ------------------------------------------------
; effective area
area_sg = iresp.AREA_SG[*,0]
wav_sg = iresp.LAMBDA[*,0]
A_eff = INTERPOL(area_sg, (wav_sg*10.), wav)

PRINT, minmax(area_sg)
;STOP
; ------------------------------------------------
; spectral resolution, Pix_lambda
spec_res = MEAN(DERIV(wav))

; ------------------------------------------------
; spatial resolution
spat_res = MEAN(DERIV(yscale)) * (!DPI/(180.*3600.))
; expect Pix_xy = 8.0964E-7

; ------------------------------------------------
; set slit width
;w_slit = 3 arcsec 
w_slit = !DPI / (180.* 3600.*3.)

; ------------------------------------------------
; set speed of light
c_km = 3e+5
c_cm = 3e+10

; -----------------------------------------------
; Photon energy
E_phot = []

; Planck's constant in ergs
h= 6.626e-27 

; ------------------------------------------------
parameters = MAKE_ARRAY(4, N_ELEMENTS(img[0,*,0]), N_ELEMENTS(img[0,0,*]))
; to compute for full img, J=399, I=1095
TIC, /PROFILER
clock = TIC()
FOR J = 0,(N_ELEMENTS(img[0,0,*])-1) DO BEGIN
	PRINT, J
	FOR I = 0,(N_ELEMENTS(img[0,*,0])-1) DO BEGIN
		ind = WHERE(img[*,I,J] GE -199) ; ignore overscan values
		IF ind[0] NE -1 THEN BEGIN
		coords = [ind[0],ind[-1]]
		;print, coords
		intens = img[coords[0]:coords[1],I,J] ; non-overscan intensity values
		;print, MINMAX(intens), I, J
		;PRINT, img[coords[0],I,J], img[coords[1],I,J]
		row_wav = wav[coords[0]:coords[1]] ; non-overscan wavelengths for this row
		E_phot = h * (c_cm/(row_wav*1e-8))
		Area_eff = A_eff[coords[0]:coords[1]]

		ENDIF ELSE BEGIN
			params = [-200,-200,-200,-200]
		;	PRINT, 'Entirely overscan,', I,J
		ENDELSE
		; mpfitpeak requires at least nterms elements to run
			intens_cal = []
		IF (N_ELEMENTS(intens) GE 4) AND (N_ELEMENTS(row_wav) GE 4) THEN BEGIN
		FOR w = 0,(N_ELEMENTS(row_wav)-1) DO BEGIN
			intens_cal = intens * (E_phot[w]*dn2phot)$
				/ (Area_eff[w] * spat_res * spec_res * t_exp[J] * w_slit)
		ENDFOR
			myfit = MPFITPEAK(row_wav, intens_cal, params, NTERMS=4)
		ENDIF ELSE BEGIN
		ENDELSE
		;print, params
			parameters[*,I,J] = params
	ENDFOR
	;TOC, clock, REPORT=interimReport
	;PRINT, interimReport[-1]

ENDFOR
TOC, REPORT=finalReport
PRINT, finalREPORT[-1]


; ------------------------------------------------
; velocity conversion

v = c_km * (parameters[2,*,*]/wav_0)
;v = REFORM(v)
HELP, v

; ------------------------------------------------
; DEBUGGING STUFF
HELP, parameters

;PRINT, 'Effective area range:', MINMAX(Area_eff)
;PRINT, 'Photon Energy range:', MINMAX(E_phot)
;PRINT, 'Spectral Radiance range:', MINMAX(parameters[0,*])
PRINT, 'Writing parameters...'
SAVE, v, parameters, filename=path+'cal_parameters_'+rastnum+'.sav'
PRINT, 'Parameters saved to: ', path + 'cal_parameters_'+rastnum+'.sav'
; -----------------------------------------------

angst_char = STRING("305B)
WAIT, 1

WINDOW, 0, RETAIN=2
PLOT, v, parameters[0,*,*], PSYM=3, $ 
	;TITLE='Spectral Radiance vs. Line Width', $
	XRANGE=[0.01, c_km], YRANGE=[0.1, 1e+10],$
	XTITLE='Line Width [km/s]', YTITLE='Spectral Radiance!C[erg s!U-1!N'+ angst_char +'!U-1!Ncm!U-2!Nsr!U-1!N]', $
	/XLOG, /YLOG, /YNOZERO, $
	CHARSIZE=2
scrncap = TVRD(TRUE=1)
WRITE_PNG, path+'calibrated_plot_FULL.png', scrncap
PRINT, 'Plot saved to: ', path + 'calibrated_plot_FULL_'+rastnum+'.png'
PRINT, 'Procedure complete.'
PRINT, STRING(7B)

END
