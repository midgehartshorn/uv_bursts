PRO RATIO_HISTOGRAMS
path = '/home/miriam/Documents/MHC/Summer23/code'

fname ='/data/iris_l2_20130924_114443_4000254145_raster_t000_r00000.fits'
obs_tag = '20130924'
fname = path+fname

; -----------------------------------------------
RESTORE, path+'/analysis/'+obs_tag+'/detections.sav'

RESTORE, path +'/analysis/'+obs_tag+'/'+obs_tag+'_Si_IV_1394_cal_intensity.sav'
intens_1394=cal_intensity

RESTORE, path +'/analysis/'+obs_tag+'/'+obs_tag+'_Si_IV_1403_cal_intensity.sav'
intens_1403=cal_intensity

RESTORE, path+'/analysis/'+obs_tag+'/'+obs_tag+'_Si_IV_1403_cal_err.sav'
err_1403 = cal_err

RESTORE, path+'/analysis/'+obs_tag+'/'+obs_tag+'_Si_IV_1394_cal_err.sav'
err_1394 = cal_err

RESTORE, path+'/analysis/'+obs_tag+'/wav_exp.sav'
wav_shift = wav_exp2-wav_exp1

RESTORE, path +'/analysis/'+obs_tag+'/cal_'+ obs_tag+ '_Si_IV_1394_parameters.sav'
background = parameters[3,*,*]
background =REFORM(background)

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
trunc1 = WHERE ((wav1 LT (lam1+1.3)) AND (wav1 GT (lam1 -1.3)))
wav_trunc1 = wav1[trunc1]

trunc2 = WHERE ((wav2 LT (lam2+1.7)) AND (wav2 GT (lam2 -1.7)))
wav_trunc2 = wav2[trunc2]
ni_yes=ni_yes[*,1:*]
num = N_ELEMENTS(ni_yes[0,*])
ratio = MAKE_ARRAY(num)
avg_ratio = MAKE_ARRAY(num)
avg_intens=MAKE_ARRAY(num)
rat_err=MAKE_ARRAY(num)

dist_rat = MAKE_ARRAY(num)

num = num-1

PRINT, num

FOR K=0,num DO BEGIN
coords = ni_yes[*,K]

img_1394 = (intens_1394[*,coords[0], coords[1]]-background[coords[0], coords[1]])
img1 = img_1394[trunc1]
avg_intens[K]=MEAN(img1)

img_1403 = (intens_1403[*,coords[0], coords[1]]-background[coords[0], coords[1]])
img2= img_1403[trunc2]
im2_err = err_1403[*,coords[0], coords[1]]

; SHIFT PROFILE
find_cent1=wav_trunc1-wav_exp1
find_cent1=sort(ABS(find_cent1))
center1= find_cent1[0]
find_cent2=wav_trunc2-wav_exp2
find_cent2=sort(ABS(find_cent2))
center2= find_cent2[0]
find_shift = center1-center2
img2sh = SHIFT(img2, find_shift)

; FIND LOCAL MEAN
small_window = WHERE(wav_trunc1 GT wav_exp1 -0.1 AND wav_trunc1 LT wav_exp1+0.1)
tot_rat = img1/img2sh
avg_ratio[K] = MEAN(tot_rat[small_window])

; RATIO AT CORE
ratio[K]=img1[center1]/img2sh[center1]
rat_err[K] = SQRT((1/img2[center2])^2 * err_1394[center1]^2 + (img1[center1]/img2sh[center1]^2)^2*err_1403[center2]^2)
dist_rat[K] = ratio[K]-avg_ratio[K]

ENDFOR

unwm_rat = TOTAL(ratio/rat_err^2)/TOTAL(1/rat_err^2)
unwm_dev = TOTAL(ABS(dist_rat)/rat_err^2)/TOTAL(1/rat_err^2)
hist = HISTOGRAM(ratio, NBINS=20, LOCATION=binvals)
hist_off = HISTOGRAM(ABS(dist_rat),NBINS=15, LOCATION=binvals_off)

;unwm_hist = HISTOGRAM(unwm_rat, NBINS=20, LOCATION=unwm_bin,MIN=0, MAX=3)
;weight_dev = HISTOGRAM(unwm_dev, NBINS=15, LOCATION=undevbin)

med_offset = MEDIAN(ABS(dist_rat[SORT(dist_rat)]))

SAVE, hist, binvals, FILENAME=path+'/analysis/'+obs_tag+'/histogram.sav'
SAVE, hist_off, binvals_off, FILENAME=path+'/analysis/'+obs_tag+'/histogram_offset.sav'

!p.multi=0
;PLOT, avg_intens, ratio, PSYM=3, CHARSIZE=3, THICK=3, /YNOZERO
;SAVE, avg_intens,ratio, FILENAME=path+'/analysis/'+obs_tag+'/ratios.sav'

;STOP
LOADCT, 39
WINDOW, 0, RETAIN=2
PLOT, binvals, hist, CHARSIZE=3, THICK=3, YTITLE='Frequency', XTITLE='Si IV 1394/Si IV 1403 at Core', PSYM=10, TITLE='Distribution of Si IV Ratios', SUBTITLE=obs_tag, CHARTHICK=2, XTHICK=3, YTHICK=3, COLOR=0, BACKGROUND=255
OPLOT, [MEDIAN(ratio), MEDIAN(ratio)], [0,200], COLOR=250, THICK=3, LINESTYLE=2
OPLOT, [2,2], [0,200],LINESTYLE=0, THICK=2, COLOR=0
OPLOT, [unwm_rat, unwm_rat], [0,200], COLOR=60, LINESTYLE=3, THICK=3

scrncap=TVRD(TRUE=1)
WRITE_PNG, path+ '/analysis/'+obs_tag+'/HIST_DIST_'+obs_tag+'.png',scrncap


cont = ''
READ, cont, PROMPT='Next?'
IF cont EQ 'y' THEN BEGIN

PLOT, binvals_off, hist_off, CHARSIZE=3, THICK=2, YTITLE='Frequency', XTITLE='Distance from Local Mean', PSYM=10, TITLE='Deviation from Expected Ratio', SUBTITLE=obs_tag
OPLOT, [med_offset, med_offset], [0,200], COLOR=250, LINESTYLE=2, THICK=2
OPLOT, [0,0], [0,200], LINESTYLE=0, THICK=2, COLOR=0
OPLOT, [unwm_dev, unwm_dev], [0,200], COLOR=60, LINESTYLE=3, THICK=2

scrncap=TVRD(TRUE=1)
WRITE_PNG, path+ '/analysis/'+obs_tag+'/HIST_DEV_'+obs_tag+'.png',scrncap
ENDIF

END
