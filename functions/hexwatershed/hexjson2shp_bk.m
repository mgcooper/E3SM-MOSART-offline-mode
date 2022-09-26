function S = hexjson2shp(json)
%hexjson2shp converts hexwatershed.json to shapefile

% this is preserved b/c it shows how to init a geoshape, in particular
% setting the geometry of the first 'atts' used to init the shape was key
% to getting subsequent calls to 'append' to work, but this is VERY SLOW

% this is very slow, and i can't figure out how to speed it up. but once it
% runs, the file can be saved and used in geospatial programs that are fast

% the number of cells
ncell = numel(json);

% use the first entry to initialize the geoshape
atts     = json{1,1}; 
vertex   = atts.vVertex;
nverts   = numel(vertex); % i logged nverts and they range from 4-8
latlon   = nan(nverts,2);
for m = 1:nverts
   latlon(m,1) = vertex{1,m}.dLatitude_degree;
   latlon(m,2) = vertex{1,m}.dLongitude_degree;
end

% remove the vertex lat/lon and init the geoshape. note - adding the
% 'Geometry' field is 
atts           = rmfield(atts,'vVertex');
atts.Geometry  = 'polygon';

% make a shapefile
S  = geoshape(latlon(:,1),latlon(:,2),atts);

% for n = 1:ncell
for n = 1:100
     
   atts     = json{1,n}; 
   vertex   = atts.vVertex;
   nverts   = numel(vertex); % i logged nverts and they range from 4-8
   latlon   = nan(nverts,2);
   atts     = rmfield(atts,'vVertex');
  
   % get the lat lon
   for m = 1:nverts
      latlon(m,1) = vertex{1,m}.dLatitude_degree;
      latlon(m,2) = vertex{1,m}.dLongitude_degree;
   end
   
   S = append(S,latlon(:,1),latlon(:,2),atts);
   
   %s(n).Latitude    = latlon(:,1);
   %s(n).Longitude   = latlon(:,2);
   
   % latlon(:,3) = repmat(n,nverts,1);
   % coords = vertcat(coords,latlon);
end



