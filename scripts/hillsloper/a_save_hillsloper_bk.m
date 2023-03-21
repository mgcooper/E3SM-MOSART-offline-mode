clean

savedata = true;
sitename = getenv('USER_MOSART_DOMAIN_NAME');
plotmap  = true;
plotgeo  = false;

pathdata = getenv('USER_HILLSLOPER_DATA_PATH');
pathsave = getenv('USER_MOSART_DOMAIN_DATA_PATH');

switch sitename
   case 'sag_basin'
      fnametopo = 'IfSAR_5m_DTM_Alaska_Albers_Sag_basin.tif';
   case 'trib_basin'
      fnametopo = 'Sag_gage_HUC_filled.tif';
   case 'test_basin'
      fnametopo = 'huc_190604020404.tif';
end
fnametopo = fullfile(getenv('USER_DOMAIN_TOPO_DATA_PATH'),fnametopo);

warning('off') % so polyshape stops complaining

% v3 has one orphan link and otherwise appears to be ok so i just need to
% confirm that the link-hs_id mapping is correct, then check if my methods to
% reconstruct the flow network are correct, and if so I can archive the old
% version of b_make_newslopes specific to v1 and move forward with a version
% that works for each basin

% note: this needs the DEM to be in planar coordinates to compute the area
% of each hillslope, otherwise it would work with a geo dem i think

% this is an initial save of the data to get it into a useable form,
% additional work is needed to get it ready for mosart, which is done in
% b_make_newslopes

% for slopes, we need:
% area (provided with slopes)
% slope (provided with links, but links and slopes are not associative)
% elevation (not provided)
% 

%% read in the data

flist = getlist(pathdata,'*.shp'); % {flist.name}'

try % for sag_basin, links is file 3, nodes is 4, so need to use explicit method
   finfo = shapeinfo(fullfile(pathdata,flist(1).name));
   links = shaperead(fullfile(pathdata,flist(2).name)); % new sf w/hs_id
   nodes = shaperead(fullfile(pathdata,flist(3).name));
   slopes = shaperead(fullfile(pathdata,flist(1).name));
catch ME
   if strcmp(ME.identifier,'MATLAB:license:checkouterror')
      activate m_map
      if sitename == "sag_basin"
         links = loadgis(fullfile(pathdata,'Sag_links.shp'),'m_map');
         nodes = loadgis(fullfile(pathdata,'Sag_nodes.shp'),'m_map');
         slopes = loadgis(fullfile(pathdata,'Sag_hillslopes.shp'),'m_map');
         bounds = loadgis('Sag_basin_NHD_Alaska_Albers.shp','m_map');
      else
         links = loadgis(fullfile(pathdata,flist(2).name),'m_map');
         nodes = loadgis(fullfile(pathdata,flist(3).name),'m_map');
         slopes = loadgis(fullfile(pathdata,flist(1).name),'m_map');
      end
   end
end

Nnodes = length(nodes);
Nlinks = length(links);
Nslopes = length(slopes);

%% convert strings to doubles
N = Nlinks;
V = {'us_node_id','ds_node_id','ds_da_km2','us_da_km2','slope','len_km','hs_id'};
for n = 1:length(V)
   vi = V{n};
   % between here and else was not in sag_basin version
   di = {links.(vi)};
   if strcmp(vi,'hs_id')
      for j = 1:length(di)
         [links(j).(vi)] = str2double(strsplit(di{j},','));
      end
   else
      di = num2cell(cellfun(@str2double,{links.(vi)}));
      [links(1:N).(vi)] = di{:};
   end
   % sag basin version went straight from vi=V{n} here:
   %di = num2cell(cellfun(@str2double,{links.(vi)}));
   %[links(1:N).(vi)] = di{:};
end

% nodes is more complicated, because some fields have multiple values
N = Nnodes;
V = {'hs_id','conn','da_km2'};
for n = 1:length(V)
   di = {nodes.(V{n})};
   for j = 1:length(di)
      [nodes(j).(V{n})] = str2double(strsplit(di{j},','));
   end
end






%%

