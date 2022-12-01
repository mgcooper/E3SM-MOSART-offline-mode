clean

site_name = 'trib_basin';
save_file = true;

ats_runID = 'huc0802_gauge15906000_nopf';
ats_fname = 'huc0802_gauge15906000_nopf_discharge_2D.xlsx';
slopes_fname = 'mosart_hillslopes.mat';


fname_slopes = [getenv('USER_HILLSLOPER_DATA_PATH') filesep slopes_fname];

% load the hillsloper data
load(fname_slopes,'mosartslopes'); slopes = mosartslopes;

% load([pathdata 'mosart_hillslopes']); slopes = mosartslopes;

% runoff_template_path = [getenv('USER_MOSART_TEMPLATE_PATH') filesep site_name filesep 'mingpan'];
runoff_template_path = [getenv('USER_MOSART_RUNOFF_PATH') filesep site_name filesep 'mingpan'];
runoff_output_path = [getenv('USER_MOSART_RUNOFF_PATH') filesep site_name filesep 'ats'];


% test the function
[newinfo,roffATS,roffMP] = makeAtsRunoff(ats_runID,ats_fname, ...
   slopes_fname,site_name,runoff_output_path,runoff_template_path,save_file);


cd(runoff_template_path)

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
% 2. 

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



