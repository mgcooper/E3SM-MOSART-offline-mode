function plotMeshWithPolys(XC,YC,XV,YV,P,varargin)

% P can be a polyshape scalar or array, or a cell array e.g. P = [PX,PY];

if nargin == 6
   plottype = varargin{1};
else
   plottype = "patchplot";
end
   

% Make a simple plot (fast)
if plottype == "fastplot"
   % scatter plot the cell centroids
   scatter(XC,YC);
else
   % Plot the mesh. This is time consuming
   plotMeshVertices(XV,YV);
end
hold on; axis off

% Plot the poly's
plotpolygon(P);


% For reference, might be useful when using lat/lon, plat,plon are the drbc
% basins, I think
% figure; 
% geomap(plat,plon); 
% plotm(plat,plon)
% plotm([Sdrbc.Lat],[Sdrbc.Lon],'r');
% figure; plot(P); hold on; cellfun(@plot,PX,PY)