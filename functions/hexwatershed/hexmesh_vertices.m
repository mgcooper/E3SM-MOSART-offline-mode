function [latverts,lonverts,numverts] = hexmesh_vertices(Mesh)
%HEXMESH_VERTICES return latitude and longitude vectors of hexmesh cell vertices
% 
%  [latverts,lonverts,numverts] = hexmesh_vertices(Mesh)
% 
% See also

cellIDs = transpose([Mesh(:).lCellID]);
numcells = numel(cellIDs);
lonverts = NaN(8,numcells);
latverts = NaN(8,numcells);
numverts = NaN(numcells,1);
for n = 1:numcells
   tmpx = [Mesh(n).vVertex(:).dLongitude_degree];
   tmpy = [Mesh(n).vVertex(:).dLatitude_degree];
   numverts(n) = numel(tmpx);
   lonverts(1:numel(tmpx),n) = tmpx;
   latverts(1:numel(tmpy),n) = tmpy;
end