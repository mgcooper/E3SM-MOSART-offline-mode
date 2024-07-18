function S = hexjson2shp(jsonfile,varargin)
   %hexjson2shp converts hexwatershed.json to shapefile and saves it as
   %filename.shp

   parser = inputParser;
   parser.FunctionName = mfilename;
   addRequired(parser, 'jsonfile', @isscalartext);
   addParameter(parser, 'savefile', false, @islogical);
   addParameter(parser, 'filename', 'tmp.shp', @isscalartext);

   parse(parser,jsonfile,varargin{:});

   jsonfile = parser.Results.jsonfile;
   savefile = parser.Results.savefile;
   filename = parser.Results.filename;

   % read the json file
   json = loadjson(jsonfile);

   % use the first entry to initialize the geo struct fields
   atts = json{1,1};
   atts = rmfield(atts,'vVertex');
   fields = fieldnames(atts);
   ncells = numel(json);
   S = geostructinit('polygon',ncells,'fieldnames',fields);

   % cycle over all cells and populate the geostruct
   for n = 1:ncells

      atts = json{1,n};
      vertex = atts.vVertex;
      atts = rmfield(atts,'vVertex');

      % add the lat lon
      for m = 1:numel(vertex)
         S(n).Lat(m) = vertex{1,m}.dLatitude_degree;
         S(n).Lon(m) = vertex{1,m}.dLongitude_degree;
      end

      % add the attribute
      for m = 1:numel(fields)
         S(n).(fields{m}) = atts.(fields{m});
      end
   end

   % use built-in updategeostruct to compute the bounding box field
   S = updategeostruct(S);

   % reorder the struct fields to match the order that shaperead returns
   oldfields = fieldnames(S);
   igeom = find(oldfields == "Geometry");
   ibbox = find(oldfields == "BoundingBox");
   newfields = [oldfields(igeom); oldfields(ibbox); oldfields(igeom+1:ibbox-1)];
   S = orderfields(S,newfields);

   % save the file
   if savefile == true
      writeGeoShapefile(S,filename);
   end
end
