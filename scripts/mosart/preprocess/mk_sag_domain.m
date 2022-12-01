clean

site_name   = 'trib_basin';
runID       = 'huc0802_gauge15906000_nopf';

%% set paths

% set paths
path_domain_data           = getenv('USER_HILLSLOPER_DATA_PATH');
path_domain_file_template  = getenv('USER_MOSART_TEMPLATE_PATH')
path_mosart_file_save      = getenv('USER_E3SM_CONFIG_PATH');
path_area_file             = getenv('USER_ATS_DATA_PATH');

% 
area_file = 'huc0802_gauge15906000_nopf_subcatch_area.csv';
area_file = [path_area_file filesep runID filesep area_file];

% path_domain_data           = '../data/hillsloper/';
% path_domain_file_template  = '../data/templates/icom/';
% path_mosart_file_save      = ['../data/e3sm-input/gridded/' sitename '/'];

% path.data   = '/Users/coop558/mydata/e3sm/domain_files/icom_template/';
% path.save   = '/Users/coop558/myprojects/e3sm/sag/e3sm_input/sag_basin/';
% path.sag    = setpath('interface/data/hillsloper/sag_basin/');
% cd(path.save)

%% Load the hillsloper data and modify it for MOSART 

load([path_domain_data filesep 'mosart_hillslopes'],'mosartslopes');
slopes = mosartslopes; clear mosartslopes

% to compute the surface area of each sub-basin in units of steradians
Aearth  = 510099699070762;       % m2, this is earth area defined in E3SM
% Aearth  = 510065621724089;     % this is the area i used in other functions

% assign values to each variable
xc      = [slopes.longxy]';
yc      = [slopes.latixy]';
mask    = (int32(ones(size([slopes.longxy]))))';
frac    = (ones(size([slopes.longxy])))';
ncells  = size(mask,1);
area    = ([slopes.area].*4.*pi./Aearth)';      % sr

% sum(area)
% sum([slopes.area])
% 12961625875

% get the area form the area file
A        = readfiles(area_file);

% compute the bounding box of each sub-basin
for n = 1:length(slopes)
    bbox        = slopes(n).bbox;
    xbox        = bbox(:,1);
    ybox        = bbox(:,2);
    xv(:,n)     = [xbox(1) xbox(2) xbox(2) xbox(1)]; % ll ccw
    yv(:,n)     = [ybox(1) ybox(1) ybox(2) ybox(2)];
end

%% 2. read in icom files to use as a template, and write the new file

fdomain     = 'domain_u_icom_half_sparse_grid_c200610.nc';
fdomain     = [path_domain_file_template fdomain];

fsave       = [path.save 'domain_sag_test.nc'];

if exist(fsave,'file'); delete(fsave); end

myschema.xc     = ncinfo(fdomain,'xc');
myschema.yc     = ncinfo(fdomain,'yc');
myschema.xv     = ncinfo(fdomain,'xv');
myschema.yv     = ncinfo(fdomain,'yv');
myschema.mask   = ncinfo(fdomain,'mask');
myschema.area   = ncinfo(fdomain,'area');
myschema.frac   = ncinfo(fdomain,'frac');

% modify the size to match the sag domain
myschema.xc.Size    = [ncells,1];
myschema.yc.Size    = [ncells,1];
myschema.xv.Size    = [4,ncells,1];
myschema.yv.Size    = [4,ncells,1];
myschema.mask.Size  = [ncells,1];
myschema.area.Size  = [ncells,1];
myschema.frac.Size  = [ncells,1];

myschema.xc.Dimensions(1).Length    = ncells;
myschema.yc.Dimensions(1).Length    = ncells;
myschema.xv.Dimensions(2).Length    = ncells;
myschema.yv.Dimensions(2).Length    = ncells;
myschema.mask.Dimensions(1).Length  = ncells;
myschema.area.Dimensions(1).Length  = ncells;
myschema.frac.Dimensions(1).Length  = ncells;

ncwriteschema(fsave,myschema.xc);
ncwriteschema(fsave,myschema.yc);
ncwriteschema(fsave,myschema.xv);
ncwriteschema(fsave,myschema.yv);
ncwriteschema(fsave,myschema.mask);
ncwriteschema(fsave,myschema.area);
ncwriteschema(fsave,myschema.frac);

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% write the variable values
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ncwrite(fsave,'xc',xc);
ncwrite(fsave,'yc',yc);
ncwrite(fsave,'xv',xv);
ncwrite(fsave,'yv',yv);
ncwrite(fsave,'mask',mask);
ncwrite(fsave,'area',area);
ncwrite(fsave,'frac',frac);

% read in the new file to compare with the old file                        
%==========================================================================
newinfo.domain  = ncinfo(fsave);