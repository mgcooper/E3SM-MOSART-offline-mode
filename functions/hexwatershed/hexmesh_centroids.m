function [latc,lonc,numc] = hexmesh_centroids(Mesh)
%HEXMESH_CENTROIDS return latitude and longitude of hexmesh cell centroids
% 
%  [latc,lonc,numc] = hexmesh_centroids(Mesh)
% 
% See also hexmesh_vertices

numc = numel([Mesh(:).lCellID]);
lonc = transpose([Mesh(:).dLongitude_center_degree]);
latc = transpose([Mesh(:).dLatitude_center_degree]);