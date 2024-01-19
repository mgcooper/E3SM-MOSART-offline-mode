function [newinfo,roff,roffMP] = makeAtsRunoff( ...
                                 site_name, ...
                                 fname_runoff_data, ...
                                 fname_domain_data,...
                                 path_runoff_files, ...
                                 path_runoff_template, ...
                                 save_files, ...
                                 varargin)
   %MAKEATSRUNOFF

   withwarnoff('MATLAB:imagesci:netcdf:varExists')

   % PARSE INPUTS
   opts = optionParser('make_backups', varargin(:));

   % set the filename for the custom area data
   if nargin > 6
      fname_area_data = varargin{1};
   end

   %% load the hillsloper domain data

   load(fname_domain_data, 'links');
   hs_id = [links.hs_ID];

   % plot the hillsloper data if needed for debugging
   % plothillsloper(mosartslopes,links)

   %% create the output path if it doesn't exist

   if ~isfolder(path_runoff_files)
      mkdir(path_runoff_files);
   end

   %% convert the ats data to a netcdf

   % read in the ats runoff spreadsheet
   if strcmp('trib_basin', site_name)
      [roff, time, area] = prepAtsRunoff( ...
         fname_area_data, fname_runoff_data, hs_id);
   elseif strcmp('sag_basin', site_name)
      load(fname_runoff_data, 'Data')
      roff = Data{:, :};
      time = Data.Time;
      area = Data.Properties.CustomProperties.Area;
      roff = roff ./ area;                   % m3/d -> m/d
      roff = roff * 1000 ./ (24 * 3600);     % m/d -> mm/s
      roff = reshape(roff, 365, [], size(roff, 2));
   end

   runyears = unique(year(time));
   [~, nyears, nslopes] = size(roff);

   % initialize an array to store the mingpan runoff, which is returned for
   % comparison with ats runoff
   roffMP = nan(size(roff));

   for n = 1:nyears

      nyear = num2str(runyears(n));
      fname = ['runoff_' site_name '_' nyear '.nc'];
      fcopy = fullfile(path_runoff_template, fname); % finfo = ncinfo(fcopy);
      fsave = fullfile(path_runoff_files, fname);

      % keep the ming pan runoff to compare with ATS
      roffMP(:, n, :) = permute(ncread(fcopy, 'QDRAI'), [3 2 1]);

      if isfile(fsave) && opts.make_backups == true
         fbackup = backupfile(fsave);
         copyfile(fsave, fbackup);
      else
         system(['cp ' fcopy ' ' fsave]);
      end

      % QDRAI
      schem = ncinfo(fcopy, 'QDRAI');
      Qtemp = squeeze(roff(:, n, :));
      QDRAI = nan(nslopes, 1, 365);
      for m = 1:365
         QDRAI(:, 1, m) = Qtemp(m, :);
      end

      if save_files
         % ncwriteschema isn't needed if the file exists, which it will with the
         % system(cp) call above, unless i want to change the schema, which
         % isn't done but there's no harm in keeping it
         ncwriteschema(fsave, schem);
         ncwrite(fsave, 'QDRAI', QDRAI);
      end

      % QOVER
      schem = ncinfo(fcopy, 'QOVER');
      QOVER = 0 * QDRAI;

      if save_files
         ncwriteschema(fsave, schem);
         ncwrite(fsave, 'QOVER', QOVER);
      end
      newinfo = ncinfo(fsave);
   end

   % send back the ats and mingpan runoff as timetables of basin runoff in m3/s
   roff = reshape(roff, 365*nyears, nslopes);
   roff = sum(roff .* area, 2) / 1000;
   roff = array2timetable(roff, 'RowTimes', time);

   roffMP = reshape(roffMP, 365*nyears, nslopes);
   roffMP = sum(roffMP.*area, 2) / 1000;
   roffMP = array2timetable(roffMP, 'RowTimes', time);
end

