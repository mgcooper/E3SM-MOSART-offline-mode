clearvars
close all
clc

% TODO:
% 1 - add globalID_DependentCells (done)
% 2 - put globalID_DependentCells into a uniform table (done)
% 3 - repeat for MPAS domain mesh (~18,000 cells) if that can be found

% set the pyhexwatershed output version
% hexvers  = 'pyhexwatershed20220901014';
hexvers  = 'mpas_c220107';

% workon E3SM-MOSART-offline-mode

% set the search radius (meters)
rxy = 10000;

% add paths to inputs
setpath(['icom/hexwatershed/' hexvers],'data');
setpath('icom/dams/','data');

% load the mesh, flowline, and dams data
load('mpas_mesh.mat','Mesh');
load('mpas_flowline.mat','Line');
load('susq_dams.mat','Dams');

% find mesh cell flow direction. this is used to find all cells downstream of
% each dam
%----------------------------------------------------
[cell_ID, cell_dnID] = hexmesh_dnID(Mesh);

for n = 1:numel(Mesh)
   Mesh(n).cell_ID = cell_ID(n);
   Mesh(n).cell_dnID = cell_dnID(n);
end

% find which mesh cells contribute to each flowline segment. the 'iMesh' field
% produced by this function is used to find the mesh cells that contain a
% flowline for plotting but this isn't necessary for the algorithm
%----------------------------------------------------
Line = findMeshCellsOnFlowline(Mesh,Line);

% run the kdtree function
%-------------------------
[Dams,Mesh] = makeDamDependency(Dams,Mesh,Line,'searchradius',rxy,'IDtype','global');

% put the dependent cells into their own table
numdams = height(Dams);
maxcells = max(cellfun(@numel,Dams.ID_DependentCells));
DependentCells = nan(numdams,maxcells);
for n = 1:numdams
   cells_n = Dams.globalID_DependentCells{n};
   DependentCells(n,1:numel(cells_n)) = cells_n;
end

% save the data
if savedata == true
   save('Dams_with_Dependency.mat','Dams');
   save('DependentCellsArray.mat','DependentCells');
end

%% plot the result
%-------------------------

% choose a dam, and color the faces of the dependent mesh cells
figure('Position', [50 60 1200 1200]); hold on; 
for n = 1:height(Dams)
   idam     = n
   idepends = Dams.DependentCells{idam};

   
   patch_hexmesh(Mesh); % use 'FaceMapping','Elevation' to see the elevation
   patch_hexmesh(Mesh(idepends),'FaceColor','g'); 
%    patch_hexmesh(Mesh([Mesh.iflowline]),'FaceColor','b'); 
   scatter(Dams.Lon,Dams.Lat,'m','filled'); % geoshow(Line); 
   scatter(Dams.Lon(idam),Dams.Lat(idam),100,'r','filled');
   geoshow(Line);
   pause; clf
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% 18,559

% 1. for each dam, find the shortest path to the flowline
% 2. starting at that cell, find all flowline cells downstream 
% 3. run kd tree

% this is how I figured out that Mesh.iSegment doesn't matches Line.iStreamSegment
% macfig; 
% for n = 1:numel(Line)
%    itest = find([Mesh.iSegment] == Line(n).iStream_segment);
%    patch_hexmesh(Mesh(itest)); hold on; geoshow(Line(n));
%    pause; 
% end

% % this mpas mesh is very detailed, includes the bay (20276 cells)
% pathroot = 'icom/hexwatershed/pyhexwatershed20211130002/pyflowline/';
% pathdata = setpath(pathroot,'data');
% 
% Info        = shapeinfo([pathdata 'mpas.shp']);
% [Mesh,Meta] = shaperead([pathdata 'mpas.shp'],'UseGeoCoords',true);
% 
% figure; geoshow(Mesh);


% % the reason I don't use these is 
% make the filenames
% filemesh = [pathdata 'mesh/mpas_mesh.shp'];
% fileline = [pathdata 'pyflowline/flowline_simplified.shp'];
% filedams = [pathdams 'icom_dams.shp'];

% DamsInfo = shapeinfo(filedams);
% MeshInfo = shapeinfo(filemesh);
% LineInfo = shapeinfo(fileline);
% Dams     = shaperead(filedams,'UseGeoCoords',true);
% Mesh     = shaperead(filemesh,'UseGeoCoords',true);
% Line     = shaperead(fileline,'UseGeoCoords',true);

% [Dams,DamsAtts]   = shaperead(filedams,'UseGeoCoords',true);
% [Mesh,MeshAtts]   = shaperead(filemesh,'UseGeoCoords',true);
% [Line,LineAtts]   = shaperead(fileline,'UseGeoCoords',true);


% % the issue here is that Mesh won't have the hexagon lat/lon values
% Mesh     = readtable('mpas_mesh_atts.xlsx');
% Dams     = readtable('icom_dams.xlsx');
% Line     = shaperead('flowline_simplified.shp','UseGeoCoords',true);

% % the issue here is that the fieldnames are truncated to 10 characters
% Mesh     = shaperead('mpas_mesh.shp','UseGeoCoords',true);
% Dams     = shaperead('icom_dams.shp','UseGeoCoords',true);
% Line     = shaperead('flowline_simplified.shp','UseGeoCoords',true);


% numel([Line(end).iMesh]')

% use this to have a plot open before running the function
% macfig; 
% patch_hexmesh(Mesh); hold on;
% patch_hexmesh(Mesh(imesh),'FaceColor','g');
