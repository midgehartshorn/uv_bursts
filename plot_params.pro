;FUNCTION PLOT_PARAMS, lambda,fname, param_name,obs_tag, PARTIAL=partial
PRO PLOT_PARAMS
; ACQUIRE DATA
; ------------------------------------------------

lambda=1394
fname ='iris_l2_20140805_133003_3883108846_raster_t000_r00000.fits'
path = '/run/media/midge/SamsungSSD/data/20140805/'
fname = path +fname
obs_tag=20140805
param_name='Si_IV_1394_parameters.sav'

specData=IRIS_OBJ(fname)

line = specDATA->GETWINDX(lambda)
linid=specDATA->GETLINE_ID(line)
; just want the 1394 line
wav = specDATA->GETLAM(line)

OBJ_DESTROY, specData
; ------------------------------------------------

RESTORE, path+param_name

linid=REPSTR(linid, ' ', '_')
outname=linid

;img = KEYWORD_SET(partial) ? data[*,800:900,*] : data[*,*,*]

; ------------------------------------------------
; PLOTTING
; ------------------------------------------------
LOADCT, 39
WINDOW, 0, RETAIN=2
PLOT, wav, parameters[0,*], PSYM=4, SYMSIZE=1.5, CHARSIZE=2,$
	TITLE='Peak Intensity', XTITLE='Wavelength', YTITLE='Value', $
	COLOR= 150, YRANGE=[0.001, 15000], /YLOG, /YNOZERO

scrncap = TVRD(TRUE=1)
WRITE_PNG, path+outname+'_param_A.png', scrncap

PLOT, wav, parameters[1,*], PSYM=4, SYMSIZE=1.5, CHARSIZE=2,$
	/YNOZERO, $
	TITLE='Doppler Shift', XTITLE='Wavelength', YTITLE='Value', $
	COLOR= 150

scrncap = TVRD(TRUE=1)
WRITE_PNG, path+outname+'_param_B.png', scrncap

PLOT, wav, parameters[2,*], PSYM=4, SYMSIZE=1.5, CHARSIZE=2,$
	TITLE='Exponential Line Width', XTITLE='Wavelength', YTITLE='Value',$
	COLOR=150

scrncap = TVRD(TRUE=1)
WRITE_PNG, path+outname+'_param_C.png', scrncap

PLOT, wav, parameters[3,*], PSYM=4, SYMSIZE=1.5, CHARSIZE=2,$
	TITLE='Background Intensity', XTITLE='Wavelength', YTITLE='Value',$
	COLOR=150

scrncap = TVRD(TRUE=1)
WRITE_PNG, path+outname+'_param_D.png', scrncap

PLOT, parameters[2,*], parameters[0,*], PSYM=3, SYMSIZE=1, CHARSIZE=2,$
	TITLE='Peak Intensity vs. Line Width', XTITLE='Line Width', $
	YTITLE='Peak Intensity [Arb. Units]', YRANGE=[0.01, MAX(parameters[0,*])], /XLOG, /YLOG, /YNOZERO
scrncap = TVRD(TRUE=1)
WRITE_PNG, path+outname+'_comp_plot.png', scrncap
; ------------------------------------------------

END


