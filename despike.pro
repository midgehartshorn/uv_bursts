PRO DESPIKE
; despiking for improved image quality
obs_tag = '20140805'
path = '/run/media/midge/SamsungSSD/data/'+obs_tag+'/'

; modify parameters filename, created by radio_cal.pro OR rename.pro
;RESTORE, path+'/parameters_full.sav'
RESTORE, path+'cal_parameters.sav'

intensity = TRANSPOSE(REFORM(parameters[0,*,*]))
doppler = TRANSPOSE(REFORM(parameters[1,*,*]))
width = TRANSPOSE(REFORM(parameters[2,*,*])) 

despiked_intens = IRIS_PREP_DESPIKE(intensity, SIGMAS=2.7,NITER=1000,MODE='both',MIN_STD=1.0)

despiked_width = IRIS_PREP_DESPIKE(width,SIGMAS=2.0,NITER=1000,MIN_STD=0.5,MODE='both')

despiked_dop = IRIS_PREP_DESPIKE(doppler,SIGMAS=2.0,NITER=1000,MIN_STD=0.5,MODE='both')

SAVE, despiked_intens, despiked_width, despiked_dop, filename=path+'despiked_params.sav'

END
