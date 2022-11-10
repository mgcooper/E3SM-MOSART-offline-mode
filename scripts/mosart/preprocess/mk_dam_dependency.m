clearvars
close all
clc

savedata = false;

% set the pyhexwatershed output version
hexvers = 'pyhexwatershed20220901014';

% workon E3SM-MOSART-offline-mode

% set the search radius (meters)
rxy = 30000;

% add paths to inputs
setpath(['icom/hexwatershed/' hexvers],'data');
setpath('icom/dams/','data');

% load the mesh, flowline, and dams data
load('mpas_mesh.mat','Mesh');
load('mpas_flowline.mat','Line');
load('susq_dams.mat','Dams');

% find mesh cell flow direction
[ID,dnID] = hexmesh_dnID(Mesh);

sum(ID==-9999)
sum(ID==-1)
sum(dnID==-9999)

for n = 1:numel(Mesh)
   Mesh(n).cell_ID = ID(n);
   Mesh(n).cell_dnID = dnID(n);
end

% find which mesh cells contribute to each flowline segment. the 'iMesh' field
% produced by this function is used to find the mesh cells that contain a
% flowline for plotting but this isn't necessary for the algorithm
Line = findMeshCellsOnFlowline(Mesh,Line);

% get the x,y location of the dams and the mesh cell centroids
londams = Dams.Lon;
latdams = Dams.Lat;
lonmesh = transpose([Mesh.dLongitude_center_degree]);
latmesh = transpose([Mesh.dLatitude_center_degree]);
zmesh = transpose([Mesh.Elevation]);

% project to utm. i used this to find the zone: utmzone(ymesh(1),xmesh(1))
projutm18T     = projcrs(32618,'Authority','EPSG');
[xmesh,ymesh]  = projfwd(projutm18T,latmesh,lonmesh);
[xdams,ydams]  = projfwd(projutm18T,latdams,londams);

% get the mesh cells that contain a flowline and add that info to the Mesh 
imeshline = vertcat(Line(:).iMesh);
[Mesh.iflowline] = deal(false);
for n = 1:numel(imeshline)
   Mesh(imeshline(n)).iflowline = true;
end
% keep this to find all hex cells that contain a flowline using the Mesh
% attribute iSegment, which should work with updated hexwatershed output
% unique([Mesh.iSegment])

% pass this to the function so it returns the DependentCell ID's in terms of
% the global (hexwatershed) lCellID rather than the local 1:numcells ID.
globalID = [Mesh.lCellID];

% run the kdtree function
%-------------------------
[DependentCells,i_DependentCells] =  makeDamDependency( ...
                        ID,dnID,[xdams ydams],[xmesh ymesh zmesh], ...
                        'searchradius',rxy,'userID',globalID);

% add the dependent cells to the Dams tble
for n = 1:numel(xdams)
   Dams.ID_DependentCells{n} = DependentCells(n,~isnan(DependentCells(n,:)));
   Dams.i_DependentCells{n} = i_DependentCells(n,~isnan(i_DependentCells(n,:)));
end

% save the data
if savedata == true
   save('data/matfiles/Dams_with_Dependency.mat','Dams');
   save('data/matfiles/DependentCellsArray.mat','DependentCells');
end

%% plot the result
%-------------------------

% choose a dam, and color the faces of the dependent mesh cells
idam = 7;
%IDdepends = Dams.ID_DependentCells{idam};
%idepends = Dams.i_DependentCells{idam};
IDdepends = rmnan(DependentCells(idam,:));
idepends = ismember([Mesh.lCellID],IDdepends);

figure('Position', [50 60 1200 1200]); hold on; 
patch_hexmesh(Mesh); % use 'FaceMapping','Elevation' to see the elevation
patch_hexmesh(Mesh(idepends),'FaceColor','g'); 
scatter(Dams.Lon,Dams.Lat,'m','filled'); % geoshow(Line); 
scatter(Dams.Lon(idam),Dams.Lat(idam),100,'r','filled');
geoshow(Line);

% % plot all in a loop
% figure('Position', [50 60 1200 1200]); hold on; 
% for n = 1:height(Dams)
%    idam     = n
% %    IDdepends = Dams.ID_DependentCells{idam};
% %    idepends = Dams.i_DependentCells{idam};
%    
%    IDdepends = rmnan(DependentCells(idam,:));
%    idepends = find(ismember([Mesh.lCellID],IDdepends));
%    
%    patch_hexmesh(Mesh); % use 'FaceMapping','Elevation' to see the elevation
%    patch_hexmesh(Mesh(idepends),'FaceColor','g'); 
% %    patch_hexmesh(Mesh([Mesh.iflowline]),'FaceColor','b'); 
%    scatter(Dams.Lon,Dams.Lat,'m','filled'); % geoshow(Line); 
%    scatter(Dams.Lon(idam),Dams.Lat(idam),100,'r','filled');
%    geoshow(Line);
%    pause; clf
% end

% subset one set of dependent cells and write a shapefile
% idam = 7;
idam = find(Dams.Name == "ADAM T. BOWER MEMORIAL");
IDdepends = rmnan(DependentCells(idam,:));
idepends = find(ismember([Mesh.lCellID],IDdepends));
tmp = Mesh(idepends);
writeGeoShapefile(tmp,['data/shp/dependentCells' num2str(idam) '.shp'])

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
