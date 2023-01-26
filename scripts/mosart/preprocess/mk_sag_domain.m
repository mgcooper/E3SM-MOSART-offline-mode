clean

%% set the options

opts = const( ...
   'save_file',true,...
   'sitename','trib_basin',...
   'runID','huc0802_gauge15906000_nopf',...
   'farea','huc0802_gauge15906000_nopf_subcatch_area.csv',...
   'ftemplate','domain_u_icom_half_sparse_grid_c200610.nc',...
   'testplot',true);

sitename = opts.sitename;

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

% fdomain is used as a template to get the right .nc file format
fname_domain = ...
   fullfile(...
   path_domain_file_template,opts.ftemplate);

% farea is an optional file 
fname_area_file = ...
   fullfile( ...
   path_area_file,opts.runID,opts.farea);

% fsave is the domain file created by this script
fname_save = ...
   fullfile( ...
   path_mosart_file_save,['domain_' sitename '.nc']);

%% load the hillsloper data that has ID and dnID and prep it for MOSART

load( ...
   fullfile(path_domain_data,'mosart_hillslopes.mat'),'mosartslopes');

%% TEST

% compare the area in the area file to the hillsloper areas
A = readfiles(fname_area_file); 

% sum(A.area_m2_)/sum([slopes.area]) 1.16
% sum([slopes.area]) trib: 73818500, sag (?) 12961625875

%% write the file
[schema,info,data] = ...
   mosartMakeDomainFile(mosartslopes,fname_domain,fname_save,opts);

% go to the ouput folder 
cd(path_mosart_file_save)

% not sure what this was, maybe plot the boxes around each node 
if opts.test_plot
   macfig
   for n = 1:data.xc
      if isfield(data,'xv')
         plot(data.xv(:,n),data.yv(:,n)); hold on;
      end
      myscatter(data.xc(n),data.yc(n),80); hold on;
      pause
   end
end


% compare with the one produced by mk_huc_domain 
ftest = '/Users/coop558/work/data/e3sm/config/domain_trib_test.nc';
fcomp = compareMosartFiles(fname_save,ftest);

% says xc not equal
d1 = ncreaddata(fname_save);
d2 = ncreaddata(ftest);

isequal(d1.xc,wrapTo360(d2.xc))
figure; scatterfit(d1.xc,wrapTo360(d2.xc))


