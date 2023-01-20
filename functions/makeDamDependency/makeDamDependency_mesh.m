function [Dams,Mesh] = makeDamDependency_mesh(Dams,Mesh,Line,varargin)
%makeDamDependency adds an array of logical indices called 'DependentCells' to
%input table Dams. The DependentCells for each dam are true for mesh cells in
%Mesh that 'depend' on each dam in Dams.
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
% Author: Matt Cooper, 26-Sep-2022, https://github.com/mgcooper
% 

% 9 Jan 2022: I compared this to the _tbls version and I am nearly certain this
% version can be deleted. The main difference is the distinction b/w imeshdams
% and iflowlinedams in the if useflowline section, which I recall was related
% to something I realized that simplified the indexing, I think something about
% indexing going from 1:numcells when I was using a find statement, and by
% adding the if useflowline statement to the _tbls version I was able to keep
% both behaviors. I almost deleted this function but keepign it for now just in
% case. MAYBE I MADE THIS TEMPORARILY TO WORK WITH THE WHOLE DOMAIN MESH AND
% NEVER WORKED ON IT THEN MADE THE _TBLS VERSION 

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'makeDamDependency';
p.StructExpand    = false;
   
addRequired(p,    'Dams',                    @(x)istable(x)            );
addRequired(p,    'Mesh',                    @(x)isstruct(x)           );
addRequired(p,    'Line',                    @(x)isstruct(x)           );
addParameter(p,   'searchradius', 10000,     @(x)isnumeric(x)          );
addParameter(p,   'plotfig',      false,     @(x)islogical(x)          );
addParameter(p,   'damname',      'all',     @(x)ischar(x)|isstring(x) );

parse(p,Dams,Mesh,Line,varargin{:});

rxy      = p.Results.searchradius;
plotfig  = p.Results.plotfig;
damname  = p.Results.damname;
   
%------------------------------------------------------------------------------

useflowline = false; 

% if a single dam was requested, subset Dams
if damname ~= "all"
   Dams = Dams(Dams.Name == damname,:);
end
numdams = size(Dams,1);

% get the x,y location of all the mesh cell centroids
latmesh  = transpose([Mesh.dLatitude_center_degree]);
lonmesh  = transpose([Mesh.dLongitude_center_degree]);
zmesh    = transpose([Mesh.Elevation]);

% NOTE: these are not used but keep them if we want to use the flowline rather
% than the mesh cells that contain the flowline. get the x,y of the flowlines.
% [latline,lonline] = polyjoin({Line.Lat},{Line.Lon});

% project to utm. i used this to find the zone: utmzone(clat(1),clon(1))
proj           = projcrs(32618,'Authority','EPSG');
[xmesh,ymesh]  = projfwd(proj,latmesh,lonmesh);          % mesh
[xdams,ydams]  = projfwd(proj,Dams.Lat,Dams.Lon);        % dams
% [xline,yline]  = projfwd(proj,latline,lonline);          % flowline

% keep this to find all hex cells that contain a flowline using the Mesh
% attribute iSegment, which should work with updated hexwatershed output
% unique([Mesh.iSegment])

% build the kdtree for the mesh
MeshTree = createns([xmesh ymesh]);

% get the mesh cells that contain a flowline and add that info to the Mesh
imeshline = vertcat(Line(:).iMesh);
[Mesh.iflowline] = deal(false);
for n = 1:numel(imeshline)
   Mesh(imeshline(n)).iflowline = true;
end

% subset the mesh cells that contain a flowline
xmeshline = xmesh(imeshline);     % mesh-flowline x
ymeshline = ymesh(imeshline);     % mesh-flowline y
zmeshline = zmesh(imeshline);     % mesh-flowline elevation
MeshLine = Mesh(imeshline);

% imeshdams are the indices of the mesh cells nearest each dam
if useflowline == true
   % find the nearest cell to each dam that contains a flowline:
   [imeshdams,~] = dsearchn([xmesh(imeshline) ymesh(imeshline)],[xdams ydams]);
else
   % find the nearest cell to each dam whether it contains a flowline or not:
   [imeshdams,~] = dsearchn([xmesh ymesh],[xdams ydams]);
end

% for each dam, find all downstream cells to the outlet
[dnidx,dnID] = findDownstreamCells(Mesh,imeshdams);

