clean

% this assumes the ming pan data files have already been created, then reads
% those in and replaces the runoff with the ats runoff

%% set the options

savefile = true;
sitename = 'trib_basin';
atsrunID = 'huc0802_gauge15906000_nopf';
fname_domain_data = 'mosart_hillslopes.mat';
fname_runoff_data = 'huc0802_gauge15906000_nopf_discharge_2D.xlsx';
fname_hsarea_data = 'huc0802_gauge15906000_nopf_subcatch_area.csv';

opts = const( ...
   'savefile',savefile, ...
   'sitename',sitename, ...
   'startyear',1998, ...
   'endyear',2002, ...
   'runID',atsrunID);

%% build paths

path_domain_data = ...
   getenv('USER_HILLSLOPER_DATA_PATH');

path_runoff_data = ...
   fullfile( ...
   getenv('USER_ATS_DATA_PATH'), ...
   opts.runID);

path_runoff_template = ...
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'), ...
   opts.sitename, ...
   'mingpan');

% set the filename for the output file
path_runoff_file = ...
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'), ...
   opts.sitename, ...
   'ats', ...
   opts.runID);

%% build filenames

% set the filename for the custom area data
fname_area_data = ...
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

% load the ats runoff data 
[roff,time,area] = prepAtsRunoff(fname_area_data,fname_runoff_data,hs_id);

runyears = unique(year(time));
[~,nyears,nslopes] = size(roff);

roffMP = nan(size(roff));    % initialize ats runoff

for n = 1:nyears

   nyear = num2str(runyears(n));
   fname = ['runoff_' site_name '_' nyear '.nc'];
   fcopy = fullfile(path_runoff_template,fname); % finfo = ncinfo(fcopy);
   fsave = fullfile(path_runoff_file,fname);

   % keep the ming pan runoff to compare with ATS
   roffMP(:,n,:) = permute(ncread(fcopy,'QDRAI'),[3 2 1]);

   if isfile(fsave) && opts.make_backups == true
      fbackup = backupfilename(fsave);
      copyfile(fsave,fbackup);
   else
      system(['cp ' fcopy ' ' fsave]);
   end

   % QDRAI
   schem = ncinfo(fcopy,'QDRAI');
   Qtemp = squeeze(roff(:,n,:));
   QDRAI = nan(nslopes,1,365);
   for m = 1:365
      QDRAI(:,1,m) = Qtemp(m,:);
   end

   if save_file
      % ncwriteschema isn't needed if the file exists, which it will with the
      % system(cp) call above, unless i want to change the schema, which isn't
      % done but there's no harm in keeping it
      ncwriteschema(fsave,schem); 
      ncwrite(fsave,'QDRAI',QDRAI);
   end

   % QOVER
   schem = ncinfo(fcopy,'QOVER');
   QOVER = 0.0.*QDRAI;

   if save_file
      ncwriteschema(fsave,schem);
      ncwrite(fsave,'QOVER',QOVER);
   end
   newinfo = ncinfo(fsave);
end

