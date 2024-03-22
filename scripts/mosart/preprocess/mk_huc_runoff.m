clean

% sitename    = 'trib_basin';
% startyear   = 2003;
% endyear     = 2017;

sitename    = 'sag_basin';
% startyear   = 1979;
startyear   = 2017;
endyear     = 2017;

% jan 2023 the important thing is that this uses gridded runoff (ming pan).
% mk_ats_runoff uses the lists

% sep 2022 i am deleting the test_basin and directory. the only diff b/w
% this script was startyear was 1985 and endyear was 2017.

% jul 2022 this makes input runoff using the gridded data, should be Ming
% Pan's runoff, for the ungaged test basin. there was basically no
% difference between this script and the one in hru/, so i think the hru/
% one was never finished, and instead i used mk_ats_runoff.m

% need to change the stuff in user_dlnd.streams to match the vars in teh
% domain file, specifically lat/lon/time whereas the new one i wrote is
% xc/yc so need to add time to the runoff files and maybe rename

% set the options
opts = const( ...
   'savefile',        true,      ...
   'sitename',        sitename,  ...
   'inputGridded',    true,      ...
   'outputGridded',   false,     ...
   'checkdata',       true,      ...
   'startyear',       startyear, ...
   'endyear',         endyear    );

nyears = endyear-startyear+1;

%% build paths

path_domain_data = ...
   getenv('USER_MOSART_DOMAIN_DATA_PATH');

path_domain_template = ...
   getenv('USER_E3SM_CONFIG_PATH');

path_runoff_data = ...
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'), ...
   'north_slope', ...
   'mingpan');

path_runoff_save = ...
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'), ...
   opts.sitename, ...
   'mingpan');

% if using GPCC.daily.nc:
% path_runoff_data = setpath(...
%  'e3sm/compyfs/inputdata/lnd/dlnd7/hcru_hcru','data');

%%

% use the 1-d unstructured domain file as a domain template
fdomain = fullfile( ...
   path_domain_template, ['domain_' sitename '.nc']);

% load the hillsloper data
load(fullfile(path_domain_data, 'mosart_hillslopes.mat'), 'mosartslopes');

% frunoff is used as a template to get the right .nc file format
for n = 1:nyears

   thisyear = num2str(startyear + n - 1);

   frunoff = fullfile(path_runoff_data, ['sag_' thisyear '_mosart.nc']);
   fsave   = fullfile(path_runoff_save, ['runoff_' sitename '_' thisyear '.nc']);

   [schema, info, data] = mosart.makeRunoffFile( ...
      mosartslopes, frunoff, fdomain, fsave, opts);

end

%%

% % This is to create a dummy 2018 file for full sag runs b/c the ATS sim's go
% % thorugh 2018 but ming pan files end at 2017, so this creates a dummy 2018 ming
% % pan hillslope-config file for use as template in mk_ats_runoff
% savefile = true;
% startyear = 2017;
% endyear = 2017;
% path_runoff_files = '/Users/coop558/work/data/e3sm/forcing/sag_basin';
%
% % Copy to the directory above b/c makeDummyRunoffFiles creates a dummy file
% % before and after, thus 2016 would be overwritten
% copyfile(fullfile(path_runoff_files, 'mingpan', 'runoff_sag_basin_2017.nc'), ...
%    fullfile(path_runoff_files, 'runoff_sag_basin_2017.nc'));
%
% % Create the dummy file(s)
% CopyInfo = makeDummyRunoffFiles(sitename, startyear, endyear, ...
%    path_runoff_files, savefile, 'nobackups');
%
% % Move the dummy 2018 file to the mingpan folder
% movefile(fullfile(path_runoff_files, 'runoff_sag_basin_2018.nc'), ...
%    fullfile(path_runoff_files, 'mingpan'));

%%
cd(path_runoff_save)

% data = ncreaddata(frunoff);

% data = ncreaddata(fsave);
%
% min(data.QDRAI(:))
% max(data.QDRAI(:))
% min(data.QOVER(:))
% max(data.QOVER(:))
%
% sum(isnan(data.QDRAI(:)))
% sum(isnan(data.QOVER(:)))
% sum(isinf(data.QDRAI(:)))
% sum(isinf(data.QOVER(:)))
%
% % use this to see an existing file
% info.runoff = ncinfo(fsave);
% info.domain = ncinfo(fdomain);
% data        = ncreaddata('runoff_test_basin_1979.nc');

data = ncreaddata(['runoff_' opts.sitename '_' num2str(opts.startyear) '.nc']);

% plot the runoff

if opts.checkdata == true

   for n = opts.startyear:opts.endyear

      fsave = fullfile(...
         path_runoff_save, ['runoff_' opts.sitename '_' num2str(n) '.nc']);
      data = ncreaddata(fsave);

      tiledlayout('flow'); nexttile;
      plot(sum(squeeze(data.QDRAI),1));
      ylabel('daily runoff [mm/s]'); nexttile
      plot(cumsum(sum(squeeze(data.QDRAI),1)));
      ylabel('cumulative runoff [mm/s]');
      title(num2str(n));
      pause; clf
   end
end

% for reference, this is the GPCC data used
% pathtemp  = '/Users/coop558/mydata/e3sm/forcing/lnd/dlnd7/hcru_hcru/';
% ftemplate   = [pathtemp 'GPCC.daily.nc'];

% and this is the Ming Pan runoff file Tian made
% pathtemp  = '/Users/coop558/myprojects/e3sm/sag/forcing/';
% frunoff = [pathtemp 'sag_' num2str(n) '_mosart.nc'];

% But Donghui said the dimensions of the runoff forcing files should match
% the dimenisons of the domain file, and my domain file is based on the
% domain_u_icom file from Donghui, which has ni,nj, so I used that one
% above instead of the runoff forcing file from Tian (or the GPCC)
% pathtemp  = '/Users/coop558/mydata/e3sm/input/icom/';
% fdomain = [pathtemp 'domain_u_icom_half_sparse_grid_c200610.nc'];

% BUT since i already have the domain file for the sag setup, i just use
% that one above
