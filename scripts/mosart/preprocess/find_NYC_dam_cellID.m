clean

pathadd('/Users/coop558/work/data/e3sm/config')
data = ncreaddata('MOSART_Mid-Atlantic_MPAS_c220107.nc');

damlat = dmsToDegrees([41, 25, 5; 41, 5, 10]);
damlon = wrapTo360(-dms2degrees([73, 42, 0; 73, 45, 50]));

gridlat = data.lat;
gridlon = data.lon;

latlims = [min(gridlat), max(gridlat)];
lonlims = [min(gridlon), max(gridlon)];

k = convhull(gridlon, gridlat);

figontop; 
plot(gridlon(k), gridlat(k)); hold on;
plot(damlon, damlat, 'o'); formatPlotMarkers ;

%% find the grid cell id of the dams

[row, col] = findnearby(gridlon, gridlat, damlon, damlat, 1);

foundlon = gridlon(col)';
foundlat = gridlat(col)';
[foundlon foundlat]
[damlon damlat]

foundID = data.ID(col);

% 765 = west branch, 4143 = Kensico

figure; 
plot(gridlon(k), gridlat(k)); hold on;
plot(foundlon, foundlat, 'o'); hold on; scatter(damlon, damlat,'o')
formatPlotMarkers
labelpoints(foundlon, foundlat, {'West Branch', 'Kensico'})



figure


% technically I think I 
