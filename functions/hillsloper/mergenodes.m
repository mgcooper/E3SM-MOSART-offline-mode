function [nodes, rm_node, rp_node] = mergenodes(nodes, rm_node_ID, rp_node_ID, ...
      rm_slope_ID, rm_link_ID, rm_flag)
   %MERGENODES Merge two nodes into one, combining attributes.
   %
   % 
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
end
