clean

% this saves the shapefile of dams clipped to the susq basin

Dams = shaperead('susq_dams.shp','UseGeoCoords',true);
Dams = struct2table(Dams);
Dams = removevars(Dams,{'Lat1','Lon1'});
Dams = renamevars(Dams,{'Capacity_k'},{'Capacity_km3'});
save('susq_dams.mat','Dams');