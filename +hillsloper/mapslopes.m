function mapslopes(slopes, links, nodes, boundary, option)
   %MAPSLOPES Plot hillsloper slopes, links, and nodes using mapshow
   %
   % Alternative to plothillsloper

   if nargin < 5
      option = 'worldmap';
   end

   % for now keep these false
   labelnodes = false;
   labellinks = false;

   % As long as slopes, nodes, and links were loaded using hillsloper.readfiles,
   % they should have Lat/Lon fields and X/Y
   try
      [latSlopes, lonSlopes] = latlonFromGeoStruct(slopes);
      [latNodes, lonNodes] = latlonFromGeoStruct(nodes);
      [latLinks, lonLinks] = latlonFromGeoStruct(links);
   catch
   end

   latlims = [min(latNodes) max(latNodes)]; % + [-0.001 0.001];
   lonlims = [min(lonNodes) max(lonNodes)]; % + [-0.001 0.001];

   specs = hillsloper.createSymbolSpecs();

   % plot using mapshow
   if strcmp(option, 'mapshow')

      figure;
      mapshow(slopes); hold on;
      mapshow(links, 'SymbolSpec', specs.links); hold on
      mapshow(nodes, 'SymbolSpec', specs.nodes);

   elseif strcmp(option, 'worldmap')

      % plot using worldmap with plotm
      figure
      geomap(latSlopes, lonSlopes)

      plotm(latSlopes, lonSlopes, 'g'); hold on;
      plotm(latNodes, lonNodes, 'ro'); formatPlotMarkers;
      plotm(latLinks, lonLinks, 'b');

      % Not sure if scatterm is more performant than plotm
      % scatterm(latNodes, lonNodes, 6, 'filled')

   elseif strcmp(option, 'geoshow')

      % plot using geoshow
      figure;
      worldmap(latlims, lonlims);
      geoshow(nodes, 'SymbolSpec', specs.nodes)

   end

   if labelnodes

      % jitter for the labels
      jitterx = (lonlims(2)-lonlims(1))/80; %#ok<*UNRCH>
      jittery = (latlims(2)-latlims(1))/80;

      x = lonNodes + jitterx / 2;
      y = latNodes + jittery / 2;

      % probably don't want this for entire sag basin
      for n = 1:length(nodes)
         nid = num2str(nodes(n).id);
         textm(y(n), x(n), nid, 'Color', 'r', 'FontSize', 12)
      end
   end

   if labellinks

      % This plots the link ids on the slopes, but is too slow for full Sag

      x = lonSlopes;
      y = latSlopes;

      for n = 1:length(slopes)

         % plot(slopes(n).Lon,slopes(n).Lat,'Color','g'); hold on;

         jitterx = rand*(max(x)-min(x));
         jittery = rand*(max(y)-min(y));

         nx = nanmean(x)-(rand*jitterx/2);
         ny = nanmean(y)-(rand*jittery/2);

         nid = num2str(slopes(n).link_ID);
         text(nx, ny, nid, 'Color', 'r', 'FontSize', 12);
      end
   end
end

%%
function plotm_hillsloper(slopes, links, nodes)

   % This is only here temporarily to get it out of the bottom of
   % b_make_newslopes. The reason it is so slow is the polyshape creation.
   % Not sure if the loop over the struct is faster than calling
   % latlonFromGeostruct like I do in the main function above.

   % this is extremely slow with the entire sag basin

   % jitter for the labels
   latlims = [min([nodes.Lat]) max([nodes.Lat])];
   lonlims = [min([nodes.Lon]) max([nodes.Lon])];
   freq = 1;

   figure
   worldmap(latlims, lonlims);

   % plot the hillslope outlines
   for n = 1:length(slopes)
      plotm(slopes(n).Lat,slopes(n).Lon,'Color','b');
   end

   % plot the river network ('links')
   for n = 1:length(links)
      plotm(links(n).Lat,links(n).Lon,'-','Color','g');
   end

   % plot the river network nodes
   for n = 1:length(nodes)
      plotm(nodes(n).Lat,nodes(n).Lon,'.','Color','r','MarkerSize',20);
   end

   % label the hillslopes
   for n = 1:freq:length(slopes)
      shpn = polyshape(slopes(n).Lon,slopes(n).Lat);
      [cx,cy] = centroid(shpn);
      textm(cy,cx,int2str(slopes(n).hs_id),'Color','b','FontSize',14)
   end

   % label the river reaches
   for n = 1:freq:length(links)
      % links.id
      ry = nanmean(links(n).Lat)+jittery;
      rx = nanmean(links(n).Lon)+jitterx;
      rid = int2str(links(n).id);
      textm(ry,rx,rid,'Color',rgb('dark green'),'FontSize',12)
   end

   % label nodes.id
   for n = 1:freq:length(nodes)
      nx = nodes(n).Lon+jitterx/2;
      ny = nodes(n).Lat+jittery/2;
      nid = num2str(nodes(n).id);
      textm(ny,nx,nid,'Color','r','FontSize',12)
   end

   % label nodes.sbasins
   % for n = 1:freq:length(nodes)
   %     nx = nodes(n).Lon-jitterx;
   %     ny = nodes(n).Lat-jittery;
   %     nid = nodes(n).sbasins;
   %     textm(ny,nx,nid,'Color',rgb('dark red'),'FontSize',12)
   % end
end
