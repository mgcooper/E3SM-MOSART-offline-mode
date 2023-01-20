clean

savedata = false;

hexvers = 'pyhexwatershed20221115006'; % 'pyhexwatershed20220901014';
pathdata = setpath(['icom/hexwatershed/' hexvers '/hexwatershed'],'data');
pathsave = setpath(['icom/hexwatershed/' hexvers '/hexwatershed'],'data');

% make the shapefile
Mesh = hexjson2shp(fullfile(pathdata,'hexwatershed.json'));

% check the result in qgis

% save the attributes as a table
remove = {'Lat','Lon','BoundingBox','Geometry'};
Atts = struct2table(rmfield(Mesh,remove));

% read the flowline and save it as a .mat file - do this in the script that
% uses the mesh and flowline to build the dam dependencey et.
% Links = shaperead(fullfile(pathdata,'flowline_simplified.shp'));

% save the data
if savedata == true   
   writeGeoShapefile(Mesh,fullfile(pathsave,'mpas_mesh.shp'));
   writetable(Atts,fullfile(pathsave,'mpas_mesh_atts.xlsx'));
   save(fullfile(pathsave,'mpas_mesh.mat'),'Mesh');
end