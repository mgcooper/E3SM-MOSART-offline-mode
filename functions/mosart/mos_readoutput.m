function mosart = mos_readoutput(flist,varargin)

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
load('proj_alaska_albers','proj_alaska_albers');
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

for n = 1:nfiles

   try
      D(n,:,:) = data(n).(var);
      T(n,:)   = data(n).mcdate;
   catch
   end

   % add the outlet
   try
      D(n,:,outID) = data(n).RIVER_DISCHARGE_TO_OCEAN_LIQ(:,outID);
   catch
   end
end

allNan  = false(nfiles,1);
for n = 1:nfiles
   if all(isnan(D(n,:,:)))
      allNan(n)  = true;
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
