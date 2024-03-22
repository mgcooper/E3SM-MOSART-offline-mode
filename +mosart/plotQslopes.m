function h = plotQslopes(mosart,varargin)
   %PLOTQSLOPES Plots a map of links colored by discharge D
   %
   %  H = PLOTQSLOPES(MOSART,VARARGIN)
   %
   % See also:


   % check if an axis handle is provided (credit to Kelley Kearney, function
   % 'boundedline', for this argument check)
   isax = cellfun(@(x) isscalar(x) && ishandle(x) && ...
      strcmp('axes', get(x,'type')), varargin);

   if any(isax)
      ax = varargin{isax};
      varargin = varargin(~isax);
   else
      ax = gca; % get handle for existing figure and/or create a new axis object
   end

   if nargin>1 && strcmp(varargin{1},'log')

      flag = true;
      Data = [mosart.logD];
      minD = min(Data(:));
      maxD = max(Data(:));
      cmap = parula(numel(Data));
      spec = makesymbolspec( ...
         'Polygon', ...
         {'logD',[minD maxD], ...
         'FaceColor',cmap, ...
         'FaceAlpha',0.95, ...
         'EdgeColor','none'} ...
         );
   else
      flag = false;
      Data = [mosart.D];
      minD = min(Data(:));
      maxD = max(Data(:));
      cmap = parula(numel(Data));
      spec = makesymbolspec( ...
         'Polygon', ...
         {'D',[minD maxD], ...
         'FaceColor',cmap, ...
         'FaceAlpha',0.95, ...
         'EdgeColor','none'} ...
         );
   end

   % make the figure
   % f = figure;

   if ~isfield(mosart,'X') && isfield(mosart,'X_hs')
      for n = 1:numel(mosart)
         mosart(n).X = mosart(n).X_hs;
         mosart(n).Y = mosart(n).Y_hs;
      end
   end

   h1 = mapshow(ax,mosart,'SymbolSpec',spec);

   % make the colorbar
   caxis([minD maxD])
   c = colorbar;

   if flag == true
      Data = exp(Data); %
      if max(Data(:)) > 100 && max(Data(:)) <= 1000
         c.Limits        = [minD/1.2 maxD*1.2];
         c.Ticks         = log([0.001 0.01 0.1 1 10 100 1000]);
         c.TickLabels    = {'0.001','0.01','0.1','1','10','100','1000'};
      elseif max(Data(:)) > 10 && max(Data(:)) <= 100
         c.Limits        = [minD/1.2 maxD*1.2];
         c.Ticks         = log([0.001 0.01 0.1 1 10 100]);
         c.TickLabels    = {'0.001','0.01','0.1','1','10','100'};
      elseif max(Data(:)) > 1 && max(Data(:)) <= 10
         c.Limits        = [minD/1.2 maxD*1.2];
         c.Ticks         = log([0.001 0.01 0.1 1 10]);
         c.TickLabels    = {'0.001','0.01','0.1','1','10'};
      elseif max(Data(:)) > 0.1 && max(Data(:)) <= 1
         c.Limits        = [minD/1.2 maxD*1.2];
         c.Ticks         = log([0.001 0.01 0.1 1]);
         c.TickLabels    = {'0.001','0.01','0.1','1'};
      else
         c.Limits        = [minD/1.2 maxD*1.2];
         c.Ticks         = log([0.001 0.01 0.1]);
         c.TickLabels    = {'0.001','0.01','0.1'};
      end
   end

   c.Label.String = 'm$^3$ s$^{-1}$';
   c.Label.FontSize = 18;

   xlabel('Easting (m)'); ylabel('Northing (m)');

   h.h = h1;
   h.c = c;

   axis image

   figformat

   h.c.Label.Interpreter='latex';
   h.c.Label.FontSize=20;
end
