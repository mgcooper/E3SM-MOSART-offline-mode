clean

% This is an example of how the MOSART output can be processed using the
% functions in functions/. These functions take the unstructured MOSART
% output and map the runoff onto the hillslopes, locate the hillslope that
% contains the basin outlet, and computes the runoff.

savedata = true;
savefigs = false;
sitename = 'sag_basin';
runid = 'sag_basin.2014.2018.run.2024-03-22-122924.ats';

setenv('MOSART_SITENAME', sitename)
setenv('MOSART_RUNID', runid);

% These are only needed to read the instanaeous ats runoff
atsrunID = ats.setrunid(runid);

%% set paths

path_runoff_forcing_data = fullfile( ...
   getenv('USER_ATS_DATA_PATH'), ...
   atsrunID);

path_mosart_output_data = fullfile( ...
   getenv('E3SMOUTPUTPATH'), ...
   getenv('MOSART_RUNID'), ...
   'run');

path_mosart_output_save = fullfile( ...
   getenv('E3SMOUTPUTPATH'), ...
   getenv('MOSART_RUNID'), ...
   'mat');

% cd(path_mosart_output_data)

%% load the sag discharge data and the instantaneous ats runoff

sagData = loadSagData(sitename);

runoffData = load(fullfile( ...
   path_runoff_forcing_data, "ats_runoff.mat")).('runoff');

% For reference, this returns the full data table
% test = ats.loadrunoff;
% test = sum(test{:, :}, 2); % equivalent to runoffData.ats

% the ats_runoff table above has ming pan runoff already
% load(fullfile(getenv("MATLAB_ACTIVE_PROJECT_DATA_PATH"), ...
%    "sag_ming_pan_runoff"), "runoff")

%% read the e3sm output and clip the data to the gaged basin and time

% if h0 and h1 files exist, h1 = daily data saved annually, but depending
% on how the tapes are set up the daily data can be h0 so gotta set this
mosartData = mosart.readoutput(path_mosart_output_data);

% Fails with new full sag until sag.mask updated, also the obs in sag struct end
% in 2007
try
   mosartData = mosart.clipbasin(mosartData, sagData);
catch
end

% Add the ming pan runoff and instantaneous ats runoff to the table
mosartData.gaged.Dpan = runoffData{:, "pan"};
mosartData.gaged.Rats = runoffData{:, "ats"};
mosartData.gaged.Dpan_avg = mean(reshape(runoffData{:, "pan"}, 365, []), 2);
mosartData.gaged.Rats_avg = mean(reshape(runoffData{:, "ats"}, 365, []), 2);

%% save it

if savedata == true
   if ~isfolder(path_mosart_output_save)
      mkdir(path_mosart_output_save);
      addpath(path_mosart_output_save);
   end

   fname = fullfile(path_mosart_output_save, 'mosart.mat');
   backupfile(fname, true);
   save(fname, 'MosartData');
end

% convert to csv to send to Bo
datatable = atsmosarttable(mosartData);
if savedata == true
   fname_save = ['ats-mosart-' getenv('MOSART_RUNID') '.xlsx'];
   fname_save = fullfile(getenv('MOSART_TESTBED'), sitename, fname_save);
   backupfile(fname_save, true)
   writetimetable(datatable, fname_save);
end

%% plot it

H = plotatsmosart();

if savefigs == true
   path_figures = fullfile(getenv('MOSART_TESTBED'), sitename, runid);
   if ~isfolder(path_figures)
      mkdir(path_figures)
   end
   exportgraphics(H.f1, fullfile(path_figures, 'ats-mosart-annual-avg.png'), ...
      'Resolution', 300);
   exportgraphics(H.f2, fullfile(path_figures, 'ats-mosart-timeseries.png'), ...
      'Resolution', 300);
   exportgraphics(H.f3, fullfile(path_figures, 'ats-mosart-scatter-avg.png'), ...
      'Resolution', 300);
   exportgraphics(H.f4, fullfile(path_figures, 'ats-mosart-scatter.png'), ...
      'Resolution', 300);
end

%%

% sag_basin
% runid = 'sag_basin.2013.2019.run.2024-01-19-105008.ats';

% trib_basin
% runid = 'trib_basin.1997.2003.run.2023-06-16-112625.ats';
% runid = 'trib_basin.1997.2003.run.2023-06-16-120102.ats';
% runid = 'trib_basin.1997.2003.run.2023-06-16-120102.ats';

% trib_basin.1997.2003.run.2023-06-16-112625.ats a8
% trib_basin.1997.2003.run.2023-06-16-120102.ats a5
