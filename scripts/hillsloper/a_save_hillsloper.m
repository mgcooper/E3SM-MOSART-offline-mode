clean

savedata = true;
sitename = getenv('USER_MOSART_DOMAIN_NAME');
plotmap  = true;
plotgeo  = false;
pathsave = getenv('USER_MOSART_DOMAIN_DATA_PATH');

%% read in the data
[basins, slopes, links, nodes, bounds, ftopo] = readHillsloperData(sitename);

% mapshow/geoshow not terribly slow, but remember this is much faster:
[lat, lon] = latlonFromGeoStruct(slopes);
geomap(lat, lon)
plotm(lat, lon)

% patchm(lat, lon, 'g') ; % works but very slow

%% compute topo 

% Don't think this is needed anymore
% slopes = computeHillslopeTopo(slopes, ftopo);

%% qa qc
info = verifyTopology(slopes, links, basins, true);

%% save the data

if savedata == true
   save(fullfile(pathsave,'sag_hillslopes'),'slopes','links','nodes');
end
