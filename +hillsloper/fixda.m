function basins = fixda(basins, links, nodes)

   % For testing:
   % n = 1;   % this is an endbasin which does not have the error
   % n = 164; % this one does

   for n = 1:numel(basins)

      if not(basins(n).endbasin)
         continue
      end

      hs_ID = basins(n).hs_ID;
      this_basin = hillsloper.getslope(basins, hs_ID);
      this_link = hillsloper.getlink(links, hs_ID, 'hs_ID');
      this_node = hillsloper.getnode(nodes, this_link.ds_node_ID, 'node_ID');

      % nodes.conn is a vector of link_IDs for the upstream/downstream links of
      % each node. It is 3x1 at 3-way confluences, and 2x1 at at 2-way. Not sure
      % if this will fail if a 4-way confluence is involved, which should only
      % occur with the "fixed" topology.
      if numel(this_node.conn) > 2

         % Simply assign the local area to the da.
         basins(n).da = basins(n).area_km2 * 1e6;

         % Double check that the extra area indeed matches the upstream
         % confluence drainage area.
         verifyarea(basins, links, this_basin, this_link, this_node)
      end
   end
end

function verifyarea(basins, links, this_basin, this_link, this_node)
   % This is a formal check that the "extra" area is resolved by subtracting
   % the da of the "other" upstream link at an endbasin confluence.

   % For clarity on these notes, refer to nodes.pptx.
   %
   % If this function is called on the hillsloper output before the topology
   % fix for the bad link (1391) is applied, it will fail on this_link_ID = 185,
   % which drains to link 1391. The problem is that this_conn_IDs does not
   % contain the "upstream confluence link" 1390, which is the one with the
   % extra drainage area. Instead it is [1391, 2663, 2665]. Since this_link_ID
   % is 185, and this_ds_link_ID is 2663, there remains two IDs in
   % this_conn_IDs, which are assigned to this_us_link_ID:
   %
   % this_us_link_ID = this_conn_IDs(~ismember(this_conn_IDs, ...
   %    [this_link_ID, this_ds_link_ID]));
   %
   % If it worked correctly, then this_conn_IDs would consist of this_link_ID,
   % this_ds_link_ID, and the third one would be the correct this_us_link_ID
   % (1390 in this case). Instead we get this_us_link_ID = 1391, 2665, which are
   % passed to getlink which fails, but that's good because neither of these are
   % the correct upstream link.
   %
   % All of that said, this is good because it means we can confirm whether it
   % works b/4 and after the topology fix. To confirm the correct result for the
   % pre-fix case, replace this_us_link_ID in this line with the known correct
   % one, 1390:
   %
   % this_us_link = hillsloper.getlink(links, 1390, 'link_ID');
   %
   % Then continue to check_extra_area and it matches.


   this_basin_da = this_basin.da;
   this_basin_area = this_basin.area_km2 * 1e6;
   this_extra_area = this_basin_da - this_basin_area;

   % this_extra_area should equal the da of the confluence link.
   % this_node.conn

   % To find the confluence link, we remove this link and this downstream
   % link_ID from the conn IDs, what remains is the upstream link_ID,
   % which is the link with the "extra" drainage area.
   this_conn_IDs = this_node.conn;
   this_link_ID = this_link.link_ID;
   this_ds_link_ID = this_link.ds_link_ID;
   this_us_link_ID = this_conn_IDs(~ismember(this_conn_IDs, ...
      [this_link_ID, this_ds_link_ID]));

   % To automate this, it might be quite complicated and/or impossible, so it
   % might be easier to revisit the removelink function and adjust the conn
   % field to be consistent with the original conn, e.g., the fix removes
   % link 1391, and connects link 185 to link 2663 instead. The og conn for
   % node 2332 where link 185 met 1391 would be 185, 1390, 1391. When 185 is
   % connected to 2663 instead, it now has the 1390 upstream and also 2665,
   % plus the downstream 2663, so 2665

   % This loop is only necessary because of the three-way confluence created in
   % hillsloper.removelink specifically in mergenodes when the rm_link conn ID
   % is combined with the rp_link conn ID resulting in a conn field with 4 IDs:
   % the original two upstream and downstream plus the new upstream (which
   % shares a common downstream).

   for n = 1:numel(this_us_link_ID)

      % The da field of this_us_link should equal the "extra area"
      this_us_link = hillsloper.getlink(links, this_us_link_ID(n), 'link_ID');
      this_us_basin = hillsloper.getslope(basins, this_us_link.hs_ID);

      check_extra_area = this_extra_area - this_us_basin.da;

      % If the independent check on the extra area is more than 1% off from the
      % extra area, flag it
      areaIsVerified = abs(check_extra_area / this_extra_area) * 100 < 1;

      if areaIsVerified
         break
      end
   end

   if not(areaIsVerified)
      warning('extra area does not match')
   end
end
