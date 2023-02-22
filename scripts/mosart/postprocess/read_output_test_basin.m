clean

% This is an example of how the MOSART output can be processed using the
% functions in functions/. These functions take the unstructured MOSART
% output and map the runoff onto the hillslopes, locate the hillslope that
% contains the basin outlet, and computes the runoff. 

% THE NEW RUN IS OUT OF ORDER - the test run i did last week was in the right
% order so compare run.trib.test.sh to run.trib.sh

addpath(genpath('/Users/coop558/myprojects/matlab/bfra'));

savedata = true;
savefigs = false;

setenv('MOSART_SITENAME','trib_basin')
setenv('MOSART_RUNID','trib_basin.1997.2003.run.2023-02-08-164525.ats');

%% set paths

pathdata = fullfile(getenv('E3SMOUTPUTPATH'),getenv('MOSART_RUNID'),'run');
pathsave = fullfile(getenv('E3SMOUTPUTPATH'),getenv('MOSART_RUNID'),'mat');

% cd(pathdata)

% load the sag river basin data
load('/Users/coop558/work/data/interface/sag_basin/sag_data');

sag.site_name = getenv('MOSART_SITENAME');

% for the trib basin, load that data and replace the data in 'sag'
flow = bfra.loadflow('SAGAVANIRKTOK R TRIB NR PUMP STA 3 AK');
sag.time = flow.Time;
sag.flow = flow.Q;

% figure; plot(sag.time,sag.flow);

%% read the e3sm output and clip the data to the gaged basin and time

% if h0 and h1 files exist, h1 = daily data saved annually, but depending
% on how the tapes are set up the daily data can be h0 so gotta set this

mosart = mos_readoutput(pathdata);
mosart = mos_clipbasin(mosart,sag);

%% save it

if savedata == true
   if ~isfolder(pathsave); mkdir(pathsave); addpath(pathsave); end
   
   fname = fullfile(pathsave,'mosart.mat');
   n = 1;
   while isfile(fname)
      n = n + 1;
      fname = fullfile(pathsave,['mosart_' num2str(n) '.mat']);
   end
   save(fname,'mosart');
end

% convert to csv to send to Bo
datatable = atsmosarttable(mosart);
if savedata == true
   fname = ['ats-mosart-' getenv('MOSART_RUNID') '.xlsx'];
   fname = fullfile(getenv('MOSART_TESTBED'),fname);
   writetimetable(datatable,fname);
end

%% plot it

H = plotatsmosart;

if savefigs == true
   exportgraphics(f1,'ats-mosart-annual-avg.png','Resolution',300);
   exportgraphics(f2,'ats-mosart-timeseries.png','Resolution',300);
end

