PRO PLOT_CONTOUR
path = '/home/miriam/Documents/MHC/Summer23/code'

RESTORE, path +'/iris_intro/conf_detections.sav'

bin_mask = MAKE_ARRAY(1096,400)

bin_mask[ni_confirmed] = 1

help, bin_mask

print, MEAN(bin_mask)
END
