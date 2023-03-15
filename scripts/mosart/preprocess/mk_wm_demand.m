clean

% https://github.com/Arctic-InteRFACE/E3SM/blob/master/components/mosart/
%    src/wrm/WRM_modules.F90

pathdata = setpath('e3sm/compyfs/inputdata/waterdemand/','data');

% I have the annual diversions 

% TODO:
% - Compare GCAM demand to DRBC / SRBC
% - map annual drbc data onto seasonal demand cycle from gcam
% - conservative remapping of total demand onto mpas mesh

% PICK UP on the gcam vs drbc cmoparison, check what demand sectors are included
% in both b/c they're different by 2 orders of magnitude

%% read in the GCAM data

list = dir(fullfile([pathdata '*.nc']));
info = ncinfo([pathdata list(1).name]);
lat = ncread([pathdata list(1).name],'lat');
lon = ncread([pathdata list(1).name],'lon');

%% grid the GCAM data

[LON,LAT] = meshgrid(lon,lat);
LAT = flipud(LAT);

TWD = nan([size(LAT),numel(list)]);
for n = 1:numel(list)
   dat = ncread([pathdata list(n).name],'totalDemand');
   TWD(:,:,n) = flipud(permute(dat,[2,1]));
end
TWD = mean(TWD,3,'omitnan');

% confirm the orientiation
% figure; scatter(LON(:),LAT(:),20,TWD(:),'filled');

%% map the data onto the hex mesh

Mesh = jsondecode(fileread(getenv('MESHJSONFILE')));
[ID,dnID] = hexmesh_dnID(Mesh);
[latc,lonc,numc] = hexmesh_centroids(Mesh);
[latv,lonv,numv] = hexmesh_vertices(Mesh);

% wrap the lon to 360
lonc = wrapTo360(lonc);
lonv = wrapTo360(lonv);

% for reference
% [latmin,latmax] = bounds(LAT(:))
% [lonmin,lonmax] = bounds(LON(:))
[latmin,latmax] = bounds(latc(:));
[lonmin,lonmax] = bounds(lonc(:));


%% plot the data
try
   usamap
   scatterm(LAT,LON,TWD);
   geobox([latmin,latmax],[lonmin,lonmax]);
catch
   figure;
   scatter(LON(:),LAT(:),20,TWD(:),"filled");
   geobox([latmin,latmax],[lonmin,lonmax]);
end

%% clip gcam to drb shape

Sdrbc = loadgis('DELW.shp');
P = polyshape(wrapTo360(Sdrbc.X),Sdrbc.Y);
[Z,I] = clipRasterByPoly(TWD,LON,LAT,P,'areasum');
   
figure; geoshow(Sdrbc); hold on; plot(P);
scatter(LON(I),LAT(I))

% so this shows that the total water demand for this month is ~10^9, whereas the
% WDSW sum is ~10^11, so now I need to figure out if the data is apples to
% apples

%% read in the DRBC data

pathsave = setpath('icom/dams/drbc/withdrawals','data');
load([pathsave 'withdrawals'],'Withdrawals','Meta');

% now I would need to map the GCAM data onto the 127 sub-basins, so instead, I
% could just compare the entire basin
WDSW = Withdrawals.WDSW;

tableprops(WDSW)

% plot one basin
figure; plot(WDSW,'Time','DB001')

% basin sum 
test = sum(table2array(WDSW),2,'omitnan');
test = convertunits(test.*10^6,'galUS','m^3'); % mgd -> m3/d
test = convertunits(test,'day','s'); % m3/d -> m3/s
figure; plot(WDSW.Time,test)

% gettableunits(WDSW)


%% test conservative regridding

% below here is just a copy of the StructuredGrid_2D_Test1 (I think, could be an
% unstructured example)

% To pick up on this, plot the hex mesh and the gcam grid and send an email to
% Mohammad asking about conservative mapping onto the hex mesh ... might also
% work to use the clipRasterByPoly I modified 

% ... just thinking it through a bit ... I don't think the cell shape matters,
% what matters is the total conservation over the domain, so the cell centroids
% and distances between them determine the interpolation weights, then to get a
% volume its just multiplication by cell areas

nPoly=1;    % This would be a bilinear interpolation
nInterp=-4; % Negative Sign shows to use at least 4 points from source grid
            % for each point of destination grid.

%% Generating the Source Grid
xn = LON(:);
yn = LAT(:);

%% Generating the destination grid - Finding the cell centers

xc=lonc;
yc=latc;

%% Ploting source and destination grid
figure
plot(xn(:),yn(:),'k.','MarkerSize',6);
hold on
plot(xc(:),yc(:),'rx','MarkerSize',6);
axis tight;
axis square;
legend('Source Grid','Destination Grid');

%% Constructing the Interpolant
% Note that we do not need the data on the source grid to create the
% interpolant.
disp('- Constructing the interpolant')
P=ConstructPolyInterpolant2D(xn,yn,xc,yc,nPoly,nInterp);

%% Generarting some Data
disp('- Generating some data and interpolating')
F1=@(x,y) (sin(sqrt(x.^2+y.^2)));
zn=F1(xn,yn);
zc_interp=reshape(P*zn(:),size(xc));
zc_Analytic=F1(xc,yc);
RMSE=sqrt(mean((zc_Analytic(:)-zc_interp(:)).^2));

figure
surface(xc,yc,zc_interp,'EdgeColor','none');
title(['nPoly: ' num2str(nPoly) ', RMSE= ' num2str(RMSE)]);
axis tight

%% Generating some more data
disp('- Generating multiple data field on the source grid and interpolating them.')
F2=@(x,y) (sin(x).*cos(y));
F3=@(x,y) (exp(-sqrt(x.^2+y.^2)));
F4=@(x,y,x0,y0) (exp(-sqrt((x-x0).^2+(y-y0).^2)));

zn(:,:,1)=F1(xn,yn);
zn(:,:,2)=F2(xn,yn);
zn(:,:,3)=F3(xn,yn);
zn(:,:,4)=F4(xn,yn,mean(xn(:)),mean(yn(:)));

zc_Analytic(:,:,1)=F1(xc,yc);
zc_Analytic(:,:,2)=F2(xc,yc);
zc_Analytic(:,:,3)=F3(xc,yc);
zc_Analytic(:,:,4)=F4(xc,yc,mean(xn(:)),mean(yn(:)));

%% Now interpolating
% Note that the same interpolant is used for all data fields and they can
% be all interpolated with one sparse matrix multiplication.
zc_interp=P*reshape(zn,nx*ny,4); % There are 4 data fields each having nx*ny data points.
zc_interp=reshape(zc_interp,(nx-1),(ny-1),4); % these two commands can be combined in one.
                                              % They were separated for clarity.

%% calculating the RMSE and plotting
RMSE=zeros(4,1);
figure
for i=1:4
  RMSE(i)=sqrt(mean((reshape(zc_Analytic(:,:,i),(nx-1)*(ny-1),1)-reshape(zc_interp(:,:,i),(nx-1)*(ny-1),1)).^2));
  subplot(2,2,i);
  surface(xc,yc,squeeze(zc_interp(:,:,i)),'EdgeColor','none');
  title(['F' num2str(i) ', nPoly: ' num2str(nPoly) ', RMSE:' num2str(RMSE(i))])
  axis tight
  axis square
end











