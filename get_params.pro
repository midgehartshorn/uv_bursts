PRO GET_PARAMS
; A function to compute parameters for 4-term single Gaussian fits (SGFs) applied across spectral data
; inputs: filename, desired wavelength
; outputs: parameters[array]
; keywords: FULL read in full array, otherwise read in smaller array

; ------------------------------------------------
; CHANGE THESE
lambda = 1394
fname = 'iris_l2_20140805_133003_3883108846_raster_t000_r00000.fits'
obs_tag='20140805'
; ------------------------------------------------
; ACQUIRE DATA
path = '/run/media/midge/SamsungSSD/data/20140805/'
fname = path+fname

specDATA=IRIS_OBJ(fname)

win = specDATA->GETWINDX(lambda)

data = specDATA->GETVAR(win, /LOAD)

; just want the 1394 line
wav = specDATA->GETLAM(win)
linid = specDATA->GETLINE_ID(win)

OBJ_DESTROY, specDATA
; ------------------------------------------------
linid= REPSTR(linid, ' ', '_')

;img = KEYWORD_SET(FULL) ? data[*,*,*] : data[*,800:900,*]
img = data[*,*,*]
PRINT, SIZE(img)

; DETERMINE PARAMETERS
; ------------------------------------------------
parameters = [[0,0,0,0]]
yfits = [0]

; to loop through entire dataset, J=0,399; I=0,1095
FOR J = 0,(N_ELEMENTS(img[0,0,*])-1) DO BEGIN 
FOR I = 0,(N_ELEMENTS(img[0,*,0])-1) DO BEGIN
	ind = []
	ind = WHERE(img[*,I,J] GE -199)
	;PRINT, 'indices:', ind

	; where are the first and last valid positions
	coords = [ind[0], ind[-1]]
	;PRINT, 'coords:', coords

	; intensities are pixel values
	intens = img[coords[0]:coords[1],I,J]
	;print, intens

	;PRINT, 'length of row data:', N_ELEMENTS(intens)
	row_wav = wav[coords[0]:coords[1]]
	;PRINT, 'length of row wav:', N_ELEMENTS(row_wav)

	; mpfitpeak requires at least nterms in params
	IF (N_ELEMENTS(intens) GE 4) AND (N_ELEMENTS(row_wav) GE 4) THEN BEGIN 
	yfit = MPFITPEAK(row_wav, intens, params, NTERMS=4)

	;yfits = [[yfits],[yfit]]
	; add new values to array of parameters
	parameters = [[parameters], [params]]
ENDIF ELSE BEGIN
		;PRINT, 'Entirely overscan:', I,J
	ENDELSE
ENDFOR
PRINT, J
ENDFOR


; to get rid of spurious first row
dims = SIZE(parameters,/DIMENSIONS)
extra_row = [0]
parameters = parameters[*, WHERE(~HISTOGRAM(extra_row, MIN=0, MAX=dims[1]-1),/NULL)]

SAVE, parameters, filename=path+linid+'_parameters.sav'
;RETURN, parameters
; ------------------------------------------------
END


