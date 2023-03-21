function hs_new = mergeslopes(slopes,slope_id)
%MERGE_SLOPES merge the plus/minus hillslopes with each other

% slopes    = structure (shapefile) containing hillslopes
% slope_id  = id of the slope to be removed

% indices of the hillslopes
if numel(slope_id)==2 && slope_id(1)+slope_id(2)==0
   idx_p = ismember([slopes.hs_ID],slope_id);    % 'plus' = larger
   idx_m = ismember([slopes.hs_ID],-slope_id);   % 'minus' = smaller
elseif numel(slope_id)==2 && abs(slope_id(2)-slope_id(1))==1
   idx_p = ismember([slopes.hs_ID],slope_id(1));
   idx_m = ismember([slopes.hs_ID],slope_id(2));
elseif numel(slope_id)==1
   idx_p = ismember([slopes.hs_ID],slope_id);
   idx_m = ismember([slopes.hs_ID],-slope_id);
end

% pull out the hillslopes
hs_p = slopes(idx_p);  % hillslope remove plus
hs_m = slopes(idx_m);  % hillslope remove minus

% 15 March 2023, test turning this off, it might not work for sag_basin until
% the merging is finished
% for the case where numel(slope_id)==1, the negative one might not have
% link_ID and ds_link_ID
% if numel(slope_id)==1
%    if isempty(hs_m.link_ID)
%       hs_m.link_ID = hs_p.link_ID;
%    end
% 
%    if isempty(hs_m.ds_link_ID)
%       hs_m.ds_link_ID = hs_p.ds_link_ID;
%    end
% end

% create a polyshape to extract the new boundaries
xnew = [hs_m.X hs_p.X];
ynew = [hs_m.Y hs_p.Y];
hspoly = polyshape(xnew,ynew);         % merged polyshape
[xnew,ynew] = boundary(hspoly);        % just the boundary
hspoly = polyshape(xnew,ynew);         % make a new polyshape
[xlim,ylim] = boundingbox(hspoly);     % new boundingbox
% if the weird stuff near the outlet is problematic, try reverting to using
% xnew,ynew as the x/y coordinates of the merged hillslope

% this works b/c the elevatoin data was 5 m but it creates slivers where the
% hillslope narrows to one pixel width which become islands in the debuffer.
% test = polybuffer(hspoly,2.5,'JointType','square'); 
% test = polybuffer(test,-2.5,'JointType','square');
% figure; plot(test);
% test = rmslivers(hspoly,2);
% figure; plot(hspoly); hold on; plot(test); 

% new hillslope, with combined x/y/etc.
hs_new.Geometry = hs_m.Geometry;
hs_new.BoundingBox = [xlim' ylim'];
hs_new.X = xnew;
hs_new.Y = ynew;
hs_new.ncells = hs_m.ncells + hs_p.ncells;
hs_new.darea_m2 = hs_m.da + hs_p.da;
hs_new.harea_m2 = (hs_m.area_km2 + hs_p.area_km2)*1e6; % compare with: area(hspoly)

% 20 Mar 2023, commented this out, use the provided area instead
% hs_new.harea = hs_m.harea + hs_p.harea;

% % TODO: need elevation and slope
% % area-weighted elevation and slope
% helev1 = hs_m.helev * hs_m.harea_m2 / hs_new.harea_m2;
% helev2 = hs_p.helev * hs_p.harea_m2 / hs_new.harea_m2;
% hs_new.helev = round(helev1+helev2,0);
% 
% hslp1 = hs_m.hslp * hs_m.harea_m2 / hs_new.harea_m2;
% hslp2 = hs_p.hslp * hs_p.harea_m2 / hs_new.harea_m2;
% hs_new.hslp = round(hslp1+hslp2,4);
% 
