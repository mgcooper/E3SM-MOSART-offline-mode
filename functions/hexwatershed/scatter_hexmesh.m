function scatter_hexmesh(Mesh,varargin)
%scatter_hexmesh plots the hexwatershed mesh using scatter 

%------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'scatter_hexmesh';

addRequired(   p, 'Mesh');
addParameter(  p, 'FaceColor', 'k', @(x)ischar(x)|isnumeric(x));
addParameter(  p, 'MarkerSize',40,  @(x)isnumeric(x));

parse(p,Mesh,varargin{:});

FaceColor = p.Results.FaceColor;
MarkerSize = p.Results.MarkerSize;
%------------------------------------------------------------------------------

hold on;
for n = 1:numel(Mesh)
   lat = Mesh(n).dLatitude_center_degree;
   lon = Mesh(n).dLongitude_center_degree;
   
   scatter(lon,lat,MarkerSize,FaceColor,'filled');
end
