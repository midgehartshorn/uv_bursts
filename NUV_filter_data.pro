PRO NUV_FILTER_DATA

lambda = 2801
fname = 'iris_l2_20131203_075414_3800254046_raster_t000_r00000.fits'

obs_tag = '20131203'
param_fname ='/analysis/'+obs_tag+'/trimmed_parameters.sav' 

path = '/home/miriam/Documents/MHC/Summer23/code/'
RESTORE, path + param_fname
fname = path+'data/'+fname

RESTORE, path+'/analysis/'+obs_tag+'/NUV_wav_exp.sav' 

specDATA = IRIS_OBJ(fname)
winid=specDATA->GETWINDX(lambda)
data = specDATA->GETVAR(winid, /LOAD)
wav = specDATA->GETLAM(winid)
linid=specDATA->GETLINE_ID(winid)
OBJ_DESTROY,specDATA
mn_yes = [[0,0]]
mn_no =[[0,0]]
linid=REPSTR(linid, ' ', '_')

;help, cand_ind
ny = N_ELEMENTS(data[0,*,0])
nx = N_ELEMENTS(data[0,0,*])
ind = ARRAY_INDICES([ny,nx], cand_ind, /DIMENSIONS)
;help, ind
num = N_ELEMENTS(ind[0,*])
num= num-1
print, num

LOADCT, 39
	WINDOW, 0
	!p.MULTI=[0,1,2,0,0]
FOR K = 0, num DO BEGIN
	coords = ind[*,K]
	img = data[*,coords[0], coords[1]]
	good = WHERE(img GT -199)
	IF good[0] NE -1 THEN BEGIN
	candidate = img
	wav_arr = wav

	PLOT, wav_arr, candidate, XRANGE=[2798.5, 2800], XSTYLE=1, XTITLE='Wavelength [angstroms]', CHARSIZE=2, CHARTHICK=2, BACKGROUND=255, COLOR=0, YTITLE='Relative Intensity [arb. units]', TITLE='Potential UV Burst', THICK=2
	; Mg II UV Triplet 2
	;OPLOT, [2797.930, 2797.930], [-2e+4, 2e+4], LINESTYLE=2, COLOR=250, THICK=1
	OPLOT, [2798.7529, 2798.7529], [-2e+4, 2e+4], LINESTYLE=2, COLOR=60, THICK=1

	OPLOT, [2798.8230, 2798.8230], [-2e+4, 2e+4], LINESTYLE=2, COLOR=60, THICK=1
	; Mg II UV Triplet 3
	;OPLOT, [2797.998, 2797.998], [-2e+4, 2e+4], LINESTYLE=2, COLOR=250, THICK=1
	
	; Mn I
	OPLOT, [2801.907, 2801.907], [-2e+4, 2e+4], LINESTYLE=2, COLOR=250, THICK=3
	; Mn I
	OPLOT, [2799.094, 2799.094], [-2e+4, 2e+4], LINESTYLE=2, COLOR=60, THICK=1

	PLOT, wav_arr, candidate, XRANGE=[2799.5, 2802.5], XSTYLE=1, XTITLE='Wavelength [angstroms]', CHARSIZE=2, CHARTHICK=2, BACKGROUND=255, COLOR=0, YTITLE='Relative Intensity [arb. units]', TITLE='Potential UV Burst', THICK=2
	OPLOT, [2801.907, 2801.907], [-2e+4, 2e+4], LINESTYLE=2, COLOR=250, THICK=3

	next=''
	READ, next, PROMPT=STRING(K)+'. Mn I inversion? (y/n)'
	IF (next EQ 'y' OR next EQ 'Y') THEN BEGIN
	mn_yes = [[mn_yes],[coords]]
ENDIF ELSE IF (next EQ 'p' OR next EQ'P') THEN BEGIN
	K =K-2
ENDIF ELSE BEGIN
	mn_no = [[mn_no],[coords]]
	ENDELSE
	ENDIF
ENDFOR

SAVE, mn_yes, mn_no, filename=path+'/analysis/'+obs_tag+'/'+'inversions.sav'
PRINT, 'Number of Inversions: ', N_ELEMENTS(mn_yes[0,*])


END
