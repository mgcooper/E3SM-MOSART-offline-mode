clean

%% set paths
pathdata = '/Users/coop558/myprojects/e3sm/sag/e3sm_input/sag_basin/';

f_mosart = [pathdata 'MOSART_sag_test.nc'];
info_mos = ncparse(f_mosart);
data_mos = ncreaddata(f_mosart,info_mos.Variables);

f_domain = [pathdata 'domain_sag_test.nc'];
info_dom = ncparse(f_domain);
data_dom = ncreaddata(f_domain,info_dom.Variables);

pathdata = '/Users/coop558/mydata/e3sm/inputdata/lnd/dlnd7/';
info_gpcc = ncparse([pathdata 'GPCC.daily.nc']);

%% 
% 
% This was to diagnose why the dummy 2018 file had bad calendar start date - it
% was because i didn't use the methods in makeDummyRunoffFile, see section added
% to mk_huc_runoff that fixed it

% f0 = '/Users/coop558/work/data/e3sm/forcing/sag_basin/ats/sag_basin/runoff_sag_basin_2016.nc';
% f1 = '/Users/coop558/work/data/e3sm/forcing/sag_basin/ats/sag_basin/runoff_sag_basin_2017.nc';
% f2 = '/Users/coop558/work/data/e3sm/forcing/sag_basin/ats/sag_basin/runoff_sag_basin_2018.nc';
% 
% d0 = ncreaddata(f0);
% d1 = ncreaddata(f1);
% d2 = ncreaddata(f2);
% 
% open d0
% open d1
% open d2
% 
% % The problem is the 2018 file has "days since 2017-1 


