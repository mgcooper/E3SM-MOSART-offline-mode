function plotBasinLinks(basins, links, hs_id_list, slopes)

   % Use this to confirm the links.hs_ID correctly map onto basins.hs_ID

   if nargin < 3
      hs_id_list = [links.hs_ID];
   end

   if nargin == 4
      plotSlopesLinks(basins, links, slopes, hs_id_list)
   end

   % figontop
   figure
   for n = 1:numel(hs_id_list)

      hs_id = hs_id_list(n);

      slope = hillsloper.getslope(basins, hs_id);
      link = hillsloper.getlink(links, hs_id, 'hs_ID');

      link_lat = rmnan([link.Lat]);
      link_lon = rmnan([link.Lon]);

      slope_lat = rmnan([slope.Lat]);
      slope_lon = rmnan([slope.Lon]);

      plot(slope_lon, slope_lat); hold on
      plot(link_lon, link_lat);
      title(['n = ' num2str(n) ', hs id = ' num2str(hs_id)])

      % Activate this to plot all in a loop to confirm
      % pause; clf
   end

end

function plotSlopesLinks(basins, links, slopes, hs_id_list)

   hs_id_list = [links.hs_ID];

   figure
   for n = 1:numel(hs_id_list)

      hs_id = hs_id_list(n);

      [slope_p, slope_n] = hillsloper.getslope(slopes, hs_id);
      basin = hillsloper.getslope(basins, hs_id);
      link = hillsloper.getlink(links, hs_id, 'hs_ID');


      link_lat = rmnan([link.Lat]);
      link_lon = rmnan([link.Lon]);

      basin_lat = rmnan([basin.Lat]);
      basin_lon = rmnan([basin.Lon]);

      slope_p_lat = rmnan([slope_p.Lat]);
      slope_p_lon = rmnan([slope_p.Lon]);

      slope_n_lat = rmnan([slope_n.Lat]);
      slope_n_lon = rmnan([slope_n.Lon]);

      plot(basin_lon, basin_lat); hold on
      plot(slope_p_lon, slope_p_lat, ':');
      plot(slope_n_lon, slope_n_lat, ':');
      plot(link_lon, link_lat, 'b');
      title(['n = ' num2str(n) ', hs id = ' num2str(hs_id)])

      % Activate this to plot all in a loop to confirm
      pause; clf
   end

end
