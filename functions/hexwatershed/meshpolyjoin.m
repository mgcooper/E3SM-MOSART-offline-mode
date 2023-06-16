function [XV,YV,V,isclockwise] = meshpolyjoin(XV,YV)

% CellVertices = [{num2cell(XV)},{num2cell(YV)}];
XV = arrayfun(@(n) XV(n,~isnan(XV(n,:))),(1:length(XV))','uni',0);
YV = arrayfun(@(n) YV(n,~isnan(YV(n,:))),(1:length(YV))','uni',0);

if polyorder(XV{1},YV{1},"ccw") % if ccw, fliplr to cw
   V = cellfun(@fliplr, [XV, YV],'uni',0);
else
   V = [XV, YV];
end

% pull out the verts in case they were reordered
XV = V(:,1);
YV = V(:,2);

% Check that all cells are ordered clockwise
isclockwise = all(polyorder(V(:,1),V(:,2),"cw"));