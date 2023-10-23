FUNCTION PSF_PRACTICE

; ACQUIRE DATA
; ------------------------------------------------
path = '/home/miriam/Documents/MHC/Summer23/code/iris_intro'
fname = path+'/iris_l2_20130924_114443_4000254145_raster_t000_r00000.fits'

specData=IRIS_OBJ(fname)

data = specData->GETVAR(4, /LOAD)

; just want the 1394 line
wav = specDATA->GETLAM(4)

OBJ_DESTROY, specData
; ------------------------------------------------

;img = data[*,800:1095,*]
img = data[*,*,*]

; OPTIONAL TESTS
; -----------------------------------------------
;dims = SIZE(data, /DIMENSIONS)

;print, 'The size of data is: ', dims

;print, SIZE(wav, /DIMENSIONS)

;max = MAX(img[*,0,0])
;min = MIN(img[*,0,0])
;print, min, max

; DETERMINE PARAMETERS
; ------------------------------------------------
parameters = [[0,0,0,0]]
yfits = [0]

; to loop through entire dataset, J=0,399; I=0,1095
FOR J = 0,399 DO BEGIN 
FOR I = 0,1095 DO BEGIN
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
ENDFOR


; to get rid of spurious first row
dims = SIZE(parameters,/DIMENSIONS)
extra_row = [0]
parameters = parameters[*, WHERE(~HISTOGRAM(extra_row, MIN=0, MAX=dims[1]-1),/NULL)]

; continue to plots?
cont= ''
READ, cont, PROMPT='Plot data? (y/n)'

IF (cont EQ 'y' OR cont EQ 'Y') THEN BEGIN

; PLOTTING
; ------------------------------------------------
LOADCT, 39
WINDOW, 0, RETAIN=2
PLOT, wav, parameters[0,*], PSYM=4, SYMSIZE=1.5, CHARSIZE=2,$
	TITLE='Peak Intensity', XTITLE='Wavelength', YTITLE='Value', $
	COLOR= 150, YRANGE=[0.001, 15000], /YLOG, /YNOZERO

scrncap = TVRD(TRUE=1)
WRITE_PNG, path+'/param_A.png', scrncap

PLOT, wav, parameters[1,*], PSYM=4, SYMSIZE=1.5, CHARSIZE=2,$
	/YNOZERO, $
	TITLE='Doppler Shift', XTITLE='Wavelength', YTITLE='Value', $
	COLOR= 150

scrncap = TVRD(TRUE=1)
WRITE_PNG, path+'/param_B.png', scrncap

PLOT, wav, parameters[2,*], PSYM=4, SYMSIZE=1.5, CHARSIZE=2,$
	TITLE='Exponential Line Width', XTITLE='Wavelength', YTITLE='Value',$
	COLOR=150

scrncap = TVRD(TRUE=1)
WRITE_PNG, path+'/param_C.png', scrncap

PLOT, wav, parameters[3,*], PSYM=4, SYMSIZE=1.5, CHARSIZE=2,$
	TITLE='Background Intensity', XTITLE='Wavelength', YTITLE='Value',$
	COLOR=150

scrncap = TVRD(TRUE=1)
WRITE_PNG, path+'/param_D.png', scrncap

PLOT, parameters[2,*], parameters[0,*], PSYM=3, SYMSIZE=1, CHARSIZE=2,$
	TITLE='Peak Intensity vs. Line Width', XTITLE='Line Width', $
	YTITLE='Peak Intensity [Arb. Units]', YRANGE=[0.01, MAX(parameters[0,*])], /XLOG, /YLOG, /YNOZERO
scrncap = TVRD(TRUE=1)
WRITE_PNG, path+'/comp_plot.png', scrncap
; ------------------------------------------------
ENDIF ELSE BEGIN
ENDELSE


RETURN, parameters
; ------------------------------------------------
END


