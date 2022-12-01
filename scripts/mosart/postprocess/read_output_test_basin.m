clean

% This is an example of how the MOSART output can be processed using the
% functions in functions/. These functions take the unstructured MOSART
% output and map the runoff onto the hillslopes, locate the hillslope that
% contains the basin outlet, and computes the runoff. 

addpath(genpath('/Users/coop558/myprojects/matlab/bfra_dev_bk'));

savedata = true;
savefigs = false;
sitename = 'trib_basin';
run      = 'trib_basin.1997.2003.run.2022-11-22.ats';
% run      = 'trib_basin.1997.2003.run.2022-11-18.ats';
% run    = 'trib_basin.1998.2002.run.2022-07-21.ats';

%% set paths

pathdata = [getenv('E3SMOUTPUTPATH') run '/run/'];
pathsave = [getenv('E3SMOUTPUTPATH') run '/mat/'];

if ~exist(pathsave,'dir'); mkdir(pathsave); addpath(pathsave); end; 

cd(pathdata)

% load the sag river basin data
load('/Users/coop558/work/data/interface/sag_basin/sag_data');

sag.site_name = sitename;

% for the trib basin, load that data and replace the data in 'sag'
flow     = bfra_loadflow('SAGAVANIRKTOK R TRIB NR PUMP STA 3 AK');
sag.time = flow.Time;
sag.flow = flow.Q;

% figure; plot(sag.time,sag.flow);

%% read the e3sm output and clip the data to the gaged basin and time

% if h0 and h1 files exist, h1 = daily data saved annually, but depending
% on how the tapes are set up the daily data can be h0 so gotta set this
flist   = getlist(pathdata,'*.mosart.h0*');
mosart  = mos_readoutput(flist);
mosart  = mos_clipbasin(mosart,sag);


%% save it
if savedata == true
    if ~exist(pathsave,'dir'); mkdir(pathsave); end
    save([pathsave 'mosart.mat'],'mosart');
end


