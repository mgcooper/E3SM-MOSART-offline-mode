function mosart = mos_readoutput(flist,varargin)
%MOS_READOUTPUT reads the mosart .nc files in flist and sends back the outlet
%discharge in m3/s.
% 
% 
% 

% this works if the data are daily, organized as annual files, 
% need to modify for monthly averages
    
% the second input must be the name of a variable 
    if nargin > 1
        var = varargin{1};
    else
        var = 'RIVER_DISCHARGE_OVER_LAND_LIQ';
    end
    
% read the nc info, make a list of variables, get lat/lon
    nfiles  = numel(flist);
    fdir    = [flist(1).folder '/'];
    info    = ncinfo([fdir flist(1).name]);
    vars    = {info.Variables.Name};
    lon     = double(ncread([fdir flist(1).name],'lon'));
    lat     = double(ncread([fdir flist(1).name],'lat'));

% project the lat/lon to alaska albers
%     load('proj_alaska_albers','proj_alaska_albers');
   proj_alaska_albers = projcrs(3338,'Authority','EPSG');
    [x,y]   = projfwd(proj_alaska_albers,lat,lon);
    
% read all the data
    for n = 1:nfiles
        data(n) = ncreaddata([fdir flist(n).name],vars);
    end

% stitch the discharge data into one long timeseries
% init the discharge array (ncells x ndays x nyears = 3266 x 365 x 30)
    [ndays,ncells] = size(data(1).(var));
    
    D       = nan(nfiles,ndays,ncells);
    T       = nan(nfiles,ndays);

    % locate the outlet id
    outID   = find(~isnan(data(1).RIVER_DISCHARGE_TO_OCEAN_LIQ(1,:)));

    % mcdate is the actual calendar date, format is YYYYMMDD
    
    for n = 1:nfiles
        
        try
            D(n,:,:) = data(n).(var);  % save RIVER_DISCHARGE_OVER_LAND_LIQ
            T(n,:)   = data(n).mcdate; % 
        catch
        end
        
        % add the outlet
        try
            D(n,:,outID) = data(n).RIVER_DISCHARGE_TO_OCEAN_LIQ(:,outID);
        catch
        end 
    end
    
%     % use this to plot one file (should be one year of data)
%     for n = 1:nfiles
%       test = squeeze(D(n,:,:));
%       plot(test(:,outID)); hold on; pause;
%     end

%    Discharge = readalldischarge(data,ndays,ncells);

    
    % check if any files have all nan data
    allNan  = false(nfiles,1);
    for n = 1:nfiles
        if all(isnan(D(n,:,:)))
            allNan(n)  = true;
        end
    end
    
    % warn the user if any files have all nan data
    if any(allNan)
       nanfiles = flist(allNan);
       for n = 1:sum(allNan)
         warning(['data all nan for file ' nanfiles(n).name])
       end
    end
    
    D       = D(~allNan,:,:);
    T       = T(~allNan,:);
    nfiles  = size(D,1);
    
    
% compute mean annual D, std dev, and reshape into a timeseries
    Davg    = squeeze(mean(D,1));
    Dstd    = squeeze(std(D,[],1));
    Dyrs    = D;
    Tyrs    = datetime(T,'ConvertFrom','yyyymmdd');
    
% put it in a long timeseries
    D       = permute(D,[2,1,3]); T = permute(T,[2,1]);
    D       = reshape(D,ndays*nfiles,ncells);
    T       = datetime(T(:),'ConvertFrom','yyyymmdd');
    
% shift the calendar back one day    
    T = T - days(1);
    
% package output
    mosart.data     = data;
    mosart.D        = D;
    mosart.T        = T;
    mosart.Davg     = Davg;
    mosart.Dstd     = Dstd;
    mosart.Dyrs     = Dyrs;
    mosart.Tyrs     = Tyrs;
    mosart.info     = info;
    mosart.lat      = lat;
    mosart.lon      = lon;
    mosart.x        = x;
    mosart.y        = y;
    mosart.outID    = outID;
    
%     Qmodavg = mean(reshape(Dmod,365,nyrs),2);
%     Tavg    = datenum(Tobs(1:365));
        
