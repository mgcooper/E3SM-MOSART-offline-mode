function newslopes = remove_slopes(slopes,rm_slope,rp_slope,rp_flag)
    %REMOVE_SLOPES merge one hillslope with another
    
    % slopes    = structure (shapefile) containing hillslopes
    % rm_slope  = id of the slope to be removed
    % rp_slope  = id of the slope that replaces (merges with) rm_slope
    % rp_flag   = 1 for rp_slope plus, 0 for rp_slope minus
    
    % indices of the hillslopes
    idxrm_p     = find([slopes.hs_id] == rm_slope);     % 'plus' = larger
    idxrm_m     = find([slopes.hs_id] == -rm_slope);    % 'minus' = smaller
    if rp_flag == 1
        idrp    = rp_slope; % keep track for easier indexing at the end
        idxrp   = find([slopes.hs_id] == rp_slope);
    else
        idrp    = -rp_slope;
        idxrp   = find([slopes.hs_id] == -rp_slope);
    end
    
    % pull out the hillslopes
    hsrm_p      = slopes(idxrm_p);  % hillslope remove plus
    hsrm_m      = slopes(idxrm_m);  % hillslope remove minus
    hsrp        = slopes(idxrp);    % hillslope replace (here, plus)

    % create a polyshape to extract the new boundaries
    xnew        = [hsrp.X hsrm_m.X hsrm_p.X];   
    ynew        = [hsrp.Y hsrm_m.Y hsrm_p.Y];
    hspoly      = polyshape(xnew,ynew);     % merged polyshape
    [xnew,ynew] = boundary(hspoly);         % just the boundary
    hspoly      = polyshape(xnew,ynew);     % make a new polyshape
    [xlim,ylim] = boundingbox(hspoly);      % new boundingbox
    % if the weird stuff near the outlet is problematic, try reverting to using
    % xnew,ynew as the x/y coordinates of the merged hillslope

    % new hillslope, with combined x/y/etc.
    nhs             = hsrp;   % inherit fields
    nhs.BoundingBox = [xlim' ylim'];
    nhs.X           = xnew;
    nhs.Y           = ynew;
    nhs.ncells      = hsrp.ncells+hsrm_m.ncells+hsrm_p.ncells;
    nhs.da          = hsrp.da+hsrm_m.da+hsrm_p.da;
    nhs.harea       = hsrp.harea+hsrm_m.harea+hsrm_p.harea;
    
    % area-weighted elevation and slope
    helev1          = hsrp.helev*hsrp.harea/nhs.harea;
    helev2          = hsrm_m.helev*hsrm_m.harea/nhs.harea;
    helev3          = hsrm_p.helev*hsrm_p.harea/nhs.harea;
    nhs.helev       = roundn(helev1+helev2+helev3,0);
    
    hslp1           = hsrp.hslp*hsrp.harea/nhs.harea;
    hslp2           = hsrm_m.hslp*hsrm_m.harea/nhs.harea;
    hslp3           = hsrm_p.hslp*hsrm_p.harea/nhs.harea;
    nhs.hslp        = roundn(hslp1+hslp2+hslp3,-4);
    
    % remove and replace (update idx after each removal)
    newslopes       = slopes;
    idx             = find([newslopes.hs_id] == rm_slope);
    newslopes(idx)  = [];
    idx             = find([newslopes.hs_id] == -rm_slope);
    newslopes(idx)  = [];
    idx             = find([newslopes.hs_id] == idrp);
    newslopes(idx)  = nhs;
end

