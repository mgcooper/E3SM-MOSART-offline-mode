clearvars
close all
clc

% set the pyhexwatershed output version
hexvers  = 'pyhexwatershed20220901014';

% workon E3SM-MOSART-offline-mode

% set the search radius (meters)
rxy      = 10000;

% set output save path
pathsave = setpath('icom/dams/','data');

% add paths to inputs
setpath(['icom/hexwatershed/' hexvers],'data');
setpath('icom/dams/','data');

% load the mesh, flowline, and dams data
load('mpas_mesh.mat','Mesh');
load('mpas_flowline.mat','Line');
load('icom_dams.mat','Dams');


% find mesh cell flow direction
%----------------------------------------------------
[global_ID, global_dnID] = hexmesh_dnID(Mesh);

for n = 1:numel(Mesh)
   Mesh(n).global_ID = global_ID(n);
   Mesh(n).global_dnID = global_dnID(n);
end

% find which mesh cells contain each flowline segment
%----------------------------------------------------

% extract the mesh cell centroid coordinates
lonmesh = transpose([Mesh.dLongitude_center_degree]);
latmesh = transpose([Mesh.dLatitude_center_degree]);

% each line is comprised of segments with vertices that are near but not
% exactly equal to the mesh cell centroids. this means we cannot locate the
% mesh cell that contains each line segment by logic. instead, iterate over the  
% vertices of each line segment and find the nearest mesh cell, and add that
% index to the line attributes.

% make a figure to see the mesh if desired
% figure('Position', [50 60 1200 1200]); hold on; 
% patch_hexmesh(Mesh); hold on;

for n = 1:numel(Line)
   
   lat = Line(n).Lat;
   lon = Line(n).Lon;
   
   idx = nan(1,numel(lat));
   for m = 1:numel(lat)
      % scatter(lon(m),lat(m),'b','filled');
      idx(m) = dsearchn([lonmesh latmesh],[lon(m) lat(m)]);
   end
   Line(n).iMesh = idx(:);
   Line(n).Lat_Mesh = latmesh(idx);
   Line(n).Lon_Mesh = lonmesh(idx);
   
   % this can be used to see the flowline vertices
   % geoshow(Line(n));
end


% run the kdtree function
%-------------------------

% suggest keeping plotfig false and then using the plotting stuff below to see
% the result
[Dams,Mesh] = makeDamDependency(Dams,Mesh,Line,'searchradius',rxy);


if savedata == true
   save([pathsave 'Dams_with_Dependency.mat'],'Dams');
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
   patch_hexmesh(Mesh([Mesh.iflowline]),'FaceColor','b'); 
   scatter(Dams.Lon,Dams.Lat,'m','filled'); % geoshow(Line); 
   scatter(Dams.Lon(idam),Dams.Lat(idam),100,'r','filled');
   pause; clf
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% 1. for each dam, find the shortest path to the flowline
% 2. starting at that cell, find all flowline cells downstream 
% 3. run kd tree
% remove dams outside the mesh domain


% this is how I figured out that Mesh.iSegment doesn't matches Line.iStreamSegment
% macfig; 
% for n = 1:numel(Line)
%    itest = find([Mesh.iSegment] == Line(n).iStream_segment);
%    patch_hexmesh(Mesh(itest)); hold on; geoshow(Line(n));
%    pause; 
% end

% % this mpas mesh is very detailed, includes the bay
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
