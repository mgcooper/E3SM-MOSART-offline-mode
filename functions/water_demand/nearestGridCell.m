function I = nearestGridCell(XGrid,YGrid,XMesh,YMesh)
% findMeshNearestNeighbor

if isGeoGrid(YGrid,XGrid)
   [XGrid,YGrid] = ll2utm(YGrid,XGrid,18,'wgs84');
end

% find the nearest gcam cell to each mesh cell, to map the annual drbc onto
% monthly gcam cycle
[I,~] = dsearchn([XGrid,YGrid],[XMesh,YMesh]);