clean

% NOTE: mk_ats_runoff is entirely reconciled with this and makeAtsRunoff. The
% only difference is the opts struct commented out below.

save_file = true;
site_name = 'trib_basin';
ats_runID = 'huc0802_gauge15906000_nopf'; %'huc0802_gauge15906000';
ats_fname = 'huc0802_gauge15906000_nopf_discharge_2D.xlsx';
slopes_fname = 'mosart_hillslopes.mat';

% this assumes the mingpan data files have already been created, then reads
% those in and replaces the runoff with the ats runoff

%% this is how it was done in mk_ats_runoff in case i want to go back to that

% % set the options
% opts     = const( 'savefile',       false,                        ...
%                   'sitename',       sitename,                     ...
%                   'startyear',      1998,                         ...
%                   'endyear',        2002                          );
%                 
% nyears   = opts.endyear-opts.startyear+1;


%% set paths to the runoff template files and the output path

% path_runoff_file_template = ...
%    fullfile( ...
%    getenv('USER_MOSART_TEMPLATE_PATH'),site_name,'mingpan');

path_runoff_file_template = ...  % was pathtemp in mk_ats_runoff
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'),site_name,'mingpan');

path_runoff_file_save = ...      % was pathsave in mk_ats_runoff
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'),site_name,'ats');

path_domain_data_file = ...      % was pathdata in mk_ats_runoff
   fullfile( ...
   getenv('USER_HILLSLOPER_DATA_PATH'),slopes_fname);

path_area_file = ...
   getenv('USER_ATS_DATA_PATH');

%% load the hillsloper data that has ID and dnID and prep it for MOSART

load(path_domain_data_file,'mosartslopes');

plot_hillsloper(slopes,links)

%% test the function

[newinfo,roffATS,roffMP] = makeAtsRunoff( ...
   ats_runID, ...
   ats_fname, ...
   site_name, ...
   path_domain_data_file, ...
   path_runoff_file_save, ...
   path_runoff_file_template, ...
   save_file);


cd(path_runoff_file_template)

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

% as long as the forcing file path is set in the user_dlnd file, the run script
% should be good as-is b/c 

qfs/people/coop558/data/e3sm/forcing/ats/huc0802_gauge15906000_nopf



%% compare ATS roff with ming pan roff

figure('Position',[165   299   762   294]);
subplot(1,2,1);
plot(timeATS(:),roffATS); hold on;
plot(timeATS(:),roffMP);
legend('ATS','Ming Pan');
ylabel('daily runoff [m$^3$ s$^{-1}$]');

subplot(1,2,2);
plot(timeATS(:),cumsum(roffATS.*(3600*24/1e9))); hold on;
plot(timeATS(:),cumsum(roffMP.*(3600*24/1e9)));
l = legend('ATS','Ming Pan');
ylabel('cumulative runoff [km$^3$]');
figformat




% % these were for reference but should be sorted otu now
% runoff_template_path = '/Users/coop558/myprojects/e3sm/sag/input/hru/';
% runoff_output_path = '/Users/coop558/myprojects/e3sm/sag/input/hru/';
% runoff_template_path = [runoff_template_path opts.sitename '/mingpan/'];
% runoff_output_path = [runoff_output_path opts.sitename '/ats/'];
% 
% 
% pathdata = setpath('interface/sag_basin/hillsloper/trib_basin/newslopes/','data');
% pathats  = setpath(['interface/sag_basin/ats/' atsrun],'data','goto');
% pathtemp = '/Users/coop558/myprojects/e3sm/sag/input/hru/';
% pathsave = '/Users/coop558/myprojects/e3sm/sag/input/hru/';
% pathtemp = [pathtemp opts.sitename '/mingpan/'];
% pathsave = [pathsave opts.sitename '/ats/'];



