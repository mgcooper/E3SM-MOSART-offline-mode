function [TWD, row, col, dist] = readGcamWaterDemand(lat, lon)

% this was not used in the drbc remapping, it was written for the nyc demand


% read in the GCAM coordinates
list = dir(fullfile(getenv('USER_GCAM_DATA_PATH'), '*.nc'));
LAT = ncread(fullfile(getenv('USER_GCAM_DATA_PATH'), list(1).name),'lat');
LON = wrapTo180(ncread(fullfile(getenv('USER_GCAM_DATA_PATH'), list(1).name),'lon'));
% info = ncinfo(fullfile(getenv('USER_GCAM_DATA_PATH'), list(1).name));

% grid the coordinate vectors
[LON,LAT] = meshgrid(LON,LAT);
LAT = flipud(LAT);

% find the nearest cell to the lat lon
[row, col, dist] = findnearby(LON, LAT, lon, lat);

% get the gcam water demand
TWD = nan(numel(list), 1);
for n = 1:numel(list)
   fname = fullfile(getenv('USER_GCAM_DATA_PATH'), list(n).name);
   v = flipud(permute(ncread(fname, 'totalDemand'), [2,1]));
   TWD(n,:) = v(row, col);
end

% package in a timetable
Time = datetime(1980,1,1):calmonths(1):datetime(2018,12,31);
TWD = array2timetable(TWD, 'RowTimes', Time);
TWD = settableunits(TWD, 'm3 s-1');

% add the lat/lon coordinates as properties
TWD = settableprops(TWD, ...
   {'Lat','Lon', 'row', 'col', 'distanceToGridCell'}, ...
   {'table', 'table', 'table', 'table', 'table'}, {lat, lon, row, col, dist});

% check the units property was set correctly
% tableprops(TWD)
