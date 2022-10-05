clean

savedata = false;

hexvers  = 'pyhexwatershed20220901014';
pathdata = setpath(['icom/hexwatershed/' hexvers '/hexwatershed'],'data');
pathsave = setpath(['icom/hexwatershed/' hexvers '/hexwatershed'],'data');

% make the shapefile
Mesh     = hexjson2shp([pathdata 'hexwatershed.json']);

% save the attributes as a table
dontkeep = {'Lat','Lon','BoundingBox','Geometry'};
Atts     = struct2table(rmfield(Mesh,dontkeep));

% read the flowline and save it as a .mat file - do this in the scrip that
% uses the mesh and flowline to build the dam dependencey et.
% Links    = shaperead([pathdata 'flowline_simplified.shp']);

% save the data
if savedata == true   
   writeGeoShapefile(Mesh,[pathsave 'mpas_mesh.shp']);
   writetable(Atts,[pathsave 'mpas_mesh_atts.xlsx']);
   save([pathsave 'mpas_mesh.mat'],'Mesh');
end