PRO COMPARE_PAIR_V2

;***** Issues addressed in v2 *****
;
;- img1 and img2 were not the same size when ratio calibration performed,
;  corrected by truncating img2 to be the same size as img1
;- img1_err and img2_err did not match the sizes of img1 and img2, respectively,
;  corrected by applying trunc1 and trunc2 index arrays to error arrays
;- img2_err was not shifted to match img2sh
;- There were a number of problems in the calculation of the ratio uncertainty
;  - The unshifted img2 was used instead of img2sh
;  - Full 3D error arrays were used instead of those pertaining to just the two Si IV
;    profiles involved in the ratio calculation
;  - Added an aggressive number of parentheses due to my order-of-operations paranoia
;
;**********************************

;
obs_tag = '20150206' ; this is just the date, but it's a directory on my system
path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'
rastnum= ''

;path = 'C:\Users\cmadsen\SI_IV_Opacity_Code\'

; ---------------------------------------------
; CHANGE THESE FOR EACH DATASET
fname ='iris_l2_20150206_051507_3800256196_raster_t000_r00000.fits'

fname = path+fname
; -----------------------------------------------
; INPUT
; -----------------------------------------------
PRINT, 'Restoring files...'
RESTORE, path+'detections'+rastnum+'.sav' 
PRINT, 'Detections restored.'

RESTORE, path +'1394_cal_intensity'+rastnum+'.sav',/VERBOSE
intens_1394=cal_intensity

RESTORE, path +'1403_cal_intensity'+rastnum+'.sav', /VERBOSE
intens_1403=cal_intensity
PRINT, 'Calibrated Intensity restored.'

RESTORE, path+'1403_cal_err'+rastnum+'.sav', /VERBOSE
err_1403 = cal_err

RESTORE, path+'1394_cal_err'+rastnum+'.sav', /VERBOSE
err_1394 = cal_err
PRINT, 'Calibrated Error restored.'
; -----------------------------------------------
PRINT, 'Reading wavelengths...'
lam1 = 1394
lam2 = 1403
specDATA = IRIS_OBJ(fname)
winid1=specDATA->GETWINDX(lam1)
winid2=specDATA->GETWINDX(lam2)
wav1 = specDATA->GETLAM(winid1)
wav2 = specDATA->GETLAM(winid2)
OBJ_DESTROY,specDATA
PRINT, 'Destroyed SPEC object...'
; -----------------------------------------------
; compute calibrated mean spectral profiles
; -----------------------------------------------

msp1 = MEAN(MEAN(intens_1394, DIMENSION=2,/NAN), DIMENSION=2,/NAN)
trunc1 = WHERE ((wav1 LT (lam1+1.3)) AND (wav1 GT (lam1 -1.3)))
wav_trunc1 = wav1[trunc1]
msp1=msp1[trunc1]
;PRINT, msp1

msp2 = MEAN(MEAN(intens_1403, DIMENSION=2, /NAN), DIMENSION=2, /NAN)
trunc2 = WHERE ((wav2 LT (lam2+1.7)) AND (wav2 GT (lam2 -1.7)))
wav_trunc2 = wav2[trunc2]

msp2=msp2[trunc2]
mspfit1 = MPFITPEAK(wav_trunc1, msp1, cent1, NTERMS=4)
mspfit2 = MPFITPEAK(wav_trunc2, msp2, cent2, NTERMS=4)


wav_exp1 = cent1[1]
wav_exp2 = cent2[1]

PRINT, 'Aligning centers...'
wav_shift = wav_exp2-wav_exp1
print, wav_shift
; -----------------------------------------------

PRINT, 'Restoring parameters...'
RESTORE, path +'cal_parameters'+rastnum+'.sav'
background = parameters[3,*,*]
background =REFORM(background)

opt_thick = [[0,0]]
opt_thin = [[0,0]]