% the new links have hs_id field, one is nan
count = cellfun(@numel,{links.hs_id});
[sum(count==0) sum(count==1)]
numel(unique([links.hs_id]));
links_hs_id = tocol(sort([links.hs_id]));

% repeat for lsopes
count = cellfun(@numel,{slopes.hs_id});
[sum(count==0) sum(count==1)]
numel(unique([slopes.hs_id]));
slopes_hs_id = [slopes.hs_id];

% this says that links(1392) has nan for its hs_id
find(isnan([links.hs_id])) % 1392 is nan
links(isnan([links.hs_id])) % link_id = 1391

% so check if any slopes have a link id of 1391
find([slopes.link_id] == links(isnan([links.hs_id])).id)

slopes(find(slopes_hs_id==1392))

% % this didn't work so just load the shapefile
% testlat = slopes(1).Lat;
% testlon = slopes(1).Lon;
% figure; plot(testlon,testlat);
% sum(isnan(test))
% 
% lat = cellfun(@transpose,{slopes.Lat},'Uni',0);
% lon = cellfun(@transpose,{slopes.Lon},'Uni',0);
% lat = vertcat(lat{:});
% lon = vertcat(lon{:});
% [lat,lon] = closePolygonParts(lat,lon);

% plot it
figure;
figure; plot(lon,lat);
plot(links(isnan([links.hs_id])).Lon,links(isnan([links.hs_id])).Lat)

%% process the DEM

% this takes forever so do it here once

% use topo toolbox to read the elevation data
activate topotoolbox
DEM = GRIDobj(fnametopo);           % elevation
GRD = gradient8(DEM);               % slope

try
   finfo = geotiffinfo(fnametopo);
   DEM.georef.SpatialRef.ProjectedCRS = finfo.CoordinateReferenceSystem;
   GRD.georef.SpatialRef.ProjectedCRS = finfo.CoordinateReferenceSystem;
   [~,R] = readgeoraster(fnametopo);   % spatial referencing
   res = R.CellExtentInWorldX;
   isgeo = false;
   if strcmp(R.CoordinateSystemType,'geographic'); isgeo = true;end
catch ME
   if strcmp(ME.identifier,'MATLAB:license:checkouterror')
      % DEM.georef.SpatialRef.ProjectedCRS = ''; % not sure how to handle this
      % GRD.georef.SpatialRef.ProjectedCRS = ''; % not sure how to handle this
      res = DEM.cellsize;
      isgeo = false; % assume we're using ifsar
   end
end

% use this to get the x,y coords of the DEM
[X,Y] = DEM.getcoordinates;
[~,X,Y] = GRIDobj2mat(DEM);
[X,Y] = meshgrid(X,Y);


% for reference, from the sag_basin version:
% load([pathtopo 'sag_dems'],'R','Z'); % 5 m dem, for plotting
% [~,slope] = gradientm(Z,R);          % only works with geo coords

% i used this to confirm that bbox in slopes is compatible with bbox2R
% bbox = mapbbox(R,R.RasterSize(1),R.RasterSize(2));

