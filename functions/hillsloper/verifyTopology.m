function info = verifyTopology(slopes, links, basins, field, showinfo)
   %VERIFYTOPOLOGY Verify hillsloper topology is valid
   % 
   % INFO = VERIFYTOPOLOGY(SLOPES, LINKS, NODES, BASINS, FIELD, TRUE) finds
   % links with zero, nan, missing, or more than one element in FIELD, which
   % indicates bad topology, and returns information about the elements of
   % slopes, links, basins, and nodes needed to fix the bad topology.
   % 
   % If FIELD = 'hs_ID', then information is returned for slopes, links, nodes,
   % and basins, because they each have that field. 
   % 
   % If FIELD = 'link_ID', then information is returned for slopes and links,
   % because they each have that field but basins and nodes does not.
   % 
   % This function looks for links with zero, nan, missing, or more than one
   % element in the hs_ID field, which indicates bad topology. 
   % 
   % Common fields:
   % hs_ID           slopes, links, basins, nodes 
   % link_ID         slopes, links
   %
   % See also: removelink
   
   % TODO: add nodes
   
   if nargin < 4
      field = 'hs_ID';
   end
   if nargin < 5
      showinfo = false;
   end

   switch field
      case 'hs_ID'

         % links, slopes, and basins have hs_ID
         info.links = collectInfo(links, field, showinfo);
         info.slopes = collectInfo(slopes, field, showinfo);
         info.basins = collectInfo(basins, field, showinfo);

      case 'link_ID'

         % links and slopes have link_ID
         info.links = collectInfo(links, field, showinfo);
         info.slopes = collectInfo(slopes, field, showinfo);
         
      otherwise
         
   end

   % Get the link ID for the link with a nan hillslope. Note that the
   % information added below provides the info needed to fix hillsloper v2 sag
   % river basin, but I am not sure it would work in general. In this case,
   % there is one extra link, one extra node, and one extra basin, but there are
   % no extra slopes (the extra basin is only in the combined 'basins' struct,
   % the 'slopes' struct does not have the error).

   if sum(isnan([links.hs_ID])) > 0
      info.rm_link_ID = links(isnan([links.hs_ID])).link_ID;
      info.rm_node_ID = links([links.link_ID] == info.rm_link_ID).us_node_ID;
      
      % check if any slopes have the bad link id
      try
         % If the bad link is not associated with an hs_ID field in slopes, this
         % will be empty
         info.rm_slope_ID = slopes([slopes.link_ID] == info.rm_link_ID).hs_ID;
      catch
         % And in that case, the bad link should have nan in its hs_ID field
         info.rm_slope_ID = links(isnan([links.hs_ID])).hs_ID;
      end
   else
      info.rm_link_ID = [];
      info.rm_node_ID = [];
      info.rm_slope_ID = [];
   end

   % This shows how the bad slope ID doesn't exist because it is not present in
   % the 'slopes' struct, which the hs_ID field is mapped to. It is only in
   % links and basins.
   % rm_slope_ID = links([links.link_ID] == rm_link).hs_ID;

   % This is an alternative way to get the bad node programmatically, but this
   % returns both the upstream and downstream node of the bad link. The one to
   % remove is the downstream node, which it be possible to determine based on
   % the order of nodes.conn i.e. whether the bad link ID is first or laast, but
   % i am not sure
   % rm_node_idx = find(arrayfun(@(node) ismember(info.rm_link_ID, node.conn), nodes));
   % rm_node_ID = [nodes(rm_node_idx).node_ID];

   % Note that none of these are the bad hillslope, because the nodes are not
   % associated with 'slopes', and the bad hillslope doesn't exist in 'slopes'
   % it exists in 'basins'.
   % nodes(rm_node_idx).hs_ID;

   % NOTE: see getOutletFeatures. Depending on when this is called, that
   % function has some checks to verify the outlet is correct.

end

function info = collectInfo(data, field, showinfo)
   % Collects and summarizes the field from the given data structure

   % Count the number of field entries for each entry in data
   count = cellfun(@numel, {data.(field)});

   % Create summary information
   info.(field) = [data.(field)];
   info.([field '_count']) = count;
   info.([field '_num_unique']) = numel(unique([data.(field)])); % Note: includes nan
   info.([field '_num_nan']) = sum(isnan([data.(field)]));
   info.([field '_num_missing']) = sum(count==0);
   info.([field '_num_with_one_elem']) = sum(count==1);
   info.([field '_num_with_extra_elems']) = sum(count>1);

   info.elems_with_nan = data(isnan([data.(field)]));

   if showinfo
      if strcmp(inputname(1), 'links')
         fprintf('Counts for %s:  Zero %s: %d, One %s: %d, >1 %ss: %d, NaN %s: %d\n', ...
            inputname(1), field, sum(count==0), field, sum(count==1), field, ...
            sum(count>1), field, sum(isnan([data.(field)])));
      else
         fprintf('Counts for %s: Zero %s: %d, One %s: %d, >1 %ss: %d, NaN %s: %d\n', ...
            inputname(1), field, sum(count==0), field, sum(count==1), field, ...
            sum(count>1), field, sum(isnan([data.(field)])));
      end
   end
end
