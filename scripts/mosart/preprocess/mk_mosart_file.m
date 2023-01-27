clean

sitename = 'icom';

% set the options
opts = const('savefile',false,'sitename',sitename);

% set paths
path_domain_data = getenv('USER_MOSART_DOMAIN_DATA_PATH');
path_domain_file_template = getenv('USER_MOSART_TEMPLATE_PATH');
path_mosart_file_save = getenv('USER_E3SM_CONFIG_PATH');

%% domain data - where hillsloper and hexwatershed differ

% load the domain data
% load(fullfile(path_domain_data,'mosart_hillslopes'),'mosartslopes');

% option 1: load the json and do the processing
% load(fullfile(path_domain_data,'hexwatershed.json'),'mosartslopes');
% str = fileread(getenv('MESHJSONFILE'));
% data = jsondecode(str);

% option 2: load the pre-processed mesh file

% find mesh cell flow direction
load(fullfile(getenv('USER_MOSART_DOMAIN_DATA_PATH'),'mpas_mesh.mat'),'Mesh');
[ID,dnID] = hexmesh_dnID(Mesh);

Mesh = addstructfields(Mesh,ID);
Mesh = addstructfields(Mesh,dnID);

oldfields = {'dLatitude_center_degree','dLongitude_center_degree'};
newfields = {'latixy','longxy'};
Mesh = renamestructfields(Mesh,oldfields,newfields);


%% continue

% ftemp is used as a template to get the right .nc file format
ftemp = fullfile(path_domain_file_template,'MOSART_icom_half_c200624.nc');
fsave = fullfile(path_mosart_file_save,['MOSART_' sitename '_test.nc']);

% write the file
[schema,info,data] = mos_makemosart(Mesh,ftemp,fsave,opts);

cd(path_mosart_file_save)

% for template files see sftp://compy.pnl.gov/compyfs/inputdata/rof/mosart/

% % older version
% path_domain_data = setpath(['interface/data/sag/hillsloper/' sitename '/newslopes/']);
% path_domain_file_template = setpath('e3sm/input/icom/','data');
% path_mosart_file_save = setpath(['/e3sm/sag/input/gridded/' sitename],'project');