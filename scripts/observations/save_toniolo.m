clean

% Read and save the Toniolo discharge observations for Sag River

% To pick up on this, Need to read in each sheet and organize, but more
% difficult is assigning a vector reach to each gage, see notes below, basically
% I think all of htem except DSS4 and ASS1 should work

% mgc: The data were either .xlsx or .csv. I converted the .csv to .xlsx for a
% consistent workflow, but retained the og .csv files.

% Note the table may be wrong in terms of the "Data Type" column e.g. "Q"
% indicates discharge, the table does not list Q for ASS1, but there is ASS1
% discharge, but it's the only one missing "Q" in the table, and it is included
% in the folders ie. the

% I compared the sites in qgis to the map Fig 1 in Toniolo - the two sites which
% are outside the Sag boundary we used are ABPB (BP Bridge), DSS1, and ASD3
% of those, two are ones I named (ABPB and ASD3), and one (ASD3) is not included
% on the Toniolo map. The one which is outside the bounds but could be useful is
% DSS1. But it's in the braided zone along the reach we excluded.

% TLDR: Exclude DSS1 from any analysis of ATS-MOSART vs discharge obs. Possibly
% exclude ABPB and ASD3 from any meteorological analysis. These three stations
% are outside our delineation.

% The ones with discharge according to the table:
% DSS1 - exclude, on second, west "mainstem" outside our delineation
% DSS2 - keep, snap to nearest flowline should work
% DSS3 - keep, snap to nearest flowline should work
% DSS4 - keep, requires detailed investigation to determine right flowline
% DSS5 - keep, on east mainstem inside our delination, snap nearest should work
% ASS1 - keep, but snap to nearest may not work, see notes



% notes on each site by comparing it in qgis to the vector flowline vs the map
%
% DSS5: should be a good choice for the lowermost gage, it is along the same
% "main stem" that we use in our delineation, upstream of where it appears to
% braid off into the second "main stem" which we exclude, but which ABPB/DSS1
% are along.
%
% DSS2: close to the "main stem" in the narrows, should be able to find nearest
% flowline and snap to it
%
% ASS1: might not be on the right flowline, appears to be one too far to the
% west
%
% DSS4: Most upstream, nearest vector flowline is a headwater trib, seems very
% unlikely this is the right flowline, Toniolo Fig. 1 too coarse to tell, need
% higher resolution figure
%
% UPDATE on DSS4: See Fig. 4 in report, turn on the basemap in qgis, it's clear
% the site is located correctly near the Dalton HWY, but the nearest reach is
% not the right one, need to manually assign it to the main stem Sag
%
% DSS3: looks good


%% Description

% Data as taken from Hydrological,  Sedimentological, and Meteorological
% Observations and Analysis of the Sagavanirktok River: 2019 Final Report.
% (Toniolo et. al.)

