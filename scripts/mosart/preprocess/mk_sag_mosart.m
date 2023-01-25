clean

sitename = 'trib_basin_test';

% set the options
opts = const('savefile',true,'sitename',sitename);

% set paths
path_domain_data = getenv('USER_HILLSLOPER_DATA_PATH');
path_domain_file_template = getenv('USER_MOSART_TEMPLATE_PATH');
path_mosart_file_save = getenv('USER_E3SM_CONFIG_PATH');

% load the hillsloper data
load(fullfile(path_domain_data,'mosart_hillslopes'),'mosartslopes');

% ftemp is used as a template to get the right .nc file format
ftemp = fullfile(path_domain_file_template,'MOSART_icom_half_c200624.nc');
fsave = fullfile(path_mosart_file_save,['MOSART_' sitename '.nc']);

% write the file
[schema,info,data] = mos_makemosart(mosartslopes,ftemp,fsave,opts);
cd(p.save)

% for template files see sftp://compy.pnl.gov/compyfs/inputdata/rof/mosart/

% % older version
% path_domain_data = setpath(['interface/data/sag/hillsloper/' sitename '/newslopes/']);
% path_domain_file_template = setpath('e3sm/input/icom/','data');
% path_mosart_file_save = setpath(['/e3sm/sag/input/gridded/' sitename],'project');