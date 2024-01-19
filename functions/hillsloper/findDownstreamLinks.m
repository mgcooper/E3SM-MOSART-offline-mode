function [links, inletID, outletID] = findDownstreamLinks(links, nodes)
   %FINDDOWNSTREAMLINKS add ID->dnID connectivity and inlet/outlet info to links
   %
   % links = findDownstreamLinks(links,nodes) uses LINKS and NODES geostructs
   % from readHillsloperData output to identify upstream/downstream link
   % connectivity and basin inlet (headwater) and outlet links; 
   % 
   % [links,inletID,outletID] = findDownstreamLinks(links,nodes) also returns
   % the inlet and outlet link_IDs
   % 
   % The following fields are added to LINKS:
   %  ds_link_ID
   %  us_hs_ID
   %  ds_hs_ID
   %  us_conn_ID
   %  ds_conn_ID
   %  isInlet
   %  isOutlet
   % 
   % definitions
   %
   % hs_ID         = id of the hillslope in which a link exists
   % us_hs_ID      = hillslopes upstream of the upstream node
   % ds_hs_ID      = hillslopes upstream of the downstream node
   %
   % See also:

   inletID = zeros(numel(links),1);
   outletID = [];

   [links.us_hs_ID] = deal([]);
   [links.ds_hs_ID] = deal([]);
   [links.ds_link_ID] = deal([]);
   [links.us_conn_ID] = deal([]);
   [links.ds_conn_ID] = deal([]);
   [links.isInlet] = deal(false);
   [links.isOutlet] = deal(false);

   % % the reason this doesn't work is b/c i_ds is not scalar in the loop
   % outletID = sort(find(cellfun(@numel,{nodes.conn})==1));

   % foundout = false;

   % % This note was in makenewslopes. The loop was in both makenewlinks and
   % makenewslopes but I moved it out of makenewslopes after fine tuning it and
   % renameing makenewlinks findDownstreamLinks. My interpretation of the note is
   % that it is good that this loop is no longer in makenewslopes, but
   % findDownstreamLinks has to be run first before makenewslopes, meaning the
   % domains that didn't have orphan links such as trib_basin for whcih I went
   % straight to makenewslopes will now need findDownstreamLinks as a pre-step

   % % NOTE: this loop sets the ds_link_ID but the numbering doesn't follow
   % % n=1:numel(links), so this loop must complete before adding additional
   % % information based on the link_ID -> ds_link_ID connectivity.
   % % TLDR: don't add stuff to this loop.
   
   % Note: The length(us_conn_id) > 1 condition is key to determine the flow
   % network, together with the inletID and outletID conditions), because it
   % indicates confluences, and i think walking each confluence guarantees
   % coverage

   for n = 1:numel(links)

      % Get the IDs of the current link and its upstream and downstream nodes
      hs_link_id = links(n).link_ID;
      us_node_id = links(n).us_node_ID;
      ds_node_id = links(n).ds_node_ID;

      % Get the index of the upstream and downstream nodes in the 'nodes' struct
      i_us = [nodes.node_ID] == us_node_id;
      i_ds = [nodes.node_ID] == ds_node_id;

      % Get the hillslope IDs and connectivity for upstream and downstream nodes
      us_hs_id = nodes(i_us).hs_ID;
      ds_hs_id = nodes(i_ds).hs_ID;
      us_conn_id = nodes(i_us).conn;
      ds_conn_id = nodes(i_ds).conn;
      % 'hs_id' and 'conn' are the only two pieces of info in nodes

      % u_id = upstream link id
      if length(us_conn_id) > 1 % this is a confluence
         u_id = us_conn_id(us_conn_id ~= hs_link_id);
         indx = length(u_id);
         while indx > 0
            i_ul = ismember([links.link_ID], u_id(indx));
            links(i_ul).ds_link_ID = hs_link_id;
            indx = indx - 1;
         end
      end

      links(n).us_hs_ID = us_hs_id;
      links(n).ds_hs_ID = ds_hs_id;
      links(n).us_conn_ID = us_conn_id;
      links(n).ds_conn_ID = ds_conn_id;

      if length(us_conn_id) == 1
         inletID(n) = hs_link_id;
         links(n).isInlet = true;
      end

      if length(ds_conn_id) == 1
         % foundout = true;
         outletID = hs_link_id;
         links(n).isOutlet = true;
      end

   end

   % replace the empty ds_link_ID for the outlet link with nan
   links(cellfun(@isempty, {links.ds_link_ID})).ds_link_ID = nan;

   % Remove unused values from inletID
   inletID = inletID(inletID ~= 0);

   % Check if the hillslope numbering is consecutive
   if any(diff([links.link_ID]) > 1)
      % assert(false, 'Hillslope ID numbering is not consecutive');
      warning('Hillslope ID numbering is not consecutive');
   end

   % Confirm that the link with the largest upstream drainage area is the outlet
   assertEqual( ...
      links(max([links.us_da_km2]) == [links.us_da_km2]).link_ID, ...
      outletID)
   
   % % 20 March 2023, commented this out b/c it complicates comparison with the og
   % % shapefiles e.g. in qgis trying to sort out orphan links/nodes
   % % Renumber the link_ID field to start at 1, rather than zero
   % if any([links.link_ID] == 0)
   %     for n = 1:length(links)
   %       links(n).link_ID = links(n).link_ID + 1;
   %       links(n).ds_link_ID = links(n).ds_link_ID + 1;
   %     end
   %     inletID = inletID + 1;
   %     outletID = outletID + 1;
   % end
end
