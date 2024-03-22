function [nodes, rm_node, rp_node] = mergenodes(nodes, rm_node_ID, rp_node_ID, ...
      rm_slope_ID, rm_link_ID, rm_flag)
   %MERGENODES Merge two nodes into one, combining attributes.
   %
   % [NODES, RM_NODE, RP_NODE] = MERGENODES( ...
   %    NODES, RM_NODE_ID, RP_NODE_ID, RM_SLOPE_ID, RM_LINK_ID, RM_FLAG)
   %
   % See notes at end about possible bad side effects of updating fields such
   % as conn without also updating every single other field in slopes, basins,
   % links, and nodes.
   %
   % See also: removelink

   if nargin < 6
      rm_flag = false;
   end

   % Get the nodes to remove and replace
   rm_node = nodes([nodes.node_ID] == rm_node_ID);
   rp_node = nodes([nodes.node_ID] == rp_node_ID);

   % 1. Process rp_node
   rp_node.hs_ID = unique(horzcat(rp_node.hs_ID, rm_node.hs_ID));
   rp_node.conn = unique(horzcat(rp_node.conn, rm_node.conn));

   % Remove rm_slope and rm_link if they are members of the combined hs_ID/conn
   rp_node.hs_ID = rp_node.hs_ID(~ismember([rp_node.hs_ID], rm_slope_ID));
   rp_node.conn = rp_node.conn(~ismember([rp_node.conn], rm_link_ID));

   nodes([nodes.node_ID] == rp_node_ID) = rp_node;

   % remove the bad node
   if rm_flag
      nodes([nodes.node_ID] == rm_node_ID) = [];
   end

   % Combining rp_node.conn with rm_node.conn ends up having bad side-effects.
   % For a node in a standard hillsloper network, there are at most three links
   % in conn: two upstream links and their common downstream one. For a given
   % link, you can use the ds_link_ID and link_ID fields to eliminate two of
   % the three IDs in conn, leaving the other upstream one as the third. When
   % fixing the bad upstream drainage area issue, this (was) essential, because
   % it's the third ID in conn, the other upstream link, which has the "extra"
   % drainage area which needs to be subtracted. If rm_node.conn is combined
   % with rp_node.conn, then a fourth ID exists in conn (a second upstream
   % link), and its difficult or impossible to know which of the upstream links
   % carries the "extra area" without being in this function. Unfortunately,
   % it is necessary to combine the conn IDs for the upstream walk to work, e.g.
   % in plotlinks. So I added a special procedure to hillsloper.da to deal with
   % this, which loops over the us links, which is just one link in every case
   % except the one created by this function, which is two, and for this case,
   % it checks if the "extra area" is resolved by subtracting the da of the us
   % link and if so exits.
end
