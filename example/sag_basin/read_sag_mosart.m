clean

%% set paths
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pathdata  = '/Users/coop558/myprojects/e3sm/sag/e3sm_input/sag_basin/';

fmosart     = [pathdata 'MOSART_sag_test.nc'];
info_mos    = ncparse(fmosart);
data_mos    = ncreaddata(fmosart,info_mos.Variables);

fdomain     = [pathdata 'domain_sag_test.nc'];
info_dom    = ncparse(fdomain);
data_dom    = ncreaddata(fdomain,info_dom.Variables);

pathdata    = '/Users/coop558/mydata/e3sm/inputdata/lnd/dlnd7/';
info_gpcc   = ncparse([pathdata 'GPCC.daily.nc']);



