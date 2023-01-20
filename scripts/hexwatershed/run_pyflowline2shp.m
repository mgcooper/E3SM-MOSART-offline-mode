clean

% i used this to confirm that the json file attributes were exported correctly
% when the json file was exported to a shp in qgis. They are identical so i use
% shaperead and save to a table here for consistency with hexwatershed workflow

savedata = true;
hexvers = 'pyhexwatershed20221115006'; %'pyhexwatershed20220901014';

% define the path where the data will be saved
pathsave = setpath(['icom/hexwatershed/' hexvers '/pyflowline'],'data');

% add the hexwatershed path to access the data
setpath(['icom/hexwatershed/' hexvers '/pyflowline'],'data','goto');

dirlist = getlist(pwd,'**');
fgeojson = 'flowline_conceptual.geojson';
fjsoninfo = 'flowline_conceptual_info.json';

for n = 1:numel(dirlist)
   geojson  = fullfile(dirlist(n).folder,dirlist(n).name,fgeojson);
   jsoninfo = fullfile(dirlist(n).folder,dirlist(n).name,fjsoninfo);
   line_n   = pyflowlinejson2shp(geojson,jsoninfo);
   if n == 1
      Line = transpose(line_n);
   else
      Line = [Line; transpose(line_n)]; %#ok<AGROW> 
   end
end

figure; geoshow(Line)

% make the shapefile
% geojson  = 'flowline_conceptual.geojson';
% jsoninfo = 'flowline_conceptual_info.json';
% Line     = pyflowlinejson2shp(geojson,jsoninfo);

% save the attributes as a table
remove = {'Geometry','BoundingBox','Lat','Lon'};
Atts = struct2table(rmfield(Line,remove));

% save it
if savedata == true
   writeGeoShapefile(Line,fullfile(pathsave,'mpas_flowline_conceptual.shp'));
   save(fullfile(pathsave,'mpas_flowline.mat'),'Line');
   writetable(Atts,fullfile(pathsave,'mpas_flowline_atts.xlsx'));
end


% % read the shapefile and the flowline info
% Line = shaperead('flowline_conceptual.shp','UseGeoCoords',true);
% Info = loadjson('flowline_conceptual_info.json');



