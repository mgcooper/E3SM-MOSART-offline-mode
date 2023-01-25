function [schema,info,data] = mos_makerunoff(slopes,frunoff,fdomain,fsave,opts)
%MOS_MAKERUNOFF
% 
%     [schema,info,data] = mos_makerunoff(slopes,frunoff,fdomain,fsave,opts)
% 
% Inputs
% 
%   'slopes' a structure with the following fields:
%       longxy  = latitude of computational unit, scalar
%       latixy  = longitude of computational unit, scalar
%       area    = area in m2
% 
%     'opts'
%        inputGridded
%        outputGridded
%        save_file


% Unlike mos_makemosart and mos_makedomain, this function doesn't
% use any information from the hillslopes structure except for the position
% information which is used to interpolate the runoff to the slopes

% % For reference:
% QDRAI subsurface runoff, mm/s
% QOVER surface runoff, mm/s
% QRUNOFF total runoff, mm/s

% GPCC.daily.nc
% QDRAI
% QOVER
% QRUNOFF

% GPCC.daily.runoff.1979-2008.nc
% QDRAI
% QOVER

% if the input forcing is gridded, call the gridded function
if opts.inputGridded

   [schema,info,data] = griddedRunoff(slopes,frunoff,fdomain,fsave,opts);

else

   [schema,info,data] = listedRunoff(slopes,frunoff,fdomain,fsave,opts);

end


%-------------------------------------------------------------------------------
function [schema,info,data] = listedRunoff(slopes,frunoff,fdomain,fsave,opts)

% not implemented, instead i use a gridded runoff file as a template and
% simply replace the gridded data with listed (unstructured) data


%-------------------------------------------------------------------------------
function [schema,info,data] = griddedRunoff(slopes,frunoff,fdomain,fsave,opts)
% works with ming pan sag_YYYY_mosart.nc and GPCC.daily.nc
% % read the hillslope lat/lon, ID, and downstream ID
ID      = [slopes.ID];
lat     = [slopes.lat];
lon     = [slopes.lon];

% read the runoff dataset
varInfo     = ncinfo(frunoff);
varNames    = {varInfo.Variables.Name};
data        = ncreaddata(frunoff,varNames);

% read the lat/lon
[LON,LAT]   = meshgrid(data.lon,data.lat);
LAT         = flipud(LAT);

% this ensures they are both wrapped to 360
lon         = wrapTo360(lon);
LON         = wrapTo360(LON);

% check which runoff vars are provided
% QDRAI subsurface runoff, mm/s
% QOVER surface runoff, mm/s
% QRUNOFF total runoff, mm/s
newVars     = {'QRUNOFF','QDRAI','QOVER'};
hasQRUNOFF  = false;
hasQDRAI    = false;
hasQOVER    = false;
% this is probably here for compatibility with ming pan and GPCC files
if isfield(data,'QRUNOFF'); hasQRUNOFF  = true; end
if isfield(data,'QDRAI');   hasQDRAI    = true; end
if isfield(data,'QOVER');   hasQOVER    = true; end

hasVars = [hasQRUNOFF,hasQDRAI,hasQOVER];

% this checks if the forcing is all in QRUNOFF, QDRAI, QOVER, or split
% between QDRAI and QOVER. it isn't a comprehensive check and needs to
% be fixed at some point
if hasQRUNOFF
   Runoff = permute(data.QRUNOFF,[2,1,3]);

elseif hasQDRAI && ~hasQOVER
   Runoff = permute(data.QDRAI,[2,1,3]);

elseif hasQOVER && ~hasQDRAI
   Runoff = permute(data.QOVER,[2,1,3]);

elseif hasQOVER && hasQDRAI
   Rover  = permute(data.QOVER,[2,1,3]);
   Rdrain = permute(data.QDRAI,[2,1,3]);
   Runoff = Rover + Rdrain;
else
   error('runoff data not recognized');
end

Runoff  = flipud(Runoff);
LON     = LON(:);
LAT     = LAT(:);

if opts.outputGridded == true
   [schema,info,data] = griddedRunoffOutput(Runoff,LON,LAT, ...
      lon,lat,hasVars,newVars,frunoff,fdomain,fsave,opts);

else
   [schema,info,data] = listedRunoffOutput(Runoff,LON,LAT, ...
      lon,lat,hasVars,newVars,frunoff,fdomain,fsave,opts);
end




