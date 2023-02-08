clean

% THIS IS READY TO COPY INTO MK_ATS_RUNOFF ... THEY ARE IDENTICAL TO THE POINT
% WHERE MAKEATSRUNOFF IS CALLED ... THEN KEEP MK_ATS_RUNOFF AND DELETE THIS

% this assumes the ming pan data files have already been created, then reads
% those in and replaces the runoff with the ats runoff

%% set the options

savefile = true;
sitename = 'trib_basin';
atsrunID = 'huc0802_gauge15906000_nopf';
fname_domain_data = 'mosart_hillslopes.mat';
fname_runoff_data = 'huc0802_gauge15906000_nopf_discharge_2D.xlsx';
fname_hsarea_data = 'huc0802_gauge15906000_nopf_subcatch_area.csv';

opts = const( ...
   'savefile',savefile, ...
   'sitename',sitename, ...
   'startyear',1998, ...
   'endyear',2002, ...
   'runID',atsrunID);

%% build paths

path_domain_data = ...
   getenv('USER_HILLSLOPER_DATA_PATH');

path_runoff_data = ...
   fullfile( ...
   getenv('USER_ATS_DATA_PATH'), ...
   opts.runID);

path_runoff_template = ...
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'), ...
   opts.sitename, ...
   'mingpan');

% set the filename for the output file
path_runoff_file = ...
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'), ...
   opts.sitename, ...
   'ats', ...
   opts.runID);

%% build filenames

% set the filename for the custom area data
fname_area_data = ...
   fullfile( ...
   path_runoff_data, fname_hsarea_data);

% set the filename for the ats runoff data
fname_runoff_data = ...
   fullfile( ...
   path_runoff_data, fname_runoff_data);

% set the filename for the hillsloper data
fname_domain_data = ...
   fullfile( ...
   path_domain_data, fname_domain_data);

%% make the runoff files

[newinfo,roffATS,roffMP] = makeAtsRunoff( ...
                           sitename, ...
                           atsrunID, ...
                           fname_runoff_data, ...
                           fname_domain_data, ...
                           path_runoff_file, ...
                           path_runoff_template, ...
                           savefile, ...
                           fname_hsarea_data);

cd(path_runoff_template)


% compare ATS roff with ming pan roff
timeATS = roffATS.Time;
roffATS = roffATS.roff;
timeMP = roffMP.Time;
roffMP = roffMP.roffMP;

figure('Position',[165   299   762   294]);
subplot(1,2,1);
plot(timeATS,roffATS); hold on;
plot(timeMP,roffMP);
legend('ATS','Ming Pan');
ylabel('daily runoff [m$^3$ s$^{-1}$]');

subplot(1,2,2);
plot(timeATS,cumsum(roffATS.*(3600*24/1e9))); hold on;
plot(timeATS,cumsum(roffMP.*(3600*24/1e9)));
l = legend('ATS','Ming Pan');
ylabel('cumulative runoff [km$^3$]');
figformat('linelinewidth',1.5)


% FROM HERE, WE NEED TO:
% 1. use reyear_ats to make the 1997/2003 files and fix the schema
% 2. copy the runoff files to compy:
% qfs/people/coop558/data/e3sm/forcing/ats/<ats_runID>
% 3. copy the user_dlnd.streams.txt.lnd.gpcc.ats.<site_name> to local and edit
% the filenames if needed
% 4. copy the run script to local and edit as needed
% 5. copy the dlnd and run script back to compy
% 6. run the run script

% THEN WE NEED TO READ THE DATA BACK
% 1. edit and run cp_compy2local.sh to copy the data to E3SM_OUTPUT_PATH
% 2. edit and run scripts/mosart/postprocess/read_output_test_basin.m
% 3. 