% Data are for sites in Sagavanirktok River basin, sites as defined in:
% [Table1](https://docs.google.com/spreadsheets/d/13hIb03w6m7JVK8RT3drzREKOWPcwYnLVDNwLtN7S2hs/).
%
% Data may come from tables in main report body, appendix D, or appendix G (the
% included data DVD).

%%% file name descriptions:
% - files named `table-[N]-[name].xlsx` are from the main text
% - files named `table-D[N]-[name].xlsx` are from appendix D
% - files named `[site-id]_[site-name]_*.csv` are derived from the data in
%   appendix G.

% Files are sorted in to subdirectories by site if there are multiple files

%%% Citation
% H. Toniolo, E.K. Youcha, A. Bondurant, I. Ladines, J. Keech, D. Vas, E.
% LaMesjerant, andJ. Bailey (2020). Hydrological,  Sedimentological, and
% Meteorological Observations and Analysis of the Sagavanirktok River: 2019
% Final Report. University of Alaska Fairbanks, Water and Environmental Research
% Center, Report INE/WERC 20.01, Fairbanks, AK.

%% Set the path and read the metadata table
pathdata = fullfile(getenv('USERDATAPATH'), 'interface', ...
   'Discharge_River', 'Sagavanirktok River', 'Toniolo_2020_report');

% Read the metadata table
metadata = readtable(fullfile(pathdata, "site_data.xlsx"));
metadata = renamevars(metadata, ["Latitude_WGS84_", "Longitude_WGS84_"], ...
   ["latitude", "longitude"]);

%% Read the discharge data

% Should be the [site-id]_[site-name]_*.xlsx files, they contain the discharge
% reconstructed from stage. The table-*.xlsx files are the raw adcp data.

filelist = listfiles(pathdata, pattern="discharge.xlsx", ...
   subfolders=true, aslist=true, asstring=true, fullpath=true);

runoff = cell(numel(filelist), 1);
flags = cell(numel(filelist), 1);
tspan = NaT(numel(filelist), 2);
for n = 1:numel(filelist)
   
   % Get the filename, the sitename from the filename, 
   % and remove the sitename column from the table.
   thisfile = filelist(n);
   [~, thisname] = fileparts(thisfile);
   thisname = char(thisname);
   thisname = thisname(1:4);
   thisdata = readtimetable(thisfile);
   thisdata = removevars(thisdata, "StationID");
   
   % Get the timespan of this data
   tspan(n, :) = timespan(thisdata);
   
   % Separate the table into discharge and flags
   flags{n} = removevars(thisdata, "Discharge_m3_s_");
   thisdata = removevars(thisdata, "DischargeFlag");
   thisdata = renamevars(thisdata, "Discharge_m3_s_", thisname);
   
   % Flags 7777, 6999 exist in the Discharge column, not DischargeFlag
   thisdata{thisdata.(thisname) == 7777, :} = NaN;
   thisdata{thisdata.(thisname) == 6999, :} = NaN;
   
   runoff{n} = thisdata;
end

%% Synchronize the runoff timetables to a common hourly calendar
func = @(x) mean(x, 'omitnan');
Data = synchronize(runoff{:}, 'hourly', func, 'IncludedEdge', 'left');
Data = renametimetabletimevar(Data);

% Add units property
Data = settableprops(Data, 'units', 'table', 'm3 s-1');

% Add locations
latitude = metadata.latitude( ...
   ismember(metadata.SiteID, Data.Properties.VariableNames));
longitude = metadata.longitude( ...
   ismember(metadata.SiteID, Data.Properties.VariableNames));
Data = settableprops(Data, 'latitude', 'variable', latitude);
Data = settableprops(Data, 'longitude', 'variable', longitude);

%% Synchronize the flags timetables to a common hourly calendar

% This shows that there are no actual flags other than the 7777 and 6999 ones
% which were in the Discharge column and set nan above, so I don't save the
% flags data or do any further processing.
for n = 1:numel(flags)
   tmp = flags{n};
   unique(tmp.DischargeFlag(~isnan(tmp.DischargeFlag)))
end

% Flags dictionary
Flags.Ice = "ice affected stage";
Flags.EST = "Estimated";
Flags.M = "Measured";

% Ice-Ice affected stage, 
% EST-Estimated, 
% M-Measured, 
% 7777-data not collected, 
% 6999-bad/missing

%% Plots

Data = renametimetabletimevar(Data);

figure
plot(Data.Time, Data{:, :})
legend(Data.Properties.VariableNames)

% All of the DSS5 data is missing
figure
plot(Data.Time, Data.DSS5)

%% Save the data

if savedata == true

   % Save a matfile
   filename = fullfile(getenv('USERDATAPATH'), 'interface', 'sag_basin', ...
      'sag_toniolo_discharge.mat');
   save(filename, 'Data')
   
   % Save a shapefile
   filename = fullfile(getenv('USERGISPATH'), 'sag_toniolo_sites.shp');

   % Convert to a geostruct and write the shapefile
   S = table2geostruct(metadata, "geometry", "Point");
   writeGeoShapefile(S, filename)

   % For reference, I thought if I created a geotable it might write the .prj
   % file, which is the purpose of writeGeoShapefile, but it did not.
   % GT = table2geotable(metadata);
   % GT.Shape.GeographicCRS = projwgs84();
   % shapewrite(GT, filename);

end


