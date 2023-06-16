clean

savedata = false;
pathdata = setpath('e3sm/compyfs/inputdata/waterdemand/','data');

usegeo = false;

%% Load the subbasin shapefiles

[P,PX,PY,PA] = loadDrbcBasins(usegeo);

% Load the gcam data to overlay the centroids on the map
[~,XGcam,YGcam] = loadGcamWaterDemand(usegeo);

%% Read in the mesh

% [XC,YC,XV,YV,NV] = readMeshJsonFile( ...
%    getenv('USER_HEXWATERSHED_MESH_JSONFILE_FULLPATH'));
[XC,YC,XV,YV] = read_e3sm_domain_file( ...
   getenv('USER_E3SM_DOMAIN_NCFILE_FULLPATH'));

if usegeo == false
   [XC,YC] = ll2utm(YC,XC,18,'wgs84');
   [XV,YV] = ll2utm(YV,XV,18,'wgs84');
end

%% clip the mesh to the DRB outline

[XC,YC,XV,YV,IMesh] = clipMeshToPoly(P,XC,YC,XV,YV);

% For testing:
% NV = NV(IMesh,:);

% fast scatter plot
% figure; plotMeshWithPolys(XC,YC,XV,YV,P,'fastplot');

% This is time consuming but confirms things are ok
figure('Position',[217 14 555 590]); hold on;
plotMeshWithPolys(XC,YC,XV,YV,[PX,PY]);

% Add the gcam grid centroids
scatter(XGcam,YGcam,20,'sk','filled'); % copygraphics(gcf);

%% Convert the mesh verts to cell arrays

[XV,YV,~,isclockwise] = meshpolyjoin(XV,YV);

%% brute force remapping

V = PA; % for this test, map polys onto cells, so V is size P

% call the function
[W,IN,V2] = remap_unstructured(V,XV,YV,[PX PY]);

% note - I copied weights.mat to e3sm offline mode repo data folder
if savedata == true
   save('weights','W','IN','XC','YC','XV','YV','PX','PY','IMesh')
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

