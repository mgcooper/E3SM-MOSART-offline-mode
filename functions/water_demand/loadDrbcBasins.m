function [P,PX,PY,PA] = loadDrbcBasins(varargin)

warning('off','MATLAB:polyshape:repairedBySimplify');

usegeo = varargin{1};

Sdrbc = loadgis('DELW.shp','UseGeoCoords',true);
load('drbc_subbasins.mat','Basins')

% in this case, we have the shape areas, so send them in
PA = [Basins.Meta.Shape_Area].';
PX = {Basins.Bounds.X}.';
PY = {Basins.Bounds.Y}.';

% convert to lat lon then repackage 
[PX,PY] = polyvec(PX,PY);

% Use DRB full basin to first clip the mesh
if usegeo == true
   P = polyshape([wrapTo360(Sdrbc.Lon(:)),Sdrbc.Lat(:)]);
   [PY,PX] = utm2ll(PX,PY,18,'nad83');
   PX = wrapTo360(PX);
   % PX = cellmap(@wrapTo360,PX); % only needed after going back to polycells
else
   [x,y] = ll2utm(Sdrbc.Lat(:),Sdrbc.Lon(:),18,'wgs84');
   P = polyshape(x,y);
end
[PX,PY] = polycells(PX,PY);

warning('on','MATLAB:polyshape:repairedBySimplify');

% This was in the script but wasn't used, but could add an option here to
% convert to polyshape
% Pbasins = cellfun(@polyshape,PX,PY);





