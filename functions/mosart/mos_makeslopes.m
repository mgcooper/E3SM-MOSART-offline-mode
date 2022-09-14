function [newslopes,newlinks,info] = mos_makeslopes(slopes,links,nodes,plot_slopes)
%MOS_MAKESLOPES takes the slopes, links, and nodes shapefiles and
%identifies the upstream/downstream link connectivity as well as the inlet
%(headwater) and outlet id's

% definitions
% hs_id         = id of the hillslope in which a link exists
% us_hs_id      = hillslopes upstream of the upstream node
% ds_hs_id      = hillslopes upstream of the downstream node

newlinks    = links;    % inherit the geometry and bounding box
newslopes   = slopes;
inletID    = [];       % initialize the inlet and outlet ID arrays
outletID   = [];

% NOTE: this loop sets the ds_link_ID but the numbering doesn't follow
% n=1:numel(links), so this loop must complete before adding additional
% information based on the link_ID -> ds_link_ID connectivity.
% TLDR: don't add stuff to this loop.

for n = 1:numel(links)
   
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
      ul_id   = us_conn_id(us_conn_id~=link_id);
      n_ul    = length(ul_id);
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
      inletID    = [inletID;links(n).id];
   end
   
   if length(ds_conn_id) == 1
      outletID   = [outletID;links(n).id];
   end
   
end

% outlet links have no dnid, set to nan
for n = 1:numel(newlinks)
   if isempty(newlinks(n).ds_link_ID)
      newlinks(n).ds_link_ID = nan;
   end
end

% remove dupiclate fields
removeVars  = {'id','ds_node_id','us_node_id'};
for n = 1:numel(removeVars)
   if isfield(newlinks,removeVars{n})
      newlinks = rmfield(newlinks,removeVars{n});
   end
end

% remove unneccesary fields
removeVars  = {'link_id','outlet_idx','bp','endbasin'};
for n = 1:numel(removeVars)
   if isfield(newslopes,removeVars{n})
      newslopes   = rmfield(newslopes,removeVars{n});
   end
end

% new feb 2022, add link_ID to slopes
for n = 1:numel(newlinks)
   thisLink_ID     = newlinks(n).link_ID;
   thisLink_dsID   = newlinks(n).ds_link_ID;
   thisLink_hsID   = newlinks(n).hs_id;
   for m = 1:numel(newslopes)
      thisSlope_hsID  = newslopes(m).hs_id;
      if any(ismember(thisLink_hsID,thisSlope_hsID))
         newslopes(m).link_ID    = thisLink_ID;
         newslopes(m).ds_link_ID = thisLink_dsID;
      end
   end
end

% pretty sure these 'x' vars only exist in the earlier hillsloper versions
% for the huc 12
if isfield(newslopes,'area0x2CKm2')
   newslopes = renameStructField2(newslopes,'area0x2CKm2','da');
end

% % % % %  Final checks:

% 1. confirm hillslope numbering is consecutive
IDs     = [newlinks.link_ID];
% dnIDs   = [newlinks.ds_link_ID];
dIDs    = diff(IDs);

% inspect dIDs to figure out where the numbering goes astray

if ~isempty(find(dIDs>1,1))
   error('ds ID numbering astray, stop and figure out why');
end

% 2. ensure ID field starts at 1, rather than zero
if any([newlinks.link_ID]==0)
   for n = 1:numel(newlinks)
      newlinks(n).link_ID     = newlinks(n).link_ID+1;
      newlinks(n).ds_link_ID  = newlinks(n).ds_link_ID+1;
   end
   for n = 1:numel(newslopes)
      newslopes(n).link_ID     = newslopes(n).link_ID+1;
      newslopes(n).ds_link_ID  = newslopes(n).ds_link_ID+1;
   end
   inletID    = inletID+1;
   outletID   = outletID+1;
end



% Assign info
info.inlet_ID   = inletID;
info.outlet_ID  = outletID;

% plot the slopes if requested
if plot_slopes == true
   info.h = mos_plotslopes(newslopes,newlinks,nodes);
end

% not sure if this is needed, it was in a different part of the script
% for n = 1:length(links)
%     ds_node_id      = str2double(links(n).ds_node_id);
%     ds_node_id      = find(ismember([nodes.hs_id],ds_node_id));
%     if length(ds_node_id) == 1
%         outlet_ID   = links(n).id;
%     end
% end

end

