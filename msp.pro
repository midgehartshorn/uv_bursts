PRO MSP
;, lambda, filename, obs_tag
; ---------------------------------------------------------
; ARE YOU SURE YOU DON'T MEAN MSP_SI4.PRO?
; A function to return the expected wavelength for a given line by computing the mean spectral profile for a raster file.
; ---------------------------------------------------------
filename='iris_l2_20150225_124705_3820104096_raster_t000_r00000.fits'
obs_tag='20150225'
lambda=1394

path = '/run/media/midge/SamsungSSD/data/' + obs_tag+ '/'

fname = path + filename

specDATA = IRIS_OBJ(fname)
winid = specDATA->GETWINDX(lambda)
linid = specDATA->GETLINE_ID(winid)
data = specDATA->GETVAR(winid, /LOAD)
wav = specDATA->GETLAM(winid)

OBJ_DESTROY, specDATA
print, linid

linid=REPSTR(linid, ' ', '_')
mean_prof= MEAN(MEAN(data, DIMENSION=2),DIMENSION=2)

;trunc = WHERE ((wav LT 1395.3) AND (wav GT 1392.3))

trunc = WHERE ((wav LT (lambda+1.3)) AND (wav GT (lambda-1.3)))
wav_trunc = wav[trunc]

mean_prof_trunc = mean_prof[trunc]

WINDOW, 0

PLOT, wav_trunc, mean_prof_trunc

SAVE, wav_trunc, mean_prof_trunc, filename=path+linid+'_msp.sav'
;STOP

yfit = MPFITPEAK(wav_trunc, mean_prof_trunc, centroid, NTERMS=4)
c = 3e+5 ; speed of light in km/s
wav_0 = centroid[1]
SAVE, wav_0, filename=path+'wav_exp.sav'

; distance to ni ii
ni_ii = wav_0 - 1393.330
ni_ii =  c* (ni_ii/wav_0)
lower_bound = ni_ii/2.


; extreme doppler shift/fits to edge of plotting window
dop_ext = c* (1.3/wav_0)

PRINT, 'Expected wavelength: ', wav_0
PRINT, 'Lower bound for line width to capture Ni II absorption: ', lower_bound
PRINT, 'Cutoff for extreme Doppler shift: ', dop_ext

END
