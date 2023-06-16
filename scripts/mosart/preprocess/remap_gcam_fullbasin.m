clean

% This clips the GCAM grid cells that overlap the DRB and saves the TWD
% timetable of demand for each grid cell as GCAM_waterdemand.mat.

% mk_water_demand was supposed to do the remapping onto the mesh, but right now
% it reads in the TWD timetable and compares with the DRBC subbasin demand data
% and makes the bar plot. 

% It uses the conservative clipping around the edges, and I confirmed it is
% nearly identical to the naive clipping I did earlier, so I did not resave the
% data, since this is mainly for comparison with DRBC sub-basin data, summed
% over the basin.

savedata = false;
pathdata = setpath('e3sm/compyfs/inputdata/waterdemand/','data');

%% read in the basin shapefile

Sdrbc = loadgis('DELW.shp','UseGeoCoords',true);
PX = wrapTo360(Sdrbc.Lon);
PY = Sdrbc.Lat;
P = polyshape(PX,PY);

%% read in the GCAM coordinates

list = dir(fullfile([pathdata '*.nc']));
info = ncinfo([pathdata list(1).name]);
lat = ncread([pathdata list(1).name],'lat');
lon = ncread([pathdata list(1).name],'lon');

%% clip the GCAM coordinates to the basin boundary

% grid the coordinate vectors
[LON,LAT] = meshgrid(lon,lat);
LAT = flipud(LAT);

% convert to lists
LAT = LAT(:);
LON = LON(:);

% Get the interpolation weights
[~,W,IN,ON,A] = clipRasterByPoly(LON,LON,LAT,P,'weights');

% check the weights - should be a positive number representing the 
% grid cells removed due to partial overlap
% (sum(IN) + sum(ON)) - sum(W) 

% Use IN or ON to clip the cells, then apply the weights
I = IN | ON; % sum(I)

% figure; 
% plotMapGrid(LON(I),LAT(I));
% hold on; plot(P);

%% test forward / reverse

% Read in a sample file
fname = fullfile(pathdata,list(1).name);
V = flipud(permute(ncread(fname,'totalDemand'),[2,1]));

% Get the interpolation weights
[VC,W,IN,ON,A] = clipRasterByPoly(V,LON,LAT,P,'areasum'); sum(VC)

figure; 
plotMapGrid(LON(ON),LAT(ON));
hold on; plot(P);

%% test reverse

[VP,W,IN,ON,A] = clipRasterByPoly(VC,LON,LAT,P,'areasum','ReverseMapping',true); 
sum(VP)

WIN = horzcat(W{:});
nzc = find(sum(WIN > 0, 2));
WIN = WIN(nzc,:);
XIN = LON(nzc);
YIN = LAT(nzc);
mPX = cellfun(@(x) median(x,'omitnan'),PX);
mPY = cellfun(@(x) median(x,'omitnan'),PY);

figure; 
plotMapGrid(LON(ON),LAT(ON)); hold on; plot(P);
scatter(LON(IN|ON),LAT(IN|ON),100,VP(IN|ON),'filled'); colorbar;


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

%% convert to timetable

Time = datetime(1980,1,1):calmonths(1):datetime(2018,12,31);
TWD = array2timetable(transpose(TWD),'RowTimes',Time);
TWD = settableunits(TWD,'m3 s-1');

% check the units property was set correctly
% tableprops(TWD)

% add the lat/lon coordinates as properties
TWD = addprop(TWD,{'Lat','Lon'},{'table','table'});
TWD.Properties.CustomProperties.Lat = LAT;
TWD.Properties.CustomProperties.Lon = LON;

% check it:
% figure; 
% scatter( ...
%    TWD.Properties.CustomProperties.Lon, ...
%    TWD.Properties.CustomProperties.Lat, ...
%    20,mean(table2array(TWD),1),'filled');

%% save it
savematfile(fullfile( ...
   getenv('ACTIVE_PROJECT_DATA_PATH'),'matfiles','GCAM_waterdemand'), ...
   'TWD', ...
   savedata);


% % % This is how it was done the first time, with the simple clip mask I. The
% main code above uses the edge weights, but the result is effectively identical
% so I did not resave the data, since its just basin-scale data for comparison.

% find grid cells in the domain (239)
% [~,I] = clipRasterByPoly2(LON,LON,LAT,P,'none');
% 
% % % check it:
% figure; 
% plotMapGrid(LON(I),LAT(I));
% hold on; plot(P);
% % clip the coordinates
% LAT = LAT(I);
% LON = LON(I);
% 
% TWD = squeeze(nan([size(LAT),numel(list)]));
% for n = 1:numel(list)
%    fname = fullfile(pathdata,list(n).name);
%    v = flipud(permute(ncread(fname,'totalDemand'),[2,1]));
%    TWD(:,n) = v(I);
% end

% % % And this was how I tested to confirm 
% %% 
% TEST = nan(numel(list),1);
% for n = 1:numel(list)
%    fname = fullfile(pathdata,list(n).name);
%    v = reshape(flipud(permute(ncread(fname,'totalDemand'),[2,1])),[],1);
%    %[V,W,IN,ON,A] = clipRasterByPoly2(v,LON,LAT,P,'areasum');
%    TEST(n) = nansum(v.*W);
% end
% 
% figure; plot(nansum(table2array(TWD),2),TEST,'o'); addOnetoOne;
% 
% % sum(IN)+sum(ON)
% 
% figure; 
% plotMapGrid(LON(ON),LAT(ON)); hold on; 
% plot(LON(IN),LAT(IN),'o','MarkerFaceColor','k','MarkerEdgeColor','none')
% plot(LON(ON),LAT(ON),'o','MarkerFaceColor','m','MarkerEdgeColor','none')
% plot(P);
% 
% (sum(v(IN),'omitnan') + sum(v(ON),'omitnan') + sum(v(IN),'omitnan'))/2
% sum(table2array(TWD(1,:)),'omitnan')