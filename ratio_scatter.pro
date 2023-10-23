PRO RATIO_SCATTER
path='/home/miriam/Documents/MHC/Summer23/code/analysis/'

obs1 = '20130924'
obs2 = '20131203'
obs3 = '20150206'

RESTORE, path+obs1+'/ratios.sav'
int1 =avg_intens
rat1=ratio 

RESTORE, path+obs2+'/ratios.sav'
int2=avg_intens
rat2=ratio

RESTORE, path+obs3+'/ratios.sav'
int3=avg_intens
rat3=ratio
LOADCT, 39
TVLCT, 0,0,0,0
!p.multi=0
PLOT, int1, rat1, CHARSIZE=4, THICK=4, /YNOZERO, /NODATA, COLOR=0, BACKGROUND=255, CHARTHICK=4, XTHICK=4, YTHICK=4, YTITLE='Si IV Pair Ratio', XTITLE='Spectral Radiance', TITLE='Distribution of Line Pair Ratios', XRANGE=[0,5e+5], YRANGE=[1,3.5]

OPLOT,[0,1e+6],[2,2],  LINESTYLE=2, COLOR=0, THICK=3
; 2013 Sep (Peter et al)
OPLOT, int1, rat1,  PSYM=1, COLOR=25, THICK=3, SYMSIZE=2;, LABEL='2013-09-24'
; 2013 Dec
;OPLOT, int2, rat2,  PSYM=7, COLOR=88, THICK=3, SYMSIZE=2;, LABEL='2013-12-03'
; 2015 Feb
;OPLOT, int3, rat3,  PSYM=5, COLOR=207, THICK=3, SYMSIZE=2;, LABEL='2015-02-06'
scrncap = TVRD(TRUE=1)
WRITE_PNG, path+'ratio_dist_1.png', scrncap

;LEGEND, /DATA, /AUTO_TEXT_COLOR
END
