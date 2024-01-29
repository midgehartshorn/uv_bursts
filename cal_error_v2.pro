PRO CAL_ERROR_V2

;**** Issues addressed in v2 *****
;- Radiometric calibriation factor incorporated into error calculation
;- Removed ABS() applied to intens in radiometric calibration
;- Replaced Area_eff = A_eff[wav] with a redundant assignment since
;  wav is not array of indices and A_eff is already scaled to wav via INTERPOL()
;- IRIS_GET_RESPONSE() was recently updated to address issues with FUV background
;  subtraction under thermospheric absorption conditions, ratios now closer to 2.
;*********************************

; A program to convert spectral units from DN to physical units
; (E_photon * DN2PHOT_SG)/(A_eff * Pix_xy * Pix_lambda * t_exp * W_slit)
; ------------------------------------------------
; CHANGE THESE:
;lambda = 1394
lambda = 1403
fname = 'iris_l2_20150206_051507_3800256196_raster_t000_r00000.fits'
sjname = 'iris_l2_20150206_051507_3800256196_SJI_1400_t000.fits'
obs_tag='20150206' ; directory name
rastnum = ''
path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'
;path = 'C:\Users\cmadsen\SI_IV_Opacity_Code\'

;-------------------------------------------------
fname = path +fname
sjname = path +sjname

specDATA = IRIS_OBJ(fname)
specDATA->SHOW_LINES
winid = specDATA->GETWINDX(lambda)
linid=specDATA->GETLINE_ID(winid)
data = specDATA->GETVAR(winid,/LOAD)
wav = specDATA->GETLAM(winid)
T_exp = specDATA->GETEXP()
date= specDATA->GETINFO('date_obs')

solary = specDATA->GETYPOS()
solarx = specDATA->GETXPOS()
OBJ_DESTROY,specDATA

SJI_data = IRIS_SJI(sjname)
yscale = SJI_data->YSCALE()
OBJ_DESTROY,SJI_data
; ------------------------------------------------
PRINT,'Error Calibration for: ', linid,'wavelength: ', lambda, 'date: ', date
img = data[*,*,*]

linid=REPSTR(linid, ' ', '_')

; ------------------------------------------------
; EXPECTED WAVELENGTH

; mean profile
mean_prof = MEAN(MEAN(data, DIMENSION=2), DIMENSION=2)

; truncate profile to avoid influence of overscan
trunc = WHERE((wav LT (lambda+1.3)) AND (wav GT (lambda-1.3)))

wav_trunc = wav[trunc]
mean_prof_trunc = mean_prof[trunc]

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

; ------------------------------------------------
; spectral resolution, Pix_lambda
spec_res = MEAN(DERIV(wav))

; ------------------------------------------------
; spatial resolution: expect Pix_xy = 8.0964E-7
spat_res = MEAN(DERIV(yscale)) * (!DPI/(180.*3600.))

; ------------------------------------------------
; set slit width: w_slit = 3 arcsec 
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

; Read noise: 1.75 counts/pix
r_noise=1.75

print, 'Original values: '
print, img[25,100:120,25]

; ------------------------------------------------
cal_err = MAKE_ARRAY(N_ELEMENTS(img[*,0,0]),N_ELEMENTS(img[0,*,0]), N_ELEMENTS(img[0,0,*]))
cal_intensity=MAKE_ARRAY(N_ELEMENTS(img[*,0,0]),N_ELEMENTS(img[0,*,0]), N_ELEMENTS(img[0,0,*]))
HELP, cal_err
HELP, cal_intensity

TIC
FOR J = 0,(N_ELEMENTS(img[0,0,*])-1) DO BEGIN
	FOR I = 0,(N_ELEMENTS(img[0,*,0])-1) DO BEGIN
	intens = img[*,I,J]
	E_phot = h * (c_cm/(wav*1e-8))
	;Area_eff = A_eff[wav]
	area_eff = a_eff

	err=[]
	intens_cal = []
		FOR w = 0,(N_ELEMENTS(wav)-1) DO BEGIN
		psi = (E_phot[w]*dn2phot) / (Area_eff[w] * spat_res * spec_res * t_exp[J] * w_slit)
		;intens_cal = ABS(intens) * (E_phot[w]*dn2phot)$
			;/ (Area_eff[w] * spat_res * spec_res * t_exp[J] * w_slit)
		intens_cal = intens * psi
		;err = SQRT((ABS(intens_cal)/dn2phot)+ (r_noise^2.0))
		err = psi*SQRT((ABS(intens)/dn2phot)+ (r_noise^2.0))
		ENDFOR
		cal_err[*,I,J]=err
		cal_intensity[*,I,J]=intens_cal

	ENDFOR
	PRINT, J
ENDFOR

TOC
PRINT, 'Saving...'

lambda = STRTRIM(lambda,2)
SAVE, cal_intensity, filename=path+lambda+'_cal_intensity' + rastnum + '.sav'

SAVE, cal_err, filename=path+lambda+'_cal_err' +rastnum+'.sav'

print, 'Calibrated values: '
print, cal_intensity[25,100:120,25]
print, 'Calibrated error: '
print, cal_err[25,100:120,25]
; ------------------------------------------------

; ------------------------------------------------
PRINT, 'Filename: ', fname
PRINT, 'Wavelength: ', lambda
PRINT, 'Procedure complete.'
PRINT, STRING(7B)

END

