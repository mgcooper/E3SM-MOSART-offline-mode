clean

% forward and reverse mapping is finished, I confirmed it works for the multi
% polygon and single polygon case. 
% 
% now I need to try reverse mapping onto the mesh. Not sure if I should start
% with forward from mesh to poly, probably same either way since reverse mapping
% happens at the end 

% NOTE: i skipped the case of mapping GCAM lat-lon onto Mesh, return to that 

% Once I move onto this, check the commented stuff at bottom of mk_wm_demand for
% reading in the mesh, getting centroids, etc. This branched off
% remap_gcam_subbasins, which maps gcam lat-lon onto subbasins, whereas I want
% to map sub-basins onto grid cells.

savedata = false;
pathdata = setpath('e3sm/compyfs/inputdata/waterdemand/','data');

%% Load the mesh

% get the pyhexwatershed output version
hexvers = getenv('USER_HEXWATERSHED_VERSION');

% load the mesh, flowline, and dams data
% load(fullfile(getenv('USER_E3SM_DOMAIN_DATA_PATH'),'mpas_mesh.mat'),'Mesh');

%% Load the subbasin shapefiles

Sdrbc = loadgis('DELW.shp','UseGeoCoords',true);
load('drbc_subbasins.mat','Basins')

% Use DRB full basin to first clip the mesh
P = polyshape([wrapTo360(Sdrbc.Lon(:)),Sdrbc.Lat(:)]);

% in this case, we have the shape areas, so send them in
PA = [Basins.Meta.Shape_Area].';
PX = {Basins.Bounds.X}.';
PY = {Basins.Bounds.Y}.';

% PX = Basins.Bounds.X;
% PY = Basins.Bounds.Y;

% convert to lat lon then repackage 
[PX,PY] = polyjoin(PX,PY);
[PY,PX] = utm2ll(PX,PY,18,'nad83');
[PX,PY] = polysplit(PX,PY);

% figure; 
% geomap(plat,plon); 
% plotm(plat,plon)
% plotm([Sdrbc.Lat],[Sdrbc.Lon],'r');

% figure; hold on; cellfun(@plot,PX,PY)

%% Read in the mesh

Mesh = jsondecode(fileread(getenv('MESHJSONFILE')));
% [ID,dnID] = hexmesh_dnID(Mesh);
[YC,XC,NC] = hexmesh_centroids(Mesh);
[YV,XV,NV] = hexmesh_vertices(Mesh);

% transpose the vertices
XV = XV.'; YV = YV.';

% wrap the lon to 360
XC = wrapTo360(XC);
XV = wrapTo360(XV);
PX = cellmap(@wrapTo360,PX);

% for reference
% [latmin,latmax] = bounds(LAT(:))
% [lonmin,lonmax] = bounds(LON(:))
[YMIN,YMAX] = bounds(YC(:));
[XMIN,XMAX] = bounds(XC(:));

%% check inputs

% length(unique([XC,YC],'rows'))

%% clip the mesh to the DRB outline

[~,~,IN] = exactremap(YC,XC,YC,P,'clip','GridOption','unstructured');

% Clip the data
XC = XC(IN);
YC = YC(IN);
XV = XV(IN,:);
YV = YV(IN,:);
NV = NV(IN,:); % for testing

% Plot to confirm
figure; 
plot(P); hold on;
scatter(XC,YC); 
% cellfun(@plot,PX,PY);

clear Sdrbc Basins Mesh IN

% NOTE: what this reveals is that we don't want to do weights if we just want to
% clip. Also, clip currently happens in processOnePolygon, but it uses the
% corner vertex method, so its incompatible with unstructured grids unless we
% have a method to find jumps in x,y where dx,dy wrap around the grid and set
% them to the prio cell dx/dy (by the way, we should use a centered difference
% for unstrucutred anyway, and this reveals that to first detect jumps, we would
% want a non-centered b/c it will dilute the jump). SO, basically, we need to
% either remove the corner check from clipOnePolygon, or not support
% irregular/unstructured, which means require users to clip before hand.

