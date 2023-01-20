function [newlinks,inletID,outletID] = mos_makenewlinks(links,nodes)
%MAKE_NEWLINKS takes the links and nodes shapefiles and identifies the
%upstream/downstream link connectivity as well as the inlet (headwater)
%and outlet id's

newlinks = links;    % inherit the geometry and bounding box
inletID = [];        % initialize the inlet and outlet ID arrays
outletID = [];

for n = 1:length(links)
   
   link_id     = links(n).id;
   us_node_id  = links(n).us_node_id;
   ds_node_id  = links(n).ds_node_id;
   i_us        = find(ismember([nodes.id],us_node_id));
   i_ds        = find(ismember([nodes.id],ds_node_id));
   us_hs_id    = nodes(i_us).hs_id;
   ds_hs_id    = nodes(i_ds).hs_id;
   us_conn_id  = nodes(i_us).conn;
   ds_conn_id  = nodes(i_ds).conn;
   % 'hs_id' and 'conn' are the only two pieces of info in nodes
   
   % use 'ul' for 'uplink' instead of 'us' for 'upstream'
   if length(us_conn_id) > 1   % this is a confluence
      ul_id = us_conn_id(us_conn_id~=link_id);
      n_ul = length(ul_id);
      while n_ul > 0
         i_ul = find(ismember([links.id],ul_id(n_ul)));
         newlinks(i_ul).ds_link_ID = link_id;
         n_ul = n_ul-1;
      end
   end
   
   newlinks(n).link_ID     = link_id;
   newlinks(n).us_node_ID  = us_node_id;
   newlinks(n).ds_node_ID  = ds_node_id;
   newlinks(n).us_hs_ID    = us_hs_id;
   newlinks(n).ds_hs_ID    = ds_hs_id;
   newlinks(n).us_conn_ID  = us_conn_id;
   newlinks(n).ds_conn_ID  = ds_conn_id;
   
   if length(us_conn_id) == 1
      inletID = [inletID;links(n).id];
   end
   
   if length(ds_conn_id) == 1
      outletID = [outletID;links(n).id];
   end
end

% outlet links have no dnid, set to nan
for n = 1:length(newlinks)
   if isempty(newlinks(n).ds_link_ID)
      % disp(n)
      newlinks(n).ds_link_ID = nan;
   end
end

% remove dupiclate fields
newlinks = rmfield(newlinks,{'id','ds_node_id','us_node_id'});

% not sure if this is needed, it was in a different part of the script
% for n = 1:length(links)
%     ds_node_id = str2double(links(n).ds_node_id);
%     ds_node_id = find(ismember([nodes.hs_id],ds_node_id));
%     if length(ds_node_id) == 1
%         outlet_ID = links(n).id;
%     end
% end

