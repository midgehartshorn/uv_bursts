PRO  EXAMINE_DETECTIONS, lambda, fname, msp, detections, obs_tag
lambda =1394
fname = 'iris_l2_20140820_054051_3800256196_raster_t000_r00000.fits'

obs_tag = '20140820'
path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'

RESTORE, path+'detections.sav'

RESTORE, path+'Si_IV_1394_msp.sav', /VERBOSE
;RESTORE, path+'wav_exp.sav'
;wav_exp1=wav_0
wav_exp1=1393.7852
fname = path+fname
specDATA = IRIS_OBJ(fname)
winid=specDATA->GETWINDX(lambda)
data = specDATA->GETVAR(winid, /LOAD)
wav = specDATA->GETLAM(winid)
OBJ_DESTROY,specDATA
PRINT, wav_exp1

ni_confirmed = [[0,0]]

angst_char=STRING("305B)
num = N_ELEMENTS(ni_yes[0,*])
num = num-1
LOADCT, 39

FOR K=0,num DO BEGIN
coords = ni_yes[*,K]
img = data[*,coords[0], coords[1]]
candidate = img
wav_arr = wav
PLOT, wav_arr, candidate, XRANGE=[1392.7,1395.3], XSTYLE=1, XTITLE='Wavelength ['+angst_char+']', CHARSIZE=6, CHARTHICK=4, BACKGROUND=255, COLOR=0, YTITLE='Relative Intensity [arb. units]', TITLE='Potential UV Burst', THICK=5, XTHICK=4, YTHICK=4
OPLOT, wav_trunc, mean_prof_trunc,  COLOR = 30, THICK=4
OPLOT, [1393.33,1393.33], [-20000,20000], LINESTYLE=2, COLOR=250, THICK=5
XYOUTS, 0.22,0.7,'Ni II 1393.3'+angst_char, COLOR=250, CHARSIZE=4, CHARTHICK=4, /NORMAL
OPLOT, [wav_exp1,wav_exp1], [-20000,20000], LINESTYLE=3, COLOR=75, THICK=5
XYOUTS, 0.51,0.7,'Si IV 1393.8'+angst_char, COLOR=75, CHARSIZE=4, CHARTHICK=4, /NORMAL

write = ''
READ, write, PROMPT='Save image? (y/n)'
IF write EQ 'y' OR write EQ 'Y' THEN BEGIN
	ID = STRING(FORMAT='(I03)', K)
	scrncap=TVRD(TRUE=1)
	WRITE_PNG, path + '/img/DET_' +ID+ '_image.png', scrncap
ENDIF

retain = ''
READ, retain, PROMPT='Confirm Ni II? (y/n)'
IF write EQ 'y' OR write EQ 'Y' THEN BEGIN
	ni_confirmed = [[ni_confirmed],[coords]]
ENDIF
ENDFOR

SAVE, ni_confirmed, filename=path+'conf_detections.sav'

PRINT, 'Number of Detections: ', N_ELEMENTS(ni_confirmed)
PRINT, ni_confirmed

END
