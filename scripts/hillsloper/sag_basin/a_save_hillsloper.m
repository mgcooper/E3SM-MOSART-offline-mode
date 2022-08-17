clean

save_data   = true;
plot_map    = 0;
p.data      = '/Users/coop558/mydata/e3sm/sag/hillsloper/IFSAR_hillslopes/';
p.topo      = '/Users/coop558/mydata/e3sm/topo/topo_toolbox/flow_network/basin/';
p.save      = setpath('interface/data/hillsloper/sag_basin/');

warning('off') % so polyshape stops complaining
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% read in the data
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
list        = dir(fullfile([p.data '*.shp']));
info        = shapeinfo([p.data list(1).name]);
slopes      = shaperead([p.data list(1).name]);
links       = shaperead([p.data list(3).name]); % new sf w/hs_id
nodes       = shaperead([p.data list(4).name]);

Nnodes      = length(nodes);
Nlinks      = length(links);
Nslopes     = length(slopes);

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% this takes forever so do it here once
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% load IfSAR dem and calculate slope
% load([p.topo 'sag_dems'],'R','Z');      % 5 m dem, for plotting
% [~,slope]   = gradientm(Z,R);           % only works with geo coords

% use topo toolbox instead
fname       = 'IfSAR_5m_DTM_Alaska_Albers_Sag_basin.tif';
fname       = ['/Users/coop558/mydata/e3sm/topo/' fname];
DEM         = GRIDobj(fname);           % elevation
G           = gradient8(DEM);           % slope
[~,R]       = readgeoraster(fname);     % spatial referencing
res         = R.CellExtentInWorldX;
% i used this to confirm that bbox in slopes is compatible with bbox2R
% bbox        = mapbbox(R,R.RasterSize(1),R.RasterSize(2));

% loop through the hillslopes and extract the mean elevation and slope
for i = 1:length(slopes)
    hs          = slopes(i);
    x           = hs.X;   
    y           = hs.Y;
    hspoly      = polyshape(x,y);
    
    % this is MUCH faster than inpolygon if a coarser res is used to query
    % the dem, with ~no impact on accuracy, since we're taking the mean.
    % If res=5, it gives identical results as inpolygon w/o coarsening
    bbox        = hs.BoundingBox;
    Rhs         = bbox2R(bbox,res*5);       
    [xhs,yhs]   = R2grid(Rhs);
    xhs         = reshape(xhs,size(xhs,1)*size(xhs,2),1);
    yhs         = reshape(yhs,size(yhs,1)*size(yhs,2),1);
    inhs        = inpolygon(xhs,yhs,x,y);
    helev       = roundn(nanmean(mapinterp(DEM.Z,R,xhs(inhs),yhs(inhs),'linear')),0);
    hslp        = roundn(nanmean(mapinterp(G.Z,R,xhs(inhs),yhs(inhs),'linear')),-4);
    harea       = roundn(area(hspoly),0);
    
    if isnan(helev) || isnan(hslp) % set the resolution back to 5
        Rhs         = bbox2R(bbox,res);       
        [xhs,yhs]   = R2grid(Rhs);
        xhs         = reshape(xhs,size(xhs,1)*size(xhs,2),1);
        yhs         = reshape(yhs,size(yhs,1)*size(yhs,2),1);
        inhs        = inpolygon(xhs,yhs,x,y);
        helev       = roundn(nanmean(mapinterp(DEM.Z,R,xhs(inhs),yhs(inhs),'linear')),0);
        hslp        = roundn(nanmean(mapinterp(G.Z,R,xhs(inhs),yhs(inhs),'linear')),-4);
        harea       = roundn(area(hspoly),0);
    end
    % what this does is build a bounding box around the hillslope, then
    % creates a grid of points at res*5 x-y spacing, then takes the points
    % within the hillslope boundary, and queries the dem at those points
    
    % put the values into the slopes table
    slopes(i).      ...
        harea   = harea;
    slopes(i).      ...
        hslp    = hslp;
    slopes(i).      ...
        helev   = helev; 
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% reproject to geographic for easier plotting
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
proj        = info.CoordinateReferenceSystem;
Xnodes      = [nodes.X];
Ynodes      = [nodes.Y];
[lt,ln]     = projinv(proj,Xnodes,Ynodes);

for i = 1:Nnodes
    nodes(i).Lat    = lt(i);
    nodes(i).Lon    = ln(i);
end

% links and slopes require a loop
for i = 1:Nlinks
    yi              = [links(i).Y];
    xi              = [links(i).X];
% this prevents an extra 90o from being appended to end of lt, not sure why
% it happens, figured closePolygonParts would fix it, but it doesn't
    [xi,yi]         = poly2cw(xi,yi);
    [xi,yi]         = closePolygonParts(xi,yi);
    [lt,ln]         = projinv(proj,xi,yi);
    links(i).Lat    = lt;
    links(i).Lon    = ln;
end

for i = 1:Nslopes
    yi              = [slopes(i).Y];
    xi              = [slopes(i).X];
    [xi,yi]         = poly2cw(xi,yi);
    [xi,yi]         = closePolygonParts(xi,yi);
    [lt,ln]         = projinv(proj,xi,yi);
    slopes(i).Lat   = lt;
    slopes(i).Lon   = ln;
end

% for some reason, there are values of 90o in 'Lat' for some slopes. the
% poly actions up above don't fix them all. also, i noticed for i = 12
% there is a tiny area detached from the slope, not fixing for now
for i = 1:length(slopes)
    
    % slopes
    lati            = [slopes(i).Lat];
    loni            = [slopes(i).Lon];
    idx             = find(lati==90);
    lati(idx)       = [];
    loni(idx)       = [];
    slopes(i).Lat   = lati;
    slopes(i).Lon   = loni;
end
    
    
% and there is one nan value in the Lon variable
for i = 1:length(links)
    
    % links
    lati        = [links(i).Lat];
    idx         = find(lati==90);
    loni        = [links(i).Lon];
    nani        = isnan(loni);
    lati(nani)  = nan;
    links(i).Lat   = lati;
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% convert strings to doubles
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
N = Nlinks;
V = {'us_node_id','ds_node_id','ds_da_km2','us_da_km2','slope','len_km','hs_id'};
for i = 1:length(V)
    vi                  = V{i};
    di                  = num2cell(cellfun(@str2double,{links.(vi)}));
    [links(1:N).(vi)]   = di{:};
end

% nodes is more complicated, because some fields have multiple values
N = Nnodes; 
V = {'hs_id','conn','da_km2'};
for i = 1:length(V)
    di = {nodes.(V{i})};
    for j = 1:length(di)
        [nodes(j).(V{i})] = str2double(strsplit(di{j},','));
    end
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% plot using mapshow
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if plot_map == true
nodespec    = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
                6,'MarkerFaceColor','g','MarkerEdgeColor','none'});
linkspec    = makesymbolspec('Line',{'Default','Color','b','LineWidth',1});
figure;
mapshow(links,'SymbolSpec',linkspec); hold on
mapshow(nodes,'SymbolSpec',nodespec);
end
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% plot using worldmap
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if plot_map == true
latlims     = [min(LATnodes) max(LATnodes)];
lonlims     = [min(LONnodes) max(LONnodes)];

figure;
worldmap(latlims,lonlims)
scatterm(LATnodes,LONnodes,6,'filled')
end
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% save the data
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if save_data == true
    save([p.save 'sag_hillslopes'],'slopes','links','nodes');
end


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