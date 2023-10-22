function slopes = computeHillslopeTopo(slopes, fnametopo)

   % For each hillslope, need:
   % area (provided with slopes)
   % slope (provided with links, but links and slopes are not associative)
   % elevation (not provided)
   %
   % Update:
   % The new 'basins' (merged slopes) are associative with links, and has the
   % area field as before, and links has the slope, but only the slopes struct
   % has the area, elevation, and hillslope slope, so whether or not I use this
   % function to read in the external topo data and compute those values, I need
   % to process the merged slopes somehow, but I should be able to compute
   % weighted averages based on surface area. 
   %
   % area: basins (3250)
   % slope: links (3250) (but is this the right slope?)
   % elevation: slopes - but the values are 

   % warning('off') % so polyshape stops complaining
   
   % Try to activate topotoolbox
   success = true;
   try
      activate topotoolbox
   catch ME
      if strcmp(ME.identifier, 'MATLAB:UndefinedFunction')
         success = false;
      end
   end
   
   % Use topo toolbox to read the elevation data
   try
      DEM = GRIDobj(fnametopo); % elevation
      GRD = gradient8(DEM); % slope
   catch ME
      if strcmp(ME.identifier, 'MATLAB:UndefinedFunction')
         error('Topo Toolbox required.')
      end
   end

   % Try to read the data using mapping toolbox 
   try
      finfo = geotiffinfo(fnametopo);
      DEM.georef.SpatialRef.ProjectedCRS = finfo.CoordinateReferenceSystem;
      GRD.georef.SpatialRef.ProjectedCRS = finfo.CoordinateReferenceSystem;
      [~,R] = readgeoraster(fnametopo);   % spatial referencing
      res = R.CellExtentInWorldX;
      isgeo = false;
      if strcmp(R.CoordinateSystemType,'geographic'); isgeo = true;end
   catch ME
      if strcmp(ME.identifier,'MATLAB:license:checkouterror')
         % DEM.georef.SpatialRef.ProjectedCRS = ''; % not sure how to handle this
         % GRD.georef.SpatialRef.ProjectedCRS = ''; % not sure how to handle this
         res = DEM.cellsize;
         isgeo = false; % assume we're using ifsar
      end
   end

   % Get the x,y coords of the DEM
   [X, Y] = DEM.getcoordinates;
   [~, X, Y] = GRIDobj2mat(DEM);
   [X, Y] = meshgrid(X,Y);
   % I think the X, Y above were used in the inpolygon method commented out at
   % the end
   

   % for reference, from the sag_basin version:
   % load([pathtopo 'sag_dems'],'R','Z'); % 5 m dem, for plotting
   % [~,slope] = gradientm(Z,R);          % only works with geo coords

   % i used this to confirm that bbox in slopes is compatible with bbox2R
   % bbox = mapbbox(R, R.RasterSize(1), R.RasterSize(2));

   % Loop through the hillslopes and extract the mean elevation and slope
   for n = 1:numel(slopes)

      hs = slopes(n);
      if isfield(hs,'X')
         x = hs.X;
         y = hs.Y;
      elseif isfield(hs,'Lon')
         x = hs.Lon;
         y = hs.Lat;
         if islatlon(y,x)
            error('ambiguous coordinate system')
         end
      end
      hspoly = polyshape(x,y);

      % this is MUCH faster than inpolygon if a coarser res is used to query
      % the dem, with ~no impact on accuracy, since we're taking the mean.
      % If res=5, it gives identical results as inpolygon w/o coarsening

      % Construct a grid of points to interpolate the hillslope
      box = hs.BoundingBox;
      Rhs = bbox2R(box, res*5);
      
      [xhs, yhs] = R2grid(Rhs);
      
      xhs = reshape(xhs, size(xhs, 1) * size(xhs, 2), 1);
      yhs = reshape(yhs, size(yhs, 1) * size(yhs, 2), 1);
      ihs = inpolygon(xhs, yhs, x, y);
      
      if isgeo
         hslp = round(mean( ...
            geointerp(GRD.Z, R, yhs(ihs), xhs(ihs), 'linear'), 'omitnan'), 4);
         hele = round(mean( ...
            geointerp(DEM.Z, R, yhs(ihs), xhs(ihs), 'linear'), 'omitnan'), 0);
         harea = round(area(hspoly), 0);
      else
         hele = round(mean( ...
            mapinterp(DEM.Z, R, xhs(ihs), yhs(ihs), 'linear'), 'omitnan'), 0);
         hslp = round(mean( ...
            mapinterp(GRD.Z, R, xhs(ihs), yhs(ihs), 'linear'), 'omitnan'), 4);
         harea = round(area(hspoly), 0);
      end

      % try something different
      % idx = inpoly([X(:) Y(:)],[x y]); % way too slow

      % try topotoolbox interp

      if isnan(hele) || isnan(hslp) % set the resolution back to 5
         
         Rhs = bbox2R(box, res);
         
         [xhs,yhs] = R2grid(Rhs);
         
         xhs = reshape(xhs, size(xhs, 1) * size(xhs, 2), 1);
         yhs = reshape(yhs, size(yhs, 1) * size(yhs, 2), 1);
         ihs = inpolygon(xhs, yhs, x, y);
         
         hele = round(mean( ...
            mapinterp(DEM.Z, R, xhs(ihs), yhs(ihs), 'linear'), 'omitnan'), 0);
         
         hslp = round(mean( ...
            mapinterp(GRD.Z, R,xhs(ihs), yhs(ihs), 'linear'), 'omitnan'), 4);
         
         harea = round(area(hspoly),0);
      end
      
      % This builds a bounding box around the hillslope, then creates a grid of
      % points at res*5 x-y spacing, then takes the points within the hillslope
      % boundary, and queries the dem at those points.

      % put the values into the slopes table
      slopes(n).harea = harea;
      slopes(n).hslp = hslp;
      slopes(n).helev = hele;
   end
   
   % Below here is the part that added Lat Lon fields and checked for inserted
   % 90o Lats which i think is b/c of Nan separators
end

% for reference, this is the method that used inpolygon
% % i need the coordinates of the dem pixels
% [xdem,ydem] = pixcenters(R,R.RasterSize(1),R.RasterSize(2));
% [X,Y]       = meshgrid(xdem,ydem);
% Xrs         = reshape(X,size(X,1)*size(X,2),1);
% Yrs         = reshape(Y,size(Y,1)*size(Y,2),1);
%
% % reshape dem and slope then discard the objects
% elev        = double(reshape(DEM.Z,size(DEM.Z,1)*size(DEM.Z,2),1));
% slope       = double(reshape(G.Z,size(G.Z,1)*size(G.Z,2),1));
%
% clear xdem ydem X Y DEM G
% % this confirms that inpolygon works as expected
% % in        = inpolygon(Xrs,Yrs,x,y);
% % figure; plot(x,y); hold on; plot(Xrs(in),Yrs(in),'.')

% % and then inside the loop:
% hsidx       = inpolygon(Xrs,Yrs,x,y);           % dem pixels inside hs
% hslp        = roundn(mean(elev(hsidx)),-4);
% helev       = roundn(mean(elev(hsidx)),-4);