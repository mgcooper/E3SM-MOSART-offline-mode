function h = plotQlinks(links,slopes,varargin)
   %PLOTQLINKS Plots a map of links colored by discharge D
   %
   %  H = PLOTQLINKS(LINKS, SLOPES, VARARGIN)
   %
   % See also:

   if nargin>2 && strcmp(varargin{1},'log')

      flag = true;
      Data = [links.logD];
      minD = min(Data(:));
      maxD = max(Data(:));
      cmap = parula(numel(Data));
      spec = makesymbolspec( ...
         'Line', ...
         {'logD',[minD maxD],'Color',cmap,'LineWidth',3} ...
         );
   else

      flag = false;
      Data = [links.D];
      minD = min(Data(:));
      maxD = max(Data(:));
      cmap = parula(numel(Data));
      spec = makesymbolspec( ...
         'Line', ...
         {'D',[minD maxD],'Color',cmap,'LineWidth',3});
   end

   % make the figure
   f = figure;

   % for n = 1:numel(slopes)
   %    plot(slopes(n).X_hs,slopes.Y_hs)
   % end

   if ~isfield(slopes,'X') && isfield(slopes,'X_hs')
      for n = 1:numel(slopes)
         slopes(n).X = slopes(n).X_hs;
         slopes(n).Y = slopes(n).Y_hs;
      end
   end

   % SYMBOLSPEC FOR THE SLOPES
   slopespec = makesymbolspec( ...
      'Polygon', ...
      {'Default', ...
      'FaceColor',rgb('forest green'), ...
      'FaceAlpha',0.15, ...
      'EdgeColor','k'} ...
      );

   % PLOT THE SLOPES
   mapshow(slopes,'SymbolSpec',slopespec); hold on;

   % PLOT THE LINKS
   h1 = mapshow(links,'SymbolSpec',spec);

   % make the colorbar
   caxis([minD maxD])
   c = colorbar;

   if flag == true
      if max(Data(:)) > 10 && max(Data(:)) <= 100
         c.Ticks = log([0.01 0.1 1 10 100]);
         c.TickLabels = {'0.01','0.1','1','10','100'};
      elseif max(Data(:)) > 1 && max(Data(:)) <= 10
         c.Ticks = log([0.01 0.1 1 10]);
         c.TickLabels = {'0.01','0.1','1','10'};
      elseif max(Data(:)) > 0.1 && max(Data(:)) <= 1
         c.Ticks = log([0.01 0.1 1]);
         c.TickLabels = {'0.01','0.1','1'};
      else
         c.Ticks = log([0.01 0.1]);
         c.TickLabels = {'0.01','0.1'};
      end
   end

   c.Label.String = 'm$^3$ s$^{-1}$';
   c.Label.FontSize = 18;

   h.f = f;
   h.h = h;
   h.c = c;

   xlabel('Easting (m)'); ylabel('Northing (m)');
   axis image

   % figformat('linelinewidth',3)

   h.c.Label.Interpreter='latex';
   h.c.Label.FontSize=20;
end