% check the weights - should be a positive number representing the 
% grid cells removed due to partial overlap
% (sum(IN) + sum(ON)) - sum(W) 

% Use IN or ON to clip the cells, then apply the weights
% I = IN | ON; % sum(I)

%% make up some dummy data

% V = flipud(permute(ncread(fname,'totalDemand'),[2,1]));

% F1=@(x,y) (sin(sqrt(x.^2+y.^2)));
% zn=F1(xn,yn);
% zc_interp=reshape(P*zn(:),size(xc));
% zc_Analytic=F1(xc,yc);
% RMSE=sqrt(mean((zc_Analytic(:)-zc_interp(:)).^2));
% 
% figure
% surface(xc,yc,zc_interp,'EdgeColor','none');
% title(['nPoly: ' num2str(nPoly) ', RMSE= ' num2str(RMSE)]);
% axis tight

%%

% This is time consuming but confirms things are ok
% xv = transpose(XV);
% yv = transpose(YV);
% figure; hold on;
% arrayfun( @(n) patch('Faces',1:find(isnan(yv(:,n)),1,'first')-1, ...
%    'Vertices',[xv(:,n),yv(:,n)],'FaceColor','none'), ...
%    1:size(yv,2));
% cellfun(@plot, PX, PY);

% % after transposing for some reason this doesnt' work, so 

% figure; hold on;
% arrayfun( @(n) patch('Faces',1:find(isnan(YV(n,:)),1,'first')-1, ...
%    'Vertices',[XV(n,:),YV(n,:)],'FaceColor','none'), ...
%    1:size(YV,1));
% plot(plon,plat)
% plot([Sdrbc.Lon],[Sdrbc.Lat],'r');

% patch('Faces',1:find(isnan(YV(1,:)),1,'first'), 'Vertices',[XV(1,:); YV(1,:)].');

% % I think this is very slow, and it isn't compatible with newer mesh fields
% figure; 
% patch_hexmesh(Mesh,'LonField','dLongitude_center_degree','LatField', ...
%    'dLatitude_center_degree');
% hold on;
% plot(plon,plat)
% plot([Sdrbc.Lon],[Sdrbc.Lat],'r');

%% test

% PICK BACK UP - need to support mesh vertices ... maybe start with the
% centroids, assume square cells, just to sort out issues with unstrucutred
% mesh, which might have already been sorted out gettign it to support the clip
% operation for unstructured, I think the first place it comes up is
% enclosedGridCells, I just need an option to NOT compute XV,YV if gridType is
% irregular and/or unstructured, in which case XV,YV must be supplied. Also
% allowing AXY like PA would be good so we don't have to compute it inside. 

% It might work to sub out X,Y for XV,YV, at first glance it all looks simple
% except for floodfill

% This maps the CELLS onto the POLYS. Then we pass the result back in and use
% ReverseMapping to test mapping POLYS onto CELLS.

% CellVertices = [{num2cell(XV)},{num2cell(YV)}];
XCellVertices = arrayfun(@(n) XV(n,~isnan(XV(n,:))),(1:length(XV))','uni',0);
YCellVertices = arrayfun(@(n) YV(n,~isnan(YV(n,:))),(1:length(YV))','uni',0);
CellVertices = cellfun(@fliplr, [XCellVertices, YCellVertices],'uni',0);
all(ispolycw(CellVertices(:,1),CellVertices(:,2)))

[VP,W] = exactremap(NV,XC,YC,[PX PY], ...
   'areasum', ...
   'GridOption', 'unstructured', ...
   'CellVertices',CellVertices, ...
   'ReverseMapping', false, ...
   'PolygonAreas',PA);

% horzcat(num2cell(XV),num2cell(YV))
% xtest = cellfun(@(x) median(x,'omitnan'), CellVertices(:,1), 'uni', true);
% ytest = cellfun(@(x) median(x,'omitnan'), CellVertices(:,2), 'uni', true);

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

