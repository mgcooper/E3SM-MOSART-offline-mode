function [schema,info,data] = mosartMakeDomainFile(slopes,ftemplate,fsave,opts)
   % MOSARTMAKEDOMAINFILE build domain file for MOSART
   %
   %  Inputs
   %
   %     'slopes' : a structure with the following fields:
   %
   %     longxy   : latitude of computational unit, scalar
   %     latixy   : longitude of computational unit, scalar
   %     area     : area in m2
   %
   %  Outputs
   %
   %     'schema' : netcdf schema for the domain file
   %     'info'   : ncinfo struct for the domain file
   %     'data'   : ncread output, the data written to the file
   %
   % See also

   % these are the variables created by this function:
   %vars = {'xc','yc','xv','yv','mask','area','frac'};
   vars = {'xc','yc','mask','area','frac'};

   % number of hillslope units in the domain
   ncells = numel(slopes);

   % to compute the surface area of each sub-basin in units of steradians
   Aearth = 510099699070762; % m2, this is earth area defined in E3SM
   % Aearth  = 510065621724089;     % this is the area i used previously

   % assign values to each variable
   data.xc = wrapTo360([slopes.longxy]');
   data.yc = [slopes.latixy]';
   data.mask = int32(ones(ncells,1));
   data.frac = double(ones(ncells,1));
   data.area = ([slopes.area].*4.*pi./Aearth)'; % steradians

   % compute the bounding box of each sub-basin
   data.xv = nan(4,ncells);                    % x vertices
   data.yv = nan(4,ncells);                    % y vertices

   % should be as simple as this:
   % slopes = updateBoundingBox(slopes,'Lon_hs','Lat_hs');

   for n = 1:length(slopes)

      % if the bounding box is already provided, use it
      if isfield(slopes,'BoundingBox')

         xb = slopes(n).BoundingBox(:,1);
         yb = slopes(n).BoundingBox(:,2);

         if islatlon(yb(1),xb(1))

            % we're done, could assign the data and continue, but instead check
            % if the bbox can be computed in lat/lon from the provided data

         else % compute the bounding box in lat/lon

            % use geoquadpt if lat/lon fields are provided in the domain data
            if isfield(slopes,'Lat_hs')
               try
                  [yb,xb] = geoquadpt([slopes(n).Lat_hs],[slopes(n).Lon_hs]);

                  % do this later so it applies to the other cases
                  % xb = wrapTo360(xb);

               catch ME % the mapping tbx is not available
                  if strcmp(ME.identifier,'MATLAB:license:checkouterror')
                     slopes = updateBoundingBox(slopes,'Lon_hs','Lat_hs');
                     xb = slopes(n).BoundingBox(:,1);
                     yb = slopes(n).BoundingBox(:,2);
                  end
               end

            else

               % Compute the bbox of the hillslope in cartesian coordinates
               x = slopes(n).X_hs;
               y = slopes(n).Y_hs;

               %----------------------------------------------------------------
               % BELOW HERE NOT SURE WHY I CONVERTED TO X/Y FIRST TO GET BBOX
               % THEN WENT BACK TO LAT/LON ... SHOULD BE ABLE TO JUST USE THE
               % LAT/LON ... the issue is if the data doesn't have lat/lon, then
               % I need to know the projection and convert to lat/lon.

               if ~islatlon(y(1),x(1))
                  % need the projection
                  error('no lat/lon data found')
               end

               % this is sufficient to compute the bounding box
               [xb(1),xb(2)] = bounds(x);
               [yb(2),yb(2)] = bounds(y);

               %----------------------------------------------------------------

               % % check if the hillslope boundary X/Y_hs are actually lat/lon
               % tf = islatlon(y(1),x(1));

               % % convert to xy to use boundingbox (can I just use min/max?)
               % if tf
               %    [x,y,f] = ll2utm([y,x]);
               % end

               % [xb,yb] = boundingbox(polyshape(x,y));

               % % convert back to lat/lon
               % if tf
               %    [yb,xb] = utm2ll(xb,yb,f);
               % end
            end
         end
      end

      % shouldn't be possible, but double check that the data is lat/lon.
      if islatlon(yb(1),xb(1))

         xb = wrapTo360(xb);

         data.xv(:,n) = [xb(1) xb(2) xb(2) xb(1)];
         data.yv(:,n) = [yb(1) yb(1) yb(2) yb(2)];
      else
         error('something went wrong')
      end
   end

   % use the template file to get the schema
   for n = 1:numel(vars)
      schema.(vars{n}) = ncinfo(ftemplate,vars{n});
   end

   % modify the size information to match the new domain
   schema.xc.Size    = [ncells,1];
   schema.yc.Size    = [ncells,1];
   schema.xv.Size    = [4,ncells,1];
   schema.yv.Size    = [4,ncells,1];
   schema.mask.Size  = [ncells,1];
   schema.area.Size  = [ncells,1];
   schema.frac.Size  = [ncells,1];

   schema.xc.Dimensions(1).Length    = ncells;
   schema.yc.Dimensions(1).Length    = ncells;
   schema.xv.Dimensions(2).Length    = ncells;
   schema.yv.Dimensions(2).Length    = ncells;
   schema.mask.Dimensions(1).Length  = ncells;
   schema.area.Dimensions(1).Length  = ncells;
   schema.frac.Dimensions(1).Length  = ncells;

   % write the new file
   if opts.save_file

      % delete the file if it exists, otherwise there will be errors
      if exist(fsave,'file')
         delete(fsave);
      end

      for n = 1:numel(vars)
         ncwriteschema(fsave,schema.(vars{n}));
         ncwrite(fsave,vars{n},data.(vars{n}));
      end

      % read in the new file to compare with the old file
      info = ncinfo(fsave);
      % data = ncreaddata(fsave);
   else
      info = 'file not written, see newschema';
      try
         data = ncreaddata(fsave);
      catch
      end
   end

   % note - the dimensions of the 2d variables will be ni,nj, but Donghui says
   % if nj=1, the coupler treats the data as 1-d. ALSO note that the runoff
   % forcings should match the domain file, not MOSART, so in the runoff
   % frocings I need to have ni,nj

   % Say in your case, I think ni = 22, nj =1 for the runoff domain. Then
   % MOSART input should have gridcell dimension, which have the size of 22 as
   % well. And they should have the same order (e.g., matched ID). (edited)


   % % the original logic:
   % for n = 1:length(slopes)
   %
   %    % Compute the area of the hillslopes in cartesian coordinates
   %    y = slopes(n).Y_hs;
   %    x = slopes(n).X_hs;
   %
   %    % if the hillslope boundary X/Y_hs are actually lat/lon, convert to x,y
   %    tf = islatlon(y(1),x(1));
   %    if tf
   %       [x,y,f] = ll2utm([y,x]);
   %    end
   %
   %    % if bounding box is already in the struct, use it
   %    if isfield(slopes,'BoundingBox')
   %       xb = slopes(n).BoundingBox(:,1);
   %    else
   %       poly    = polyshape(x,y);
   %       [xb,yb] = boundingbox(poly);
   %    end
   %
   %    if tf
   %       [y,x] = utm2ll(xb,yb,f);
   %    end
   %
   %    % looks like I commented this out b/c new data has Lat/Lon so I can just 
   %    % use geoquadpt directly, meaning steps above aren't necessary
   %    % data.xv(:,n) = [x(1) x(2) x(2) x(1)];
   %    % data.yv(:,n) = [y(1) y(1) y(2) y(2)];
   %
   %    % this wasn't a try/catch originally, so just remove try/catch to go back
   %    try
   %       [lat,lon] = geoquadpt([slopes(n).Lat_hs],[slopes(n).Lon_hs]);
   %       lon = wrapTo360(lon);
   %    catch ME
   %       if strcmp(ME.identifier,'MATLAB:license:checkouterror')
   %          % get the lat/lon bbox another way
   %       end
   %    end
   %    data.xv(:,n) = [lon(1) lon(2) lon(2) lon(1)];
   %    data.yv(:,n) = [lat(1) lat(1) lat(2) lat(2)];
   % end
end
