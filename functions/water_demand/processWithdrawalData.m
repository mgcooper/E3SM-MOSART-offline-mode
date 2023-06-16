function [CUTW, CUSW, CUGW, Time] = processWithdrawalData(Withdrawals)

% The sectors that overlap:
% DRBC: PWS (w/wo SSD), PWR, IND, IRR
% GCAM: municipal, electricity, industrial, agriculture+livestock
% sectors = {'PWS','PWR','IND','IRR'};


% Build lists of subbasins that have data for each category: cusw (consumptive
% use surface water), cugw (consumptive use ground water)
sectors = fieldnames(Withdrawals);
cusw_hucs = cell(numel(sectors),1); % consumptive use 
for n = 1:numel(sectors)
   cusw = gettablevarnames(Withdrawals.(sectors{n}).CUSW);
   cugw = gettablevarnames(Withdrawals.(sectors{n}).CUGW);
   
   % remove the 'DB' prefix to obtain the basin number, which will be used to
   % index into the regularly-shaped arrays
   cusw_hucs{n} = cellfun(@(x) str2double(strrep(x,'DB','')), cusw, 'uni', 1);
   cugw_hucs{n} = cellfun(@(x) str2double(strrep(x,'DB','')), cugw, 'uni', 1);
end

% get all unique huc8 basin numbers to create uniform-size arrays across sectors 
all_unique_hucs = unique([cellflatten(cusw_hucs),cellflatten(cugw_hucs)]);

%% Extract the data for each huc8 and the selected sectors

rows = size(Withdrawals.PWS.CUSW,1);
cols = numel(all_unique_hucs);
CUSW = nan(rows,cols,numel(sectors));
CUGW = nan(rows,cols,numel(sectors));
% inan = true(rows,cols,numel(sectors));

for n = 1:numel(sectors)
   
   % Get the data in array format
   cusw = table2array(Withdrawals.(sectors{n}).CUSW);
   cugw = table2array(Withdrawals.(sectors{n}).CUGW);
   
   % Assign the surface water and groundwater to the columns for this huc8
   CUSW(:,cusw_hucs{n},n) = mgd2cms(cusw);
   CUGW(:,cugw_hucs{n},n) = mgd2cms(cugw);
   %inan(:,huclist{n},n) = isnan(DRBC(:,huclist{n},n));
end

% CUSW and CUGW are nyears x nsubbasins x nsectors

%% Sum total water use across sectors

% Determine which rows (years) and columns (subbasins) are nan for all sectors.
% cusw_inan = all(isnan(CUSW),3);
% cugw_inan = all(isnan(CUGW),3);

% The inan indices above could be used to reset values to NaN after gap-filling,
% but for now, sum acrosss all sectors with omitnan

CUSW = sum(CUSW,3,'omitnan');
CUGW = sum(CUGW,3,'omitnan');
CUTW = sum(cat(3,CUSW,CUGW),3,'omitnan');

Time = Withdrawals.PWS.WDSW.Time;


% DRBC = array2timetable(DRBC,'RowTimes',Time);
% CU = rowsum(DRBC,'addcolumn',false);

