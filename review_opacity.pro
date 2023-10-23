PRO REVIEW_OPACITY;
;, fname, msp, detections, obs_tag

obs_tag = '20140805 ; this is just the date, but it's a directory on my system
path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'

; ---------------------------------------------
; CHANGE THESE FOR EACH DATASET
fname ='iris_l2_20140805_133003_3883108846_raster_t000_r00000.fits'

fname = path+fname
; -----------------------------------------------
; INPUT
; -----------------------------------------------
RESTORE, path+'opacity.sav' 
print, opt_thick
STOP

RESTORE, path +'Si_IV_1394_cal_intensity.sav'
intens_1394=cal_intensity

RESTORE, path +'Si_IV_1403_cal_intensity.sav'
intens_1403=cal_intensity

RESTORE, path+'Si_IV_1403_cal_err.sav'
err_1403 = cal_err

RESTORE, path+'Si_IV_1394_cal_err.sav'
err_1394 = cal_err
; -----------------------------------------------
lam1 = 1394
lam2 = 1403
specDATA = IRIS_OBJ(fname)
winid1=specDATA->GETWINDX(lam1)
winid2=specDATA->GETWINDX(lam2)
wav1 = specDATA->GETLAM(winid1)
wav2 = specDATA->GETLAM(winid2)
OBJ_DESTROY,specDATA
; -----------------------------------------------
; compute calibrated mean spectral profiles
; -----------------------------------------------

trunc1 = WHERE ((wav1 LT (lam1+1.3)) AND (wav1 GT (lam1 -1.3)))
wav_trunc1 = wav1[trunc1]

trunc2 = WHERE ((wav2 LT (lam2+1.7)) AND (wav2 GT (lam2 -1.7)))
wav_trunc2 = wav2[trunc2]

RESTORE, path+'wav_exp.sav'

wav_shift = wav_exp2-wav_exp1
; -----------------------------------------------
; SET WINDOW RANGE FOR RATIO PLOT (DISTANCE FROM WAV_0)
win_range = 0.4
wav_rat = [wav_exp1-win_range, wav_exp1+win_range]
; -----------------------------------------------

RESTORE, path +'cal_parameters.sav'
background = parameters[3,*,*]
background =REFORM(background)


opt_thick_conf = [[0,0]]
opt_thin_conf = [[0,0]]

num = N_ELEMENTS(opt_thick)/2 - 1
print, num
LOADCT, 39
WINDOW, 0, RETAIN=2, XSIZE=1024

FOR K=0,num DO BEGIN
coords = opt_thick[*,K]

img_1394 = (intens_1394[*,coords[0], coords[1]]-background[coords[0], coords[1]])
img1 = img_1394[trunc1]

img_1403 = (intens_1403[*,coords[0], coords[1]]-background[coords[0], coords[1]])
img2= img_1403[trunc2]
im2_err = err_1403[*,coords[0], coords[1]]

find_cent1=wav_trunc1-wav_exp1
find_cent1=sort(ABS(find_cent1))
center1= find_cent1[0]
find_cent2=wav_trunc2-wav_exp2
find_cent2=sort(ABS(find_cent2))
center2= find_cent2[0]
find_shift = center1-center2

img2sh = SHIFT(img2, find_shift)
ratio=img1/img2sh

rat_err = SQRT((1/img2)^2 * err_1394^2 + (img1/img2^2)^2*err_1403^2)

PRINT, coords
!p.multi =[0,1,2,0,0]
PLOT, wav_trunc1, img1, $
       	XRANGE=[1392.0,1395.0],  XSTYLE=1, XTITLE='Wavelength [angstroms]', CHARSIZE=2, CHARTHICK=2, BACKGROUND=0, COLOR=255, $
	YTITLE='Relative Intensity [arb. units]', TITLE='Si IV Lines', THICK=1.5, XTHICK=2, YTHICK=2
OPLOT, (wav_trunc2-wav_shift), img2,  COLOR = 250, THICK=1.5
OPLOT, [wav_exp1,wav_exp1], [-1e+5,2e+7], LINESTYLE=1, COLOR=190, THICK=3
OPLOT, [wav_rat[0],wav_rat[0]], [-1e+4,2e+7], LINESTYLE=2, THICK=1
OPLOT, [wav_rat[1],wav_rat[1]], [-1e+4,2e+7], LINESTYLE=2, THICK=1
OPLOT, (wav_trunc2-wav_shift), (img2+im2_err), COLOR=80
OPLOT, (wav_trunc2-wav_shift), (img2-im2_err), COLOR=80


small_window = WHERE(wav_trunc1 GT wav_exp1 -0.1 AND wav_trunc1 LT wav_exp1+0.1)
avg_ratio = MEAN(ratio[small_window])

PLOT, wav_trunc1, ratio, XRANGE=wav_rat, YRANGE=[-5,10], XTITLE='Wavelength', TITLE='Si IV Line Pair Ratio', CHARSIZE=2, CHARTHICK=2, XTHICK=2, YTHICK=2, YTITLE='Si IV 1394/Si IV 1403'
	OPLOT, [wav_exp1-0.1,wav_exp1+0.1],[avg_ratio, avg_ratio], COLOR=208, LINESTYLE=2
	OPLOT, [1390,1400],[2,2], COLOR = 250
	OPLOT, [1393.7956, 1393.7956], [-10,10], COLOR=190, LINESTYLE=2
	OPLOT, wav_trunc1, (ratio+rat_err), COLOR = 80
	OPLOT, wav_trunc1, (ratio-rat_err), COLOR = 80

thick = ''
READ, thick, PROMPT='Optically thick? '
IF thick EQ 'y' OR thick EQ 'Y' THEN BEGIN
	opt_thick_conf = [[opt_thick_conf], [coords]]
	ID = STRING(FORMAT='(I03)', K)
	scrncap=TVRD(TRUE=1)
	WRITE_PNG, path + 'img/RATIO_' +ID+ '.png', scrncap
ENDIF ELSE BEGIN
	opt_thin_conf = [[opt_thin_conf], [coords]]

ENDELSE
ENDFOR

SAVE, opt_thick, opt_thin, filename = path+'opacity.sav'
PRINT, 'Number of Optically Thick Detections: ', N_ELEMENTS(opt_thick[0,*])
PRINT, 'Number Confirmed: ', N_ELEMENTS(opt_thick_conf[0,*])

END
