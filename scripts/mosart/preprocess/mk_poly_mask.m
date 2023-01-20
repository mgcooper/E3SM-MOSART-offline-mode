clean

% make a polygon mask for the delaware and susquehanna basins

%% load the basin shapefiles to use as masks

mask = loadgis(getenv('BOUNDSFILE'),'UseGeoCoords',true);
mask = polyshape(mask.Lon,mask.Lat);
lonmask = mask.Vertices(:,1);
latmask = mask.Vertices(:,2);

if savedata == true
   save('data/matfiles/susq_delw_mask.mat','mask','latmask','lonmask');
end