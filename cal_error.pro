PRO CAL_ERROR
; A program to convert spectral units from DN to physical units
; (E_photon * DN2PHOT_SG)/(A_eff * Pix_xy * Pix_lambda * t_exp * W_slit)
; ------------------------------------------------
; CHANGE THESE:
lambda = 1394
fname = 'iris_l2_20151204_061345_3690088076_raster_t000_r00000.fits'
sjname = 'iris_l2_20151204_061345_3690088076_SJI_1400_t000.fits'
date= '2015-12-04'
obs_tag=REPSTR(date, '-', '')

date = date+'T00:00:00.000'

;-------------------------------------------------
path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'
fname = path +fname
sjname = path +sjname

specDATA = IRIS_OBJ(fname)
specDATA->SHOW_LINES
winid = specDATA->GETWINDX(lambda)
linid=specDATA->GETLINE_ID(winid)
data = specDATA->GETVAR(winid,/LOAD)
wav = specDATA->GETLAM(winid)
T_exp = specDATA->GETEXP()

solary = specDATA->GETYPOS()
solarx = specDATA->GETXPOS()
OBJ_DESTROY,specDATA

SJI_data = IRIS_SJI(sjname)
yscale = SJI_data->YSCALE()
OBJ_DESTROY,SJI_data
; ------------------------------------------------
PRINT,'Error Calibration for: ', linid, lambda, date
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

;WINDOW, 0 
;PLOT, wav_trunc, mean_prof_trunc 

yfit = MPFITPEAK(wav_trunc, mean_prof_trunc, centroid, NTERMS=4)

; wav_0 is expected wavelength
wav_0 = centroid[1]
; ------------------------------------------------
; DN2PHOT_SG
;date=''
;READ, date, PROMPT='Date/time? (yyyy-mm-ddT:hh:mm.sss) '
iresp = IRIS_GET_RESPONSE(date)
dn2phot = iresp.DN2PHOT_SG[0]
;print, dn2phot

; ------------------------------------------------
; effective area
area_sg = iresp.AREA_SG[*,0]
PRINT, MINMAX(area_sg)
wav_sg = iresp.LAMBDA[*,0]
A_eff = INTERPOL(area_sg, (wav_sg*10.), wav)

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
; to compute for full img, J=399, I=1095
FOR J = 0,(N_ELEMENTS(img[0,0,*])-1) DO BEGIN
	FOR I = 0,(N_ELEMENTS(img[0,*,0])-1) DO BEGIN
	intens = img[*,I,J]
	E_phot = h * (c_cm/(wav*1e-8))
	Area_eff = A_eff[wav]

	err=[]
	intens_cal = []
		FOR w = 0,(N_ELEMENTS(wav)-1) DO BEGIN
		intens_cal = ABS(intens) * (E_phot[w]*dn2phot)$
			/ (Area_eff[w] * spat_res * spec_res * t_exp[J] * w_slit)
		err = SQRT(ABS(intens_cal)/dn2phot+ r_noise^2)
		ENDFOR
		cal_err[*,I,J]=err
		cal_intensity[*,I,J]=intens_cal

	ENDFOR
	PRINT, J
ENDFOR

TOC
SAVE, cal_intensity, filename=path+lambda+'_cal_intensity.sav'

SAVE, cal_err, filename=path+linid+'_cal_err.sav'

;dims = SIZE(parameters,/DIMENSIONS)

print, 'Calibrated values: '
print, cal_intensity[25,100:120,25]
print, 'Calibrated error: '
print, cal_err[25,100:120,25]
; ------------------------------------------------

; ------------------------------------------------

PRINT, 'Procedure complete.'
PRINT, STRING(7B)

END
