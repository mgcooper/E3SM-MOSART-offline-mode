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
   %vars    = {'xc','yc','xv','yv','mask','area','frac'};
    vars    = {'xc','yc','mask','area','frac'};
    
% number of hillslope units in the domain
    ncells  = numel(slopes);

% to compute the surface area of each sub-basin in units of steradians
    Aearth  = 510099699070762; % m2, this is earth area defined in E3SM

% assign values to each variable
    data.xc     = wrapTo360([slopes.longxy]');
    data.yc     = [slopes.latixy]';
    data.mask   = int32(ones(ncells,1));
    data.frac   = double(ones(ncells,1));
    data.area   = ([slopes.area].*4.*pi./Aearth)';      % steradians

% compute the bounding box of each sub-basin
    data.xv = nan(4,ncells);                    % x vertices
    data.yv = nan(4,ncells);                    % y vertices

    for n = 1:length(slopes)
        
        % Compute the area of the hillslopes in cartesian coordinates
        y   = slopes(n).Y_hs;
        x   = slopes(n).X_hs;

        tf  = islatlon(y(1),x(1));
        if tf
            [x,y,f] = ll2utm([y,x]);
        end

        poly    = polyshape(x,y);
        [xb,yb] = boundingbox(poly);

        if tf
            [y,x] = utm2ll(xb,yb,f); 
        end
        
      % data.xv(:,n) = [x(1) x(2) x(2) x(1)];
      % data.yv(:,n) = [y(1) y(1) y(2) y(2)];
      
        [lat,lon]   = geoquadpt([slopes(n).Lat_hs],[slopes(n).Lon_hs]);
        lon         = wrapTo360(lon);
      
      	data.xv(:,n) = [lon(1) lon(2) lon(2) lon(1)];
        data.yv(:,n) = [lat(1) lat(1) lat(2) lat(2)];
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
    if exist(fsave,'file'); delete(fsave); end
    
    for n = 1:numel(vars)
        ncwriteschema(fsave,schema.(vars{n}));
        ncwrite(fsave,vars{n},data.(vars{n}));
    end

% read in the new file to compare with the old file                        
    info = ncinfo(fsave);
    data = ncreaddata(fsave);
else
    info = 'file not written, see newschema';
    try
      data = ncreaddata(fsave);
    end
end


% note - the dimensions of the 2d variables will be ni,nj, but Donghui says
% if nj=1, the coupler treats the data as 1-d. ALSO note that the runoff
% forcings should match the domain file, not MOSART, so in the runoff
% frocings I need to have ni,nj

% Say in your case, I think ni = 22, nj =1 for the runoff domain. Then
% MOSART input should have gridcell dimension, which have the size of 22 as
% well. And they should have the same order (e.g., matched ID). (edited)
