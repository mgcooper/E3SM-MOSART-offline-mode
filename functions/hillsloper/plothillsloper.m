function plothillsloper(slopes,links,varargin)
   %PLOTHILLSLOPER Plot the slopes, links, and nodes from hillsloper
   %
   %  Syntax
   %
   %     plothillsloper(slopes, links) plots the slopes and links
   %     plothillsloper(slopes, links, nodes) also plots the nodes
   %
   %  See also

   %% parse inputs
   parser = inputParser();
   parser.FunctionName = mfilename;
   parser.StructExpand = false;
   parser.addRequired('slopes', @isstruct);
   parser.addRequired('links', @isstruct);
   parser.addOptional('nodes', [], @isstruct);
   parser.addParameter('pauseflag', false, @islogical);
   parser.addParameter('labelflag', false, @islogical);
   parser.addParameter('labelfields', {''}, @iscell);
   parser.parse(slopes, links, varargin{:});

   % This is used to create fieldnames for each data structure to pass to
   % labelpoints, to label the links, slopes, and nodes. The fieldnames are the
   % 'labelfields' input parameter.
   opts.links = '';
   opts.slopes = '';
   opts.nodes = '';
   opts = parse_pv_pairs(opts, parser.Results.labelfields);
   
   nodes = parser.Results.nodes;
   pauseflag = parser.Results.pauseflag;
   labelflag = parser.Results.labelflag;
   labelfields = parser.Results.labelfields;
   
   plotnodes = false;
   if ~isempty(nodes)
      plotnodes = true;
   end

   labelflag = false;
   if ~isempty(labelfields)
      labelflag = true;
   end

   % % old parsing
   % plotnodes = false;
   % if nargin >= 3
   %    plotnodes = true;
   %    if nargin == 3
   %       pauseflag = false;
   %    end
   % end

   % need to determine if both slopes and nodes have planar and/or geo coords

   %% Create the figure
   
   figure; hold on;

   for n = 1:numel(slopes)

      % Search for planar coords first, then convert to planar if geo is found.s
      if isfield(slopes,'X_hs')
         lonn = [slopes(n).X_hs];
      elseif isfield(slopes,'X')
         lonn = [slopes(n).X];
      elseif isfield(slopes,'Lon_hs')
         lonn = [slopes(n).Lon_hs];
      elseif isfield(slopes,'Lon')
         lonn = [slopes(n).Lon];
      elseif isfield(slopes,'lon')
         lonn = [slopes(n).lon];
      end

      if isfield(slopes,'Y_hs')
         latn = [slopes(n).Y_hs];
      elseif isfield(slopes,'Y')
         latn = [slopes(n).Y];
      elseif isfield(slopes,'Lat_hs')
         latn = [slopes(n).Lat_hs];
      elseif isfield(slopes,'Lat')
         latn = [slopes(n).Lat];
      elseif isfield(slopes,'lat')
         latn = [slopes(n).lat];
      end

      % If lat/lon are not vectors, they are probably the slope centroid
      if isscalar(latn) || isscalar(lonn)
         warning('no hillslope outlines found')
      end

      % If no X_hs,Y_hs were found, convert the lat-lon to utm
      if islatlon(latn,lonn)
         [x,y] = ll2utm(latn,lonn);
      else
         x = lonn;
         y = latn;
      end
      plot(x,y,'Color','g');

      if labelflag && ~isempty(opts.slopes)
         xlab = mean(lonn,'omitnan');
         ylab = mean(latn,'omitnan');
         labelpoints(xlab,ylab,num2str(slopes(n).(opts.slopes)),'Color','g');
      end
   end

   for n = 1:numel(links)

      if isfield(links,'X')
         lonn = [links(n).X];
      elseif isfield(links,'Lon')
         lonn = [links(n).Lon];
      elseif isfield(links,'lon')
         lonn = [links(n).lon];
      end

      if isfield(links,'Y')
         latn = [links(n).Y];
      elseif isfield(links,'Lon')
         latn = [links(n).Lat];
      elseif isfield(links,'lon')
         latn = [links(n).lat];
      end

      % If no X,Y were found, convert the lat-lon to utm
      if islatlon(latn,lonn)
         [x,y] = ll2utm(latn,lonn);
      else
         x = lonn;
         y = latn;
      end

      plot(x,y,'Color','b');

      if labelflag && ~isempty(opts.links)
         xlab = mean(lonn,'omitnan');
         ylab = mean(latn,'omitnan');
         labelpoints(xlab,ylab,num2str(links(n).(opts.links)),'Color','b');
      end

      if pauseflag
         pause;
      end
   end

   if plotnodes
      for n = 1:length(nodes)

         if isfield(nodes,'X')
            lonn = [nodes(n).X];
         elseif isfield(nodes,'Lon')
            lonn = [nodes(n).Lon];
         elseif isfield(links,'lon')
            lonn = [nodes(n).lon];
         end

         if isfield(nodes,'Y')
            latn = [nodes(n).Y];
         elseif isfield(nodes,'Lat')
            latn = [nodes(n).Lat];
         elseif isfield(links,'lat')
            latn = [nodes(n).lat];
         end

         % If no X,Y were found, convert the lat-lon to utm
         if islatlon(latn,lonn)
            [x,y] = ll2utm(latn,lonn);
         else
            x = lonn;
            y = latn;
         end
         scatter(x,y,125,'k','filled');

         if labelflag && ~isempty(opts.nodes)
            xlab = mean(lonn,'omitnan');
            ylab = mean(latn,'omitnan');
            labelpoints(xlab,ylab,num2str(nodes(n).(opts.nodes)),'Color','k');
         end
      end
   end

   axis image
   xlabel('Easting (m)');
   ylabel('Northing (m)');
   hold off;

   % ax = gca;
   % ax.YAxis.TickLabels = compose('%g',ax.YAxis.TickValues);
end

function plotInlets(slopes, links, nodes)
   
   geoshow(nodes(inletID),'SymbolSpec',specs.nodes); hold on;
   geoshow(links,'SymbolSpec',specs.links);
   geoshow(nodes(~inletID),'SymbolSpec',specs.outletnode);
   geoshow(nodes(outletID),'SymbolSpec',specs.outletnode); % WRONG
   geoshow(newlinks(outletID),'SymbolSpec',specs.newlinks); % WRONG (but close)
   geoshow(newslopes(outletID),'SymbolSpec',specs.slopes); % WRONG (but close)
   
end

function plotOutlet(slopes, links, nodes)
   
   outletNode = nodes(outletID);
   outletLink = links(outletID);
   
   hold on;
   plot(outletNode.X, outletNode.Y, 'o', 'MarkerEdgeColor', 'none', ...
      'MarkerSize', 20, 'MarkerFaceColor', 'r')
   
   plot(outletLink.X, outletLink.Y, '-', 'Color', 'r')
   
   
   
   [x, y] = ll2utm(outletNode.Lat, outletNode.Lon);
   
   geoshow(nodes(inletID),'SymbolSpec',specs.nodes); hold on;
   geoshow(links,'SymbolSpec',specs.links);
   geoshow(nodes(~inletID),'SymbolSpec',specs.outletnode);
   geoshow(nodes(outletID),'SymbolSpec',specs.outletnode); % WRONG
   geoshow(newlinks(outletID),'SymbolSpec',specs.newlinks); % WRONG (but close)
   geoshow(newslopes(outletID),'SymbolSpec',specs.slopes); % WRONG (but close)
end
