PRO MSP_SI4
; A function to return the expected wavelength for a given line by computing the mean spectral profile for a raster file.

FILENAME='iris_l2_20151125_160004_3630088076_raster_t000_r00000.fits'

obs_tag='20151125'
path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'

fname = path + FILENAME 
lam1=1394
lam2=1403

specDATA = IRIS_OBJ(fname)
specDATA->SHOW_LINES
winid1 = specDATA->GETWINDX(lam1)
winid2 = specDATA->GETWINDX(lam2)
linid1 = specDATA->GETLINE_ID(winid1)
linid2 = specDATA->GETLINE_ID(winid2)
data1 = specDATA->GETVAR(winid1, /LOAD)
data2 = specDATA->GETVAR(winid2, /LOAD)
wav1 = specDATA->GETLAM(winid1)
wav2 = specDATA->GETLAM(winid2)

OBJ_DESTROY, specDATA
PRINT, 'Destroyed SPEC Object'

linid1=REPSTR(linid1, ' ', '_')
msp1= MEAN(MEAN(data1, DIMENSION=2),DIMENSION=2)
msp2= MEAN(MEAN(data2, DIMENSION=2),DIMENSION=2)

trunc1 = WHERE ((wav1 LT (lam1+1.3)) AND (wav1 GT (lam1-1.3)))
wav_trunc1 = wav1[trunc1]
msp1 = msp1[trunc1]

trunc2 = WHERE ((wav2 LT (lam2+1.3)) AND (wav2 GT (lam2-1.3)))
wav_trunc2 = wav2[trunc2]
msp2 = msp2[trunc2]


SAVE, msp1, msp2, wav_trunc1, wav_trunc2, filename=path+'si4_msp.sav'

PRINT, 'Plotting...'
WINDOW, 0
;PLOT, wav_trunc1, msp1
PLOT, wav_trunc2, msp2
wav_trunc=wav_trunc1
mean_prof_trunc=msp1

SAVE, wav_trunc, mean_prof_trunc, filename=path+linid1+'_msp.sav'

yfit1 = MPFITPEAK(wav_trunc1, msp1, cent1, NTERMS=4)
yfit2 = MPFITPEAK(wav_trunc2, msp2, cent2, NTERMS=4)
c = 3e+5 ; speed of light in km/s
wav_exp1 = cent1[1]
wav_exp2 = cent2[1]


; distance to ni ii
ni_ii = wav_exp1 - 1393.330
ni_ii =  c* (ni_ii/wav_exp1)
lower_bound = ni_ii/2.


; extreme doppler shift/fits to edge of plotting window
dop_ext = c* (1.3/wav_exp1)

PRINT, 'Expected wavelength (1394): ', wav_exp1
PRINT, 'Expected wavelength (1403): ', wav_exp2
PRINT, 'Distance between centers: ', wav_exp2-wav_exp1
PRINT, 'Lower bound for line width to capture Ni II absorption: ', lower_bound
PRINT, 'Cutoff for extreme Doppler shift: ', dop_ext

SAVE, wav_exp1, wav_exp2, filename=path+'si4_wav_exp.sav'

END
