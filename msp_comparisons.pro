PRO MSP_COMPARISONS
; A function to return the expected wavelength for a given line by computing the mean spectral profile for a raster file.

;FILENAME='iris_l2_20130924_114443_4000254145_raster_t000_r00000.fits'

path = '/home/miriam/Documents/MHC/Summer23/code'
fname = path + '/data/iris_l2_20150206_051507_3800256196_raster_t000_r00000.fits'
obs_tag='20150206'


lam=1394
specDATA = IRIS_OBJ(fname)
specDATA->SHOW_LINES

winid = 2
win_wid = 2
dat0 = specDATA->GETVAR(winid, /LOAD)
lin0 = specDATA->GETLINE_ID(winid)
wav0 = specDATA->GETLAM(winid)

OBJ_DESTROY, specDATA

RESTORE, path+'/analysis/'+obs_tag+'/opacity.sav'

trunc = WHERE ((wav0 LT (lam+win_wid)) AND (wav0 GT (lam-win_wid)))
;trunc = WHERE ((wav0 LT 2806) AND (wav0 GT 2791))
;trunc = WHERE ((wav0 LT (lam+2)) AND (wav0 GT (lam-4)))
wav_trunc = wav0[trunc]

opt_thick = opt_thick[*, 1:*]
PRINT, opt_thick
opt_thin = opt_thin[*,1:*]

angst_char=STRING("305B)
PRINT, 'Number of Thick', N_ELEMENTS(opt_thick[0,*])
PRINT, 'Number of Thin', N_ELEMENTS(opt_thin[0,*])
data_thin = dat0[*, opt_thin[0,*], opt_thin[1,*]]
mean_thin = MEAN(MEAN(data_thin, DIMENSION=2), DIMENSION=2)

data_thick = dat0[*, opt_thick[0,*], opt_thick[1,*]]
mean_thick = MEAN(MEAN(data_thick, DIMENSION=2), DIMENSION=2)


!p.multi = 0 
;WINDOW, 0, RETAIN=2
PLOT, wav_trunc, mean_thin[trunc], COLOR=255, THICK=3, CHARSIZE=4,CHARTHICK=3, TITLE=lin0+ angst_char, XTITLE='Wavelength ('+angst_char+')', YTITLE='Relative Intensity', YRANGE=[0, 375], XTHICK=2, YTHICK=2
OPLOT, wav_trunc, mean_thick[trunc], COLOR=250, THICK=3
;OPLOT, [2798.7529, 2798.7529], [-1e+2,1e+5], LINESTYLE=2
;OPLOT, [2798.8230, 2798.8230], [-1e+2,1e+5], LINESTYLE=2
;OPLOT, [2801.907, 2801.907], [-1e+2,1e+5], LINESTYLE=2

sav = ''
READ, sav, PROMPT='Save? '
IF sav EQ 'y' OR sav EQ 'Y' THEN BEGIN 
	linid=REPSTR(lin0, ' ', '_')
	scrncap =TVRD(TRUE=1)
	WRITE_PNG, path+'/analysis/'+obs_tag+'/MEAN_'+linid+'.png', scrncap

ENDIF




END
