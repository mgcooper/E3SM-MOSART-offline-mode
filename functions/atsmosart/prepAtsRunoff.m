function [roff,time,area] = prepAtsRunoff(fname_area_data,fname_runoff_data,hs_id)

%{ 
the ats hillslopes are ordered by hillsloper hs_id, but mosartslopes are
ordered by 1:numel(links). the links.hs_id field maps between them.

1. read in the ATS runoff spreadsheet
2. read in the ATS hillslope area spreadsheet
3. merge the runoff and area for each hillslope pair
4. convert runoff from m3/d to mm/s 
%}

% ---------------

% read the runoff and area data, merge slopes, and reorder by hs_id
Data = readAtsRunoffTable(fname_runoff_data,hs_id,'mergeslopes');    % m3/d
area = transpose(combineHillslopeArea(fname_area_data,hs_id));       % m2
roff = table2array(Data);
roff = roff./area;                     % m3/d -> m/d
roff = roff.*1000./(24*3600);          % m/d -> mm/s
time = Data.Time;

[ndays,nslopes] = size(roff);
nyears = ndays/365;

% reshape to annual 
roff = reshape(roff,365,nyears,nslopes);
time = reshape(time,365,nyears);




