function h = plotQslopes(mosart,varargin)
   %PLOTQLINKS Plots a map of links colored by discharge D
   %
   %
   %
   % See also:

   % check if an axis handle is provided (credit to Kelley Kearney, function
   % 'boundedline', for this argument check)
   isax = cellfun(@(x) isscalar(x) && ishandle(x) &&                   ...
      strcmp('axes', get(x,'type')), varargin);
   if any(isax)
      ax = varargin{isax};
      varargin = varargin(~isax);
   else
      % get handle for existing figure and/or create a new axis object
      ax = gca;
   end

   hold on;

   if nargin>1 && strcmp(varargin{1},'log')

      D = [mosart.logD];
      minD = min(D(:));
      maxD = max(D(:));
      cmap = parula(numel(D));

      Dspec = makesymbolspec( ...
         'Polygon',{ ...
         'logD',         [minD maxD], ...
         'FaceColor',    cmap, ...
         'FaceAlpha',    0.95, ...
         'EdgeColor',    'none'} ) ;
   else

      D = [mosart.D];
      minD = min(D(:));
      maxD = max(D(:));
      cmap = parula(numel(D));

      Dspec = makesymbolspec( ...
         'Polygon',{ ...
         'logD',         [minD maxD], ...
         'FaceColor',    cmap, ...
         'FaceAlpha',    0.95, ...
         'EdgeColor',    'none'} ) ;
   end

   % make the figure
   h = mapshow(ax,mosart,'SymbolSpec',Dspec);
   caxis([minD maxD]) % set the colorbar
end
