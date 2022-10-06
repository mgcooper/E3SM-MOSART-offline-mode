function Line = findMeshCellsOnFlowline(Mesh,Line)
%FINDMESHCELLSONFLOWLINE finds the mesh cells that contain each flowline
%vertex and adds that info to the Line structure
% 
% Syntax:
% 
%  Line = findMeshCellsOnFlowline(Mesh,Line)
% 
% Author: Matt Cooper, 05-Oct-2022, https://github.com/mgcooper

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
   p                 = inputParser;
   p.FunctionName    = 'findMeshCellsOnFlowline';
   
   addRequired(p,    'Mesh',                 @(x)isstruct(x)           );
   addRequired(p,    'Line',                 @(x)isstruct(x)           );
   
   parse(p,Mesh,Line);
   
%------------------------------------------------------------------------------

% each line is comprised of segments with vertices that are near but not
% exactly equal to the mesh cell centroids. if they were exactly equal we could
% use == to find the mesh cells that contain each segment. instead, iterate
% over the  vertices of each line segment and find the nearest mesh cell, and
% add that index to the line attributes.

% extract the mesh cell centroid coordinates
lonmesh = transpose([Mesh.dLongitude_center_degree]);
latmesh = transpose([Mesh.dLatitude_center_degree]);

% make a figure to see the mesh if desired
% figure('Position', [50 60 1200 1200]); hold on; 
% patch_hexmesh(Mesh); hold on;

for n = 1:numel(Line)
   
   lat = Line(n).Lat;
   lon = Line(n).Lon;
   
   idx = nan(1,numel(lat));
   for m = 1:numel(lat)
      % scatter(lon(m),lat(m),'b','filled');
      idx(m) = dsearchn([lonmesh latmesh],[lon(m) lat(m)]);
   end
   Line(n).iMesh = idx(:);
   Line(n).Lat_Mesh = latmesh(idx);
   Line(n).Lon_Mesh = lonmesh(idx);
   
   % this can be used to see the flowline vertices
   % geoshow(Line(n));
end






