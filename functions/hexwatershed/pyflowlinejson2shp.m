function S = pyflowlinejson2shp(geojsonfile,jsoninfofile,varargin)
%pyflowlinejson2shp converts flowline_*.geojson and flowline_*_info.json to
%shapefile and saves it as filename.shp

%------------------------------------------------------------------------------
p              =  inputParser;
p.FunctionName =  'pyflowlinejson2shp';

addRequired(p,    'geojsonfile',             @(x)ischar(x));
addRequired(p,    'jsoninfofile',            @(x)ischar(x));
addParameter(p,   'savefile',    false,      @(x)islogical(x));
addParameter(p,   'filename',    'tmp.shp',  @(x)ischar(x));

parse(p,geojsonfile,jsoninfofile,varargin{:});

geofile  = p.Results.geojsonfile;
jsonfile = p.Results.jsoninfofile;
savefile = p.Results.savefile;
filename = p.Results.filename;
%------------------------------------------------------------------------------

% note: 
% json.features{1,n}.properties.iseg == info{1,n}.iStream_segment
% json.features{1,n}.properties.iord == info{1,n}.iStream_order
% so we only use json.features to get the lat/lon of the flowline, and we take
% the attributes from info. to maintain consistency with hexjson2shp, we call
% the infofile 'json' and the geojson file 'geodata'

% read the json file
geodata  = loadjson(geofile);
geodata  = geodata.features;
json     = loadjson(jsonfile);

% use the first entry to initialize the geo struct fields
atts     = json{1,1}; 

% flatten the start/end vertex attributes 
atts.pVertex_start_dLatitude_degree    = atts.pVertex_start.dLatitude_degree;
atts.pVertex_start_dLongitude_degree   = atts.pVertex_start.dLongitude_degree;
atts.pVertex_end_dLatitude_degree      = atts.pVertex_end.dLatitude_degree;
atts.pVertex_end_dLongitude_degree     = atts.pVertex_end.dLongitude_degree;

% remove the non-flattened start/end attributes
atts     = rmfield(atts,{'pVertex_start','pVertex_end'});

% get the list of attribute names now that they are flattened
fields   = fieldnames(atts);

% init the geo struct
nfeature = numel(json);
S        = geostructinit('Line',nfeature,'fieldnames',fields);

% cycle over all features and populate the geostruct
for n = 1:nfeature
     
   atts           = json{1,n}; 
   lonlat         = geodata{1,n}.geometry.coordinates;
   
   pVertex_start  = atts.pVertex_start;
   pVertex_end    = atts.pVertex_end;
   
   atts           = rmfield(atts,{'pVertex_start','pVertex_end'});

   % add the lat lon
   [S(n).Lat]     = deal(lonlat(:,2));
   [S(n).Lon]     = deal(lonlat(:,1));
   
   % add the pVertex attributes to 'atts'
   atts.pVertex_start_dLatitude_degree    = pVertex_start.dLatitude_degree;
   atts.pVertex_start_dLongitude_degree   = pVertex_start.dLongitude_degree;
   atts.pVertex_end_dLatitude_degree      = pVertex_end.dLatitude_degree;
   atts.pVertex_end_dLongitude_degree     = pVertex_end.dLongitude_degree;
   
   % loop over atts, adding each on to S
   for m = 1:numel(fields)
      if all(~ismember(fieldnames(atts),{'iFlag_dam'}))
         atts.iFlag_dam = 0;
      end
      S(n).(fields{m}) = atts.(fields{m});
   end
   
end

% use built-in updategeostruct to compute the bounding box field
S           = updategeostruct(S);

% reorder the struct fields to match the order that shaperead returns
oldfields   = fieldnames(S);
igeom       = find(oldfields == "Geometry");
ibbox       = find(oldfields == "BoundingBox");
newfields   = [oldfields(igeom); oldfields(ibbox); oldfields(igeom+1:ibbox-1)];
S           = orderfields(S,newfields);

% save the file 
if savefile == true
   writeGeoShapefile(S,filename);
end
