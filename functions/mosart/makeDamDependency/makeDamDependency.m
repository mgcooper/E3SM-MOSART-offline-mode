function Dams = makeDamDependency(Dams,Mesh,varargin)
%MAKEDAMDEPENDENCY adds an array of logical indices called 'DependentCells' to
%input table Dams that are true for mesh cells in Mesh that 'depend' on each
%dam in Dams.
% 
% Syntax:
% 
%  Dams = MAKEDAMDEPENDENCY(Mesh,Dams);
%  Dams = MAKEDAMDEPENDENCY(__,'searchradius',searchradius);
%  Dams = MAKEDAMDEPENDENCY(__,'plotfig',plotfig);
%  Dams = MAKEDAMDEPENDENCY(__,'damname',damname);
% 
%  searchradius is a numeric scalar that defines the cartesian distance
%  threshold beyond which cells are not dependent
% 
%  plotfig is a logical scalar that is true if you want to plot the results
%  
%  damname is a character or string that sets which Dam in input table Dams is
%  used, for example to test the function on one dam.
% 
% Author: Matt Cooper, Sep-26-2022, https://github.com/mgcooper
% 

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'makeDamDependency';
p.StructExpand    = false;
   
addRequired(p,    'Dams',                  @(x)istable(x)            );
addRequired(p,    'Mesh',                  @(x)isstruct(x)           );
addParameter(p,   'searchradius', 10000,   @(x)isnumeric(x)          );
addParameter(p,   'plotfig',      false,   @(x)islogical(x)          );
addParameter(p,   'damname',      'all',   @(x)ischar(x)|isstring(x) );

parse(p,Dams,Mesh,varargin{:});
   
plotfig  = p.Results.plotfig;
damname  = p.Results.damname;
rxy      = p.Results.searchradius;
   
%------------------------------------------------------------------------------

% if a single dam was requested, subset Dams
if damname ~= "all"
   Dams = Dams(Dams.Name == damname,:);
end

% dam capacity
cap      = Dams.Capacity_km3;

% get the x,y location of all the mesh cell centroids
clat     = [Mesh.dLatitude_center_degree];   clat = clat(:);
clon     = [Mesh.dLongitude_center_degree];  clon = clon(:);
celev    = [Mesh.Elevation];                 celev = celev(:);

% project to utm. i used this to find the zone: utmzone(clat(1),clon(1))
proj     = projcrs(32618,'Authority','EPSG');
[cx,cy]  = projfwd(proj,clat,clon);

% get the x,y location of the dams
[dx,dy]  = projfwd(proj,Dams.Lat,Dams.Lon);

% exclude dams outside the mesh
bound    = boundary(cx,cy);
bound    = polyshape(cx(bound),cy(bound));
inbound  = inpolygon(dx,dy,bound.Vertices(:,1),bound.Vertices(:,2));
dx       = dx(inbound);
dy       = dy(inbound);
cap      = cap(inbound);
numdams  = sum(inbound);

% find the hex cell nearest each dam
[idx,~]  = dsearchn([cx cy],[dx dy]);

% this will hold the dependent indices for each dam:
idepends = cell(numdams,1);

% plot the hex centroids, the dams, and the starting points. durign the
% loop the dependent cells can be plotted on top of this map
if plotfig == true
   macfig; 
   scatter(cx,cy,'filled'); hold on;
   scatter(dx,dy,cap.*1000,'filled');
   scatter(cx(idx),cy(idx),100,'g');
end


% for each dam, start at the nearest cell and find all cells with lower
% elevation, then find all cells within rXY distance from each cell
for n = 1:numdams

   % the x,y of the cell nearest this dam
   xn = cx(idx(n));
   yn = cy(idx(n));

   elev = celev(idx(n));

   % Tian - this is the key part where instead of xlower/ylower, we would
   % need xriver/yriver where xriver/yriver are the cells along the channel
   % that are lower than the starting point at the dam. we would actually
   % need cx/cy/celev to be the x/y/elev of all points along the channel
   % below the dam

   ilower = celev<elev;
   xlower = cx(ilower);
   ylower = cy(ilower);
   zlower = celev(ilower);

   % sort x,y,z lower from high to low elevation
   xyz      = sortrows([xlower ylower zlower],3,'descend');
   xysearch = [xyz(:,1) xyz(:,2)];

   % make the kdtree
   kdtree   = createns(xysearch);

   % find the indices of cells within rxy distance of each cell in xysearch
   inearby = rangesearch(kdtree,xysearch,rxy);

   for m = 1:numel(inearby)

      icell = inearby{m};
      xnearby = xysearch(icell,1);
      ynearby = xysearch(icell,2);

      % use this to see the result:
      if plotfig == true
         scatter(xnearby,ynearby,50,'g','filled');
         pause(.2); 
      end
   end

   % get all the cells that fall within rxy of any cell in xysearch (these
   % are the cells that depend on this dam)
   allidx = [];
   for m = 1:numel(inearby)
      allidx = [allidx; cell2mat(inearby(m))'];
   end
   allidx = unique(allidx);

   % this should be all the dependent cells for each dam
   idepends{n} = allidx;

   % % this was gonna be a brute force search
   % nlower = sum(ilower);   
   % while nlower>0
   %   nlower = nlower-1;
   %   kdtree = createns(XY);
   % end

end

% add the dependency to the Dams table
for n = 1:numdams
   Dams.DependentCells{n} = idepends{n};
end


% % testing kdtree
% % use lat/lon
% rLL         = 1.0;               % 1 degree?
% LL          = [clon(:) clat(:)];
% kdtreeLL    = createns(LL);
% [iLL,dLL]   = rangesearch(kdtree,LL(1,:),rLL);
% 
% % use x/y
% rXY         = 50*1000;           % 50 km? 
% XY          = [cx(:) cy(:)];
% kdtreeXY    = createns(XY);
% [iXY,dXY]   = rangesearch(kdtree,XY(1,:),rXY);


% % this confirms that the dLongitude_center/dLatitude_center is the
% centroid of each hexagon
% lat   = [Mesh(n).Lat];
% lon   = [Mesh(n).Lon];
% poly  = polyshape(lon,lat);
% [clon,clat] = centroid(poly);
% [Mesh(n).dLongitude_center_degree Mesh(n).dLatitude_center_degree]


% % this works but is so slow and it doesn't plot the hexagons
% % make a map struct for the hex centroids
% Hex      = Mesh;
% Hex      = rmfield(Hex,{'Lat','Lon'});
% 
% [Hex(1:3155).Geometry]  = deal('Point');
% [Hex(1:3155).X]         = deal(cx);
% [Hex(1:3155).Y]         = deal(cy);
% 
% symspec  = makemapspec('point');
% figure; mapshow(Hex,'DisplayType','point','SymbolSpec',symspec);















