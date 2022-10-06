function [Z,R] = findFlowlineFromMesh(Mesh,varargin)
%FINDFLOWLINEFROMMESH function to extract the mesh cells for each flowline
%segment 
% 
% Syntax:
% 
%  [Z,R] = FINDFLOWLINEFROMMESH(x);
%  [Z,R] = FINDFLOWLINEFROMMESH(x,'name1',value1);
% 
% Author: Matt Cooper, 05-Oct-2022, https://github.com/mgcooper

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
   p                 = inputParser;
   p.FunctionName    = 'findFlowlineFromMesh';
   
   addRequired(p,    'Mesh',                 @(x)isstruct(x)     );
%    addParameter(p,   'namevalue',   false,   @(x)islogical(x)     );
   
   parse(p,Mesh);
   
%------------------------------------------------------------------------------

% at one point, it worked to identify the outlet using -1 as i do below and
% then i had to switch to -9999 maybe because i was passing MeshLine vs Mesh to
% findDownstreamCells or hexmesh_dnID. Just noting that here. 

% this finds the flowline segments (global_IDs) from the iSegment attribute
isegments = unique([Mesh.iSegment]);
isegments = isegments(~ismember(isegments,-1)); % -1 is non-flowline cells
for n = 1:numel(isegments)
   segment_IDs{n} = [Mesh([Mesh.iSegment]==isegments(n)).global_ID];
end

% get the flowline segments based on the ID->dnID mapping
% this uses the mesh cells / ID->dnID rather than
% the flowline / dsearch as in findMeshCellsOnFlowline. it finds the flow
% segments without any flowline files/info
   
ID = [MeshLine.global_ID];
dnID = [MeshLine.global_dnID];
% [dnID,isort]   = sort(dnID,'descend');

difID = ID(2:end)-dnID(1:end-1);
istart = [1 find(difID ~= 0) numel(ID)+1];

for n = 1:numel(istart)-1
   linkIDs{n} = ID(istart(n):istart(n+1)-1);
end

ilinks = unique(horzcat(link_IDs{:}));


% not sure if anything below here is useful, it was stuff i wrote before i
% figured out how to trace from each dam to the outlet using the mesh-based
% global ID->dnID mapping without any flowline information. prior tot hat, i
% was trying to work with the flowline segments, and wanted to find a way to
% determine all cells downstream of each dam from the segments rather than the
% cell-by-cell ID->dnID, so I got sidelined trying to figure out if the
% segments I identified based on the flowline dsearchn method matched the ones
% from iSegment and/or if I could reconcile them, which is what most of the
% stuff below does. 

% % figure out if any of the linkIDs are equivalent to the segmentIDs
% numfound = nan(numel(link_IDs),numel(segment_IDs));
% nummissing = nan(numel(link_IDs),numel(segment_IDs));
% for n = 1:numel(link_IDs)
%    linkids = link_IDs{n};
%    for m = 1:numel(segment_IDs)
%       segids = segment_IDs{m};
%       numfound(n,m) = sum(ismember(segids,linkids));
%       nummissing(n,m) = sum(ismember(segids,linkids)) - numel(linkids);      
%       if isequal(linkids,segids)
%          disp([num2str(n) ', ' num2str(m) ]);
%       end
%    end
% end
% % choose the one with the most found to order them the same
% for n = 1:size(numfound,1)
%    ifound(n) = findmax(numfound(n,:),1,'first');
% end
% 
% % use ifound to subset the iSegment links that match the links in link_IDs
% for n = 1:numel(link_IDs)
%    new_IDs{n} = segment_IDs{ifound(n)};
% end
% 
% % for n = 1:numel(link_IDs)
% %    ifound_n = ismember([Mesh.global_ID],segment_IDs{ifound(n)})
% %    inewsegments{n} = Mesh(ifound_n).global_ID;
% % end
% 
% % -----------------------------
% % compare the iSegment flowlines to the ID->dnID flowlines
% figure('Position', [50 60 1200 1200]); hold on; 
% patch_hexmesh(Mesh); geoshow(Line)
% for n = 1:numel(link_IDs)
%    patch_hexmesh(Mesh(ismember([Mesh.global_ID],link_IDs{n})),'FaceColor','g');
%    pause;
%    patch_hexmesh(Mesh(ismember([Mesh.global_ID],segment_IDs{ifound(n)})),'FaceColor','m');
%    pause;
% end
% 
% 
% 
% for n = 1:numel(segment_IDs)
%    patch_hexmesh(Mesh(ismember([Mesh.iSegment],n)),'FaceColor','g');
%    pause;
% end
% 
% 
% % -----------------------------
% % compare the iSegment flowlines to the ID->dnID flowlines
% figure('Position', [50 60 1200 1200]); hold on; 
% patch_hexmesh(Mesh); geoshow(Line)
% % plot the iSegment flowlines
% for n = 1:numel(segment_IDs)
%    patch_hexmesh(Mesh([Mesh.iSegment]==isegments(n)),'FaceColor','b');
% end
% % plot the ID->dnID flowlines
% for n = 1:numel(link_IDs)
%    patch_hexmesh(Mesh(ismember([Mesh.global_ID],link_IDs{n})),'FaceColor','g');
%    pause;
% end
% 
% 
% % this shows the conceptual flowline in green and the flowlines based on
% % Mesh.iSegment in blue
% figure('Position', [50 60 1200 1200]); hold on; 
% patch_hexmesh(Mesh); geoshow(Line)
% patch_hexmesh(MeshLine,'FaceColor','g');
% for n = 1:numel(isegments)
%    patch_hexmesh(Mesh([Mesh.iSegment]==isegments(n)),'FaceColor','b');
%    scatter(Dams.Lon,Dams.Lat,'k','filled');
%    pause;
% end
% 
% 
% 
% figure('Position', [50 60 1200 1200]); hold on; 
% patch_hexmesh(Mesh); geoshow(Line)
% patch_hexmesh(MeshLine(1),'FaceColor','g');
% for n = 2:numel(dnID)
%    
%    dnidx = find(ID == dnID(n));
%    
% %    if 
%    
%    patch_hexmesh(MeshLine(dnidx),'FaceColor','g');
%    
%    if dnidx == n+1
%       pause(0.01);
%    else
%       dnidx
%       pause;
%    end
% end
% 
% MeshLineSort = sortrows










