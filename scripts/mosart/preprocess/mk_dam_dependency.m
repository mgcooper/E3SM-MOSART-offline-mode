clearvars
close all
clc

% note: run_hexmesh2shp and run_pyflowline2shp need to be run first to create
% mpas_mesh.mat and mpas_flowline.mat 

% TODO: the dependent cells need to be found in a loop over basins, otherwise
% interbasin dependency occurs e.g. if the search radius is large, then as we go
% down stream collecting cells, some will get picked up across the basin
% boundary b/c I use a combined delw/susq boundary as the mask. cells across the
% bay also get picked up as we approach the outlet, which would be common in
% other basins with irregular geometry, so it would help to adjust rxy as we
% approach the outlet or somehow otherwise control which cells get collected
% maybe teh dependent cells have to be hydrologically connected to the flowline

%% settings

savedata = false;
plotfigs = false;

% search radius (meters)
rxy = 30000;

%% make input data available by setting the path

% % set the pyhexwatershed output version
% hexvers = 'pyhexwatershed20220901014';
% 
% % add paths to inputs
% setpath(['icom/hexwatershed/' hexvers],'data');
% setpath('icom/dams/','data');
% 
% % load the data
% load('mpas_mesh.mat','Mesh');
% load('mpas_flowline.mat','Line');
% load('susq_dams.mat','Dams');

%% make the input data available using the Config.m function / env vars

% get the pyhexwatershed output version
hexvers = getenv('USER_HEXWATERSHED_VERSION');

% load the mesh, flowline, and dams data
load(fullfile(getenv('USER_E3SM_DOMAIN_DATA_PATH'),'mpas_mesh.mat'),'Mesh');
load(fullfile(getenv('USER_PYFLOWLINE_DATA_PATH'),'mpas_flowline.mat'),'Line');
load(fullfile(getenv('USER_MOSART_DAMS_FILE_FULLPATH')),'Dams');
load(fullfile(getenv('USER_E3SM_DOMAIN_BOUNDS_FILE_FULLPATH')),'latpoly','lonpoly');

Dams.DAM_NAME(37) = {'MARSH CREEK'};

% % can also use shaperead, but icom_dams.mat has more info
% Mesh = shaperead(getenv('USER_HEXWATERSHED_MESH_SHPFILE_FULLPATH'),'UseGeoCoords',true);
% Line = shaperead(getenv('USER_HEXWATERSHED_FLOWLINE_SHPFILE_FULLPATH'),'UseGeoCoords',true);
% Dams = shaperead(getenv('USER_MOSART_DAMS_SHPFILE_FULLPATH'),'UseGeoCoords',true);

% clip the flowline to the bounds (for plotting, not needed for the algorithm)
for n = 1:numel(Line)
   [latline,lonline] = polyjoin({Line(n).Lat},{Line(n).Lon});
   inmask = inpoly([lonline latline],[lonpoly latpoly]);
   Line(n).Lat = latline(inmask);
   Line(n).Lon = lonline(inmask);
end

%% preprocess the mesh

% find mesh cell flow direction
[ID,dnID] = hexmesh_dnID(Mesh);

% check how many outlets were identified
% [sum(ID==-9999) sum(ID==-1) sum(dnID==-9999)]

% pass this to the function so it returns the DependentCell ID's in terms of
% the global (hexwatershed) lCellID rather than the local 1:numcells ID.
globalID = [Mesh.lCellID];

%% get the x,y location of the dams and the mesh cell centroids
londams = Dams.LONGITUDE;
latdams = Dams.LATITUDE;
lonmesh = transpose([Mesh.dLongitude_center_degree]);
latmesh = transpose([Mesh.dLatitude_center_degree]);
zmesh = transpose([Mesh.Elevation]);

% project to utm. i used this to find the zone: utmzone(ymesh(1),xmesh(1))
projutm18T = projcrs(32618,'Authority','EPSG');
[xmesh,ymesh] = projfwd(projutm18T,latmesh,lonmesh);
[xdams,ydams] = projfwd(projutm18T,latdams,londams);
[xmask,ymask] = projfwd(projutm18T,latpoly,lonpoly);

%% run the kdtree function

[DependentCells,i_DependentCells] = makeDamDependency(ID,dnID,[xdams ydams], ...
   [xmesh ymesh zmesh],rxy,'userID',globalID,'mask',[xmask ymask]);

%% plot the result

if plotfigs == true
   
   inmask = inpoly([xmesh,ymesh],[xmask,ymask]);
   
   % plot one dam
   % idam = 7;
   % plotDamDependency(Dams,DependentCells,Mesh(inmask),Line,[latmask lonmask],idam);
   
   % plot all dams
   plotDamDependency(Dams,DependentCells,Mesh(inmask),Line,[latpoly lonpoly]);

end


%% save the data

if savedata == true
   
   % add the dependent cells to the Dams table. memory intensive so do it here.
   Dams = addDependentCells(Dams,DependentCells);
   
   pathsave = fullfile(getenv('DATAPATH'),'dams','mat');
   save(fullfile(pathsave,'icom_dams_dep_cells.mat'),'Dams');
   writetable(Dams,fullfile(pathsave,'icom_dams_dep_cells.xlsx'));

   %save('data/matfiles/Dams_with_Dependency.mat','Dams');
   %save('data/matfiles/DependentCellsArray.mat','DependentCells');
