function [links, nodes] = removelink(links, nodes, rm_link_ID, us_link_ID, ...
      ds_link_ID, rp_link_ID, slope_flag)
   %REMOVELINK Remove link from flow network and update connectivity attributes
   %
   %   rm_link     = id(s) to be removed
   %   us_links    = id(s) of links that flow into rm_link's upstream node
   %   ds_links    = id(s) of links that flow into rm_link's downstream node
   %   us_nodes    = rm_link's upstream node id
   %   ds_nodes    = rm_link's downstream node id
   %   rp_link     = id of link that replaces rm_link
   %   slope_flag  = remove the slope associated with rm_link
   %
   % In the example below, us_node = rm_node, and ds_node = rp_node.
   % Before the merge, rp_link has two upstream links: ds_link and rm_link.
   % After the merge, rp_link has three upstream links: ds_link, us_link1, and
   % us_link2. There is one fewer node  and one fewer link in the network.
   %
   % Before:
   %            us_node   rm_link   ds_node
   %                  ↓      ↓      ↓
   % o----------------o-------------o-------------o
   %         ↑       /             /       ↑
   %     us_links → /   ds_link → /     rp_link
   %               /             /
   %              o             /
   %                           o
   % After:
   %                                ds_node
   %                                ↓
   % o-----------------------------o-------------o
   %         ↑       -------------//       ↑
   %     us_links → /             /     rp_link
   %               /  ds_link →  /
   %              o             /
   %                           o
   %
   % The link removal creates a three-way confluence which does not exist in
   % a standard hillsloper network.
   %
   % us_link fields and how they are modified:
   %
   % link_ID      :  not modified                                 *
   % hs_ID        :  not modified                                 *
   % us_node_ID   :  not modified                                 *
   % us_link_ID   :  not modified                                 *
   % us_hs_ID     :  not modified
   % us_conn_ID   :  not modified
   % ds_node_ID   :  us_node is replaced with ds_node             *
   % ds_link_ID   :  rm_link is replaced with rp_link             *
   % ds_hs_ID     :  set to the us_link and rp_link slope ID's
   % ds_conn_ID   :  rm_link is replaced with rp_link
   %
   % ds_link fields and how they are modified:
   %
   % link_ID      :  not modified
   % hs_ID        :  not modified
   % us_node_ID   :  not modified
   % us_link_ID   :  not modified
   % us_hs_ID     :  not modified
   % us_conn_ID   :  not modified
   % ds_node_ID   :  not modified
   % ds_link_ID   :  not modified
   % ds_hs_ID     :  the rm_slope ID is removed
   % ds_conn_ID   :  rm_link is removed. rp_link is already present.
   %
   % rp_link fields and how they are modified:
   %
   % link_ID      :  not modified
   % hs_ID        :  not modified
   % us_node_ID   :  not modified
   % us_link_ID   :  not modified
   % us_hs_ID     :  not modified
   % us_conn_ID   :  not modified
   % ds_node_ID   :  not modified
   % ds_link_ID   :  not modified
   % ds_hs_ID     :  the rm_slope ID is removed
   % ds_conn_ID   :  rm_link is removed. rp_link is already present.
   %
   % rp_node fields that are modified:
   %
   % node_ID
   % hs_ID
   % conn
   %
   % See also:

   % TODO: add slopes and maybe basins input/output and convert to a general
   % 'fixtopology' function ... for the bad topology in hillsloper v2, slopes
   % does not have a bad slope, the hs_ID for the bad link is NaN. However,
   % 'basins' does have it, but it cannot be identified from the fields in
   % slopes, links, or nodes, because the hs_ID field for the bad link is NaN
   % in links and nodes. I determined the hs_ID is 428 in basins manually.

   if nargin < 7
      slope_flag = false;
   end
   if nargin < 8
      node_flag = false;
   end

   debug = false;

   %% Prepare the information about the replacement

   % Get the indices of the link to be removed and its replacement
   i_rm_link = ismember([links.link_ID], rm_link_ID);
   i_rp_link = ismember([links.link_ID], rp_link_ID);

   % Get the id's of the slopes that rm_link and rp_link drain
   if slope_flag == true
      rm_slope_ID = links(i_rm_link).hs_ID;
      rp_slope_ID = links(i_rp_link).hs_ID; % use this to update ds_hs_ID
   end

   % Get the id of the node to be removed and its replacement
   rm_node_ID = links(i_rm_link).us_node_ID;
   rp_node_ID = links(i_rp_link).us_node_ID;

   %% Process nodes
   [nodes, rm_node, rp_node] = hillsloper.mergenodes(nodes, ...
      rm_node_ID, rp_node_ID, rm_slope_ID, rm_link_ID, true);

   %% Process us_link's
   rp_link = links(i_rp_link);
   rm_link = links(i_rm_link);

   % Replace the ds link/node/conn in the us_link's (the links upstream of the
   % rm_link, this adjusts their downstream connectivity to connect to rp_link)
   for n = 1:length(us_link_ID)

      i_us_link = ismember([links.link_ID], us_link_ID(n));
      this_link = links(i_us_link);

      % Replace the downstream link and node ID
      this_link.ds_link_ID = rp_link_ID;
      this_link.ds_node_ID = rp_node_ID;

      % This is used if the us/ds connectivity was built with findDownstreamLinks
      if isfield(links, 'ds_conn_ID')
         this_link.ds_conn_ID = rp_node.conn;
      end
      if slope_flag == true && isfield(this_link, 'ds_hs_ID')
         this_link.ds_hs_ID = rp_node.hs_ID;
      end

      % Append rm_link to the us_links. This ensures the us links terminate at
      % the rp_node and their path follows the hillslope discretization, but
      % creates a co-located channel along the rm_link reach.
      this_link.X = [rmnan(this_link.X) rm_link.X];
      this_link.Y = [rmnan(this_link.Y) rm_link.Y];
      if isfield(this_link, 'Lat')
         this_link.Lat = [rmnan(this_link.Lat) rm_link.Lat];
      end
      if isfield(this_link, 'Lon')
         this_link.Lon = [rmnan(this_link.Lon) rm_link.Lon];
      end
      % Compute the combined length and weighted-mean slope
      combined_length = this_link.len_km + rm_link.len_km;
      this_link.slope = wmean([this_link.slope rm_link.slope], ...
         [this_link.len_km rm_link.len_km] ./ combined_length);
      this_link.len_km = combined_length;

      % Replace this us_link with the modified one
      links(i_us_link) = this_link;
   end

   if debug == true
      figure;
      plot(this_link.X, this_link.Y, 'b'); hold on;
      plot(rm_link.X, rm_link.Y, 'r');
      scatter(rp_node.X, rp_node.Y, 'g', 'filled')
      scatter(rm_node.X, rm_node.Y, 'r', 'filled')
   end

   %% Process ds_link: links that merge with rm_link at its downstream node
   for n = 1:length(ds_link_ID)

      i_ds_link = ismember([links.link_ID], ds_link_ID(n));
      this_link = links(i_ds_link);

      if isfield(this_link, 'ds_conn_ID')
         this_link.ds_conn_ID = rp_node.conn;
      end
      if slope_flag == true && isfield(this_link, 'ds_hs_ID')
         this_link.ds_hs_ID = rp_node.hs_ID;
      end
      % Replace the link
      links(i_ds_link) = this_link;
   end

   %% Process rp_link
   if isfield(rp_link, 'us_conn_ID')
      rp_link.us_conn_ID = rp_node.conn;
   end

   % This should replace the method below
   rp_link.us_link_ID = rp_node.conn;
   rp_link.us_link_ID(ismember(rp_link.us_link_ID, rp_link_ID)) = [];

   if isfield(rp_link, 'us_hs_ID')
      rp_link.us_hs_ID = rp_node.hs_ID;
   end

   % Next shouldn't be necessary if rp_node was processed at the beginning.
   % Remove rm_slope from rp_link's us_hs_ID
   if slope_flag == true && isfield(rp_link, 'us_hs_ID')
      idx_p = ismember(rp_link.us_hs_ID, rm_slope_ID);
      idx_m = ismember(rp_link.us_hs_ID, -rm_slope_ID);
      rp_link.us_hs_ID(idx_p) = [];
      rp_link.us_hs_ID(idx_m) = [];
   end

   %% Final steps

   % Replace the rp_link with the modified version
   links(i_rp_link) = rp_link;

   % Remove the link
   links(i_rm_link) = [];
end
