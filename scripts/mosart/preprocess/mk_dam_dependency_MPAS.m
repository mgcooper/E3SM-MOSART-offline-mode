clearvars
close all
clc

% TODO:
% 1 - add globalID_DependentCells (done)
% 2 - put globalID_DependentCells into a uniform table (done)
% 3 - repeat for MPAS domain mesh (~18,000 cells) if that can be found

% set the pyhexwatershed output version
hexvers  = 'mpas_c220107';

% set the search radius (meters)
rxy = 10000;

% add paths to inputs
setpath(['icom/hexwatershed/' hexvers],'data');
setpath('icom/dams/','data');

% load the dams
load('icom_dams.mat','Dams');

% read the mosart file
fmosart = 'MOSART_Mid-Atlantic_MPAS_c220107.nc';
fdomain = 'domain_lnd_Mid-Atlantic_MPAS_c220107.nc';
domain = ncreaddata(fdomain);
mosart = ncreaddata(fmosart);

% find mesh cell flow direction
ID = [mosart.ID];
dnID = [mosart.dnID];

sum(ID==-9999)
sum(ID==-1)
sum(dnID==-9999)

% get the x,y location of the dams and the mesh cell centroids
xdams = Dams.Lon;
ydams = Dams.Lat;
xmesh = transpose([mosart.lon]);
ymesh = transpose(wrapTo180([mosart.lat]));
zmesh = mean(transpose([mosart.ele]),2);


figure; scatter(xmesh,ymesh)

[ioutlet,icontributing] = mosartOutletContributingArea(        ...
                                    fmosart,xmesh,ymesh);

dnID(ioutlet)

show_river_network(fmosart,10)
                                 
% project to utm. i used this to find the zone: utmzone(ymesh(1),xmesh(1))
projutm18T     = projcrs(32618,'Authority','EPSG');
[xmesh,ymesh]  = projfwd(projutm18T,ymesh,xmesh);
[xdams,ydams]  = projfwd(projutm18T,xdams,ydams);

% to compare ele before averaging them
% figure; 
% for n = 1:11
%    plot(zmesh(n,1:100)); hold on;
% end

% run the kdtree function
%-------------------------
DependentCells =  makeDamDependency(ID,dnID,[xdams ydams],[xmesh ymesh zmesh], ...
                  'searchradius',rxy);

% add the dependent cells to the Dams tble
for n = 1:numel(xdams)
   ok = ~isnan(DependentCells(n,:));
   Dams.ID_DependentCells{n} = DependentCells(n,ok);
end

% save the data
if savedata == true
   save('data/matfiles/Dams_with_Dependency.mat','Dams');
   save('data/matfiles/DependentCellsArray.mat','DependentCells');
end





% -----------------------------------------------------
% this shows how to use the lat/lon to map the ID from susq domain to icom
load('mpas_mesh.mat','Mesh');
prec = 10;
mlat = round(mosart.lat,prec);
dlat = round(domain.yc,prec);
mlon = round(wrapTo180(mosart.lon),prec);
dlon = round(wrapTo180(domain.xc),prec);

% for n = 1:numel(Mesh)
for n = 1:1
   lat = round(Mesh(n).dLatitude_center_degree,prec);
   lon = round(Mesh(n).dLongitude_center_degree,prec);
   
   ilat = find(lat==mlat)
   ilon = find(lon==mlon)
   
   ilat = find(lat==dlat)
   ilon = find(lon==dlon)
end   
   
   