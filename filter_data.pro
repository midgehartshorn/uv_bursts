PRO FILTER_DATA, lambda, fname, param_file, obs_tag
; ---------------------------------------------------------
; use with calibrated, trimmed parameters to detect UV bursts
; ---------------------------------------------------------

lambda = 1394
fname = 'iris_l2_20151113_130505_3630088076_raster_t000_r00000.fits'

obs_tag = '20151113'
param_fname ='trimmed_parameters.sav' 

path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'
RESTORE, path + param_fname
fname = path+fname

;RESTORE, path+'wav_exp.sav' 
;wav_exp1=wav_0
wav_exp1=1393.7937
RESTORE, path+'Si_IV_1394_msp.sav'

specDATA = IRIS_OBJ(fname)
winid=specDATA->GETWINDX(lambda)
data = specDATA->GETVAR(winid, /LOAD)
wav = specDATA->GETLAM(winid)
linid=specDATA->GETLINE_ID(winid)
OBJ_DESTROY,specDATA
ni_yes = [[0,0]]
ni_no =[[0,0]]
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
	!p.MULTI=0
FOR K = 0, num DO BEGIN
	coords = ind[*,K]
	img = data[*,coords[0], coords[1]]
	good = WHERE(img GT -199)
	IF good[0] NE -1 THEN BEGIN
	candidate = img
	wav_arr = wav

	PLOT, wav_arr, candidate, XRANGE=[1392.7,1395.3], XSTYLE=1, XTITLE='Wavelength [angstroms]', CHARSIZE=2, CHARTHICK=2, BACKGROUND=255, COLOR=0, YTITLE='Relative Intensity [arb. units]', TITLE='Potential UV Burst', THICK=2
	; Ni II
	OPLOT, [1393.33, 1393.33], [-2e+4, 2e+4], LINESTYLE=2, COLOR=250, THICK=3
	; Si IV
	OPLOT, [wav_exp1, wav_exp1], [-2e+4, 2e+4], LINESTYLE=2, COLOR=250, THICK=3
	OPLOT, wav_trunc, mean_prof_trunc, LINESTYLE=3, COLOR=30, THICK=2

	next=''
	READ, next, PROMPT=STRING(K)+'. Ni II absorption? (y/n)'
	IF (next EQ 'y' OR next EQ 'Y') THEN BEGIN
	ni_yes = [[ni_yes],[coords]]
ENDIF ELSE BEGIN
	ni_no = [[ni_no],[coords]]
		ENDELSE
	ENDIF
ENDFOR

SAVE, ni_yes, ni_no, filename=path+'detections.sav'
PRINT, 'Number of Detections: ', N_ELEMENTS(ni_yes[0,*]-1)


END
