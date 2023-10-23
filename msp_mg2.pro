PRO MSP_MG2
; A function to return the expected wavelength for a given line by computing the mean spectral profile for a raster file.

;FILENAME='iris_l2_20130924_114443_4000254145_raster_t000_r00000.fits'

path = '/home/miriam/Documents/MHC/Summer23/code'

fname = path + '/data/iris_l2_20131203_075414_3800254046_raster_t000_r00000.fits'
lam1=2799
lam2=2800
obs_tag='20131203'

specDATA = IRIS_OBJ(fname)
winid1 = specDATA->GETWINDX(lam1)
winid2 = specDATA->GETWINDX(lam2)
linid1 = specDATA->GETLINE_ID(winid1)
linid2 = specDATA->GETLINE_ID(winid2)
data1 = specDATA->GETVAR(winid1, /LOAD)
data2 = specDATA->GETVAR(winid2, /LOAD)
wav1 = specDATA->GETLAM(winid1)
wav2 = specDATA->GETLAM(winid2)

OBJ_DESTROY, specDATA

linid1=REPSTR(linid1, ' ', '_')
msp1= MEAN(MEAN(data1, DIMENSION=2),DIMENSION=2)
msp2= MEAN(MEAN(data2, DIMENSION=2),DIMENSION=2)

trunc1 = WHERE ((wav1 LT (lam1+1.3)) AND (wav1 GT (lam1-1.3)))
wav_trunc1 = wav1[trunc1]
msp1 = msp1[trunc1]

trunc2 = WHERE ((wav2 LT (lam2+1.3)) AND (wav2 GT (lam2-1.3)))
wav_trunc2 = wav2[trunc2]
msp2 = msp2[trunc2]


SAVE, msp1, msp2, wav_trunc1, wav_trunc2, filename=path+'/analysis/'+obs_tag+'/NUV_msp.sav'
!p.multi=[0,1,2]
WINDOW, 0
PLOT, wav_trunc1, msp1


PLOT, wav_trunc2, msp2
wav_trunc=wav_trunc1
mean_prof_trunc=msp1

;SAVE, wav_trunc, mean_prof_trunc, filename=path+obs_tag+'_'+linid1+'_msp.sav'

yfit1 = MPFITPEAK(wav_trunc1, msp1, cent1, NTERMS=4)
yfit2 = MPFITPEAK(wav_trunc2, msp2, cent2, NTERMS=4)
c = 3e+5 ; speed of light in km/s
wav_exp1 = cent1[1]
wav_exp2 = cent2[1]


; distance to ni ii


; extreme doppler shift/fits to edge of plotting window
dop_ext = c* (1.3/wav_exp1)

PRINT, 'Expected wavelength (', lam1, '): ', wav_exp1
PRINT, 'Expected wavelength (', lam2, '): ', wav_exp2
PRINT, 'Distance between centers: ', wav_exp2-wav_exp1

SAVE, wav_exp1, wav_exp2, filename=path+'/analysis/'+obs_tag+'/NUV_wav_exp.sav'

END
