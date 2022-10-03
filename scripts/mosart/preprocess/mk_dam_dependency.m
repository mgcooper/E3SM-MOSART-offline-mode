
clean

% set the pyhexwatershed output version
hexvers  = 'pyhexwatershed20220901014';


% set the search radius (meters)
rxy      = 10000;

% tian - this just adds the path to the data/ folder
% % set output save path and add paths to inputs
% pathsave = setpath('icom/dams/','data');
% setpath(['icom/hexwatershed/' hexvers],'data'); 
% setpath('icom/dams/','data');

% load the mesh, flowline, and dams data
load('mpas_mesh.mat','Mesh');
load('mpas_flowline.mat','Line');
load('icom_dams.mat','Dams');

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
      scatter(lon(m),lat(m),'b','filled');
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
Dams = makeDamDependency(Dams,Mesh,Line,'searchradius',rxy,'plotfig',false);


if savedata == true
   save([pathsave 'Dams_with_Dependency.mat'],'Dams');
end

% plot the result
%-------------------------

% choose a dam, and color the faces of the dependent mesh cells
idam     = 1;
idepends = Dams.DependentCells{idam};

figure('Position', [50 60 1200 1200]); hold on; 
% patch_hexmesh(Mesh); % use 'FaceMapping','Elevation' to see the elevation

for n = 1:numel(Mesh)
   patch('XData',Mesh(n).Lon,'YData',Mesh(n).Lat,'FaceColor','none');
end

for n = 1:numel(idepends)
   iface = idepends(n);
   patch('XData',Mesh(iface).Lon,'YData',Mesh(iface).Lat,'FaceColor','g');
end

geoshow(Line); scatter(Dams.Lon,Dams.Lat,'filled');
scatter(Dams.Lon(idam),Dams.Lat(idam),100,'r','filled');



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