%     figure; plot(Davg(:,100)); hold on; 
%     plot(Davg(:,100)+(2.*Dstd(:,100)./sqrt(nfiles)));
%     plot(Davg(:,100)-(2.*Dstd(:,100)./sqrt(nfiles)));
%    
%     figure; plot(T,D(:,100)); hold on;
%     for n = 1:nfiles
%         plot(Tyrs(n,:),squeeze(Dyrs(n,:,100)),':','Color','r');
%     end


% loop over all vars and determine which ones have valid data
testdata = data(1);
allvars  = fieldnames(testdata);
isallnanorzero = true(numel(allvars),1);

for n = 1:numel(allvars)
   
   thisvar = allvars{n};
   thisdata = testdata.(thisvar);
   
   % if the var is lowercase or all nan or all zero, continue
   if strcmp(thisvar,lower(thisvar)) || all(isnan(thisdata(:))) || all(thisdata(:)==0)
      continue; 
   end
   % otherwise, set isallnanorzero false
   isallnanorzero(n) = false;
end

% check the vars that aren't all nan or zero
checkvars = allvars(~isallnanorzero);


function Discharge = readalldischarge(data,ndays,ncells)

   Dvars = { ...
      'RIVER_DISCHARGE_OVER_LAND_ICE', ...
      'RIVER_DISCHARGE_OVER_LAND_LIQ', ...
      'DIRECT_DISCHARGE_TO_OCEAN_ICE', ...
      'DIRECT_DISCHARGE_TO_OCEAN_LIQ', ...
      'RIVER_DISCHARGE_TO_OCEAN_ICE', ...
      'RIVER_DISCHARGE_TO_OCEAN_LIQ', ...
      'TOTAL_DISCHARGE_TO_OCEAN_ICE', ...
      'TOTAL_DISCHARGE_TO_OCEAN_LIQ'};
   
   nvars = numel(Dvars);
   nfiles = numel(data);
   
   % this would read all the data
   Dtemp = nan(ndays*nfiles,ncells,numel(Dvars));
   for n = 1:nfiles
      si = (n-1)*365+1;
      ei = n*365;
      thisdata = data(n);
      for m = 1:nvars
         thisvar = Dvars{m};
         data_m = thisdata.(thisvar);
         Dtemp(si:ei,:,m) = data_m;
         % to get the sum over all cells:
         % Dtemp(n,m,:) = nansum(data_m,2);
      end
   end

   % convert each tile to a table
   TileSum = nan(ncells,nvars);
   for n = 1:ncells
      thistile = ['tile_' num2str(n)];
      tiledata = squeeze(Dtemp(:,n,:));
      Tiles.(thistile) = array2table(tiledata,'VariableNames',Dvars);
      TileSum(n,:) = nansum(tiledata);
   end
   
   TileSum = array2table(TileSum,'VariableNames',Dvars);
   
% % this would work but would just do it in the loop above
%    % now convert each page to a table
%    for n = 1:nvars
%       thisvar = Dvars{m};
%       Discharge.(thisvar) = array2table(Dtemp(:,:,n),'VariableNames',Dvars);
%    end
   

   % this just sums the data as a check
   Discharge = nan(nfiles,nvars);
   for n = 1:nfiles
      thisdata = data(n);
      for m = 1:nvars
         thisvar = Dvars{m};
         data_m = thisdata.(thisvar);
         Discharge(n,m) = nansum(data_m(:));
         % to get the sum over all cells:
         % Discharge(n,m,:) = nansum(data_m,2);
      end
   end
   
   Discharge = array2table(Discharge,'VariableNames',Dvars);
   

   





function tf = skipdata(thisdata)

   % in matlab, a vector is a 2-d array that is either 1xN or Nx1
   
   tf = false;
   
   % this may not work b/c is* functions fail if the datatype is incompatible
   while tf == false
      
      tf = isscalar(thisdata);
      tf = isvector(thisdata);
      tf = istable(thisdata);
      tf = ischar(thisdata);
      tf = isstring(thisdata);
      
   end
   
   %    if isscalar(thisdata) || istable(thisdata); continue; end
   %    if skipdata(thisdata) == true; continue; end