%-------------------------------------------------------------------------------
function [schema,info,data] = listedRunoffOutput(Runoff,LON,LAT,...
   lon,lat,hasVars,newVars,frunoff,fdomain,fsave,opts)

% interpolate across days the input runoff to the hillslope units
nCells = numel(lat);
nDays = size(Runoff,3);
newR  = scatteredInterpolation(LON,LAT,reshape(Runoff,[],nDays),lon,lat);
% lon = wrapTo180(lon);   % unwrap it (don't think I need this anymore)

% need a general way to deal with redistributing QRUNOFF to QDRAI/OVER
% but for now put it all in QDRAI
newData.QRUNOFF = zeros(size(newR));
newData.QDRAI   = newR;
newData.QOVER   = zeros(size(newR));

% WRITE THE NEW FILE
if opts.save_file

   % delete the file if it exists, otherwise there will be errors
   if isfile(fsave); delete(fsave); end

   % copy over these vars from the domain file to the runoff file
   %copyVars    = {'xc','yc','mask','area','frac'};
   copyVars    = {'xc','yc'};
   %renameVars  = {'lon','lat'};
   renameVars  = {'xc','yc'};
   renameNames = {'longitude','latitude'};

   for n = 1:numel(copyVars)

      copyVar     = copyVars{n};
      copySchema  = ncinfo(fdomain,copyVar);
      copyData    = ncread(fdomain,copyVar);

      copySchema.Name             = renameVars{n};
      copySchema.Attributes(3)    = [];

      % add a standard name field
      newAtts             = copySchema.Attributes;
      newAtts(3).Name     = newAtts(2).Name;
      newAtts(3).Value    = newAtts(2).Value;
      newAtts(2).Name     = newAtts(1).Name;
      newAtts(2).Value    = newAtts(1).Value;
      newAtts(1).Name     = 'standard_name';
      newAtts(1).Value    = renameNames{n};

      copySchema.Attributes   = newAtts;

      ncwriteschema(fsave,copySchema);
      ncwrite(fsave,renameVars{n},copyData);
   end

   % add a time variable
   timeData            = ncread(frunoff,'time');
   timeSchema          = ncinfo(frunoff,'time');
   timeSchema.Format   = copySchema.Format;

   ncwriteschema(fsave,timeSchema);
   ncwrite(fsave,'time',timeData);

   % now add the runoff data, using the 'xc' variable as a template
   newSchema                           = ncinfo(fdomain,'xc');
   newSchema.Size                      = [nCells,1,nDays];
   newSchema.Dimensions(3).Name        = 'time';
   newSchema.Dimensions(3).Length      = nDays;
   newSchema.Dimensions(3).Unlimited   = false;
   newSchema.Attributes(3)             = [];

   % modify values that change for each variable, and write the new data
   for n = 1:numel(newVars)

      thisVar     = newVars{n};

      % this works as long as I put the data in a var that existed in
      % the frunoff file
      if hasVars(n) == false
         continue
      end

      % this copies the standard name and units
      oldSchema                       = ncinfo(frunoff,thisVar);
      newSchema.Name                  = thisVar;
      newSchema.Attributes(1).Name    = oldSchema.Attributes(1).Name;
      newSchema.Attributes(1).Value   = oldSchema.Attributes(1).Value;
      newSchema.Attributes(2).Name    = oldSchema.Attributes(2).Name;
      newSchema.Attributes(2).Value   = oldSchema.Attributes(2).Value;

      % this is the easiest way to get the 2-d matlab var into ni,nj,time
      Qtmp = nan(nCells,1,nDays);
      for m = 1:365
         Qtmp(:,1,m) = newData.(thisVar)(:,m);
      end

      if opts.save_file
         ncwriteschema(fsave,newSchema);
         ncwrite(fsave,thisVar,Qtmp);
      end
   end

   % read in the new file to compare with the old file
   schema  = newSchema;
   info    = ncinfo(fsave);
   data    = ncreaddata(fsave);
else
   schema  = [];
   info    = 'file not written, see newschema';
   data    = [];
end


%-------------------------------------------------------------------------------
function [schema,info,data] = griddedRunoffOutput(Runoff,LON,LAT, ...
   lon,lat,hasVars,newVars,frunoff,fdomain,fsave,opts)

% if output is gridded then no interpolation is needed

%     % interpolate across days the input runoff to the hillslope units
%     nDays   = size(Runoff,3);
%     newR    = nan(nCells,nDays);
%     for n = 1:nDays
%         thisR     = tocolumn(Runoff(:,:,n));
%         newR(:,n) = scatteredInterpolation(LON,LAT,thisR,lon,lat);
%     end
%   % lon     = wrapTo180(lon);   % unwrap it (don't think I need this anymore)
%
%     nRows   = size(Runoff,1);
%     nCols   = size(Runoff,2);
%     if opts.outputGridded == true
%         newR    = reshape(newR,nRows,nCols,nDays);
%     end

nCells = numel(lon);

% need a general way to deal with redistributing QRUNOFF to QDRAI/OVER
% but for now put it all in QDRAI
newData.QRUNOFF = zeros(size(newR));
newData.QDRAI   = newR;
newData.QOVER   = zeros(size(newR));

% WRITE THE NEW FILE
if opts.save_file

   % delete the file if it exists, otherwise there will be errors
   if exist(fsave,'file'); delete(fsave); end

   % copy over these vars from the domain file to the runoff file
   %copyVars    = {'xc','yc','mask','area','frac'};
   copyVars    = {'xc','yc'};
   %renameVars  = {'lon','lat'};
   renameVars  = {'xc','yc'};

   for n = 1:numel(copyVars)

      copyVar     = copyVars{n};
      copySchema  = ncinfo(fdomain,copyVar);
      copyData    = ncread(fdomain,copyVar);


      copySchema.Name             = renameVars{n};
      copySchema.Attributes(3)    = [];

      ncwriteschema(fsave,copySchema);
      ncwrite(fsave,renameVars{n},copyData);
   end

   % add a time variable
   timeData            = ncread(frunoff,'time');
   timeSchema          = ncinfo(frunoff,'time');
   timeSchema.Format   = copySchema.Format;

   ncwriteschema(fsave,timeSchema);
   ncwrite(fsave,'time',timeData);

   % now add the runoff data, using the 'xc' variable as a template
   newSchema                           = ncinfo(fdomain,'xc');
   newSchema.Size                      = [nCells,1,nDays];
   newSchema.Dimensions(3).Name        = 'time';
   newSchema.Dimensions(3).Length      = nDays;
   newSchema.Dimensions(3).Unlimited   = false;
   newSchema.Attributes(3)             = [];

   % modify values that change for each variable, and write the new data
   for n = 1:numel(newVars)

      thisVar     = newVars{n};

      % this works as long as I put the data in a var that existed in
      % the frunoff file
      if hasVars(n) == false
         continue
      end

      % this copies the standard name and units
      oldSchema                       = ncinfo(frunoff,thisVar);
      newSchema.Name                  = thisVar;
      newSchema.Attributes(1).Name    = oldSchema.Attributes(1).Name;
      newSchema.Attributes(1).Value   = oldSchema.Attributes(1).Value;
      newSchema.Attributes(2).Name    = oldSchema.Attributes(2).Name;
      newSchema.Attributes(2).Value   = oldSchema.Attributes(2).Value;

      % this is the easiest way to get the 2-d matlab var into ni,nj,time
      Qtmp = nan(nCells,1,nDays);
      for m = 1:365
         Qtmp(:,1,m) = newData.(thisVar)(:,m);
      end

      if opts.save_file
         ncwriteschema(fsave,newSchema);
         ncwrite(fsave,thisVar,Qtmp);
      end
   end

   % read in the new file to compare with the old file
   schema  = newSchema;
   info    = ncinfo(fsave);
   data    = ncreaddata(fsave);
else
   schema  = [];
   info    = 'file not written, see newschema';
   data    = [];
end






%         % QDRAI
%             if hasQDRAI
%
%                 % the values on the RHS could also be gotten from theOldSchema
%                 newSchema.Name                      = 'QDRAI';
%                 newSchema.Size                      = [nCells,1,nDays];
%                 newSchema.Dimensions(3).Name        = 'time';
%                 newSchema.Dimensions(3).Length      = nDays;
%                 newSchema.Dimensions(3).Unlimited   = false;
%                 newSchema.Attributes(1).Name        = 'standard_name';
%                 newSchema.Attributes(1).Value       = 'subsurface_runoff';
%                 newSchema.Attributes(2).Name        = 'units';
%                 newSchema.Attributes(2).Value       = 'mm/s';
%                 newSchema.Attributes(3)             = [];
%
%                 % this is the easiest way to get the 2-d matlab var into ni,nj,time
%                 Qtmp = nan(nCells,1,nDays);
%                 for n = 1:365
%                     Qtmp(:,1,n) = QDRAI(:,n);
%                 end
%
%                 if opts.save_file
%                     ncwriteschema(fsave,newSchema);
%                     ncwrite(fsave,'QDRAI',Qtmp);
%                 end
%
%                 % look at the new schema
%                 % runoffSchema  = ncinfo(fsave);
%             end
%
%
%     % QOVER
%     if hasQOVER
%
%         newSchema                         = ncinfo(frunoff,'QOVER');
%         newSchema.Dimensions(1)           = [];
%         newSchema.Dimensions(1).Name      = 'gridcell';
%         newSchema.Dimensions(1).Length    = nCells;
%         newSchema.ChunkSize               = [];
%         newSchema.Size                    = [nCells,nDays];
%
%         if opts.save_file
%             ncwriteschema(fsave,newSchema);
%             ncwrite(fsave,'QOVER',QOVER);
%         end
%
%     end
%
%     % QRUNOFF
%     if hasQRUNOFF
%
%         newSchema                         = ncinfo(frunoff,'QRUNOFF');
%         newSchema.Dimensions(1)           = [];
%         newSchema.Dimensions(1).Name      = 'gridcell';
%         newSchema.Dimensions(1).Length    = nCells;
%         newSchema.ChunkSize               = [];
%         newSchema.Size                    = [nCells,nDays];
%         newSchema.Attributes.Name
%
%         if opts.save_file
%             ncwriteschema(fsave,newSchema);
%             ncwrite(fsave,'QRUNOFF',QRUNOFF);
%         end
%
%     end
%
%     end
%
% % assign values to each variable
%     data.xc     = [slopes.longxy]';
%     data.yc     = [slopes.latixy]';
%     data.mask   = int32(ones(ncells,1));
%     data.frac   = double(ones(ncells,1));
%     data.area   = ([slopes.area].*4.*pi./Aearth)';      % steradians
%
% % compute the bounding box of each sub-basin
%     data.xv = nan(4,ncells);                    % x vertices
%     data.yv = nan(4,ncells);                    % y vertices
%
%     for n = 1:length(slopes)
%         y   = slopes(n).Y_hs;
%         x   = slopes(n).X_hs;
%
%         tf  = islatlon(y(1),x(1));
%         if tf
%             [x,y,f] = ll2utm([y,x]);
%         end
%
%         poly    = polyshape(x,y);
%         [xb,yb] = boundingbox(poly);
%
%         if tf
%             [y,x] = utm2ll(xb,yb,f);
%         end
%
%         data.xv(:,n) = [x(1) x(2) x(2) x(1)];
%         data.yv(:,n) = [y(1) y(1) y(2) y(2)];
%     end
%
% % use the template file to get the schema
%     for n = 1:numel(copyVars)
%         schema.(copyVars{n}) = ncinfo(ftemplate,copyVars{n});
%     end
%
% % modify the size information to match the new domain
%     schema.xc.Size    = [ncells,1];
%     schema.yc.Size    = [ncells,1];
%     schema.xv.Size    = [4,ncells,1];
%     schema.yv.Size    = [4,ncells,1];
%     schema.mask.Size  = [ncells,1];
%     schema.area.Size  = [ncells,1];
%     schema.frac.Size  = [ncells,1];
%
%     schema.xc.Dimensions(1).Length    = ncells;
%     schema.yc.Dimensions(1).Length    = ncells;
%     schema.xv.Dimensions(2).Length    = ncells;
%     schema.yv.Dimensions(2).Length    = ncells;
%     schema.mask.Dimensions(1).Length  = ncells;
%     schema.area.Dimensions(1).Length  = ncells;
%     schema.frac.Dimensions(1).Length  = ncells;
%
% % write the new file
%     if opts.save_file
%
%         % delete the file if it exists, otherwise there will be errors
%         if exist(fsave,'file'); delete(fsave); end
%
%         for n = 1:numel(copyVars)
%             ncwriteschema(fsave,schema.(copyVars{n}));
%             ncwrite(fsave,copyVars{n},data.(copyVars{n}));
%         end
%
%     % read in the new file to compare with the old file
%         info = ncinfo(fsave);
%     else
%         info = 'file not written, see newschema';
%     end



%     % QDRAI
%     if hasQDRAI
%
%         theNewSchema                      = ncinfo(frunoff,'QDRAI');
%         theNewSchema.Dimensions(1)        = [];
%         theNewSchema.Dimensions(1).Name   = 'gridcell';
%         theNewSchema.Dimensions(1).Length = nCells;
%         theNewSchema.ChunkSize            = [];
%         theNewSchema.Size                 = [nCells,nDays];
%
%         if opts.save_file
%             ncwriteschema(fsave,theNewSchema);
%             ncwrite(fsave,'QDRAI',QDRAI);
%         end
%
%     end
%
%     % QOVER
%     if hasQOVER
%
%         theNewSchema                         = ncinfo(frunoff,'QOVER');
%         theNewSchema.Dimensions(1)           = [];
%         theNewSchema.Dimensions(1).Name      = 'gridcell';
%         theNewSchema.Dimensions(1).Length    = nCells;
%         theNewSchema.ChunkSize               = [];
%         theNewSchema.Size                    = [nCells,nDays];
%
%         if opts.save_file
%             ncwriteschema(fsave,theNewSchema);
%             ncwrite(fsave,'QOVER',QOVER);
%         end
%
%     end
%
%     % QRUNOFF
%     if hasQRUNOFF
%
%         theNewSchema                         = ncinfo(frunoff,'QRUNOFF');
%         theNewSchema.Dimensions(1)           = [];
%         theNewSchema.Dimensions(1).Name      = 'gridcell';
%         theNewSchema.Dimensions(1).Length    = nCells;
%         theNewSchema.ChunkSize               = [];
%         theNewSchema.Size                    = [nCells,nDays];
%         theNewSchema.Attributes.Name
%
%         if opts.save_file
%             ncwriteschema(fsave,theNewSchema);
%             ncwrite(fsave,'QRUNOFF',QRUNOFF);
%         end
%
%     end
%
%     % ID (use 'lat' as a template)
%     theNewSchema                         = ncinfo(frunoff,'lat');
%     theNewSchema.Name                    = 'ID';
%     theNewSchema.Dimensions(1).Name      = 'gridcell';
%     theNewSchema.Dimensions(1).Length    = nCells;
%     theNewSchema.Size                    = nCells;
%     theNewSchema.ChunkSize               = [];
%     theNewSchema.Attributes              = [];
%
%     if opts.save_file
%         ncwriteschema(fsave,theNewSchema);
%         ncwrite(fsave,'ID',ID);
%     end
%
%     % lat
%     theNewSchema                         = ncinfo(frunoff,'lat');
%     theNewSchema.Dimensions(1).Name      = 'gridcell';
%     theNewSchema.Dimensions(1).Length    = nCells;
%     theNewSchema.Size                    = nCells;
%     theNewSchema.ChunkSize               = [];
%
%     if opts.save_file
%         ncwriteschema(fsave,theNewSchema);
%         ncwrite(fsave,'lat',lat);
%     end
%
%     % lon
%     theNewSchema                         = ncinfo(frunoff,'lon');
%     theNewSchema.Dimensions(1).Name      = 'gridcell';
%     theNewSchema.Dimensions(1).Length    = nCells;
%     theNewSchema.Size                    = nCells;
%     theNewSchema.ChunkSize               = [];
%
%     if opts.save_file
%         ncwriteschema(fsave,theNewSchema);
%         ncwrite(fsave,'lon',lon);
%     end
%
%     schema  = theNewSchema;
%
%     if opts.save_file
%         info    = ncinfo(fsave);
%     else
%         info    = 'file not written, see newschema';
%     end

%% this shows the discrepancy between scatteredInterpolant and interp2
% interpolate the GPCC runoff to the sag basin lat/lon
% Rq          = scatteredInterpolant(LONrs,LATrs,Ravgrs,'linear');
% Rsag        = Rq(lon,lat);
% Rsag2       = interp2(LON,LAT,Ravg,lon,lat);
%
% figure;
% plotLinReg(Rsag,Rsag2); ax = gca;
% ax.XLim = ax.YLim;
% axis square
%
% figure;
% myscatter(Rsag,Rsag2);
% addOnetoOne

% for reference:
% R           = permute(data.QRUNOFF,[2,1,3]);
%
% % this suggests the data is oriented correctly
% figure;
% surf(data.lon,data.lat,mean(R,3));
% view(2); shading flat
%
% % but when LON/LAT are gridded, R has to be flipped upside down
% [LON,LAT]   = meshgrid(data.lon,data.lat);
% LAT         = flipud(LAT);
% R           = flipud(R);
% Ravg        = nanmean(R,3);

% figure;
% surf(LON,LAT,mean(R,3));
% view(2); shading flat

% % Below here is how it was when I started

% %% 1. read in icom files to use as a template for the new file
% frunoff     = [path.data 'GPCC.daily.nc'];
% fsave       = [path.save 'runoff_sag_test.nc'];
%
% info        = ncinfo(frunoff);
% vars        = {info.Variables.Name};
% data        = ncreaddata(frunoff,vars);
% data.QDRAI  = permute(data.QDRAI,[2,1,3]);
% data.QOVER	= permute(data.QOVER,[2,1,3]);
% data.QRUNOFF= permute(data.QRUNOFF,[2,1,3]);
%
% figure;
% worldmap
% surfm(data.lat,data.lon,mean(data.QRUNOFF,3));
%
%
% %% 1. Load the hillsloper data and modify it for MOSART
% 
% load([path.sag 'sag_hillslopes']);
%
% % assign values to each variable
% xc      = [newslopes.longxy]';
% yc      = [newslopes.latixy]';
% mask    = (int32(ones(size([newslopes.longxy]))))';
% frac    = (ones(size([newslopes.longxy])))';
% ncells  = size(mask,1);
%
% % compute the surface area of each sub-basin in units of steradians
% for i = 1:length(newslopes)
%     ilat        = newslopes(i).Y_hs;
%     ilon        = newslopes(i).X_hs;
%     area(i,1)   = llpoly2steradians(ilat,ilon);
% end
%
% % compute the bounding box of each sub-basin
% for i = 1:length(newslopes)
%     ilat        = newslopes(i).Y_hs;
%     ilon        = newslopes(i).X_hs;
%     [x,y,f]     = ll2utm([ilat,ilon]);
%     poly        = polyshape(x,y);
%     [xb,yb]     = boundingbox(poly);
%     [latb,lonb] = utm2ll(xb,yb,f);
%     xv(:,i)     = [lonb(1) lonb(2) lonb(2) lonb(1)];
%     yv(:,i)     = [latb(1) latb(1) latb(2) latb(2)];
% end
%
% myschema.xc     = ncinfo(frunoff,'xc');
% myschema.yc     = ncinfo(frunoff,'yc');
% myschema.xv     = ncinfo(frunoff,'xv');
% myschema.yv     = ncinfo(frunoff,'yv');
% myschema.mask   = ncinfo(frunoff,'mask');
% myschema.area   = ncinfo(frunoff,'area');
% myschema.frac   = ncinfo(frunoff,'frac');
%
% % modify the size to match the sag domain
% myschema.xc.Size    = [ncells,1];
% myschema.yc.Size    = [ncells,1];
% myschema.xv.Size    = [4,ncells,1];
% myschema.yv.Size    = [4,ncells,1];
% myschema.mask.Size  = [ncells,1];
% myschema.area.Size  = [ncells,1];
% myschema.frac.Size  = [ncells,1];
%
% myschema.xc.Dimensions(1).Length    = ncells;
% myschema.yc.Dimensions(1).Length    = ncells;
% myschema.xv.Dimensions(2).Length    = ncells;
% myschema.yv.Dimensions(2).Length    = ncells;
% myschema.mask.Dimensions(1).Length  = ncells;
% myschema.area.Dimensions(1).Length  = ncells;
% myschema.frac.Dimensions(1).Length  = ncells;
%
% ncwriteschema(fsave,myschema.xc);
% ncwriteschema(fsave,myschema.yc);
% ncwriteschema(fsave,myschema.xv);
% ncwriteschema(fsave,myschema.yv);
% ncwriteschema(fsave,myschema.mask);
% ncwriteschema(fsave,myschema.area);
% ncwriteschema(fsave,myschema.frac);
%
% %% write the variable values
% ncwrite(fsave,'xc',xc);
% ncwrite(fsave,'yc',yc);
% ncwrite(fsave,'xv',xv);
% ncwrite(fsave,'yv',yv);
% ncwrite(fsave,'mask',mask);
% ncwrite(fsave,'area',area);
% ncwrite(fsave,'frac',frac);
%
% % read in the new file to compare with the old file
% newinfo.domain  = ncinfo(fsave);