% loop through the hillslopes and extract the mean elevation and slope
for n = 1:length(slopes)

   hs = slopes(n);
   if isfield(hs,'X')
      x = hs.X;
      y = hs.Y;
   elseif isfield(hs,'Lon')
      x = hs.Lon;
      y = hs.Lat;
      if islatlon(y,x)
         error('ambiguous coordinate system')
      end
   end
   hspoly = polyshape(x,y);

   % this is MUCH faster than inpolygon if a coarser res is used to query
   % the dem, with ~no impact on accuracy, since we're taking the mean.
   % If res=5, it gives identical results as inpolygon w/o coarsening
   
   % construct a grid of points to interpolate the hillslope
   bbox = hs.BoundingBox;
   Rhs = bbox2R(bbox,res*5);
   [xhs,yhs] = R2grid(Rhs);
   xhs = reshape(xhs,size(xhs,1)*size(xhs,2),1);
   yhs = reshape(yhs,size(yhs,1)*size(yhs,2),1);
   ihs = inpolygon(xhs,yhs,x,y);
   if isgeo
      hslp = round(mean(geointerp(GRD.Z,R,yhs(ihs),xhs(ihs),'linear'),'omitnan'),4);
      hele = round(mean(geointerp(DEM.Z,R,yhs(ihs),xhs(ihs),'linear'),'omitnan'),0);
      harea = round(area(hspoly),0);
   else
      hele = round(mean(mapinterp(DEM.Z,R,xhs(ihs),yhs(ihs),'linear'),'omitnan'),0);
      hslp = round(mean(mapinterp(GRD.Z,R,xhs(ihs),yhs(ihs),'linear'),'omitnan'),4);
      harea = round(area(hspoly),0);
   end
   
   % try something different
   % idx = inpoly([X(:) Y(:)],[x y]); % way too slow
   
   % try topotoolbox interp

   if isnan(hele) || isnan(hslp) % set the resolution back to 5
      Rhs = bbox2R(bbox,res);
      [xhs,yhs] = R2grid(Rhs);
      xhs = reshape(xhs,size(xhs,1)*size(xhs,2),1);
      yhs = reshape(yhs,size(yhs,1)*size(yhs,2),1);
      ihs = inpolygon(xhs,yhs,x,y);
      hele = round(mean(mapinterp(DEM.Z,R,xhs(ihs),yhs(ihs),'linear'),'omitnan'),0);
      hslp = round(mean(mapinterp(GRD.Z,R,xhs(ihs),yhs(ihs),'linear'),'omitnan'),4);
      harea = round(area(hspoly),0);
   end
   % what this does is build a bounding box around the hillslope, then
   % creates a grid of points at res*5 x-y spacing, then takes the points
   % within the hillslope boundary, and queries the dem at those points

   % put the values into the slopes table
   slopes(n).harea = harea;
   slopes(n).hslp = hslp;
   slopes(n).helev = hele;
end


% reproject to geographic for easier plotting
proj = finfo.CoordinateReferenceSystem;
Xnodes = [nodes.X];
Ynodes = [nodes.Y];
[lt,ln] = projinv(proj,Xnodes,Ynodes);

for n = 1:Nnodes
   nodes(n).Lat = lt(n);
   nodes(n).Lon = ln(n);
end

% links and slopes require a loop
for n = 1:Nlinks
   yi = [links(n).Y];
   xi = [links(n).X];
   % this prevents an extra 90o from being appended to end of lt, not sure why
   % it happens, figured closePolygonParts would fix it, but it doesn't
   [xi,yi] = poly2cw(xi,yi);
   [xi,yi] = closePolygonParts(xi,yi);
   [lt,ln] = projinv(proj,xi,yi);
   links(n).Lat = lt;
   links(n).Lon = ln;
end

for n = 1:Nslopes
   yi = [slopes(n).Y];
   xi = [slopes(n).X];
   [xi,yi] = poly2cw(xi,yi);
   [xi,yi] = closePolygonParts(xi,yi);
   [lt,ln] = projinv(proj,xi,yi);
   slopes(n).Lat = lt;
   slopes(n).Lon = ln;
end

% for some reason, there are values of 90o in 'Lat' for some slopes. the
% poly actions up above don't fix them all. also, i noticed for i = 12
% there is a tiny area detached from the slope, not fixing for now
for n = 1:length(slopes)

   % slopes
   lati = [slopes(n).Lat];
   loni = [slopes(n).Lon];
   idx = find(lati==90);
   lati(idx) = [];
   loni(idx) = [];
   slopes(n).Lat = lati;
   slopes(n).Lon = loni;
end


% and there is one nan value in the Lon variable
for n = 1:length(links)

   % links
   lati = [links(n).Lat];
   idx = find(lati==90);
   loni = [links(n).Lon];
   nani = isnan(loni);
   lati(nani) = nan;
   links(n).Lat = lati;
end


%%%%% MOVED THE STR2DOUBLE STUFF FROM HERE UP TOP


% plot using mapshow

