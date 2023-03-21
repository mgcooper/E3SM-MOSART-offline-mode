function [slopes,links,nodes,bounds] = readHillsloperData(sitename)

pathdata = getenv('USER_HILLSLOPER_DATA_PATH');

% flist = getlist(pathdata,'*.shp'); % {flist.name}'

switch sitename
   case 'sag_basin'
      fbounds = fullfile(pathdata,'Sag_hillslopes_boundary.shp');
      fslopes = fullfile(pathdata,'Sag_hillslopes.shp');
      flinks = fullfile(pathdata,'Sag_links.shp');
      fnodes = fullfile(pathdata,'Sag_nodes.shp');
      % note: the "full sag" gaged basin is:
      % S = loadgis('sag_basin_15908000_aka.shp');
   case 'trib_basin'
      % note: this is not the actual outline of the hillsloper hillslopes, need
      % to replace with them eventually
      fbounds = '/Users/coop558/work/data/interface/sag_basin/trib_basin/trib_boundary/trib_boundary.shp';
      fslopes = fullfile(pathdata,'Sag_gage_HUC_hillslopes.shp');
      flinks = fullfile(pathdata,'Sag_gage_HUC_links.shp');
      fnodes = fullfile(pathdata,'Sag_gage_HUC_nodes.shp');
   case 'test_basin'
      fbounds = '/Users/coop558/work/data/interface/GIS_data/Sag_test_HUC12_NHD_Alaska_Albers.shp';
      fslopes = fullfile(pathdata,'huc_190604020404_hillslopes.shp');
      flinks = fullfile(pathdata,'huc_190604020404_links_w_hs_id.shp');
      fnodes = fullfile(pathdata,'huc_190604020404_nodes.shp');
end

try % for sag_basin, links is file 3, nodes is 4, so need to use explicit method
   links = shaperead(flinks);
   nodes = shaperead(fnodes);
   slopes = shaperead(fslopes);
   bounds = shaperead(fbounds);
   
catch ME
   if strcmp(ME.identifier,'MATLAB:license:checkouterror')
      activate m_map
      links = loadgis(flinks,'m_map');
      nodes = loadgis(fnodes,'m_map');
      slopes = loadgis(fslopes,'m_map');
      bounds = loadgis(fbounds,'m_map');
   end
end

Nnodes = length(nodes);
Nlinks = length(links);
Nslopes = length(slopes);

%% convert strings to doubles
N = Nlinks;
V = {'us_node_id','ds_node_id','ds_da_km2','us_da_km2','slope','len_km','hs_id'};
for n = 1:length(V)
   vi = V{n};
   % between here and else was not in sag_basin version
   di = {links.(vi)};
   if strcmp(vi,'hs_id')
      for j = 1:length(di)
         [links(j).(vi)] = str2double(strsplit(di{j},','));
      end
   else
      di = num2cell(cellfun(@str2double,{links.(vi)}));
      [links(1:N).(vi)] = di{:};
   end
   % sag basin version went straight from vi=V{n} here:
   %di = num2cell(cellfun(@str2double,{links.(vi)}));
   %[links(1:N).(vi)] = di{:};
end

% nodes is more complicated, because some fields have multiple values
N = Nnodes;
V = {'hs_id','conn','da_km2'};
for n = 1:length(V)
   di = {nodes.(V{n})};
   for j = 1:length(di)
      [nodes(j).(V{n})] = str2double(strsplit(di{j},','));
   end
end

%% convert varnames to consistent terminology

% links
oldfields = {'id','us_node_id','ds_node_id','hs_id'};
newfields = {'link_ID','us_node_ID','ds_node_ID','hs_ID'};
links = renamestructfields(links,oldfields,newfields);

% slopes
oldfields = {'hs_id','parent_id','link_id'};
newfields = {'hs_ID','parent_ID','link_ID'};
slopes = renamestructfields(slopes,oldfields,newfields);

% nodes
oldfields = {'id','hs_id'};
newfields = {'node_ID','hs_ID'};
nodes = renamestructfields(nodes,oldfields,newfields);


% % decided to leave this for now, but 
% % remove unneccesary fields (copied from makenewslopes 15 March 2023)
% removeVars = {'link_id','outlet_idx','bp','endbasin'};
% for n = 1:numel(removeVars)
%    if isfield(newslopes,removeVars{n})
%       newslopes = rmfield(newslopes,removeVars{n});
%    end
% end


