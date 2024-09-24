clean

% have:
% 15908000
% 15905100

% dont have:
% 15906000

% temporary notes about the small gaged site bo sent coordinates, I created a
% shapefile and identified the nearest link: 2652. I added it to the part below
% in teh script where the discharge is extracted, rewrote the table, and sent it
% to bo

% The coordinate of the USGS station (station id: 15905100) is
% (191402.68025042323, 2061090.432332672). I created a short horizontal line
% using the y coordinate of the station and found the intersection point of the
% horizontal line with the nearest link. The intersection point is
% (191515.43233267195, 2061090.432332672). The CRS is epsg3338. 

% lat = 68 + 27/60 + 8/3600;
% lon = -(149 + 22/60 + 24/3600);
% proj = loadprojcrs('AKA');
% [x, y] = projfwd(proj, lat, lon)
% printf({x, y})
% 
% sqmi2sqkm(297)
% % Drainage area: 297 square miles
% % Datum of gage: 2,586.68 feet above   NAVD88.

%%

% This is an example of how the MOSART output can be processed using the
% functions in functions/. These functions take the unstructured MOSART
% output and map the runoff onto the hillslopes, locate the hillslope that
% contains the basin outlet, and computes the runoff.

savedata = false;
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

% Load the toniolo discharge data - Need to get this formally in sagData
pathname = fullfile(getenv('USERDATAPATH'), 'interface', 'sag_basin');
tonioloData = load(fullfile(pathname, 'sag_toniolo_discharge.mat')).('Data');
tonioloSitenames = string(tonioloData.Properties.VariableNames);
subbasinOutletID = tonioloData.Properties.CustomProperties.linkID;

% add the atigun gage
tonioloSitenames = [tonioloSitenames, "Atigun"];
subbasinOutletID = [subbasinOutletID, 2652];

%% read the e3sm output and clip the data to the gaged basin and time

% if h0 and h1 files exist, h1 = daily data saved annually, but depending
% on how the tapes are set up the daily data can be h0 so gotta set this
mosartData = mosart.readoutput(path_mosart_output_data, ...
   subbasinOutletID=subbasinOutletID);

% figure; hold on
% plot(mosartData.T, mosartData.outletDischarge)
% plot(mosartData.T, mosartData.subbasinDischarge)

%% Create timeseries of mosart versus observations

% Retime hourly Toniolo data to daily mean, and then to the mosart calendar
tonioloDischarge = retime(tonioloData, "daily", "mean");
tonioloDischarge = retime(tonioloDischarge, mosartData.T, "fillwithmissing");

% Create a Mosart timetable with timeseries for each Toniolo gage site. Note
% that mosart.subbasinDischarge is ordered identically to tonioloDischarge.
% mosartDischarge = array2timetable( ... % need to add USGS site
%    [mosartData.subbasinDischarge, mosartData.outletDischarge], ... 
%    'RowTimes', mosartData.T, ...
%    'VariableNames', [tonioloDischarge.Properties.VariableNames, 'Outlet']);

% This one removes the outlet and uses tonioloSitenames which includes Atigun
mosartDischarge = array2timetable( ... % need to add USGS site
   mosartData.subbasinDischarge, ... 
   'RowTimes', mosartData.T, ...
   'VariableNames', tonioloSitenames);

if savedata == true
   filename = ['TonioloDischarge-mosart-' getenv('MOSART_RUNID') '.xlsx'];
   filename = fullfile(getenv('MOSART_TESTBED'), sitename, filename);
   writetimetable(mosartDischarge, filename);
   
   % Repeat with the observed data
   filename = 'TonioloDischarge-observations.xlsx';
   filename = fullfile(getenv('MOSART_TESTBED'), sitename, filename);
   writetimetable(tonioloDischarge, filename);
end

%% Below here originally followed mosart.readoutput

% Need to move toniolo stuff to a function and/or reconciel with the new format
% of the output from readoutput which should be a timetable not a struct

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
