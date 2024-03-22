clean

% This is an example of how the MOSART output can be processed using the
% functions in functions/. These functions take the unstructured MOSART
% output and map the runoff onto the hillslopes, locate the hillslope that
% contains the basin outlet, and computes the runoff.

savedata = true;
savefigs = false;
sitename = 'sag_basin';
runid = 'sag_basin.2013.2019.run.2024-01-19-105008.ats';

% sitename = 'trib_basin';
% runid = 'trib_basin.1997.2003.run.2023-06-16-112625.ats';
% runid = 'trib_basin.1997.2003.run.2023-06-16-120102.ats';
% runid = 'trib_basin.1997.2003.run.2023-06-16-120102.ats';

setenv('MOSART_SITENAME', sitename)
setenv('MOSART_RUNID', runid);

% trib_basin.1997.2003.run.2023-06-16-112625.ats a8
% trib_basin.1997.2003.run.2023-06-16-120102.ats a5

% These are only needed to read the instanaeous ats runoff
if getenv('MOSART_RUNID') == "trib_basin.1997.2003.run.2023-06-16-112625.ats"
   atsrunID = 'huc0802_gauge15906000_frozen_a8';
elseif getenv('MOSART_RUNID') == "trib_basin.1997.2003.run.2023-06-16-120102.ats"
   atsrunID = 'huc0802_gauge15906000_frozen_a5';
else
   atsrunID = 'sag_basin';
end

path_runoff_data = fullfile( ...
   getenv('USER_ATS_DATA_PATH'), ...
   atsrunID);

%% set paths

pathdata = fullfile(getenv('E3SMOUTPUTPATH'), getenv('MOSART_RUNID'), 'run');
pathsave = fullfile(getenv('E3SMOUTPUTPATH'), getenv('MOSART_RUNID'), 'mat');

% cd(pathdata)

%% load the sag discharge data and the instantaneous ats runoff

% % This is the one I modified for trib basin:
switch sitename
   case "trib_basin"

      load(fullfile(getenv("MATLAB_ACTIVE_PROJECT_DATA_PATH"), ...
         "trib_discharge"), "sag")

   case "sag_basin"

      load(fullfile(getenv("USERDATAPATH"), 'interface', 'sag_basin', ...
         "sag_data"), "sag")
end

load(fullfile(path_runoff_data, "ats_runoff.mat"))

% the ats_runoff table above has ming pan runoff already
% load(fullfile(getenv("MATLAB_ACTIVE_PROJECT_DATA_PATH"), ...
%    "sag_ming_pan_runoff"), "runoff")

sag.site_name = sitename;

%% read the e3sm output and clip the data to the gaged basin and time

% if h0 and h1 files exist, h1 = daily data saved annually, but depending
% on how the tapes are set up the daily data can be h0 so gotta set this
mosart = mos_readoutput(pathdata);
% Fails with new full sag until sag.mask updated, also the obs in sag struct end
% in 2007
try
   mosart = mos_clipbasin(mosart, sag);
catch
end

% Add the ming pan runoff and instantaneous ats runoff to the table
mosart.gaged.Dpan = runoff{:, "pan"};
mosart.gaged.Rats = runoff{:, "ats"};
mosart.gaged.Dpan_avg = mean(reshape(runoff{:, "pan"}, 365, []), 2);
mosart.gaged.Rats_avg = mean(reshape(runoff{:, "ats"}, 365, []), 2);

%% save it

if savedata == true
   if ~isfolder(pathsave)
      mkdir(pathsave);
      addpath(pathsave);
   end

   fname = fullfile(pathsave, 'mosart.mat');
   if isfile(fname)
      backupfile(fname, true);
   end

   save(fname, 'mosart');

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
   if isfile(fname)
      copyfile(fname, backupfile(fname))
   end
   writetimetable(datatable,fname);
end

%% plot it

H = plotatsmosart;

if savefigs == true
   pathsave = fullfile(getenv('MOSART_TESTBED'), sitename);
   exportgraphics(H.f1, fullfile(pathsave, 'ats-mosart-annual-avg.png'),'Resolution',300);
   exportgraphics(H.f2, fullfile(pathsave, 'ats-mosart-timeseries.png'),'Resolution',300);
   exportgraphics(H.f3, fullfile(pathsave, 'ats-mosart-scatter-avg.png'),'Resolution',300);
   exportgraphics(H.f4, fullfile(pathsave, 'ats-mosart-scatter.png'),'Resolution',300);
end

%%

colors = defaultcolors;

figure('Position', [234   233   715   384]);
plot(mosart.gaged.Tmod, mosart.gaged.Rats, '-', 'Color', colors(7, :), ...
   'LineWidth', 1); hold on
plot(mosart.gaged.Tmod, mosart.gaged.Dmod, 'Color', colors(1, :));
legend('unrouted', 'routed', 'location', 'north')
ylabel('m^3/s')

figure;
plot(mosart.gaged.Tavg, mosart.gaged.Rats_avg, '-', 'Color', colors(7, :), ...
   'LineWidth', 1); hold on
plot(mosart.gaged.Tavg, mosart.gaged.Dmod_avg, 'Color', colors(1, :));
legend('unrouted', 'routed', 'location', 'north')
ylabel('m^3/s')
datetick


figure;
plot(cumsum(mosart.gaged.Dmod_avg)); hold on;
plot(cumsum(mosart.gaged.Rats_avg))
legend('routed', 'unrouted')
if savefigs == true
   exportgraphics(gcf, fullfile(pathsave, 'ats-mosart-unrouted.png'),'Resolution',300);
end

figure; hold on
plot(cumsum(mosart.gaged.Dmod))
plot(cumsum(mosart.gaged.Rats), ':')
legend('routed', 'unrouted')

% Cumulative difference
dR = cumsum(mosart.gaged.Dmod) - cumsum(mosart.gaged.Rats);
dR (end)

% Channel storage on final timestep
% sum(mosart.S(end, :), 2) / 3600;
% (sum(mosart.S(end, :), 2) - sum(mosart.S(end-1, :), 2))  / 3600;




% resized it by hand
% exportgraphics(gcf, fullfile(pathsave, 'ats-mosart-timeseries-wide.png'),'Resolution',300);



