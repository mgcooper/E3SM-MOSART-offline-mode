clean

sitename = 'trib_basin';

%% set the options

opts = const( ...
   'savefile',true, ...
   'sitename',sitename, ...
   'runID','huc0802_gauge15906000_nopf', ...
   'farea','huc0802_gauge15906000_nopf_subcatch_area.csv', ...
   'ftemplate','MOSART_icom_half_c200624.nc', ...
   'nobackups',false, ...
   'testplot',true);

%% set paths

path_domain_data = ...
   getenv('USER_HILLSLOPER_DATA_PATH');

path_domain_file_template = ...
   getenv('USER_MOSART_TEMPLATE_PATH');

path_mosart_file_save = ...
   getenv('USER_E3SM_CONFIG_PATH');

path_area_file = ...
   getenv('USER_ATS_DATA_PATH');

%% set filenames

% ftemplate is used as a template to get the right .nc file format
fname_template = ...
   fullfile(...
   path_domain_file_template,opts.ftemplate);

% farea is an optional file 
fname_area_file = ...
   fullfile( ...
   path_area_file,opts.runID,opts.farea);

% fsave is the domain file created by this script
fname_save = ...
   fullfile( ...
   path_mosart_file_save,['MOSART_' sitename '.nc']);

%% load the hillsloper data that has ID and dnID and prep it for MOSART

load(fullfile(path_domain_data,'mosart_hillslopes.mat'),'mosartslopes');

%% put the updated ats area into the mosart fields

% the ats hillslopes are ordered by hillsloper hs_id, but mosartslopes are
% ordered by 1:numel(links). the links.hs_id field maps between them.
A = combineHillslopeArea(fname_area_file,transpose([mosartslopes.hs_id]));

% run this before replacing to see that the ordering is correct
% figure; scatterfit(A, [mosartslopes.area]) 

% replace the mosartslopes area field with the updated one
mosartslopes = addstructfields(mosartslopes,A,'newfieldnames','area');

%% write the file

% back up the existing file
if isfile(fname_save)
   fname_bk = backupfilename(fname_save);
   copyfile(fname_save,fname_bk);
end


[schema,info,data] = mos_makemosart(mosartslopes,fname_template,fname_save,opts);
cd(path_mosart_file_save)

% for template files see sftp://compy.pnl.gov/compyfs/inputdata/rof/mosart/

% % older version
% path_domain_data = setpath(['interface/data/sag/hillsloper/' sitename '/newslopes/']);
% path_domain_file_template = setpath('e3sm/input/icom/','data');
% path_mosart_file_save = setpath(['/e3sm/sag/input/gridded/' sitename],'project');