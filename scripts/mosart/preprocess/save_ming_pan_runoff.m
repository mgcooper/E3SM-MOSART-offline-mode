clean

% this reads the ming pan runoff files and saves the data

% This is not quite right for some reason ... I think I might need to multiply
% the runoff by each hillslope araa, so instead, I just read in the data I saved
% at the end of mk_ats_runoff and saved the ming pan runoff in the data/ folder


% -- temp hack to do above
load('/Users/coop558/work/data/interface/ATS/huc0802_gauge15906000_frozen_a5/ats_pan_runoff.mat')
runoff = removevars(runoff, 'ats');
runoff = renamevars(runoff, 'pan', 'runoff');
save('data/sag_ming_pan_runoff.mat','runoff');
% -- temp hack to do above

%% set the options

savefile = false;
sitename = 'trib_basin';

% These two are used to get the hillslope areas, to convert the ming pan runoff
% to basin m3/s
atsrunID = 'huc0802_gauge15906000_frozen_a5';
fname_hsarea_data = 'huc190604020802_gauge15906000_subcatch_area.xlsx';

opts = const( ...
   'savefile',savefile, ...
   'sitename',sitename, ...
   'startyear',1998, ...
   'endyear',2002, ...
   'runID',atsrunID);

%% build paths

% set the path to the template files - in this case the Ming Pan runoff files
path_runoff_template = ...
   fullfile( ...
   getenv('USER_MOSART_RUNOFF_PATH'), ...
   opts.sitename, ...
   'mingpan');

% set the filename for the output file
path_runoff_save = ...
   fullfile( ...
   getenv('MATLAB_ACTIVE_PROJECT_DATA_PATH'), ...
   ['mingpan_' opts.sitename]);

% set the path to the runoff data - in this case the ats runoff
path_runoff_data = ...
   fullfile( ...
   getenv('USER_ATS_DATA_PATH'), ...
   opts.runID);

% set the filename for the custom area data
fname_hsarea_data = ...
   fullfile( ...
   path_runoff_data, fname_hsarea_data);

%% read the ats table to get the hillslope areas

hsarea = sum(combineHillslopeArea(fname_hsarea_data)); % m2

%% read the ming pan runoff data

time = mkcalendar(datetime(1998,1,1), datetime(2002,12,31), caldays(1), "noleap");
runyears = unique(year(time));
numyears = numel(runyears);

runoff = nan(numel(time), 1);  % initialize runoff

for n = 1:numyears

   nyear = num2str(runyears(n));
   fname = ['runoff_' sitename '_' nyear '.nc'];
   fdata = fullfile(path_runoff_template,fname); % finfo = ncinfo(fcopy);

   [s, e] = chunkLoopInds(n, 1, 365);
   runoff(s:e, 1) = sum(squeeze(permute(ncread(fdata,'QDRAI'),[3 2 1])),2);
end

% convert to basin runoff in m3/s
runoff = runoff.*hsarea/1000;
runoff = array2timetable(runoff,'RowTimes',time);




% % this is right before I switched to passing in the full path to files

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

%-------------------------------------------------------------------------------
% input parsing
%-------------------------------------------------------------------------------
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

% https://www.mathworks.com/help/matlab/matlab_prog/parse-function-inputs.html
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