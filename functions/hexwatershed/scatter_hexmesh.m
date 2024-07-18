function scatter_hexmesh(Mesh,varargin)
   %scatter_hexmesh plots the hexwatershed mesh using scatter

   parser = inputParser;
   parser.FunctionName = mfilename;
   addRequired(parser, 'Mesh');
   addParameter(parser, 'FaceColor', 'k', @(x)ischar(x)|isnumeric(x));
   addParameter( parser, 'MarkerSize',40,  @(x)isnumeric(x));
   parse(parser,Mesh,varargin{:});

   FaceColor = parser.Results.FaceColor;
   MarkerSize = parser.Results.MarkerSize;

   hold on
   for n = 1:numel(Mesh)
      lat = Mesh(n).dLatitude_center_degree;
      lon = Mesh(n).dLongitude_center_degree;

      scatter(lon,lat,MarkerSize,FaceColor,'filled');
   end
end
