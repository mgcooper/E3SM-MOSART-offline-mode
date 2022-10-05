function [dnidx,dnIDs] = findDownstreamCells(Mesh,points)
%FINDDOWNSTREAMCELLS finds all Mesh cells downstream of each point in points
% 
% Syntax:
% 
%  [dnidx,dnID] = findDownstreamCells(Mesh,points);
% 
% Author: Matt Cooper, 05-Oct-2022, https://github.com/mgcooper

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
   p                 = inputParser;
   p.FunctionName    = 'findDownstreamCells';
   
   addRequired(p,    'Mesh',                 @(x)isstruct(x));
   addRequired(p,    'points',               @(x)islogical(x) | isnumeric(x));
   
   parse(p,Mesh,points);
   
%------------------------------------------------------------------------------

% if points is logical, convert to linear idx
if islogical(points)
   points = find(points);
end
numpoints = numel(points);

% pull out the global ID and dnID and locate the outlet
ID       = [Mesh.global_ID];
dnID     = [Mesh.global_dnID];
ioutlet  = find(dnID==-1);

% init the outputs
dnIDs = cell(numpoints,1);
dnidx = cell(numpoints,1);

% loop over all points and find all downstream cells
for n = 1:numpoints
   idn      = points(n);
   dnID_n   = [];
   dnidx_n  = [];
   while idn ~= ioutlet
      idn      = find(ID==dnID(idn));
      dnID_n   = [dnID_n; dnID(idn)];  %#ok<AGROW>
      dnidx_n  = [dnidx_n; idn];       %#ok<AGROW>
   end
   dnIDs{n} = dnID_n;
   dnidx{n} = dnidx_n;
end




% 
% % what were trying to do here is figure out the flow direction from segment to
% % segment rather than cell to cell. its complicated because the segments in
% % flowline_conceptual ... I should be able to pick any point, find the nearest
% % MeshLine cell, then use ID->dnID to walk downstream and pick up all cells
% 
% % -----------------------------
% % get the global_ID of the flowline segments based on the iSegment attribute
% isegments = unique([Mesh.iSegment]);
% isegments = isegments(~ismember(isegments,-1)); % -1 is non-flowline cells
% for n = 1:numel(isegments)
%    segment_IDs{n} = [Mesh([Mesh.iSegment]==isegments(n)).global_ID];
% end
% 
% % -----------------------------
% % get the flowline segments based on the ID->dnID mapping
% ID = [MeshLine.global_ID];
% dnID = [MeshLine.global_dnID];
% % [dnID,isort]   = sort(dnID,'descend');
% 
% difID = ID(2:end)-dnID(1:end-1);
% istart = [1 find(difID ~= 0) numel(ID)+1];
% 
% for n = 1:numel(istart)-1
%    link_IDs{n} = ID(istart(n):istart(n+1)-1);
% end
% ilinks = unique(horzcat(link_IDs{:}));
% 
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




