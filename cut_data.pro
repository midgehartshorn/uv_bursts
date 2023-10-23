PRO CUT_DATA
; ---------------------------------------------------------
; MUST USE RADIOMETRICALLY CALIBRATED DATA
; ---------------------------------------------------------

obs_tag = '20151204'
path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'
RESTORE, path + 'cal_parameters.sav'
RESTORE, path + 'si4_wav_exp.sav'

;wav_exp1=wav_0
wav_exp1=1393.7852

angst_char = STRING("305B)
intens = parameters[0,*,*]
linwid = parameters[2,*,*]
doppl = parameters[1,*,*]
lin_min = 35

c_km = 3e+5
linwid = c_km *(linwid/wav_exp1)
cand_ind = WHERE(intens GT 5e+3 AND linwid LT 100 AND linwid GT lin_min AND (ABS(doppl -1394) LT 1.3), COMPLEMENT=bad_ind)
SAVE, cand_ind, bad_ind, filename=path+'trimmed_parameters.sav'
TVLCT, 0,0,0,0

!p.multi=0
LOADCT, 39
WINDOW, 0, RETAIN=2
PLOT, linwid[bad_ind], intens[bad_ind], COLOR=255, PSYM=3, /XLOG, /YLOG, XRANGE=[0.01, 1e+6], CHARSIZE=4, THICK=3, CHARTHICK=3, BACKGROUND=0, XTITLE='Line Width [km/s]', YTITLE='Spectral Radiance!C[erg s!U-1!N' + angst_char + '!U-1!Ncm!U-2!Nsr!U-1!N]', TITLE='UV Burst Candidates', SYMSIZE=1, XTHICK=3, YTHICK=3
OPLOT, linwid[cand_ind], intens[cand_ind], COLOR=151, PSYM=3,SYMSIZE=1, THICK=1
scrncap=TVRD(TRUE=1)
WRITE_PNG, path + 'cut_params.png', scrncap

help, cand_ind
PRINT, 'Number of Candidates: ', N_ELEMENTS(cand_ind)

END
