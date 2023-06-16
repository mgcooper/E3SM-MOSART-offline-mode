function plotMeshVertices(XV,YV)

xv = prepVertsForPatchPlot(XV);
yv = prepVertsForPatchPlot(YV);

% patch the verts
arrayfun( @(n) patch('Faces',1:find(isnan(yv(:,n)),1,'first')-1, ...
   'Vertices',[xv(:,n),yv(:,n)],'FaceColor','none','LineWidth',0.5), ...
   1:size(yv,2));

% test this
% cellfun(@patch,XV,YV)

function verts = prepVertsForPatchPlot(verts)

if size(verts,1) > 8 && size(verts,2) <= 8 
   verts = transpose(verts);
end