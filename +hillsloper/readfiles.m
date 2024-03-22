function varargout = readfiles(sitename, requests)
   %READFILES Read hillsloper files into memory.
   %
   % [FILE1, FILE2, ..., FILEN] = HILLSLOPER.READFILES(SITENAME, FILENAMES)
   % Reads hillsloper files for SITENAME. Outputs (FILE1, FILE2, ..., FILEN) are
   % returned for each member of input variable FILENAMES.
   %
   % SEE ALSO:

   arguments
      sitename (1, :) char {mustBeMember(sitename, ...
         {'sag_basin', 'trib_basin', 'test_basin'})}
      requests (1, :) string {mustBeMember(requests, ...
         ["basins", "slopes", "links", "nodes", "boundary"])} ...
         = ["basins", "slopes", "links", "nodes", "boundary"]
   end

   % Parse inputs
   validoutputs = ["basins", "slopes", "links", "nodes", "boundary"];
   opts = optionParser(validoutputs, requests);

   % Note: previously there was an option to return the topography data
   % filename, but not the actual data. See getFileNames.

   % Get filenames and map projections
   mapproj = getMapProj(sitename);
   filenames = getFileNames(sitename);

   % Read the data
   for n = 1:nargout
      if opts.(requests(n))
         Data.(requests(n)) = readData(filenames.(requests(n)));
      end
   end

   % Convert strings to doubles, consistent fieldnames, and remove fields
   if opts.links
      Data.links = convertStringFieldsToDouble(Data.links);
      Data.links = renameLinksFields(Data.links);
      Data.links = updateCoordinateFields(Data.links, 'links');
   end
   if opts.nodes
      Data.nodes = convertStringFieldsToDouble(Data.nodes);
      Data.nodes = renameNodesFields(Data.nodes);
      Data.nodes = updateCoordinateFields(Data.nodes, 'nodes');
   end
   % basins and slopes don't have any strings
   if opts.basins
      Data.basins = renameSlopesFields(Data.basins);
      Data.basins = updateCoordinateFields(Data.basins, 'basins');
   end
   if opts.slopes
      Data.slopes = renameSlopesFields(Data.slopes);
      Data.slopes = updateCoordinateFields(Data.slopes, 'slopes');
      % Data.slopes = removeSlopesFields(Data.slopes); % Decided to keep all fields
   end

   % Add the hillslope area field to links
   if opts.links
      Data.links = addHillslopeAreaField(Data.links, Data.slopes);
   end

   % Parse outputs
   varargout = cell(nargout, 1);
   for n = 1:nargout
      switch requests(n)
         case 'basins'
            varargout{n} = Data.basins;
         case 'slopes'
            varargout{n} = Data.slopes;
         case 'links'
            varargout{n} = Data.links;
         case 'nodes'
            varargout{n} = Data.nodes;
         case 'boundary'
            varargout{n} = Data.boundary;
            % case 'ftopo'
            %    varargout{n} = Data.ftopo;
      end
   end
end

%% Set filenames
function filenames = getFileNames(sitename)

   % The ftopo's were added to replicate original a_save_hillsloper behavior. If
   % newer hillsloper data includes elevation and slope, topo data is not needed

   pathdata = getenv('USER_HILLSLOPER_DATA_PATH');
   switch sitename
      case 'sag_basin'

         % Jul 2023: Sag_hillslopes.shp replaced with Sag_basins.shp, which are
         % the pre-split slopes
         filenames.boundary = fullfile(pathdata, 'Sag_boundary.shp');
         filenames.slopes = fullfile(pathdata, 'Sag_hillslopes.shp');
         filenames.basins = fullfile(pathdata, 'Sag_basins.shp');
         filenames.links = fullfile(pathdata, 'Sag_links.shp');
         filenames.nodes = fullfile(pathdata, 'Sag_nodes.shp');
         filenames.topo = fullfile(getenv('USER_DOMAIN_TOPO_DATA_PATH'), ...
            'IfSAR_5m_DTM_Alaska_Albers_Sag_basin.tif');

         % note: the "full sag" gaged basin is:
         % S = loadgis('sag_basin_15908000_aka.shp');

      case 'trib_basin'
         % note: this is not the actual outline of the hillsloper hillslopes, need
         % to replace with them eventually
         filenames.boundary = fullfile(getenv('USERDATAPATH'), ...
            'interface/sag_basin/trib_basin/trib_boundary/trib_boundary.shp');
         filenames.slopes = fullfile(pathdata,'Sag_gage_HUC_hillslopes.shp');
         filenames.links = fullfile(pathdata,'Sag_gage_HUC_links.shp');
         filenames.nodes = fullfile(pathdata,'Sag_gage_HUC_nodes.shp');
         filenames.topo = fullfile(getenv('USER_DOMAIN_TOPO_DATA_PATH'), ...
            'Sag_gage_HUC_filled.tif');

      case 'test_basin'
         filenames.boundary = fullfile(getenv('USERGISPATH'), ...
            'Sag_test_HUC12_NHD_Alaska_Albers.shp');
         filenames.slopes = fullfile(pathdata, 'huc_190604020404_hillslopes.shp');
         filenames.links = fullfile(pathdata, 'huc_190604020404_links_w_hs_id.shp');
         filenames.nodes = fullfile(pathdata, 'huc_190604020404_nodes.shp');
         filenames.topo = fullfile(getenv('USER_DOMAIN_TOPO_DATA_PATH'), ...
            'huc_190604020404.tif');
   end
