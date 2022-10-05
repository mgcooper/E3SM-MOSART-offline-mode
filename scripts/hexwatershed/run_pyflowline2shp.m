clean

% i used this to confirm that the json file attributes were exported correctly
% when the json file was exported to a shp in qgis. They are identical so i use
% shaperead and save to a table here for consistency with hexwatershed workflow

savedata = true;
hexvers  = 'pyhexwatershed20220901014';

% define the path where the data will be saved
pathsave = setpath(['icom/hexwatershed/' hexvers '/pyflowline'],'data');

% add the hexwatershed path to access the data
setpath(['icom/hexwatershed/' hexvers '/pyflowline'],'data');

% make the shapefile
geojson  = 'flowline_conceptual.geojson';
jsoninfo = 'flowline_conceptual_info.json';
Line     = pyflowlinejson2shp(geojson,jsoninfo);

% save the attributes as a table
dontkeep = {'Geometry','BoundingBox','Lat','Lon'};
Atts     = struct2table(rmfield(Line,dontkeep));

% save it
if savedata == true
   save([pathsave 'mpas_flowline.mat'],'Line');
   writetable(Atts,[pathsave 'mpas_flowline_atts.xlsx']);
end


% % read the shapefile and the flowline info
% Line     = shaperead('flowline_conceptual.shp','UseGeoCoords',true);
% Info     = loadjson('flowline_conceptual_info.json');



