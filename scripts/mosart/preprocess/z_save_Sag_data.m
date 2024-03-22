clean

% this script aggregates all the Sag basin data into one structure

% Feb 2024 - made some edits so I could load the data this originally created
% and swap out the full sag hillsloper configuration with the new one

% note: originally this saved the sag_data and sag_data_no_geo to
% data/interface/bfra/matfiles but i moved those to data/interface/sag_basin

% 15910000 = SAGAVANIRKTOK R NR SAGWON AK
% 15908000 = SAGAVANIRKTOK R NR PUMP STA 3 AK

% main sag station runs from 1 Sep 1982 - 31 Oct 2020.
% Curran's 'omit' list has 15910000 as redundant with 15908000
% The former goes from 1971-1978 and I don't think it's in rabpro at all
%
% Sag basin is not in the GRACE list b/c it's too small

save_data = true;
save_shape = true;

update_data = true;

%% set paths
basepath = fullfile(getenv('USERDATAPATH'), 'interface');
% addpath(genpath(basepath))
% This was the only path I could not update since it's on the locked drives
% pathalt = '/Volumes/GDRIVE/DATA/arctic/ABoVE/ALT/';

% Load the existing data struct
if update_data == true
   d1 = load(fullfile(basepath, 'sag_basin/sag_data.mat'));
   d2 = load(fullfile(basepath, 'sag_basin/sag_data_no_geo.mat'));
end

%% load the flow data

load(fullfile(basepath, 'baseflow', 'flow', 'flow_prepped.mat'), 'Flow');
load(fullfile(basepath, 'baseflow', 'basins', 'basin_boundaries.mat'), ...
   'Bounds', 'Meta');
Bounds.Meta = Meta; clear Meta;

load('proj_alaska_albers.mat');
proj = proj_alaska_albers;

c = defaultcolors;

%% 1. Gaged basin data

% THE PROBLEM IS THE GAGED BASIN OUTLINE IT'S OFFSET MUST BE A PROJECTION ISSUE

% get the flow timeseries and remove missing data
Q = Flow.Q(:, contains(Flow.Meta.station, '15908000'));
si = find(~isnan(Q),1,'first');
ei = find(~isnan(Q),1,'last');
Q = Q(si:ei);
T = Flow.T(si:ei);
timespan(T)

% basin metadata
bidx = find(contains(Bounds.Meta.station, '15908000'));
meta = Bounds.Meta(bidx, :);

% gaged basin boundary and gage location
bgeo = Bounds.geo(bidx); % basin boundary
latb = bgeo.Lat;
lonb = bgeo.Lon;
latg = meta.lat;         % gage coordinates
long = meta.lon;

% % REPLACE the gage coords from meta with straight from USGS
latg = 69 + 0/60 + 57/3600;
long = -(148 + 49/60 + 4/3600);

% % CEHCK THE BASIN
proj2 = projcrs(6393,'Authority','EPSG');
[xb2, yb2] = projfwd(proj2, latb, lonb);  % basin
% % Projection isn't the problem, so there's something wrong with the lat,lon,
% possibly a rounding issue

% reproject to alaska albers (bounds has ease, sipsn, and geo)
[xb, yb] = projfwd(proj, latb, lonb);  % basin
[xg, yg] = projfwd(proj, latg, long);  % gage coordinates

% basin polyshapes
polyaka = polyshape(xb, yb);
polygeo = polyshape(lonb, latb);

% basin shapefile in geographic coordinates
basin_geo = geoshape(bgeo);
basin_geo.Metadata = table2struct(meta);

% basin shapefile in alaska albers
basin_aka = mapshape;
basin_aka.Geometry = 'Polygon';
basin_aka.X = xb;
basin_aka.Y = yb;
basin_aka.Metadata = table2struct(meta);

% gage shapefiles in geo and alaska albers
gage_geo = geopoint(latg, long);
gage_aka = mappoint(xg, yg);

% figure; geoshow(basin_geo)
% figure; mapshow(basin_aka)

%% II. Hillsloper / Mosart basin data

% mosart basin boundary and stream network
load(fullfile(basepath, 'hillsloper', 'sag_basin', ...
   'IFSAR-Hillslopes-v2', 'mosart', 'mosart_hillslopes.mat'));
% clear links slopes
tiles = mosartslopes;

% This originally read 'IFSAR-Hillslopes/Sag_hillslopes_boundary.shp'. In -v2
% that file is named Sag_boundary.shp.
basin_hs_aka = shaperead(fullfile(basepath, 'hillsloper', 'sag_basin', ...
   'IFSAR-Hillslopes-v2', 'Sag_boundary.shp'));