angst_char = STRING("305B)

num = N_ELEMENTS(ni_yes[0,*])-1
LOADCT, 39
WINDOW, 0, RETAIN=2,XSIZE=1600,YSIZE=900

spec_units = '!C[erg s!U-1!N'+angst_char+'!U-1!N cm!U-2!N sr!U-1!N]'
; BEGIN LOOP
; -----------------------------------------------
FOR K=0,num DO BEGIN
coords = ni_yes[*,K]

;print, 'background: ', background[coords[0],coords[1]]
; FIND CENTRAL WAVELENGTH
prof_x = intens_1394[*,coords[0],coords[1]]
prof_x=prof_x[trunc1]
x_fit = MPFITPEAK(wav_trunc1, prof_x, cent0, NTERMS=4)
exp_wav0 = cent0[1]

; Subtract background
img_1394 = (intens_1394[*,coords[0], coords[1]]-background[coords[0], coords[1]])
img1 = img_1394[trunc1]
im1_err = err_1394[*,coords[0], coords[1]]
im1_err = im1_err[trunc1]

; Subtract background
img_1403 = (intens_1403[*,coords[0], coords[1]]-background[coords[0], coords[1]])
img2= img_1403[trunc2]
im2_err = err_1403[*,coords[0], coords[1]]
im2_err = im2_err[trunc2]

; SHIFT 1403
find_cent1=wav_trunc1-wav_exp1
find_cent1=sort(ABS(find_cent1))
center1= find_cent1[0]
find_cent2=wav_trunc2-wav_exp2
find_cent2=sort(ABS(find_cent2))
center2= find_cent2[0]
find_shift = center1-center2

img2sh = SHIFT(img2, find_shift)
im2_errsh = SHIFT(im2_err,find_shift)
ratio=img1/img2sh

;HELP,img1
;HELP,img2
;HELP,im1_err
;HELP,im2_err
;HELP,err_1394
;HELP,err_1403

; ERROR
;rat_err = SQRT((1/img2)^2 * err_1394^2 + (img1/img2^2)^2*err_1403^2)
rat_err = SQRT((((1/img2sh)^2.0) * (im1_err^2.0)) + (((img1/(img2sh^2.0))^2.0)*(im2_errsh^2.0)))
three_sig = 3*rat_err

cent_wav = SORT(ABS(wav_trunc1-wav_exp1))
cent_wav = cent_wav[0]
PRINT, 'Ratio at central wavelength ', exp_wav0, ': ', ratio[cent_wav]

; -----------------------------------------------
; SET WINDOW RANGE FOR RATIO PLOT (DISTANCE FROM WAV_0)
win_range = 0.6
wav_rat = [exp_wav0-win_range, exp_wav0+win_range]

; WINDOW RANGE FOR AVG RATIO
small_window = WHERE((wav_trunc1 GT exp_wav0 -0.1 AND wav_trunc1 LT exp_wav0-0.05) OR (wav_trunc1 GT exp_wav0 +0.1 AND wav_trunc1 LT exp_wav0+0.15))
avg_ratio = MEAN(ratio[small_window])
PRINT, 'Average Ratio: ', avg_ratio

; PLOTTING
; -----------------------------------------------

;HELP,wav_trunc1
;HELP,ratio
;HELP,three_sig
low = ratio-three_sig
high = ratio+three_sig

!p.multi =[0,1,2]
PLOT, wav_trunc1, ratio, XRANGE=wav_rat, YRANGE=[-2,6],$
	TITLE='Si IV Line Pair Ratio',$
       	XTITLE='Wavelength ['+angst_char+']',  YTITLE='Si IV 1394/Si IV 1403',$
	CHARSIZE=3, CHARTHICK=2, XTHICK=2, YTHICK=2, THICK=3,$
	BACKGROUND=255, COLOR=0, LINESTYLE=1, XMARGIN=[10,6]

	OPLOT, [exp_wav0-0.1,exp_wav0+0.15],[avg_ratio, avg_ratio], $
	       	COLOR=cgColor('Blue'), LINESTYLE=2, THICK=3
	OPLOT, [1390,1400],[2,2],$
	       	COLOR=cgColor('Firebrick'),LINESTYLE=0, THICK=2
	OPLOT, [exp_wav0, exp_wav0], [-10,10], $
		COLOR=cgColor('Charcoal'), LINESTYLE=2, THICK=2
	OPLOT, wav_trunc1, (ratio+three_sig), $
		COLOR = cgColor('Slate Gray'), LINESTYLE=0, THICK=2
	OPLOT, wav_trunc1, (ratio-three_sig), $
		COLOR = cgColor('Slate Gray'), LINESTYLE=0, THICK=2

AL_Legend, ['Si IV 1394 '+angst_char +'/Si IV 1403 '+angst_char, 'Uncertainty '+ cgSymbol('+-') + '3'+ cgSymbol('sigma'), 'Background Ratio', 'Central Wavelength'], $
	LineStyle=[1,0,2,2],Thick=[3,2,3,2], $
	COLORS=['black', 'Slate Gray', 'Blue', 'Charcoal'], $
	BACKGROUND_COLOR=255, CHARSIZE=1.5

PLOT, wav_trunc1, img1, $
	TITLE='Si IV Lines',XRANGE=[1393,1394.5],$
	XTITLE='Wavelength ['+angst_char+']', YTITLE='Peak Intensity'+spec_units,$
        CHARSIZE=3, CHARTHICK=2, THICK=3, XTHICK=2, YTHICK=2,$
  	BACKGROUND=255, COLOR=0, XSTYLE=1, XMARGIN=[15,5]
	  
	OPLOT, (wav_trunc2-wav_shift), img2, $
		COLOR = cgColor('Lime Green'),LINESTYLE='--', THICK=3
	OPLOT, [exp_wav0,exp_wav0], [-2e+7,2e+7], $
		LINESTYLE=2, COLOR=cgColor('Charcoal'), THICK=2
	OPLOT, [exp_wav0-0.1,exp_wav0-0.1],[-2e+7,2e+7], $
		COLOR=cgColor('Blue'), LINESTYLE=0, THICK=1.5
	OPLOT, [exp_wav0+0.15,exp_wav0+0.15],[-2e+7,2e+7], $
		COLOR=cgColor('Blue'), LINESTYLE=0, THICK=1.5
	OPLOT, [wav_rat[0],wav_rat[0]], [-2e+7,2e+7], $
		LINESTYLE=1, THICK=2, COLOR=0
	OPLOT, [wav_rat[1],wav_rat[1]], [-2e+7,2e+7], $
		LINESTYLE=1, THICK=2, COLOR=0
AL_Legend, ['Si IV 1394 '+angst_char, 'Si IV 1403 '+angst_char, 'Background Reference Range', 'Central Wavelength'], $
	LineStyle=[0,0,0,2],Thick=[2,2,1,2], $
	COLORS=['black', 'lime green', 'Blue', 'Charcoal'], $
	BACKGROUND_COLOR=255, CHARSIZE=1.5

thick = ''
READ, thick, PROMPT='Optically thick? '
IF thick EQ 'y' OR thick EQ 'Y' THEN BEGIN
	opt_thick = [[opt_thick], [coords]]
	ID = STRING(FORMAT='(I03)', K)
	scrncap=TVRD(TRUE=1)
	WRITE_PNG, path + 'img/RATIO_' +ID+ '_img_white.png', scrncap
ENDIF ELSE BEGIN
	opt_thin = [[opt_thin], [coords]]

ENDELSE

ENDFOR
;SAVE, opt_thick, opt_thin, filename = path+'opacity'+rastnum+'.sav'
PRINT, 'Number of Optically Thick Detections: ', N_ELEMENTS(opt_thick[0,*])-1

END
