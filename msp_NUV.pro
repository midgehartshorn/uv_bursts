PRO MSP_NUV
; A function to return the expected wavelength for a given line by computing the mean spectral profile for a raster file.

;FILENAME='iris_l2_20130924_114443_4000254145_raster_t000_r00000.fits'

path = '/home/miriam/Documents/MHC/Summer23/code'
fname = path + '/data/iris_l2_20150206_051507_3800256196_raster_t000_r00000.fits'
lam1=1394
lam2=2799
obs_tag='20150206'

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

RESTORE, path+'/analysis/'+obs_tag+'/opacity.sav'

linid1=REPSTR(linid1, ' ', '_')
msp1= MEAN(MEAN(data1, DIMENSION=2),DIMENSION=2)
msp2= MEAN(MEAN(data2, DIMENSION=2),DIMENSION=2)

trunc1 = WHERE ((wav1 LT (lam1+1.3)) AND (wav1 GT (lam1-1.3)))
wav_trunc1 = wav1[trunc1]
msp1 = msp1[trunc1]

trunc2 = WHERE ((wav2 LT (lam2+5.5)) AND (wav2 GT (lam2-5.5)))
wav_trunc2 = wav2[trunc2]
msp2 = msp2[trunc2]

opt_thick = opt_thick[*, 1:*]
opt_thin = opt_thin[*,1:*]

PRINT, 'Number of Thick', N_ELEMENTS(opt_thick[0,*])
PRINT, 'Number of Thin', N_ELEMENTS(opt_thin[0,*])
data_thin = data2[*, opt_thin[0,*], opt_thin[1,*]]
mean_thin = MEAN(MEAN(data_thin, DIMENSION=2), DIMENSION=2)

data_thick = data2[*, opt_thick[0,*], opt_thick[1,*]]
HELP, data_thick
mean_thick = MEAN(MEAN(data_thick, DIMENSION=2), DIMENSION=2)

HELP, data_thick, mean_thick


!p.multi = 0 
;WINDOW, 0, RETAIN=2
PLOT, wav_trunc2, mean_thin[trunc2], COLOR=255, THICK=1, CHARSIZE=2
OPLOT, wav_trunc2, mean_thick[trunc2], COLOR=250, THICK=3
OPLOT, [2798.7529, 2798.7529], [-1e+2,1e+5], LINESTYLE=2
OPLOT, [2798.8230, 2798.8230], [-1e+2,1e+5], LINESTYLE=2
OPLOT, [2801.907, 2801.907], [-1e+2,1e+5], LINESTYLE=2
wav_trunc=wav_trunc1
mean_prof_trunc=msp1

sav = ''
READ, sav, PROMPT='Save? '
IF sav EQ 'y' OR sav EQ 'Y' THEN BEGIN 
	scrncap =TVRD(TRUE=1)
	WRITE_PNG, path+'/analysis/'+obs_tag+'/MEAN.png', scrncap

ENDIF


;SAVE, wav_trunc, mean_prof_trunc, filename=path+obs_tag+'_'+linid1+'_msp.sav'

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

SAVE, wav_exp1, wav_exp2, filename=path+'/analysis/'+obs_tag+'/wav_exp.sav'

END