% I think I merged all the links into one shapefile, so use that
% This file does not exist in -v2. This is the merged links as one feature. I
% tried to save it using c_write_slopes_shapefile but it took forevor and wasn't
% workign for the merged files so I defered on it - I don't think the merged
% shapefile is sued, instead I can just use geostructCoordinates to put them in
% a nan-delimeted list if needed.
%
% links_hs_aka = shaperead(fullfile(basepath, 'hillsloper', 'sag_basin', ...
%    'sag_links_mosart.shp'));


% basin and link x,y
xb_hs = basin_hs_aka.X;
yb_hs = basin_hs_aka.Y;

% xl_hs = links_hs_aka.X;
% yl_hs = links_hs_aka.Y;

% Get the nan delimited coordinates directly from links instead
[xl_hs, yl_hs] = geostructCoordinates(links, 'projected');

% unproject to lat lon
[latb_hs, lonb_hs] = projinv(proj, xb_hs, yb_hs);
[latl_hs, lonl_hs] = projinv(proj, xl_hs, yl_hs);

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% Not sure why this is necessary - why not just use the basin_hs_aka x,y
% coordinates, I guess b/c it's nice to have a polyshape

% basin polyshapes (polyshape fails on latbhs,lonbhs so I use method below)
poly_hs_aka = polyshape(xb_hs, yb_hs);
poly_hs_geo = polyshape(lonb_hs, latb_hs);

% if polyshape fails:
% [lt, ln] = projinv(proj, poly_hs_aka.Vertices(:,1), poly_hs_aka.Vertices(:,2));
% poly_hs_geo = polyshape(ln, lt);

% If it does not fail:
ln = poly_hs_geo.Vertices(:, 1);
lt = poly_hs_geo.Vertices(:, 2);
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% basin shapefile in alaska albers coordinates
basin_hs_aka = mapshape(basin_hs_aka);
links_hs_aka = mapshape(xl_hs, yl_hs);
% If reading in the merged links shapefile:
% links_hs_aka = mapshape(links_hs_aka);

% basin shapefile in geographic coordinates
basin_hs_geo = geoshape;
basin_hs_geo.Geometry = 'Polygon';
basin_hs_geo.Latitude = lt;
basin_hs_geo.Longitude = ln;

% links shapefile in geographic coordinates
links_hs_geo = geoshape;
links_hs_geo.Geometry = 'line';
links_hs_geo.Latitude = latl_hs;
links_hs_geo.Longitude = lonl_hs;

% the tiles need an X,Y field mapped from teh lat,lon field
tiles_lat = [tiles.lat];
tiles_lon = [tiles.lon];
[tiles_x, tiles_y] = projfwd(proj, tiles_lat, tiles_lon);

for n = 1:numel(tiles_lat)
   tiles(n).X = tiles_x(n);
   tiles(n).Y = tiles_y(n);
end

% build polyshapes for each hillslope
for n = 1:numel(tiles_lat)
   tiles(n).polyhs = polyshape(tiles(n).X_hs, tiles(n).Y_hs);
end

%% find the outlet hillslope (ideally only run this once).

% The gage locatioin is probably due to the precision of the lat lon
% the discrepancy matters b/c the gage hillslope is used to find the outlet
% link, whereas the slopes ... actually maybe it doesn't matter for the specific
% purpose of comparing discharge ... yes I don't think it does, BUT I ruled out
% the gage precision, that's correct, so just use the outlet ID

% NOTE: this is the linear index of the slope in [tiles] not the ID

% outID = mos_findgage([tiles.polyhs], xg, yg); % outID = 2634
outID = 2614; % old config: 2634;

% plot the polygon with the found gage
figure
plot(tiles_hs(outID).polyhs); hold on
plot(xg, yg, 'o')
formatPlotMarkers('markersize', 10)
axis equal
xlabel('eastings [m]')
ylabel('northings [m]')

%% find the hillslopes within the gaged basin
mask = maskbasin(tiles, xb, yb);
tiles_hs = tiles;
tiles = tiles(mask);

figure
plot([tiles.polyhs]); hold on
plot(xg, yg, 'o')
plot(xb, yb, 'LineWidth', 2, 'Color', rgb('dark green'))
formatPlotMarkers('markersize', 20)
axis equal
xlabel('eastings [m]')
ylabel('northings [m]')

plot(basin_hs_aka.X, basin_hs_aka.Y, '--', ...
   'LineWidth', 2, 'Color', rgb('blue'))


%% III. Topo data

