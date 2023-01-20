function [Dams,Mesh] = makeDamDependency_tbls(Dams,Mesh,Line,varargin)
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
addParameter(p,   'IDtype',       'local',   @(x)ischar(x)|isstring(x) );

parse(p,Dams,Mesh,Line,varargin{:});

rxy      = p.Results.searchradius;
plotfig  = p.Results.plotfig;
damname  = p.Results.damname;
IDtype   = p.Results.IDtype;
   
%------------------------------------------------------------------------------

% this determines whether we start the search for dependent cells at the grid
% cell that contains each dam (useflowline=false), or the grid cell nearest
% each dam that contains a flowline (useflowline=true). 
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

% project to utm. i used this to find the zone: utmzone(clat(1),clon(1))
proj           = projcrs(32618,'Authority','EPSG');
[xmesh,ymesh]  = projfwd(proj,latmesh,lonmesh);          % mesh
[xdams,ydams]  = projfwd(proj,Dams.Lat,Dams.Lon);        % dams

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
MeshLine = Mesh(imeshline);
   
% imeshdams are the indices of the mesh cells nearest each dam
if useflowline == true
   
   % find the nearest cell to each dam that contains a flowline:
   [iflowlinedams,~] = dsearchn([xmesh(imeshline) ymesh(imeshline)],[xdams ydams]);

   % transform iflowlinedams to the global mesh indices:
   imeshdams = transpose([MeshLine(iflowlinedams).cell_ID]);
   
else
   % find the nearest cell to each dam whether it contains a flowline or not:
   [imeshdams,~] = dsearchn([xmesh ymesh],[xdams ydams]);
end

% find the elevation of the cell that contains the dam
zdams = zmesh(imeshdams);

% for each dam, find all downstream cells to the outlet
switch IDtype
   case 'local'
      ID = [Mesh.cell_ID];
      dnID = [Mesh.cell_dnID];
   case 'global'
      ID = [Mesh.cell_ID];
      dnID = [Mesh.cell_dnID];
      % don't use these here, instead transform at the end
      % ID = [Mesh.lCellID];
      % dnID = [Mesh.lCellID_downslope];
end

[i_downstream,id_downstream] = findDownstreamCells(ID,dnID,imeshdams,'mosart');

% add the downstream cells to the Dams table. for IDtype 'local',
% i_DownstreamCells(2:end-1) = ID_DownstreamCells are identical except for the outlet
% cell
for n = 1:numdams
   Dams.i_DownstreamCells{n} = i_downstream{n};
   Dams.ID_DownstreamCells{n} = id_downstream{n};
end

% this will hold the dependent indices for each dam:
idepends = cell(numdams,1);

% Set up a figure before running the algorithm
%---------------------------------------------
if plotfig == true
   % green = mesh cells along the flowline. magenta = mesh cells nearest each
   % dam along the flowline. blue = flowline. black = dams.
   figure('Position', [50 60 1200 1200]); hold on; 
   patch_hexmesh(Mesh); % use 'FaceMapping','Elevation' to see the elevation
   patch_hexmesh(MeshLine,'FaceColor','g');
   patch_hexmesh(Mesh(imeshdams),'FaceColor','m'); hold on;
   geoshow(Line); scatter(Dams.Lon,Dams.Lat,'k','filled');
end


% run the algorithm
%---------------------------------------------
% for each dam, start at the nearest cell and find all cells with lower
% elevation, then find all cells within rXY distance from each cell
for n = 1:numdams

   % use the elevation of the cell nearest this dam as a threshold to exclude
   % cells found by the range search that are above the dam. this could be
   % replaced by the elevation of the dam, or the elevation of the cell that
   % contains the dam.
   % elev  = zmesh(imeshdams(n));
   
   % this uses the elevation of the mesh cell that contains the dam
   elev  = zdams(n);
   
   % gather the downstream cells for this dam. these are the query points for
   % the kdtree, which finds all cells within rxy distance of these points 
   iquery   = Dams.i_DownstreamCells{n};
   xyquery  = [xmesh(iquery) ymesh(iquery)];

   % query the mesh kdtree to find all downstream cells within rxy distance of
   % the flowline. all cells in xyquery are below the dam, but the rangesearch
   % will return cells that are above the dam, so we will trim those afterward.
   % inearby is a cell array with one cell per downstream point in xyquery.
   % each cell has the mesh indices within rxy distance of the xyquery vertex.
   inearby = rangesearch(MeshTree,xyquery,rxy);
   
   %sprintf('%.2f %.2f',xyquery(end,1),xyquery(end,2))
   %406158.04907704145, 4380451.961597792
   
   % concatenate into one list, then remove cells that are above the dam
   inearby = horzcat(inearby{:});
   inearby = unique(inearby(zmesh(inearby) < elev));
   
   % save the dependent cells for this dam
   idepends{n} = inearby;

   % see the result. only run on the first dam for demonstration (n=1)
   if plotfig == true && n == 1
      patch_hexmesh(Mesh(idepends{n}),'FaceColor','g');
      scatter_hexmesh(Mesh(imeshdams(n)),'FaceColor','y','MarkerSize',100);
      scatter_hexmesh(Mesh(iquery),'MarkerSize',20,'FaceColor','r');
   end
   
end

% add the dependency to the Dams table
for n = 1:numdams
   Dams.ID_DependentCells{n} = transpose(idepends{n});
end

% rather than request 'local' vs 'global' ID at the beginning, transform the
% dependent cells here (b/c various parts of the algorithm rely on the local ID
% implicitly via indexing into the vectors i.e. from 1:numcells. but i left the
% option in place for now b/c it might be helpful later to have all quantities
% independent of the 1:numcells indexing)
if IDtype == "global"
   globalID = [Mesh.lCellID];
   for n = 1:numel(idepends)
      id_n = idepends{n};
      id_n(id_n==-9999) = -1;
      Dams.globalID_DependentCells{n} = transpose(globalID(id_n));
   end
end

% % this shows that the mapping to globalID works:
% figure; 
% for n = 1:numel(Mesh)
%    dependentcells = Dams.DependentCells{n};
%    idependent = ismember(globalID,dependentcells);
%    patch_hexmesh(Mesh(idependent));
%    pause;
% end

% % this confirms that the dLongitude_center/dLatitude_center is the
% centroid of each hexagon
% lat   = [Mesh(n).Lat];
% lon   = [Mesh(n).Lon];
% poly  = polyshape(lon,lat);
% [clon,clat] = centroid(poly);
% [Mesh(n).dLongitude_center_degree Mesh(n).dLatitude_center_degree]


% % this works but is slow and it doesn't plot the hexagons
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



% these are not used but keep them if we want to use the flowline rather
% than the mesh cells that contain the flowline.  

% % get the x,y location of the flowlines. imesh is the indices of the hex cells
% % that contain a flowline indici
% latline     = [];
% lonline     = [];
% for n = 1:numel(Line)
%    latline     = [latline;nan;Line(n).Lat];
%    lonline     = [lonline;nan;Line(n).Lon];
%    imeshline   = [imeshline;Line(n).iMesh];
% end

% [xline,yline]  = projfwd(proj,latline,lonline);          % flowline







