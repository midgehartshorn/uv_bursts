.compile /home/miriam/Documents/MHC/Summer23/code/iris_intro/msp.pro
.compile /home/miriam/Documents/MHC/Summer23/code/iris_intro/get_params.pro
.compile /home/miriam/Documents/MHC/Summer23/code/iris_intro/plot_params.pro
.compile /home/miriam/Documents/MHC/Summer23/code/iris_intro/cut_data.pro

READ, filename, PROMPT, 'Filename?'
obs_tag='20130924'
targ_wav=1394

MSP(targ_wav, 'iris_l2_20130924_114443_4000254145_raster_t000_r00000.fits', obs_tag)

GET_PARAMS(targ_wav, 'iris_l2_20130924_114443_4000254145_raster_t000_r00000.fits', obs_tag, /FULL)

PLOT_PARAMS(targ_wav,'iris_l2_20130924_114443_4000254145_raster_t000_r00000.fits', obs_tag+'_parameters.sav')

CUT_DATA(obs_tag+'_parameters.sav')