if ~update_data
   ftopo = 'IfSAR_5m_DTM_Alaska_Albers_Sag_basin_hillsloper_100m.tif';
   [Z,R] = readgeoraster( ...
      fullfile(basepath, 'GIS_data', 'IFSAR', 'IfSAR_basin', ftopo));
   Z(Z == 0) = nan;
   Zbase = zeros(size(Z));
else
   Z = d1.sag.topo.Z;
   R = d1.sag.topo.R;
end

% leaving it at this for now

% % ALT data
% fsat = [pathalt 'Sat_ActiveLayer_Thickness_Maps_1760/data/'];
% fsat = [fsat 'Alaska_active_layer_thickness_1km_2001-2015.nc4'];
% ALT = read_satALTak(fsat);


%% package the data w/o any mapping toolbox objects


sag.flow = Q;
sag.time = T;
sag.meta = meta;
sag.units = {'flow = cms/day'};
sag.outID = outID;
sag.geo.basin_lat = latb;
sag.geo.basin_lon = lonb;
sag.geo.basin_poly = polygeo;
sag.aka.basin_x = xb;
sag.aka.basin_y = yb;
sag.aka.basin_poly = polyaka;
sag.geo.gage_lat = latg;
sag.geo.gage_lon = long;
sag.aka.gage_x = xg;
sag.aka.gage_y = yg;
sag.geo.basin_hs_lat = latb_hs;
sag.geo.basin_hs_lon = lonb_hs;
sag.geo.basin_hs_poly = poly_hs_geo;
sag.aka.basin_hs_x = xb_hs;
sag.aka.basin_hs_y = yb_hs;
sag.aka.basin_hs_poly = poly_hs_aka;
sag.geo.links_hs_lat = latl_hs;
sag.geo.links_hs_lon = lonl_hs;
sag.aka.links_hs_x = xl_hs;
sag.aka.links_hs_y = yl_hs;
sag.topo.Z = Z;
sag.topo.R = R;
sag.mask = mask';
sag.tiles = tiles;
sag.tiles_hs = tiles_hs;

% save the no-geo version
if save_data == true
   filename = fullfile(basepath, 'sag_basin', 'sag_data_no_geo.mat');
   if update_data
      % Back up the old data
      ftemp = backupfile(filename);
      copyfile(filename, ftemp);
   end
   % Save the new data
   save(filename, 'sag');
end


%% package the data w the mapping toolbox objects
sag.proj = proj;
sag.geo.basin = basin_geo;
sag.aka.basin = basin_aka;
sag.geo.gage = gage_geo;
sag.aka.gage = gage_aka;
sag.geo.basin_hs = basin_hs_geo;
sag.aka.basin_hs = basin_hs_aka;
sag.geo.links_hs = links_hs_geo;
sag.aka.links_hs = links_hs_aka;
sag.topo.R = R;


%% save the data

if save_data == true
   filename = fullfile(basepath, 'sag_basin', 'sag_data.mat');
   if update_data
      % Back up the old data
      ftemp = backupfile(filename);
      copyfile(filename, ftemp);
   end
   % Save the new data
   save(filename, 'sag');
end

% save the shapefiles
if save_shape == true
   shapewrite(basin_geo, fullfile(basepath, 'GIS_data', 'sag_basin_15908000_geo.shp'));
   shapewrite(basin_aka, fullfile(basepath, 'GIS_data', 'sag_basin_15908000_aka.shp'));
end


%% plot the data


