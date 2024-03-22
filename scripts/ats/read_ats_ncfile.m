clean

savedata = false;

% I uploaded a data file of all hillslopes into
%
% https://drive.google.com/drive/u/0/folders/1ew39d-_qJJ0j53q7eN3H7hsjPIiVTgSx .
%
% This data file includes area, waterbody fraction, longitude and latitude at
% each sub-catchment centroid, and 5-year discharges starting from 1/1/2014 of
% each hillslope. I used hillslope id as the group name of this data file, for
% example, group with path “/n3250” includes all above variables of hillslope
% id=-3250; and group with path “/3250” includes all above variables of
% hillslope id=3250.
%
% Let me know if you have any question about this data file, or if you need
% other variables, or if you want to change it to other types.

filepath = '/Users/coop558/work/data/interface/ATS';
filename = fullfile(filepath, 'sag_hillslope_discharge.nc');

fileinfo = ncinfo(filename);

% Read the hillslope (group) names
groupnames = {fileinfo.Groups.Name};

% Define the variables
varnames = {fileinfo.Groups(1).Variables.Name};

% Remove "discharge" - it is the only non-scalar data
varnames = varnames(1:end-1);

%% Read the data

% Open NetCDF file
ncid = netcdf.open(filename, 'NC_NOWRITE');

% Read the time
timeVarID = netcdf.inqVarID(ncid, 'times');
Time = netcdf.getVar(ncid, timeVarID);

% Get group id's
groupIDs = netcdf.inqGrps(ncid);
numGroups = length(groupIDs);

% Preallocate the discharge array
discharge = zeros(numel(Time), numGroups);   % m3/day
hsarea = zeros(1, numGroups);                % m2
wbfrac = zeros(1, numGroups);                % 1
lon = zeros(1, numGroups);                   % oE
lat = zeros(1, numGroups);                   % oN

% Read discharge from each group
for n = 1:numGroups

   varID = netcdf.inqVarID(groupIDs(n), 'discharge');
   discharge(:, n) = netcdf.getVar(groupIDs(n), varID);

   varID = netcdf.inqVarID(groupIDs(n), 'area');
   hsarea(n) = netcdf.getVar(groupIDs(n), varID);

   varID = netcdf.inqVarID(groupIDs(n), 'waterbody_fraction');
   wbfrac(n) = netcdf.getVar(groupIDs(n), varID);

   varID = netcdf.inqVarID(groupIDs(n), 'longitude');
   lon(n) = netcdf.getVar(groupIDs(n), varID);

   varID = netcdf.inqVarID(groupIDs(n), 'latitude');
   lat(n) = netcdf.getVar(groupIDs(n), varID);

   % % This automates it
   % for m = 1:numel(varnames)
   %    varID = netcdf.inqVarID(groupIDs(n), varnames{m});
   %    atts.(varnames{m})(n) = netcdf.getVar(groupIDs(n), varID);
   % end
end

% Close the NetCDF file
netcdf.close(ncid);

%% Combine positive and negative hillslopes

for n = 1:numel(groupnames)/2
   name_n = groupnames{n};
   name_p = strrep(name_n, 'n', '');
   idx_n = n;
   idx_p = find(ismember(groupnames, name_p));

   % discharge(:, n) = discharge(:, idx_n) + discharge(:, idx_p);
   hsarea(n) = hsarea(idx_n) + hsarea(idx_p);
   wbfrac(n) = (wbfrac(idx_n) * hsarea(idx_n) + wbfrac(idx_p) * hsarea(idx_p)) / hsarea(n);
   lat(n) = (lat(idx_n) + lat(idx_p)) / 2;
   lon(n) = (lon(idx_n) + lon(idx_p)) / 2;
end

% Remove the columns following the combined values
% discharge = discharge(:, 1:numel(groupnames)/2);
hsarea = hsarea(:, 1:numel(groupnames)/2);
wbfrac = wbfrac(:, 1:numel(groupnames)/2);
lon = lon(:, 1:numel(groupnames)/2);
lat = lat(:, 1:numel(groupnames)/2);

% figure; scatter(lon, lat, 20, mean(discharge), 'filled'); colorbar

%% Flip so the ordering is 1:3249

slopes = fliplr(strrep(groupnames(1:numel(groupnames)/2), 'n', 'hs'));
discharge = fliplr(discharge);
hsarea = fliplr(hsarea);
wbfrac = fliplr(wbfrac);
lon = fliplr(lon);
lat = fliplr(lat);

%% Convert to timetable

Time = datetime(2014, 1, 1) + days(Time);
Data = array2timetable(discharge, 'RowTimes', Time, 'VariableNames', slopes);

% Add the attributes
Data = settableprops(Data, {'Area', 'WaterFrac', 'Lon', 'Lat'}, ...
   'table', {hsarea, wbfrac, lon, lat});

%% Save the data
if savedata == true
   save(strrep(filename, '.nc', '.mat'), "Data");
end

%% This automates reading the attributes

% % Preallocate attribute arrays
% for n = 1:numel(varnames)
%    atts.(varnames{n}) = zeros(1, numGroups);
% end
%
% for n = 1:numGroups
%
%    for m = 1:numel(varnames)
%       varID = netcdf.inqVarID(groupIDs(n), varnames{m});
%       atts.(varnames{m})(n) = netcdf.getVar(groupIDs(n), varID);
%    end
% end

%% Things that were not needed but may be useful

% [ndims, nvars, ngatts, unlimdimid] = netcdf.inq(ncid);

% % Read the group names - not actually needed
% groupnames = cell(1, numGroups);
% for n = 1:numGroups
%    groupnames{n} = strrep(netcdf.inqGrpNameFull(groupIDs(n)), '/', '');
% end

%% For reference, the "standard" way that takes forever

% % Read the time
% Time = ncread(filename, 'times');
%
% % Read the groupnames and the
% groupnames = {fileinfo.Groups.Name};
% discharge = zeros(numel(Time), numel(groupnames));
%
% for n = 1:numel(groupnames)
%    discharge(:, n) = ncread(filename, [groupnames{n} '/discharge']);
% end
