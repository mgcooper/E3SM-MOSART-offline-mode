function varargout = hexmesh_dnID(Mesh)
%HEXMESH_DNID returns the ID and downstream ID (dnID) of each cell in Mesh.
%Works for global Mesh or flowline Mesh
%
%  [ID,dnID] = HEXMESH_DNID(Mesh) returns cell ID and downstream cell ID lists
%
%  Mesh = HEXMESH_DNID(Mesh) returns Mesh with added fields cell_ID and
%  cell_dnID
%
% Author: Matt Cooper, 04-Oct-2022, https://github.com/mgcooper


%--------------- input parsing
p = inputParser;
p.FunctionName = 'hexmesh_dnID';
addRequired(p, 'Mesh', @(x)isstruct(x));
parse(p,Mesh);

%--------------- processing
cell_ID = transpose([Mesh(:).lCellID]);
cell_dnID = transpose([Mesh(:).lCellID_downslope]);

% Convert ID
N = numel(cell_ID);
ID = transpose(1:N);
dnID = NaN(N,1);

for n = 1:N
   if cell_dnID(n) == -9999
      dnID(n) = -9999;
   else
      idx = find(cell_ID == cell_dnID(n));
      if isempty(idx)
         dnID(n) = -9999;
      else
         dnID(n) = ID(idx);
      end
   end
end

% package output
switch nargout
   case 1
      for n = 1:numel(Mesh)
         Mesh(n).cell_ID = ID(n);
         Mesh(n).cell_dnID = dnID(n);
      end
      varargout{1} = Mesh;

   case 2
      varargout{1} = ID;
      varargout{2} = dnID;
end





