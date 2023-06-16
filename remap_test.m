clean

savedata = false;
pathdata = setpath('e3sm/compyfs/inputdata/waterdemand/','data');

usegeo = false;

%% Load the mesh

% get the pyhexwatershed output version
hexvers = getenv('USER_HEXWATERSHED_VERSION');

%% Load the subbasin shapefiles

Sdrbc = loadgis('DELW.shp','UseGeoCoords',true);
load('drbc_subbasins.mat','Basins')

% in this case, we have the shape areas, so send them in
PA = [Basins.Meta.Shape_Area].';
PX = {Basins.Bounds.X}.';
PY = {Basins.Bounds.Y}.';

% convert to lat lon then repackage 
[PX,PY] = polyvec(PX,PY);

% Use DRB full basin to first clip the mesh
if usegeo == true
   P = polyshape([wrapTo360(Sdrbc.Lon(:)),Sdrbc.Lat(:)]);
   [PY,PX] = utm2ll(PX,PY,18,'nad83');
else
   [x,y] = ll2utm(Sdrbc.Lat(:),Sdrbc.Lon(:),18,'wgs84');
   P = polyshape(x,y);
end

[PX,PY] = polycells(PX,PY);

% figure; 
% geomap(plat,plon); 
% plotm(plat,plon)
% plotm([Sdrbc.Lat],[Sdrbc.Lon],'r');

% figure; plot(P); hold on; cellfun(@plot,PX,PY)

%% Read in the mesh

Mesh = jsondecode(fileread(getenv('MESHJSONFILE')));
[YC,XC,NC] = hexmesh_centroids(Mesh);
[YV,XV,NV] = hexmesh_vertices(Mesh);

% transpose the vertices
XV = XV.'; YV = YV.';

if usegeo == true
   % wrap the lon to 360
   XC = wrapTo360(XC);
   XV = wrapTo360(XV);
   PX = cellmap(@wrapTo360,PX);
else
   [XC,YC] = ll2utm(YC,XC,18,'wgs84');
   [XV,YV] = ll2utm(YV,XV,18,'wgs84');
end

%% clip the mesh to the DRB outline

% [~,~,IN] = exactremap(NV,XC,YC,P,'clip','GridOption','unstructured');

% try clipping a bit outside of P to see if that fixes the area gap
[XminP,XmaxP] = bounds(P.Vertices(:,1));
[YminP,YmaxP] = bounds(P.Vertices(:,2));

% this works but creates a rectangle around the watershed
% IN = ...
%    (XC >= XminP-median(abs(diff(XC)))/2) & ...
%    (XC <= XmaxP+median(abs(diff(XC)))/2) & ...
%    (YC >= YminP-median(abs(diff(YC)))/2) & ...
%    (YC <= YmaxP+median(abs(diff(YC)))/2) ;

% dB = max(median(abs(diff(XC))),median(abs(diff(YC))));
dB = 10000;
PB = polybuffer(P,dB);
IN = inpolygon(XC,YC,PB.Vertices(:,1),PB.Vertices(:,2)); sum(IN)

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

% This is time consuming but confirms things are ok
Pbasins = cellfun(@polyshape,PX,PY);
xv = transpose(XV);
yv = transpose(YV);
figure; hold on;
arrayfun(@(n) plot(Pbasins(n)),1:numel(Pbasins));
% cellfun(@plot, PX, PY);
arrayfun( @(n) patch('Faces',1:find(isnan(yv(:,n)),1,'first')-1, ...
   'Vertices',[xv(:,n),yv(:,n)],'FaceColor','none','LineWidth',0.5), ...
   1:size(yv,2));
axis off

% to add gcam centroids:
% load('GCAM_waterdemand.mat','TWD')
% latgcam = TWD.Properties.Description
% plot()

%% test

% CellVertices = [{num2cell(XV)},{num2cell(YV)}];
XCellVertices = arrayfun(@(n) XV(n,~isnan(XV(n,:))),(1:length(XV))','uni',0);
YCellVertices = arrayfun(@(n) YV(n,~isnan(YV(n,:))),(1:length(YV))','uni',0);
CellVertices = cellfun(@fliplr, [XCellVertices, YCellVertices],'uni',0);
all(polyorder(CellVertices(:,1),CellVertices(:,2)))

% XYV = CellVertices;
XV = CellVertices(:,1);
YV = CellVertices(:,2);

%% brute force it
% V = NV;
V = PA; % for this test, map polys onto cells, so V is size P

% Now that P was used to clip to P, reset P to the sub-basins
P = [PX PY];

% call the function
[W,IN,V2] = remap_unstructured(V,XV,YV,P);

% note - I copied weights.mat to e3sm offline mode repo data folder
if savedata == true
   save('weights','W','IN')
end

% these can differ up to the difference in overlap b/w polygons and mesh cells
[sum(V2) sum(V)]
100*(sum(V2)-sum(V))/sum(V)
% [sum(PA) sum(cellfun(@(x,y) polyarea(x,y),PX,PY))] % AC is the area of the mesh cells

% check if the weights exceed 1
test = cellfun(@sum,W);
[max(test) min(test)]


% % This is time consuming but confirms things are ok
% xv = transpose(XV);
% yv = transpose(YV);
% figure; hold on;
% cellfun( @(xv,yv) patch('Faces',1:numel(xv), ...
%    'Vertices',[xv.',yv.'],'FaceColor','none'), XV,YV);
% cellfun(@plot, PX, PY);
% scatter(XC,YC,30,V2,'filled'); colorbar
% % patch('Faces',1:numel(xv{1}),'Vertices',[xv{1};yv{1}].','FaceColor','none')
% scatter(XC(V2==0),YC(V2==0),40,'m','filled')