% add the downstream cells to the Dams table
for n = 1:numdams
   Dams.i_DownstreamCells{n} = dnidx{n};
   Dams.ID_DownstreamCells{n} = dnID{n};
end

% figure('Position', [50 60 1200 1200]); hold on; 
% patch_hexmesh(Mesh); geoshow(Line); scatter(Dams.Lon,Dams.Lat,'k','filled');
% patch_hexmesh(MeshLine(ismember(dam_dnIDs,ID)),'FaceColor','m');

% this will hold the dependent indices for each dam:
idepends = cell(numdams,1);

% Set up a figure before running the algorithm
%---------------------------------------------
% plot the hex centroids, the dams, and the starting points. durign the
% loop the dependent cells can be plotted on top of this map
if plotfig == true
   
   % green = mesh cells along the flowline. magenta = mesh cells nearest each
   % dam along the flowline. black = flowline
   figure('Position', [50 60 1200 1200]); hold on; 
   patch_hexmesh(Mesh); % use 'FaceMapping','Elevation' to see the elevation
   patch_hexmesh(MeshLine,'FaceColor','g');
   patch_hexmesh(Mesh(imeshdams),'FaceColor','m'); hold on;
   geoshow(Line); scatter(Dams.Lon,Dams.Lat,'b','filled');
   
   % use the cartesian coords:
   %    macfig; scatter(mx,my,'filled'); hold on;
   %    plot(fx,fy,'m');
   %    scatter(mx(idx),my(idx),100,'g','filled');
end


% run the algorithm
%---------------------------------------------
% for each dam, start at the nearest cell and find all cells with lower
% elevation, then find all cells within rXY distance from each cell
for n = 1:numdams

   % the elevation of the cell nearest this dam is used as a threshold to
   % exclude cells above the dam. this could be replaced by the elevation of
   % the dam, or the elevation of the cell that contains the dam.
   elev  = zmesh(imeshdams(n));
   
   % gather the mesh cells that are below this dam along the flowline. these
   % are the query points for the candidate tree, to find all points in the
   % candidate tree within rxy distance of these points.   
   
   % get the downstream cells for this dam
   iquery   = Dams.i_DownstreamCells{n};
   xyquery  = [xmesh(iquery) ymesh(iquery)];

   % these iquery,xyquery versions were commented out. i added the if
   % useflowline statement to draw a parallel with the _tbls version
   if useflowline == true
      iquery   = zmeshline<elev;
      xyquery  = [xmeshline(iquery) ymeshline(iquery)];
   end

   % query the mesh tree to find all cells below the dam that are also within
   % rxy distance of the flowline. all cells in xyquery are below the dam, but
   % the cells returned by the rangesearch could be above the dam, so we will
   % trim those afterward.
   inearby     = rangesearch(MeshTree,xyquery,rxy);
   
   % remove cells that are above the dam and concatenate the rest into one
   % list. inearby is a cell array with one cell per flowline vertex. each cell
   % has the indices of the Mesh that are within rxy distance of the mesh
   % centroid that contains the flowline vertex (the flowline vertices are not
   % exactly coincident with the cell centroids). but we want all the mesh
   % cells that this dam contributes to, so flatten this into one list of all 
   % mesh cells over all vertices, removing those above the dam along the way.
   allidx = [];
   for m = 1:numel(inearby)
      idx = cell2mat(inearby(m))';
      idx = idx(zmesh(idx)<elev);
      allidx = [allidx;idx];
   end
   
   % save the unique values - these are the dependent cells for this dam
   idepends{n} = unique(allidx);

   % see the result. only run on the first dam for demonstration (n=1)
   if plotfig == true && n == 1
      patch_hexmesh(Mesh(idepends{n}),'FaceColor','g');
      geoshow(Line); scatter(Dams.Lon,Dams.Lat,'b','filled');
      scatter_hexmesh(Mesh(imeshdams(n)),'FaceColor','y','MarkerSize',100);
      scatter_hexmesh(Mesh(iquery),'MarkerSize',20,'FaceColor','r');
   end
   
end

% add the dependency to the Dams table
for n = 1:numdams
   Dams.DependentCells{n} = idepends{n};
end


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















