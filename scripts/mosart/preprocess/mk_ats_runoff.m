clean

% this reads the ming pan runoff files and replaces the runoff with ats runoff

%% set the options

savefile = false;
sitename = 'trib_basin';
atsrunID = 'huc0802_gauge15906000_frozen_a8';
fname_domain_data = 'mosart_hillslopes.mat';
fname_runoff_data = 'frozen_huc190604020802_gauge15906000_discharge_2D_a8.xlsx';
fname_hsarea_data = 'huc190604020802_gauge15906000_subcatch_area.xlsx';

opts = const( ...
   'savefile',savefile, ...
   'sitename',sitename, ...
   'startyear',1998, ...
   'endyear',2002, ...
   'runID',atsrunID);

%% build paths

% set the path to the domain data - in this case the hillsloper data
path_domain_data = ...
   getenv('USER_MOSART_DOMAIN_DATA_PATH');

% set the path to the runoff data - in this case the ats runoff
path_runoff_data = ...
   fullfile( ...
   getenv('USER_ATS_DATA_PATH'), ...
   opts.runID);

% set the path to the template files - in this case the Ming Pan runoff files
path_runoff_template = ...
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'), ...
   opts.sitename, ...
   'mingpan');

% set the filename for the output file
path_runoff_files = ...
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'), ...
   opts.sitename, ...
   'ats', ...
   opts.runID);

%% create folders if they do not exist

if ~isfolder(path_runoff_data)
   error('path_runoff_data does not exist')
end

if ~isfolder(path_runoff_files)
   mkdir(path_runoff_files)
end

%% build filenames

% set the filename for the custom area data
fname_hsarea_data = ...
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
                           fname_runoff_data, ...
                           fname_domain_data, ...
                           path_runoff_files, ...
                           path_runoff_template, ...
                           savefile, ...
                           fname_hsarea_data);

%% make the dummy files one year before and one year after the first/last year

cd(path_runoff_files);

CopyInfo = makeDummyRunoffFiles(sitename,opts.startyear,opts.endyear, ...
   path_runoff_files,opts.savefile,'nobackups');

% info = ncinfo(pasteFile);
% dat = ncread(['runoff_trib_basin_' num2str(n) '.nc'],'time' );
% dat = dat+1;
% ncwrite(['runoff_trib_basin_' num2str(n) '.nc'],'time',dat);

%% save the data in .mat format

runoff = synchronize(roffMP, roffATS);
runoff = renamevars(runoff, ["roffMP", "roff"], ["pan", "ats"]);

if savefile == true
   save(fullfile(path_runoff_data, "ats_runoff.mat"), "runoff")
end
%% look at the result

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
% 1. DONE use reyear_ats to make the 1997/2003 files and fix the schema
% 2. copy the runoff files and if updated the MOSART file to compy:
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


% % double check that domain and runoff files are both updated

domain_data = ncreaddata('/Users/coop558/work/data/e3sm/config/domain_trib_basin.nc');
mosart_data = ncreaddata('/Users/coop558/work/data/e3sm/config/MOSART_trib_basin.nc');
runoff_data = ncreaddata(fullfile(path_runoff_files,'runoff_trib_basin_1997.nc'));

domain_x = domain_data.xc;
domain_y = domain_data.yc;
runoff_x = runoff_data.xc;
runoff_y = runoff_data.yc;
mosart_x = transpose(mosart_data.longxy);
mosart_y = transpose(mosart_data.latixy);

isequal(domain_x,runoff_x)
isequal(domain_y,runoff_y)
isequal(domain_x,mosart_x)
isequal(domain_y,mosart_y)