end

%% Get map projections
function mapproj = getMapProj(sitename)
   switch sitename
      case 'sag_basin'

         % mapproj is not used here anymore but would be needed for
         % computeHillslopeTopo
         mapproj = try_(@() projcrs(3338,'Authority','EPSG'));

      case 'trib_basin'
         mapproj = try_(@() projcrs(3338,'Authority','EPSG'));

      case 'test_basin'
         % For the huc 12 I used the NAD 83 (2011) alaska albers which is 6393.
         mapproj = try_(@() projcrs(6393,'Authority','EPSG'));
   end
end

%%
function data = readData(filename)
   try
      data = shaperead(filename);
   catch ME
      % NOTE: m_map reads nodes X,Y fields as Lon,Lat, not sure about the others
      if strcmp(ME.identifier,'MATLAB:license:checkouterror')
         data = loadgis(filename, 'm_map');
      end
   end
end

%% Add Lat/Lon fields
function data = updateCoordinateFields(data, structname)
   try
      data = updateCoordinates(data, 3338, "Authority", "EPSG");
   catch ME
      % likely mapping toolbox checkout error
   end

   % Add scalar x/y and lat/lon fields for easier plotting (e.g., attributes)
   if ismember(structname, {'links', 'slopes', 'basins'})

      for m = 1:numel(data)

         % To construct the fieldname, remove the plurual e.g. links->link
         fieldname = structname(1:end-1);
         data(m).([fieldname '_X']) = nanmean([data(m).X]);
         data(m).([fieldname '_Y']) = nanmean([data(m).Y]);
         data(m).([fieldname '_Lat']) = nanmean([data(m).Lat]);
         data(m).([fieldname '_Lon']) = nanmean([data(m).Lon]);
      end
   end
end

%%
function S = convertStringFieldsToDouble(S)

   % This works for both nodes and links, but an older version of nodes may
   % not work as noted in an older version: "nodes is more complicated, b/c some
   % fields have multiple values"

   V = fieldnames(S);
   V = V(structfun(@ischar, S(1,:)));
   V = V(~ismember(V, 'Geometry'));

   for n = 1:length(V)
      di = {S.(V{n})};
      for j = 1:length(di)
         [S(j).(V{n})] = str2double(strsplit(di{j},','));
      end
   end

   % % If there were not multiple values per field, this would work
   % for n = 1:length(V)
   %    di = num2cell(cellfun(@str2double,{links.(V{n})}));
   %    [links(1:length(links)).(V{n})] = di{:};
   % end

   % this shows that some values of upstream_r are vectors, which is why the
   % icon in the struct is different than the others
   % numel([links.upstream_r]);
end

%% Rename fields
function links = renameLinksFields(links)
   oldfields = {'id','us_node_id','ds_node_id','hs_id','upstream_r', 'downstream'};
   newfields = {'link_ID','us_node_ID','ds_node_ID','hs_ID','us_link_ID','ds_link_ID'};
   ireplace = ismember(oldfields, fieldnames(links));
   links = renamestructfields(links,oldfields(ireplace),newfields(ireplace));
end

function slopes = renameSlopesFields(slopes)
   % Works for slopes and basins
   oldfields = {'hs_id','parent_id','link_id','basin_id'};
   newfields = {'hs_ID','parent_ID','link_ID','hs_ID'};
   ireplace = ismember(oldfields, fieldnames(slopes));
   slopes = renamestructfields(slopes,oldfields(ireplace),newfields(ireplace));
end

function nodes = renameNodesFields(nodes)
   oldfields = {'id','hs_id'};
   newfields = {'node_ID','hs_ID'};
   ireplace = ismember(oldfields, fieldnames(nodes));
   nodes = renamestructfields(nodes,oldfields(ireplace),newfields(ireplace));
end

function slopes = removeSlopesFields(slopes)

   % Even if I want to call this function, endbasin and possibly others should
   % not be removed.
   % removeVars = {'link_id', 'outlet_idx', 'bp', 'endbasin'};
   % for n = 1:numel(removeVars)
   %    if isfield(slopes, removeVars{n})
   %       slopes = rmfield(slopes, removeVars{n});
   %    end
   % end
end

function links = addHillslopeAreaField(links, slopes)
   %Add hillslope area to links by combining the pos/neg slopes. This can be
   %done before removing links in the fix topology step as long as the
   %link.hs_ID field maps correctly to the slopes.hs_ID field, which is the case
   %for full Sag v2.

   % Note that ATS sim's use the sum of pos/neg, not the "basins" combined area
   linkIDs = [links.link_ID];
   for n = 1:length(linkIDs)
      hs_ID = links(n).hs_ID;
      hs_area = (sum([slopes([slopes.hs_ID] == hs_ID).area_km2]) + ...
         sum([slopes([slopes.hs_ID] == -hs_ID).area_km2])) * 1e6;
      links(n).hs_area_m2 = hs_area;
   end
end
