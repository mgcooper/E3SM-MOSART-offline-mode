function outlet = getOutletFeatures(slopes, links, nodes, varargin)
   %GETOUTLETFEATURES Get the outlet slope, link, and node
   %
   % GETOUTLETFEATURES(SLOPES, LINKS, NODES)
   % GETOUTLETFEATURES(SLOPES, LINKS, NODES, 'PLOT', TRUE, 'BASIN', BASIN)
   %
   % BASIN = basin outline (full basin)
   %
   % See also;

   % call this with newlinks
   %
   % Also try this, added in findDownstreamLinks:
   % newlinks([newlinks.isOutlet]);
   
   [args, params, nargs] = parseparampairs(varargin, [], 'asstruct');

   ID = [links.link_ID];
   dnID = [links.ds_link_ID];

   try
      outlet.link = links([links.isOutlet]);
   catch e
      try
         outlet.link = links(ID == outletID);
      catch
         rethrow(e)
      end
   end

   outlet.node = nodes([nodes.node_ID] == 0);

   % Confirm that the outlet has the max upstream drainage area
   assertEqual( ...
      ID(max([links.us_da_km2]) == [links.us_da_km2]), ...
      outlet.link.link_ID)
   
   % Compute the basin area in m2 for comparison with the known area of the basin
   outlet.basinarea = max([links.us_da_km2])*1000*1000;

   % % This was at the bottom of b_make_newslopes. Call to polyshape should be
   % removed, at minimum, and this might not be needed at all with newer basins
   % data structure.
   %
   % % Confirms the total area of the slopes in units of m2
   % slopeArea = zeros(length(slopes), 1);
   % for n = 1:length(slopes)
   %    slopeArea(n) = area(polyshape(slopes(n).X, slopes(n).Y));
   % end
   % % sum(slopeArea) = 12962255025;

   if params.plot
      plotOutlet(outlet, params.basin)
   end
end

function plotOutlet(outlet, bounds)
   try
      figure;
      plot(bounds.X, bounds.Y); hold on;
      plot([outlet.link.X], [outlet.link.Y], 'r');
      plot([outlet.node.X], [outlet.node.Y], 'o', 'MarkerFaceColor', 'g', ...
         'MarkerEdgeColor', 'none');
   catch ME

   end
end