% plot the basin boundary and streams
pspec = makesymbolspec('Point',{'Marker','s','MarkerSize',40'});
bspec = makesymbolspec('Polygon',{'Default','FaceColor',c(1,:),'FaceAlpha',0.5});
lspec = makesymbolspec('Line',{'Default','Color',c(1,:),'LineWidth',1});

% plot the catchment boundary and gage
maxfig
% mapshow(Zbase,R,'CData',Z,'DisplayType','surface'); hold on;
mapshow(basin_hs_aka,'SymbolSpec',bspec); hold on
mapshow(links_hs_aka,'SymbolSpec',lspec);
plot(polyaka,'FaceColor',c(4,:))
myscatter(xg,yg,c(2,:),40);
axis tight
axis equal

% confirm I can plot w/o mapping toolbox
maxfig
plot(poly_hs_aka,'FaceColor',c(1,:)); hold on;
plot(polyaka,'FaceColor',c(4,:))
plot(xl_hs,yl_hs,'Color','g');
myscatter(xg,yg,c(2,:),40)

% check them
maxfig
geoshow(basin_hs_geo);
hold on
plot(poly_hs_geo);
plot(lonb_hs, latb_hs);
plot(lonb,latb); % mapshow(links_hs_geo)

maxfig
mapshow(basin_hs_aka); hold on; plot(poly_hs_aka);
plot(xb_hs,yb_hs); plot(xb,yb); %mapshow(links_hs_aka)

% plot the masked hillslopes
for n = 1:numel(tiles)
   mapshow(tiles(n).X_hs,tiles(n).Y_hs);
end

% plot the flow data
figure; plot(T,Q); ylabel('Flow [cms]')


%% extra stuff


% % for reference
% sag.basinhs_geo = basin_hs_geo;
% sag.basinhs_aka = basin_hs_aka;
% sag.linkshs_geo = linkshs_geo;
% sag.linkshs_aka = links_hs_aka;
% sag.polyhs_geo = poly_hs_geo;
% sag.polyhs.aka = poly_hs_aka;
% sag.bounds_hs = basin_hs_aka;
% sag.streams = linkshs;
% sag.Ztopo = Z;
% sag.Rtopo = R;
% sag.poly_hs = poly_hs_aka;
%
% % remove the mapping toolbox stuff and resave
% sag0 = sag;
% sag = rmfield(sag,'proj');
% sag = rmfield(sag,'Rtopo');

% sag = rmfield(sag,{'bgeo','bounds_geo','bounds_aka','bounds_hs','Rtopo','proj'});

% for reference:
% Q
% T
% meta
% latb, lonb, xb, yb, xb_hs, yb_hs, latb_hs, lonb_hs
% latg, long, xg, yg, gage_geo, gage_aka
% poly_aka, poly_geo, poly_hs_aka, poly_hs_geo
% basin_aka, basin_geo, basin_hs_aka, basin_hs_geo
% xl_hs, yl_hs, latl_hs, lonl_hs
% links_hs_aka, links_hs_geo,


% the data:
% gaged flow
% gaged time
% metadata
% gaged basin, geo coords
% gaged basin, aka coords
% gage coordinates, geo coords
% gage coordinates, aka coords
% gaged basin, polyshape geo coords
% gaged basin, polyshape aka coords
% gaged basin, topo
% projection info

% hillsloper basin, geo coords
% hillsloper basin, aka coords
% hillsloper links, geo coords
% hillsloper links, aka coords
% hillsloper topo

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% no longer needed
% update the metadata
% meta.area_m2 = Bounds.ease(bidx).area_m2;
% meta.perm_mean = Bounds.ease(bidx).perm_mean;
% meta.perm_median = Bounds.ease(bidx).perm_media;
% meta.perm_stdev = Bounds.ease(bidx).perm_stdev;
%

% the trib - for reference (only 74 km2 and goes frozen)
% load([pathflow 'flow_prepped.mat']);
% idx = find(contains(FLOW.meta.name,'SAGAVANIRKTOK R TRIB'));
% flow = FLOW.Q(:,idx);
% time = FLOW.T;
% figure; plot(time,flow)


% % just in case, the full list
% sag.flow = Q;
% sag.time = T;
% sag.meta = meta;
% sag.units = {'flow = cms/day'};
% sag.proj = proj;
% sag.geo.basin = basin_geo;
% sag.geo.basin_lat = latb;
% sag.geo.basin_lon = lonb;
% sag.geo.basin_poly = polygeo;
% sag.aka.basin = basin_aka;
% sag.aka.basin_x = xb;
% sag.aka.basin_y = yb;
% sag.aka.basin_poly = polyaka;
% sag.geo.gage = gage_geo;
% sag.geo.gage_lat = latg;
% sag.geo.gage_lon = long;
% sag.aka.gage = gage_aka;
% sag.aka.gage_x = xg;
% sag.aka.gage_y = yg;
% sag.geo.basin_hs = basin_hs_geo;
% sag.geo.basin_hs_lat = latb_hs;
% sag.geo.basin_hs_lon = lonb_hs;
% sag.geo.basin_hs_poly = poly_hs_geo;
% sag.aka.basin_hs = basin_hs_aka;
% sag.aka.basin_hs_x = xb_hs;
% sag.aka.basin_hs_y = yb_hs;
% sag.aka.basin_hs_poly = poly_hs_aka;
% sag.geo.links_hs = links_hs_geo;
% sag.geo.links_hs_lat = latl_hs;
% sag.geo.links_hs_lon = lonl_hs;
% sag.aka.links_hs = links_hs_aka;
% sag.aka.links_hs_x = xl_hs;
% sag.aka.links_hs_y = yl_hs;
% sag.topo.Z = Z;
% sag.topo.R = R;
