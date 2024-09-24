function basins = fixda(basins, links, nodes)

   % Was gonna use this as gpt prompt and then push an actual solution to jon
   
   for n = 1:numel(basins)

      if not(basins(n).endbasin)
         continue
      end

      hs_ID = basins(n).hs_ID;
      this_basin = hillsloper.getslope(basins, hs_ID);
      this_link = hillsloper.getlink(links, hs_ID, 'hs_ID');
      this_node = hillsloper.getnode(nodes, this_link.ds_node_ID, 'node_ID');

      % nodes.conn is a vector of link_IDs for the upstream/downstream links of
      % each node. It is 3x1 at 3-way confluences (upstream tributary), and 2x1
      % at at 2-way (linear upstream-downstream connectivity, no upstream trib)
      if numel(this_node.conn) > 2

         % Simply assign the local area to the da.
         basins(n).da = basins(n).area_km2 * 1e6;

         % Double check that the extra area indeed matches the upstream
         % confluence drainage area.
         verifyarea(basins, links, this_basin, this_link, this_node)
      end
   end
end
