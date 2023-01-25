clean

savedata = false;


%% set paths

pathdata = setpath('interface/data/hillsloper/sag_basin/');
pathsave = '/Users/coop558/mydata/e3sm/sag/hillsloper/IFSAR_hillslopes/';


%% load the hillsloper data

load([pathdata 'mosart_hillslopes']);  
slopes = mosart_hillslopes; clear mosart_hillslopes;

% go through and create one list of all links with nan-separators
x = []; y = []; ID = []; dnID = []; hsID = [];
for n = 1:length(slopes)
    y     = [y;nan;slopes(n).Y_link'];
    x     = [x;nan;slopes(n).X_link'];
%     ID    = [ID;nan;slopes(n).X_link'];
end
% started to add ID etc., but doesn't work b/c it's a single polyline

links       = mapshape;
links.X     = x;
links.Y     = y;


%% write a shapefile, then use Qgis to define the projection

if savedata == true
    shapewrite(links,[pathsave 'sag_links_mosart_tmp.shp']);
end

