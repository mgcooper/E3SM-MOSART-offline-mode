clean

% forward and reverse mapping on structured grid is finished, now I need to try
% reverse mapping onto the mesh. Not sure if I should start with forward from
% mesh to poly, probably same either way since reverse mapping happens at the
% end

% This demonstrates how to remap the gcam demand onto the drbc sub-basins.
% Unlike remap_gcam_fullbasin, which computed the weights for the simple clip
% (originally) and then I added the edge weights, this one generates weigths for
% each sub-basin, as if we wanted to map the DRBC onto the sub-basins. It's the
% opposite of what we want, so I can use this to reverse the order and map the
% sub-basins onto the gcam lat-lon, or move onto the mpas mesh 

savedata = false;
pathdata = setpath('e3sm/compyfs/inputdata/waterdemand/','data');

%% read in the basin shapefile

Sdrbc = loadgis('DELW.shp','UseGeoCoords',true);
load('drbc_subbasins.mat','Basins')

% in this case, we have the shape areas, so send them in
PA = [Basins.Meta.Shape_Area].';
PX = {Basins.Bounds.X}.';
PY = {Basins.Bounds.Y}.';

% convert to lat lon then repackage 
[px,py] = polyjoin(PX,PY);
[plat,plon] = utm2ll(px,py,18,'nad83');
[PX,PY] = polysplit(plon,plat);

% figure; 
% geomap(plat,plon); 
% plotm(plat,plon)
% plotm([Sdrbc.Lat],[Sdrbc.Lon],'r');

%% read in the GCAM coordinates

list = dir(fullfile([pathdata '*.nc']));
info = ncinfo([pathdata list(1).name]);
lat = ncread([pathdata list(1).name],'lat');
lon = wrapTo180(ncread([pathdata list(1).name],'lon'));

%% clip the GCAM coordinates to the basin boundary

% grid the coordinate vectors
[LON,LAT] = meshgrid(lon,lat);
LAT = flipud(LAT);

% convert to lists
LAT = LAT(:);
LON = LON(:);

% Read in a sample file
fname = fullfile(pathdata,list(1).name);
V = flipud(permute(ncread(fname,'totalDemand'),[2,1]));

%% First method, mapping cells onto polygons (clip raster)

% % this was the way I sorted it out first, before figuring out how to map
% % polygons onto cells for the lat-lon case before moving to the mesh, but note I
% % never used the W for this case, whcih is the multi-polygon case, which
% % revealed its more complicated for this case
% 
% % Get the interpolation weights
% [~,W,IN,ON,A] = clipRasterByPoly(V,LON,LAT,[PX PY],'weights');
% 
% % NOTE: won't work for multi-polygon output 
% % check the weights - should be a negative number
% % (sum(IN) + sum(ON)) - sum(W) 
% 
% % Use IN or ON to clip the cells, then apply the weights
% I = IN | ON; % sum(I)


%%

% PICK BACK UP - right now the function returns the per-polygon statistics, but
% I want the per-cell stats, so start with the lat-lon cells, map the polygon
% data onto the cells, then move to the mesh

% This maps the CELLS onto the POLYS. Then we pass the result back in and use
% ReverseMapping to test mapping POLYS onto CELLS.
[VP,W] = clipRasterByPoly(V,LON,LAT,[PX PY], ...
   'areasum', ...
   'ReverseMapping', false, ...
   'PolygonAreas',PA);

WIN = horzcat(W{:});
nzc = find(sum(WIN > 0, 2));
WIN = WIN(nzc,:);
XIN = LON(nzc);
YIN = LAT(nzc);
mPX = cellfun(@(x) median(x,'omitnan'),PX);
mPY = cellfun(@(x) median(x,'omitnan'),PY);

figure; 
plotMapGrid(XIN,YIN); hold on;
cellfun(@plot,PX,PY);
scatter(mPX,mPY,100,VP,'filled'); colorbar;

% Now pass VP in and resample it from the POLYS onto the CELLS
[VC,W,IN,ON,A] = clipRasterByPoly(VP,LON,LAT,[PX PY], ...
   'areasum', ...
   'ReverseMapping', true, ...
   'PolygonAreas',PA);
sum(VP)
sum(VC)


% Remap the demand data

%% read the GCAM data and apply conservative clipping

TWD = squeeze(nan([size(LAT(I)),numel(list)]));
for n = 1:numel(list)
   fname = fullfile(pathdata,list(n).name);
   v = flipud(permute(ncread(fname,'totalDemand'),[2,1]));
   TWD(:,n) = v(I).*W(I);
end

% % check it:
% figure; 
% plot(sum(TWD,1,'omitnan')); 
% xylabel('time','total demand (m3/s)')