% this is right before I switched to passing in the full path to files
%
% % set the filename for the ats data
% runpath = fullfile(getenv('USER_ATS_DATA_PATH'),ats_runID);
%
% fname_ats = ...
%    fullfile( ...
%    runpath,ats_fname);
%
% % set the filename for the custom area data
% fname_area = ...
%    fullfile(...
%    runpath,'huc0802_gauge15906000_nopf_subcatch_area.csv');
%
% % set the filename for the hillsloper data
% fname_domain_data = ...
%    fullfile( ...
%    getenv('USER_HILLSLOPER_DATA_PATH'),slopes_fname);
%
% % set the filename for the output file (append runID to runoff_output_path)
% runoff_output_path = ...
%    fullfile( ...
%    runoff_output_path,ats_runID);
%
%
% % load the hillsloper data
% load( ...
%    fname_domain_data,'mosartslopes');
%


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% % from mk_ats_runoff.m before the latest output from Bo that I used when
% making this function. it combines neighboring columns, b/c I organized the
% ats_runoff.mat table for that version in that way.
%
% % combine the ats runoff for each hillslope
% for n = 1:nslopes
%     str1 = ['slope_' num2str(2*n-1) ];
%     str2 = ['slope_' num2str(2*n)];
%     roffATS(:,n) = T.(str1) + T.(str2);
% end
% clear data str1 str2
%
% % convert from m3/d to mm/s
% area    = [slopes.area];                    % m2
% roffATS = roffATS./area;                    % m/d
% roffATS = roffATS*1000/(24*3600);           % mm/s
% roffATS = reshape(roffATS,365,nyears,nslopes);
% timeATS = reshape(timeATS,365,nyears);

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%MAKEATSRUNOFF make ats runoff input file for mosart
%
% Syntax:
%
%  [Z,R] = MAKEATSRUNOFF(ats_runID);
%  [Z,R] = MAKEATSRUNOFF(ats_runID,'name1',value1);
%  [Z,R] = MAKEATSRUNOFF(ats_runID,'name1',value1,'name2',value2);
%  [Z,R] = MAKEATSRUNOFF(___,method). Options: 'flag1','flag2','flag3'.
%        The default method is 'flag1'.
%
%
%  Inputs
%
%     ats_run_ID : char indicating the ATS run ID. Must match the folder name
%     that contains the ATS runoff file, and the ATS runoff file name with .xlsx
%     or .csv appended
%
% Author: Matt Cooper, 10-Nov-2022, https://github.com/mgcooper

% input parsing
% p                 = inputParser;
% p.FunctionName    = 'makeAtsRunoff';
%
% validstrings      = {''}; % or [""]
% validoption       = @(x)any(validatestring(x,validstrings));
%
% addRequired(p,    'ats_runID',            @(x)ischar(x)     );
% addRequired(p,    'ats_fname',            @(x)ischar(x)     );
% addParameter(p,   'namevalue',   false,   @(x)islogical(x)     );
% addOptional(p,    'option',      nan,     validoption          );
%
% parse(p,ats_runID,ats_fname,varargin{:});
%
% namevalue = p.Results.namevalue;
% option = p.Results.option;
%------------------------------------------------------------------------------


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % test start - replace all this with the prepAtsRunoff call above

% % below here is just a copy of make_ats_runoff
% timeATS  = T.Time;
% ndays    = numel(timeATS);
% nslopes  = numel(mosartslopes);
% roffATS  = nan(ndays,nslopes);
% areaATS  = nan(1,nslopes);
%
% runyears = unique(year(timeATS));
% nyears   = numel(runyears);
%
% % this should work for the current T from part 1 above
% for n = 1:nslopes
%     str1 = ['hillslope_' num2str(n) ];
%     str2 = ['hillslope' num2str(n)  ];
%     roffATS(:,n) = T.(str1) + T.(str2);
%     areaATS(n) = A.area_m2_(A.ID==-n) + A.area_m2_(A.ID==n);
% end
% clear data str1 str2
%
% % sum(roffATS(:))
% % test = table2array(T); sum(test(:))
%
% % % this compares the area in the slopes table to the one provided with ats
% % area_slopes = [slopes.area];                       % m2
% % sum(areaATS)/sum(area_slopes)
%
% % convert from m3/d to mm/s
% % roffATS     = roffATS./area_slopes;                % m/d
% roffATS     = roffATS./areaATS;                    % m/d
% roffATS     = roffATS*1000/(24*3600);              % mm/s
% roffATS     = reshape(roffATS,365,nyears,nslopes);
% timeATS     = reshape(timeATS,365,nyears);

% % test end
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
