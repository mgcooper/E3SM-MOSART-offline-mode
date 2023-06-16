function varargout = readMeshJsonFile(varargin)

if nargin == 0
   filename = getenv('USER_HEXWATERSHED_MESH_JSONFILE_FULLPATH');
else
   filename = varargin{1};
end

Mesh = jsondecode(fileread(filename));
[YC,XC,NC] = hexmesh_centroids(Mesh);
[YV,XV,NV] = hexmesh_vertices(Mesh);

% transpose the vertices
XV = XV.'; YV = YV.';

% wrap the lon to 360
XC = wrapTo360(XC);
XV = wrapTo360(XV);

switch nargout
   case 1
      varargout{1} = Mesh;
   case 2
      [varargout{1:nargout}] = deal(XC,YC);
   case 3
      [varargout{1:nargout}] = deal(XC,YC,NC);
   case 4
      [varargout{1:nargout}] = deal(XC,YC,XV,YV);
   case 5
      [varargout{1:nargout}] = deal(XC,YC,XV,YV,NV);
   case 6
      [varargout{1:nargout}] = deal(XC,YC,NC,XV,YV,NV);
end