if plotmap == true
   nodespec = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
      6,'MarkerFaceColor','g','MarkerEdgeColor','none'});
   linkspec = makesymbolspec('Line',{'Default','Color','b','LineWidth',1});

   figure;
   mapshow(slopes); hold on;
   mapshow(links,'SymbolSpec',linkspec); hold on
   mapshow(nodes,'SymbolSpec',nodespec);
end

% plot using worldmap

if plotgeo == true
   latlims = [min(LATnodes) max(LATnodes)];
   lonlims = [min(LONnodes) max(LONnodes)];

   figure;
   worldmap(latlims,lonlims)
   scatterm(LATnodes,LONnodes,6,'filled')
end

%% save the data

if savedata == true
   save(fullfile(pathsave,'sag_hillslopes'),'slopes','links','nodes');
end


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

% below here was a script i started before realling the workflow i had set
% up ... i wrote the one below from the mosart/preprocess folder then
% remembered that the hillsloper processing was in the hillsloper folder so
% i moved that one into the mosart folder to avoid confusion later

% clean
%
% % started this feb 2022 to build an input file for the huc 12, few things
% % to note: there are scripts here and there are scripts itn eh mosart
% % preprocess folder, bit confusing to hvae them spread out. the 'hs_id'
% % field is the key, and i don't think i got that for the huc 12 from jon
%
% save_data   = false;
% plot_map    = false;
% path.data   = ['/Users/coop558/mydata/interface/sag_basin/hillsloper/' ...
%                     'old/hillsloper-master-4/Data/huc_190604020404/'];
%
% % read the data
% slopes      = shaperead([path.data 'huc_190604020404_hillslopes.shp']);
% nodes       = shaperead([path.data 'huc_190604020404_nodes.shp']);
% links       = shaperead([path.data 'huc_190604020404_links.shp']);
%
% slopes      = renameStructField2(slopes,'X','Lon');
% slopes      = renameStructField2(slopes,'Y','Lat');
% nodes       = renameStructField2(nodes,'X','Lon');
% nodes       = renameStructField2(nodes,'Y','Lat');
% links       = renameStructField2(links,'X','Lon');
% links       = renameStructField2(links,'Y','Lat');
%
% figure;
% geoshow(slopes); hold on;
% geoshow(links)
% geoshow(nodes);
%
% % [newlinks,inlet_ID,outlet_ID] = mos_make_newlinks(links,nodes);
%
% N = length(links);
% V = {'us_node_id','ds_node_id','ds_da_km2','us_da_km2','slope','len_km'};
% for i = 1:length(V)
%     vi                  = V{i};
%     di                  = num2cell(cellfun(@str2double,{links.(vi)}));
%     [links(1:N).(vi)]   = di{:};
% end
%
% % nodes is more complicated, because some fields have multiple values
% N = length(nodes); V = {'hs_id','conn','da_km2'};
% for i = 1:length(V)
%     di = {nodes.(V{i})};
%     for j = 1:length(di)
%         [nodes(j).(V{i})] = str2double(strsplit(di{j},','));
%     end
% end


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %




% for reference, this is the method that used inpolygon
% % i need the coordinates of the dem pixels
% [xdem,ydem] = pixcenters(R,R.RasterSize(1),R.RasterSize(2));
% [X,Y]       = meshgrid(xdem,ydem);
% Xrs         = reshape(X,size(X,1)*size(X,2),1);
% Yrs         = reshape(Y,size(Y,1)*size(Y,2),1);
%
% % reshape dem and slope then discard the objects
% elev        = double(reshape(DEM.Z,size(DEM.Z,1)*size(DEM.Z,2),1));
% slope       = double(reshape(G.Z,size(G.Z,1)*size(G.Z,2),1));
%
% clear xdem ydem X Y DEM G
% % this confirms that inpolygon works as expected
% % in        = inpolygon(Xrs,Yrs,x,y);
% % figure; plot(x,y); hold on; plot(Xrs(in),Yrs(in),'.')

% % and then inside the loop:
% hsidx       = inpolygon(Xrs,Yrs,x,y);           % dem pixels inside hs
% hslp        = roundn(mean(elev(hsidx)),-4);
% helev       = roundn(mean(elev(hsidx)),-4);