clean

% This is an example of how the MOSART output can be processed using the
% functions in functions/. These functions take the unstructured MOSART
% output and map the runoff onto the hillslopes, locate the hillslope that
% contains the basin outlet, and computes the runoff. 

savedata = true;
savefigs = false;

setenv('MOSART_SITENAME','trib_basin')
% setenv('MOSART_RUNID','trib_basin.1997.2003.run.2023-06-16-112625.ats');
setenv('MOSART_RUNID','trib_basin.1997.2003.run.2023-06-16-120102.ats');

% trib_basin.1997.2003.run.2023-06-16-112625.ats a8
% trib_basin.1997.2003.run.2023-06-16-120102.ats a5

% These are only needed to read the instanaeous ats runoff
if getenv('MOSART_RUNID') == "trib_basin.1997.2003.run.2023-06-16-112625.ats"
   atsrunID = 'huc0802_gauge15906000_frozen_a8';
elseif getenv('MOSART_RUNID') == "trib_basin.1997.2003.run.2023-06-16-120102.ats"
   atsrunID = 'huc0802_gauge15906000_frozen_a5';
end

path_runoff_data = fullfile( ...
   getenv('USER_ATS_DATA_PATH'), ...
   atsrunID);

%% set paths

pathdata = fullfile(getenv('E3SMOUTPUTPATH'),getenv('MOSART_RUNID'),'run');
pathsave = fullfile(getenv('E3SMOUTPUTPATH'),getenv('MOSART_RUNID'),'mat');

% cd(pathdata)

%% load the sag discharge data and the instantaneous ats runoff

load(fullfile(getenv("MATLAB_ACTIVE_PROJECT_DATA_PATH"), ...
   "sag_discharge"), "sag")
load(fullfile(path_runoff_data, "ats_runoff.mat"))

% the ats_runoff table above has ming pan runoff already
% load(fullfile(getenv("MATLAB_ACTIVE_PROJECT_DATA_PATH"), ...
%    "sag_ming_pan_runoff"), "runoff")

%% read the e3sm output and clip the data to the gaged basin and time

% if h0 and h1 files exist, h1 = daily data saved annually, but depending
% on how the tapes are set up the daily data can be h0 so gotta set this
mosart = mos_readoutput(pathdata);
mosart = mos_clipbasin(mosart,sag);

% Add the ming pan runoff and instantaneous ats runoff to the table
mosart.gaged.Dpan = runoff{:, "pan"};
mosart.gaged.Rats = runoff{:, "ats"};
mosart.gaged.Dpan_avg = mean(reshape(runoff{:, "pan"}, 365, []), 2);
mosart.gaged.Rats_avg = mean(reshape(runoff{:, "ats"}, 365, []), 2);

%% save it

if savedata == true
   if ~isfolder(pathsave); mkdir(pathsave); addpath(pathsave); end
   
   fname = fullfile(pathsave,'mosart.mat');
   
   save(fname,'mosart');
   
% %    This is a way to make backups but don't think i need anymore
%    fname = fullfile(pathsave,'mosart.mat');
%    n = 1;
%    while isfile(fname)
%       n = n + 1;
%       fname = fullfile(pathsave,['mosart_' num2str(n) '.mat']);
%    end
%    save(fname,'mosart');
end

% convert to csv to send to Bo
datatable = atsmosarttable(mosart);
if savedata == true
   fname = ['ats-mosart-' getenv('MOSART_RUNID') '.xlsx'];
   fname = fullfile(getenv('MOSART_TESTBED'),fname);
   writetimetable(datatable,fname);
end

%% plot it

figure; 
plot(mosart.gaged.Dmod_avg); hold on; 
plot(mosart.gaged.Rats_avg)
legend('routed', 'unrouted')

figure; 
plot(cumsum(mosart.gaged.Dmod_avg)); hold on; 
plot(cumsum(mosart.gaged.Rats_avg))
legend('routed', 'unrouted')

H = plotatsmosart;

if savefigs == true
   exportgraphics(f1,'ats-mosart-annual-avg.png','Resolution',300);
   exportgraphics(f2,'ats-mosart-timeseries.png','Resolution',300);
end

