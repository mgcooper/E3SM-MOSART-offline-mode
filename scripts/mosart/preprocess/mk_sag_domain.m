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

%{

Important notes. The mosartlsopes.latixy/longxy are the mean link lat/lon, which
may not be correct, it depends on whether the lat/lon field in the mosart
parameter file is supposed to equal the lat/lon in the domain file. The domain
file isn't even used right now b/c we use the runoff file for the domain info in
user_dlnd, but I had forgotten this. I also forgot that the mosartslopes are
numbered from 1:numel(links), and are not numbered by the hillsloper hs_id
field, since Mosart is in terms of links. This was problematic when I tried to
replace the mosartslopes area field with the new area data from Bo. Her data was
numbered using the hillsloper hs_id field. 

%}

%% set paths

path_domain_data = ...
   getenv('USER_MOSART_DOMAIN_DATA_PATH');

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

load(fullfile(path_domain_data,'mosart_hillslopes.mat'),'mosartslopes');

%% put the updated ats area into the mosart fields

% the ats hillslopes are ordered by hillsloper hs_id, but mosartslopes are
% ordered by 1:numel(links). the links.hs_id field maps between them.
A = combineHillslopeArea(fname_area_file,transpose([mosartslopes.hs_id]));

% replace the mosartslopes area field with the updated one
mosartslopes = addstructfields(mosartslopes,A,'newfieldnames','area');

% this shows the ordering is correct
% figure; scatterfit(A, [mosartslopes.area]) 

%% write the file

% back up the existing file
if isfile(fname_save)
   fname_bk = backupfilename(fname_save);
   copyfile(fname_save,fname_bk);
end

[schema,info,data] = ...
   mosartMakeDomainFile(mosartslopes,fname_domain,fname_save,opts);

% go to the ouput folder 
cd(path_mosart_file_save)

% not sure what this was, maybe plot the boxes around each node 
if opts.testplot
   macfig
   for n = 1:numel(data.xc)
      if isfield(data,'xv')
         geobox(data.yv(:,n),data.xv(:,n));
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


