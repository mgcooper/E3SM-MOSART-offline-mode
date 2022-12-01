function [newinfo,roffATS,roffMP] = makeAtsRunoff(ats_runID,ats_fname, ...
   slopes_fname,site_name,runoff_output_path,save_file,runoff_template_path,varargin)
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

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
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

runpath     = [getenv('USER_ATS_DATA_PATH') filesep ats_runID];
fname_ats   = [runpath filesep ats_fname];

fname_slopes = [getenv('USER_HILLSLOPER_DATA_PATH') filesep slopes_fname];

% load the hillsloper data
load(fname_slopes,'mosartslopes'); slopes = mosartslopes; clear mosartslopes;

fname_area = 'huc0802_gauge15906000_nopf_subcatch_area.csv';
fname_area = [runpath filesep fname_area];

% append the runID to the runoff_output_path
runoff_output_path = [runoff_output_path filesep ats_runID];

% create the output path if it doesn't exist
if ~exist(runoff_output_path,'dir')
   mkdir(runoff_output_path);
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% below here is just a copy of the most recent read_ats_hillslope_ensemble (v3)

% these data are just columns of runoff
T     = readfiles(fname_ats,'dataoutputtype','timetable');
T     = settableunits(T,'m3/d');

% read the area. the negative numbers are underscores in the runoff table, add 
A     = readfiles(fname_area);

% the new spreadsheet doesn't convert to a timetable using readfiles. the first
% three columns are year, doy, doy (repeated). So remove them, build a calendar,
% and convert to timetable: Time  = datetime(T(:,1)+T(:,2)./365)
years = T.year;
doy   = T.doy;
Time  = datetime(years(1),1,1):caldays(1):datetime(years(end),12,31);
Time  = rmleapinds(Time);
T     = T(:,4:end);
T     = table2timetable(T,'RowTimes',Time);

% R = sum(table2array(T),2); plot(R)
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% below here is just a copy of make_ats_runoff

timeATS  = T.Time;
ndays    = numel(timeATS);
nslopes  = numel(slopes);
roffATS  = nan(ndays,nslopes);
areaATS  = nan(1,nslopes);

runyears = unique(year(timeATS));
nyears   = numel(runyears);

% % % this combines neighboring columns, i think it worked for v2 meaning that
% % table must have been organized as such
% % combine the ats runoff for each hillslope
% for n = 1:nslopes
%     str1 = ['slope_' num2str(2*n-1) ];
%     str2 = ['slope_' num2str(2*n)];
%     roffATS(:,n) = T.(str1) + T.(str2);
% end
% clear data str1 str2

% this should work for the current T from part 1 above
for n = 1:nslopes
    str1 = ['hillslope_' num2str(n) ];
    str2 = ['hillslope' num2str(n)  ];
    roffATS(:,n) = T.(str1) + T.(str2);
    areaATS(n) = A.area_m2_(A.ID==-n) + A.area_m2_(A.ID==n);
end
clear data str1 str2

% sum(roffATS(:))
% test = table2array(T); sum(test(:))

% % this compares the area in the slopes table to the one provided with ats
% area_slopes = [slopes.area];                       % m2
% sum(areaATS)/sum(area_slopes)

% convert from m3/d to mm/s
% roffATS     = roffATS./area_slopes;                % m/d
roffATS     = roffATS./areaATS;                    % m/d
roffATS     = roffATS*1000/(24*3600);              % mm/s
roffATS     = reshape(roffATS,365,nyears,nslopes);
timeATS     = reshape(timeATS,365,nyears);


% % % % % % % % % % % % % % 
% % this is still make_ats_runoff but separating it cuz its the next major part


% convert the ats data to a netcdf

roffMP  = nan(size(roffATS));    % initialize ats runoff

for n = 1:nyears
    
    thisyear = num2str(runyears(n));
    frunoff = [runoff_template_path filesep 'runoff_' site_name '_' thisyear '.nc'];
    fsave   = [runoff_output_path filesep 'runoff_' site_name '_' thisyear '.nc'];
    
    % keep the ming pan runoff to compare with ATS
    roffMP(:,n,:) = permute(ncread(frunoff,'QDRAI'),[3 2 1]);
    
    if ~exist(fsave,'file')
        system(['cp ' frunoff ' ' fsave]);
    end
    
    % QDRAI
    var     = 'QDRAI';
    sch     = ncinfo(frunoff,var);
    Qtmp    = squeeze(roffATS(:,n,:));
    QDRAI   = nan(nslopes,1,365);
    for m = 1:365
        QDRAI(:,1,m) = Qtmp(m,:);
    end

    if save_file
        %ncwriteschema(fsave,sch); % this shouldn't be needed if the file exists
        %and i can get the schema from it, unless i want to change the schmea i
        %am not sure why this was here
        ncwrite(fsave,var,QDRAI);
    end

    % QOVER
    var     = 'QOVER';
    sch     = ncinfo(frunoff,var);
    QOVER   = 0.0.*QDRAI;
    
    if save_file
        %ncwriteschema(fsave,sch);
        ncwrite(fsave,var,QOVER);
    end

    newinfo = ncinfo(fsave);

end

% send back the ats and mingpan runoff as timetables of basin runoff in m3/s
roffATS  = reshape(roffATS,365*nyears,nslopes);
roffATS  = sum(roffATS.*area,2)/1000;
roffMP   = reshape(roffMP,365*nyears,nslopes);
roffMP   = sum(roffMP.*area,2)/1000;
roffATS  = array2timetable(roffATS,'RowTimes',Time);
roffMP   = array2timetable(roffMP,'RowTimes',Time);












