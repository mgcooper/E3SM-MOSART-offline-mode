function [basins,slopes,links,nodes,boundary,ftopo] = readHillsloperData(sitename)

   pathdata = getenv('USER_HILLSLOPER_DATA_PATH');

   % flist = getlist(pathdata,'*.shp'); % {flist.name}'

   % The ftopo's are temporary, added to replicate original a_save_hillsloper
   % behavior. If newer hillsloper data includes elevation and slope, the topo data
   % is not needed.

   switch sitename
      case 'sag_basin'
         
         % jul 2023, replaced Sag_hillslopes.shp with Sag_basins.shp, which are
         % the pre-split slopes
         fbounds = fullfile(pathdata,'Sag_boundary.shp');
         fslopes = fullfile(pathdata,'Sag_hillslopes.shp');
         fbasins = fullfile(pathdata,'Sag_basins.shp');
         flinks = fullfile(pathdata,'Sag_links.shp');
         fnodes = fullfile(pathdata,'Sag_nodes.shp');
         ftopo = 'IfSAR_5m_DTM_Alaska_Albers_Sag_basin.tif';
         
         % mapproj is not used here anymore but would be needed for
         % computeHillslopeTopo
         mapproj = try_(@() projcrs(3338,'Authority','EPSG'));
         
         % note: the "full sag" gaged basin is:
         % S = loadgis('sag_basin_15908000_aka.shp');

      case 'trib_basin'
         % note: this is not the actual outline of the hillsloper hillslopes, need
         % to replace with them eventually
         fbounds = '/Users/coop558/work/data/interface/sag_basin/trib_basin/trib_boundary/trib_boundary.shp';
         fslopes = fullfile(pathdata,'Sag_gage_HUC_hillslopes.shp');
         flinks = fullfile(pathdata,'Sag_gage_HUC_links.shp');
         fnodes = fullfile(pathdata,'Sag_gage_HUC_nodes.shp');
         ftopo = 'Sag_gage_HUC_filled.tif';
         
         mapproj = try_(@() projcrs(3338,'Authority','EPSG'));

      case 'test_basin'
         fbounds = '/Users/coop558/work/data/interface/GIS_data/Sag_test_HUC12_NHD_Alaska_Albers.shp';
         fslopes = fullfile(pathdata,'huc_190604020404_hillslopes.shp');
         flinks = fullfile(pathdata,'huc_190604020404_links_w_hs_id.shp');
         fnodes = fullfile(pathdata,'huc_190604020404_nodes.shp');
         ftopo = 'huc_190604020404.tif';
         
         % For the huc 12 I used the NAD 83 (2011) alaska albers which is 6393.
         mapproj = try_(@() projcrs(6393,'Authority','EPSG'));
   end

   ftopo = fullfile(getenv('USER_DOMAIN_TOPO_DATA_PATH'),ftopo);

   try % for sag_basin, links is file 3, nodes is 4, so need to use explicit method
      links = shaperead(flinks);
      nodes = shaperead(fnodes);
      slopes = shaperead(fslopes);
      basins = shaperead(fbasins);
      boundary = shaperead(fbounds);

   catch ME
      
      % NOTE: nodes X,Y fields come in as Lon,Lat with m_map, not sure about the
      % others
      
      if strcmp(ME.identifier,'MATLAB:license:checkouterror')
         links = loadgis(flinks,'m_map');
         nodes = loadgis(fnodes,'m_map');
         slopes = loadgis(fslopes,'m_map');
         basins = loadgis(fbasins, 'm_map');
         boundary = loadgis(fbounds,'m_map');
      end
   end

   %% convert strings to doubles

   % basins and slopes don't have any strings

   V = fieldnames(links);
   V = V(structfun(@ischar, links(1,:)));
   V = V(~ismember(V, 'Geometry'));

   for n = 1:length(V)
      di = {links.(V{n})};
      for j = 1:length(di)
         [links(j).(V{n})] = str2double(strsplit(di{j},','));
      end
   end

   % % If there were not multiple values per field, this would work
   % for n = 1:length(V)
   %    di = num2cell(cellfun(@str2double,{links.(V{n})}));
   %    [links(1:length(links)).(V{n})] = di{:};
   % end

   % nodes is more complicated, because some fields have multiple values
   V = fieldnames(nodes);
   V = V(structfun(@ischar, nodes(1,:)));
   V = V(~ismember(V, 'Geometry'));

   for n = 1:length(V)
      di = {nodes.(V{n})};
      for j = 1:length(di)
         [nodes(j).(V{n})] = str2double(strsplit(di{j},','));
      end
   end

   % this shows that some values of upstream_r are vectors, which is why the
   % icon in the struct is different than the others
   % numel([links.upstream_r]);

   %% convert varnames to consistent terminology

   % links
   oldfields = {'id','us_node_id','ds_node_id','hs_id','upstream_r', 'downstream'};
   newfields = {'link_ID','us_node_ID','ds_node_ID','hs_ID','us_link_ID','ds_link_ID'};
   ireplace = ismember(oldfields, fieldnames(links));
   links = renamestructfields(links,oldfields(ireplace),newfields(ireplace));

   % slopes / basins
   oldfields = {'hs_id','parent_id','link_id','basin_id'};
   newfields = {'hs_ID','parent_ID','link_ID','hs_ID'};
   ireplace = ismember(oldfields, fieldnames(slopes));
   slopes = renamestructfields(slopes,oldfields(ireplace),newfields(ireplace));

   % basins
   ireplace = ismember(oldfields, fieldnames(basins));
   basins = renamestructfields(basins,oldfields(ireplace),newfields(ireplace));

   % nodes
   oldfields = {'id','hs_id'};
   newfields = {'node_ID','hs_ID'};
   ireplace = ismember(oldfields, fieldnames(nodes));
   nodes = renamestructfields(nodes,oldfields(ireplace),newfields(ireplace));
   
   % % decided to leave this for now, but
   % % remove unneccesary fields (copied from makenewslopes 15 March 2023)
   % removeVars = {'link_id','outlet_idx','bp','endbasin'};
   % for n = 1:numel(removeVars)
   %    if isfield(newslopes,removeVars{n})
   %       newslopes = rmfield(newslopes,removeVars{n});
   %    end
   % end
   
   % add Lat/Lon fields
   links = updateCoordinates(links, 3338, "Authority", "EPSG");
   nodes = updateCoordinates(nodes, 3338, "Authority", "EPSG");
   slopes = updateCoordinates(slopes, 3338, "Authority", "EPSG");
   basins = updateCoordinates(basins, 3338, "Authority", "EPSG");
   boundary = updateCoordinates(boundary, 3338, "Authority", "EPSG");
end
