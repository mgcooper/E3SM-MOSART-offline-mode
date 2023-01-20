function [ID_DependentCells,i_DependentCells] = makeDamDependency(...
                                       ID,dnID,xydams,xyzmesh,varargin)
%makeDamDependency finds the IDs of all cells in xyzmesh that depend on each
%dam in xydams. each row of the output array 'DependentCells' contains the IDs
%of the depenent cells for the dam corresponding to that row.
% 
% Syntax:
% 
%  DependentCells = makeDamDependency(ID,dnID,xydams,xyzmesh)
%  DependentCells = makeDamDependency(__,'searchradius',searchradius);
%  DependentCells = makeDamDependency(__,'IDtype',idtype);
%  DependentCells = makeDamDependency(__,'useflowline',true/false);
%  DependentCells = makeDamDependency(__,'iflowline',iflowline);
% 
%  searchradius is a numeric scalar that defines the cartesian distance
%  threshold beyond which cells are not dependent
% 
%  useflowline is a logical scalar that is true if you want to use the values
%  in xymesh indicated by the logical array iflowline, which is true for mesh
%  cells that contain a flowline segment
%  
%  IDtype is a character or string that sets which type of ID scheme is used.
%  'mosart' is the local ID from 1:numcells, 'hexwatershed' uses the lCellID
%  field of the hexwateshed json file
% 
% Author: Matt Cooper, 26-Sep-2022, https://github.com/mgcooper
% 

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'makeDamDependency';
p.StructExpand    = false;

addRequired(p,    'ID',                         @(x)isnumeric(x)           );
addRequired(p,    'dnID',                       @(x)isnumeric(x)           );
addRequired(p,    'xydams',                     @(x)isnumeric(x)           );
addRequired(p,    'xyzmesh',                    @(x)isnumeric(x)           );
addParameter(p,   'searchradius',   10000,      @(x)isnumeric(x)           );
addParameter(p,   'userID',         nan,        @(x)isnumeric(x)           );
addParameter(p,    'iflowline',     false,      @(x)islogical(x)           );

parse(p,ID,dnID,xydams,xyzmesh,varargin{:});
   
rxy         = p.Results.searchradius;
userID      = p.Results.userID;
iflowline   = p.Results.iflowline;

% useflowline determines whether we start the search for dependent cells at the
% grid cell that contains each dam (useflowline=false), or the grid cell
% nearest each dam that contains a flowline (useflowline=true). if useflowline
% is true, then iflowline must be provided, where iflowline is a logical array
% of size equal to xmesh/ymesh that is true for cells that contain a flowline
%------------------------------------------------------------------------------

zmesh = xyzmesh(:,3);
xymesh = xyzmesh(:,1:2);
numdams = size(xydams,1);

% build the kdtree for the mesh
meshTree = createns(xymesh);
   
% imeshdams are the indices of the mesh cells nearest each dam
if any(iflowline) == true

   % find the nearest cell to each dam that contains a flowline:
   [iflowlinedams,~] = dsearchn(xymesh(iflowline,:),xydams);

   % subset the mesh cells that contain a flowline
   IDflowline = ID(iflowline);
   
   % transform iflowlinedams to the global mesh indices:
   imeshdams = transpose(IDflowline(iflowlinedams));
   
else
   % find the nearest cell to each dam whether it contains a flowline or not:
   [imeshdams,~] = dsearchn(xymesh,xydams);
end

% find the elevation of the cell that contains the dam
zdams = zmesh(imeshdams);

% for each dam, find all downstream cells to the outlet
idownstream = findDownstreamCells(ID,dnID,imeshdams,'mosart');

% init the dependent indices for each dam:
idepends = cell(numdams,1);

% run the algorithm
%---------------------------------------------
% for each dam, start at the nearest cell and find all cells with lower
% elevation, then find all cells within rXY distance from each cell
for n = 1:numdams
   
   % gather the downstream cells for this dam. these are the query points for
   % the kdtree, which finds all cells within rxy distance of these points 
   iquery = idownstream{n};
   xyquery = xymesh(iquery,:);

   % query the mesh kdtree to find all downstream cells within rxy distance of
   % the flowline. all cells in xyquery are below the dam, but the rangesearch
   % will return cells that are above the dam, they get trimmed next.
   % inearby is a cell array with one cell per downstream point in xyquery.
   % each cell has the mesh indices within rxy distance of the xyquery vertex.
   inearby = rangesearch(meshTree,xyquery,rxy);
   
   % concatenate and remove cells that are above zdams(n) (the elevation of the
   % mesh cell that contains the dam)
   inearby = horzcat(inearby{:});
   inearby = unique(inearby(zmesh(inearby) < zdams(n)));
   idepends{n} = inearby;

end

% transform the dependent cell ID's from the local to the global scheme
if ~isnan(userID)
   for n = 1:numdams
      IDdepends{n} = userID(idepends{n});
   end
end

% put the dependent cells into a table of uniform size
maxcells = max(cellfun(@numel,idepends));
ID_DependentCells = nan(numdams,maxcells);
i_DependentCells = nan(numdams,maxcells);
for n = 1:numdams
   ID_DependentCells(n,1:numel(idepends{n})) = IDdepends{n};
   i_DependentCells(n,1:numel(idepends{n})) = idepends{n};
end