end

% %% test - compare with python version
% 
% f = '/Users/coop558/myprojects/icom-wm/mosart_dams/test.txt';
% test1 = str2double(readlines(f));
% test2 = rmnan(transpose(DependentCells(end,:)));
% 
% sum(isnan(test1))
% sum(isnan(test2))
% 
% setdiff(test1,test2)
% setdiff(test2,test1)
% 
% test = DependentCells(1,:);
% test = sort(test(:));
% 

% %% extra stuff 
% 
% % % find which mesh cells contribute to each flowline segment. the 'iMesh' field
% % % produced by this function is used to find the mesh cells that contain a
% % % flowline for plotting but this isn't necessary for the algorithm
% % [Line,Mesh] = findCellsOnVectorFlowline(Line,Mesh);
% % 
% % % keep this to find all hex cells that contain a flowline using the Mesh
% % % attribute iSegment, which should work with updated hexwatershed output
% % % unique([Mesh.iSegment])
% % 
% % % create the flow network from the mesh 
% % [latline,lonline] = makeMeshFlowline(dnID,latmesh,lonmesh);
% % figure; geoshow(vertcat(latline{:}),vertcat(lonline{:}));
% 
% % % subset one set of dependent cells and write a shapefile
% % % idam = 7;
% % idam = find(Dams.Name == "ADAM T. BOWER MEMORIAL");
% % IDdepends = rmnan(DependentCells(idam,:));
% % idepends = find(ismember([Mesh.lCellID],IDdepends));
% % tmp = Mesh(idepends);
% % 
% % if savedata == true
% %    writeGeoShapefile(tmp,['data/shp/dependentCells' num2str(idam) '.shp'])
% % end
% 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% 
% % 18,559
% 
% % 1. for each dam, find the shortest path to the flowline
% % 2. starting at that cell, find all flowline cells downstream 
% % 3. run kd tree
% 
% % this is how I figured out that Mesh.iSegment doesn't matches Line.iStreamSegment
% % macfig; 
% % for n = 1:numel(Line)
% %    itest = find([Mesh.iSegment] == Line(n).iStream_segment);
% %    patch_hexmesh(Mesh(itest)); hold on; geoshow(Line(n));
% %    pause; 
% % end
% 
% % % i tried removing the nan's from the Mesh lat/lon fields so geoshow displays
% % the patches correctly but it still plots a big rectangle
% % for n = 1:numel(Mesh)
% %    Mesh(n).Lat = rmnan(Mesh(n).Lat);
% %    Mesh(n).Lon = rmnan(Mesh(n).Lon);
% % end
% 
% 
% % % this mpas mesh is very detailed, includes the bay (20276 cells)
% % pathroot = 'icom/hexwatershed/pyhexwatershed20211130002/pyflowline/';
% % pathdata = setpath(pathroot,'data');
% % 
% % Info        = shapeinfo([pathdata 'mpas.shp']);
% % [Mesh,Meta] = shaperead([pathdata 'mpas.shp'],'UseGeoCoords',true);
% % 
% % figure; geoshow(Mesh);
% 
% 
% % % the reason I don't use these is 
% % make the filenames
% % filemesh = [pathdata 'mesh/mpas_mesh.shp'];
% % fileline = [pathdata 'pyflowline/flowline_simplified.shp'];
% % filedams = [pathdams 'icom_dams.shp'];
% 
% % DamsInfo = shapeinfo(filedams);
% % MeshInfo = shapeinfo(filemesh);
% % LineInfo = shapeinfo(fileline);
% % Dams     = shaperead(filedams,'UseGeoCoords',true);
% % Mesh     = shaperead(filemesh,'UseGeoCoords',true);
% % Line     = shaperead(fileline,'UseGeoCoords',true);
% 
% % [Dams,DamsAtts]   = shaperead(filedams,'UseGeoCoords',true);
% % [Mesh,MeshAtts]   = shaperead(filemesh,'UseGeoCoords',true);
% % [Line,LineAtts]   = shaperead(fileline,'UseGeoCoords',true);
% 
% 
% % % the issue here is that Mesh won't have the hexagon lat/lon values
% % Mesh     = readtable('mpas_mesh_atts.xlsx');
% % Dams     = readtable('icom_dams.xlsx');
% % Line     = shaperead('flowline_simplified.shp','UseGeoCoords',true);
% 
% % % the issue here is that the fieldnames are truncated to 10 characters
% % Mesh     = shaperead('mpas_mesh.shp','UseGeoCoords',true);
% % Dams     = shaperead('icom_dams.shp','UseGeoCoords',true);
% % Line     = shaperead('flowline_simplified.shp','UseGeoCoords',true);
% 
% 
% % numel([Line(end).iMesh]')
% 
% % use this to have a plot open before running the function
% % macfig; 
% % patch_hexmesh(Mesh); hold on;
% % patch_hexmesh(Mesh(imesh),'FaceColor','g');
