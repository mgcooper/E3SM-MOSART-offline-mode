function hs_new = mergeslopes(slopes, slope_id)
   %MERGESLOPES merge the plus/minus hillslopes with each other

   % slopes    = structure (shapefile) containing hillslopes
   % slope_id  = id of the slope to be removed

   % Get the indices of the plus/minus hillslopes
   if numel(slope_id) == 2 && slope_id(1) + slope_id(2) == 0
      idx_p = ismember([slopes.hs_ID], slope_id);     % 'plus' = larger
      idx_m = ismember([slopes.hs_ID], -slope_id);    % 'minus' = smaller

   elseif numel(slope_id) == 2 && abs(slope_id(2) - slope_id(1)) == 1
      idx_p = ismember([slopes.hs_ID], slope_id(1));
      idx_m = ismember([slopes.hs_ID], slope_id(2));

   elseif numel(slope_id) == 1
      idx_p = ismember([slopes.hs_ID], slope_id);
      idx_m = ismember([slopes.hs_ID], -slope_id);
   end

   % Pull out the hillslopes
   hs_p = slopes(idx_p);  % hillslope remove plus
   hs_m = slopes(idx_m);  % hillslope remove minus

   % 15 March 2023, turning this off, it might not work for sag_basin until
   % the merging is finished. Update Jan 2024 - the full sag_basin had a
   % link with no hillslope. This might be for the case of a hillslope with no
   % link, as in prior hillsloper configs. So, kept it for those cases.
   %
   % For the case where numel(slope_id)==1, the negative one might not have
   % link_ID and ds_link_ID:
   % if numel(slope_id)==1
   %    if isempty(hs_m.link_ID)
   %       hs_m.link_ID = hs_p.link_ID;
   %    end
   %
   %    if isempty(hs_m.ds_link_ID)
   %       hs_m.ds_link_ID = hs_p.ds_link_ID;
   %    end
   % end

   % Extract the X,Y coordinates
   xnew = [hs_m.X hs_p.X];
   ynew = [hs_m.Y hs_p.Y];

   % Removing the nan delimeter's appears to be a bad idea b/c the polyshape
   % connects the first and final node which creates a hole (triangle) in at
   % least some cases.
   % keep = ~isnan(xnew) & ~isnan(ynew);
   % xnew = xnew(keep);
   % ynew = ynew(keep);

   % Create a polyshape to extract the new boundaries
   hspoly = polyshape(xnew, ynew);         % merged polyshape
   [xnew, ynew] = boundary(hspoly);        % just the boundary
   hspoly = polyshape(xnew, ynew);         % make a new polyshape
   [xlim, ylim] = boundingbox(hspoly);     % new boundingbox
   % if the weird stuff near the outlet is problematic, try reverting to using
   % xnew,ynew as the x/y coordinates of the merged hillslope

   % Can extract here but converting the x,y created above likely better to
   % remove the slivers and the connection b/w the first and final vertex
   lonnew = [hs_m.Lon hs_p.Lon];
   latnew = [hs_m.Lat hs_p.Lat];
   % lonnew = rmnan([hs_m.Lon hs_p.Lon]);
   % latnew = rmnan([hs_m.Lat hs_p.Lat]);


   % This works b/c the elevation data was 5 m but it creates slivers where the
   % hillslope narrows to one pixel width which become islands in the debuffer.
   % test = polybuffer(hspoly,2.5,'JointType','square');
   % test = polybuffer(test,-2.5,'JointType','square');
   % figure; plot(test);
   % test = rmslivers(hspoly,2);
   % figure; plot(hspoly); hold on; plot(test);

   % Compute area-weighted slope and elevation
   hslp = (tand(hs_p.slope0x2Emean) * hs_p.area_km2 ...
      + tand(hs_m.slope0x2Emean) * hs_m.area_km2) ...
      / (hs_m.area_km2 + hs_p.area_km2);

   helev = (hs_p.dem0x2Emean * hs_p.area_km2 ...
      + hs_m.dem0x2Emean * hs_m.area_km2) ...
      / (hs_m.area_km2 + hs_p.area_km2);

   % New hillslope, with combined x/y/etc.
   hs_new.Geometry = hs_m.Geometry;
   hs_new.BoundingBox = [xlim' ylim'];
   hs_new.X = xnew;
   hs_new.Y = ynew;
   hs_new.Lat = latnew;
   hs_new.Lon = lonnew;
   hs_new.ncells = hs_m.ncells + hs_p.ncells;
   hs_new.darea_m2 = hs_m.da + hs_p.da;
   hs_new.harea_m2 = (hs_m.area_km2 + hs_p.area_km2) * 1e6; % compare with: area(hspoly)
   hs_new.helev_m = helev;
   hs_new.hslp = hslp;
end
