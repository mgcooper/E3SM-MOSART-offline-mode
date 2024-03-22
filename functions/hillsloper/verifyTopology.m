function info = verifyTopology(slopes, links, basins, field, showinfo)
   %VERIFYTOPOLOGY Verify hillsloper topology is valid
   %
   % INFO = VERIFYTOPOLOGY(SLOPES, LINKS, NODES, BASINS, FIELD, TRUE) finds
   % links with zero, nan, missing, or more than one element in FIELD, which
   % indicates bad topology, and returns information about the elements of
   % slopes, links, basins, and nodes needed to fix the bad topology.
   %
   % If FIELD = 'hs_ID', then information is returned for slopes, links, nodes,
   % and basins, because they each have that field.
   %
   % If FIELD = 'link_ID', then information is returned for slopes and links,
   % because they each have that field but basins and nodes does not.
   %
   % This function looks for links with zero, nan, missing, or more than one
   % element in the hs_ID field, which indicates bad topology.
   %
   % Common fields:
   % hs_ID           slopes, links, basins, nodes
   % link_ID         slopes, links
   %
   % See also: removelink

   % TODO: add nodes, verify that this checks for links with bad hs_ID but also
   % slopes with bad link_ID

   if nargin < 4
      field = 'hs_ID';
   end
   if nargin < 5
      showinfo = false;
   end

   switch field
      case 'hs_ID'

         % links, slopes, and basins have hs_ID
         info.links = collectInfo(links, field, showinfo);
         info.slopes = collectInfo(slopes, field, showinfo);
         info.basins = collectInfo(basins, field, showinfo);

      case 'link_ID'

         % links and slopes have link_ID
         info.links = collectInfo(links, field, showinfo);
         info.slopes = collectInfo(slopes, field, showinfo);

      otherwise

   end

   %% Get the link ID for the link with a nan hillslope.
   %
   % Note that the information added below provides the info needed to fix
   % hillsloper v2 sag river basin, but I am not sure it would work in general.
   % In this case, there is one extra link, one extra node, and one extra basin,
   % but there are no extra slopes (the extra basin is only in the combined
   % 'basins' struct, the 'slopes' struct does not have the error).
   if sum(isnan([links.hs_ID])) > 0
      info.rm_link_ID = links(isnan([links.hs_ID])).link_ID;
      info.rm_node_ID = links([links.link_ID] == info.rm_link_ID).us_node_ID;

      % check if any slopes have the bad link id
      try
         % If the bad link is not associated with an hs_ID field in slopes, this
         % will be empty
         info.rm_slope_ID = slopes([slopes.link_ID] == info.rm_link_ID).hs_ID;
      catch
         % And in that case, the bad link should have nan in its hs_ID field
         info.rm_slope_ID = links(isnan([links.hs_ID])).hs_ID;
      end
   else
      info.rm_link_ID = [];
      info.rm_node_ID = [];
      info.rm_slope_ID = [];
   end
end

% Jan 2024 - this was here but wasn't a function, I must have beeen in a rush
% and moved this stuff out of some other script here b/c it's clearly not
% finished and it fails on the first call to verifyTOpology from
% b_make_newslopes which is necessary to get the rm_link_ID. Maybe this stuff
% works after the call to removelink etc.

function [basins, slopes] = assignID(basins, slopes)

   %% Assign hs_ID and link_ID to slopes

   % The hs_ID matches in basins and links but not slopes, and the link_ID in
   % slopes is meaningless. However, the slopes are ordered the same order as
   % basins, so use the basins-links association to assign hs_ID and link_ID to
   % slopes. Since link_ID does not exist in basins and is meaningless in
   % slopes, use link_ID for the hs_ID that matches in basins and links

   M = numel(slopes) / 2;
   slopesp = slopes([slopes.hs_ID] > 0);
   slopesn = slopes([slopes.hs_ID] < 0);

   [~, I] = sort([slopesn.hs_ID], 'descend');
   slopesn = slopesn(I);

   % If desired, confirm the order of slopes and basins
   ok = matchslopes(slopesp, slopesn, basins);

   % Assign hs_ID and link_ID to slopes
   matches = false(numel(links), 1);

   [basins(1:numel(basins)).link_ID] = deal(NaN);
   [basins(1:numel(basins)).ds_link_ID] = deal(NaN);
   [slopes(1:numel(slopes)).ds_link_ID] = deal(NaN);

   for m = 1:numel(basins)

      hs_ID = basins(m).hs_ID; % this also equals m
      ilink = [links.hs_ID] == hs_ID;

      link_ID = links(ilink).link_ID;
      ds_link_ID = links(ilink).ds_link_ID;

      % slopes.hs_ID is equivalent to the index, or fid (or hs_ID) of basins, so
      % the iterator "m" could be used instead of hs_ID.
      islope_p = [slopes.hs_ID] == hs_ID;
      islope_n = [slopes.hs_ID] == -hs_ID;

      % do i need to assign slopes.hs_ID? Or is it correct, its just confusing
      % b/c of the - / + thing?

      slopes(islope_n).link_ID = link_ID;
      slopes(islope_p).link_ID = link_ID;
      slopes(islope_n).ds_link_ID = ds_link_ID;
      slopes(islope_p).ds_link_ID = ds_link_ID;

      basins(m).link_ID = link_ID;
      basins(m).link_ID = link_ID;
      basins(m).ds_link_ID = ds_link_ID;
      basins(m).ds_link_ID = ds_link_ID;
   end

   % If that worked, how can I verify?


   % This would do the same as above, but iterate over links instead
   for m = 1:numel(links)

      hs_ID = links(m).hs_ID;
      link_ID = links(m).link_ID;
      ds_link_ID = links(m).ds_link_ID;

      ibasin = [basins.hs_ID] == hs_ID;

      if basins(ibasin).hs_ID == hs_ID
         matches(m) = true;

         % this shows that slopes.link_ID does not match
         % check = getslope(slopesp, hs_ID);
         % [link_ID, check.link_ID] % 14

         islope = abs([slopes.hs_ID]) == hs_ID;
         [slopes(islope).link_ID] = deal(link_ID);
         [slopes(islope).ds_link_ID] = deal(ds_link_ID);

         basins(ibasin).link_ID = link_ID;
      end
   end
   sum(matches)



   % Once finished,should be able to pick any hs_ID, find the slope, link, and
   % basin and they should have identical link_ID and ds_link_ID

   hs_ID = 183;

   slope = getslope(slopes, hs_ID);
   link_ID = slope.link_ID;
   link = getlink(links, link_ID);
   basin = getslope(basins, hs_ID);

   isequal(link.hs_ID, slope.hs_ID)
   isequal(link.hs_ID, basin.hs_ID)

   isequal(link.link_ID, slope.link_ID)
   isequal(link.link_ID, basin.link_ID)

   isequal(link.ds_link_ID, slope.ds_link_ID)
   isequal(link.ds_link_ID, basin.ds_link_ID)



   % Below here needs to be removed but is useful for fixing findnearby and for
   % calrifying how findpoly and inpoly2 work


   % Get the median x,y coordinate of each negative half slope. It is sufficient
   % to find the basin that contains the median of one half.
   xslopes = nan(M, 1);
   yslopes = nan(M, 1);
   for m = 1:M
      xslopes(m) = nanmean(slopesp(m).X);
      yslopes(m) = nanmean(slopesp(m).Y);
   end

   % should be faster to find which polygon the points are inside of
   found_ID = nan(M, 1);
   for m = 1:M

      xb = basins(m).X';
      yb = basins(m).Y';

      [in, xs, ys] = inmapbox(xslopes(:), yslopes(:), xb, yb);

      [IN, ON] = inpolygon(xslopes(:), yslopes(:), xb, yb);

      debug = false;
      if debug
         figure;
         plot(xb, yb); hold on;
         scatter(xs, ys, 'filled')
         scatter(xslopes(IN), yslopes(IN), 'filled');
      end

      if sum(IN) == 1 && sum(ON) == 0
         found_ID(m) = find(IN);
      else
         % [IN, ON] = inpoly2([xslopes(:) yslopes(:)], [basins(m).X', basins(m).Y']);
         % [m find(IN)]
         % [m find(ON)]
      end

      % find the nearest slope
      x = nanmedian(basins(ibasin).X);
      y = nanmedian(basins(ibasin).Y);

      [row, col] = findnearby(xslopes, yslopes, x, y, 1);

      plot([slopes(row).X], [slopes(row).Y]);


   end
   isequal(found_ID, 1:M')



   xbasins = {basins.X};
   ybasins = {basins.Y};


   % use findpoly to do it all at once
   [ip,ix,tr] = findpoly(pp,ee,pj,varargin)

   % xslope_p = nan(numel(links), 1);
   % for m = numel(slopes):-1:numel(slopes)/2+1
   %    xslope_p(m) = nanmedian(slopes(m).X);
   %    yslope_p(m) = nanmedian(slopes(m).Y);
   % end



   % Confirm if hs_ID matches in basins and links (it does)
   dists = nan(numel(links), 1);
   matches = false(numel(links), 1);

   % the slopes hs_ID does not match basins and links, but

   for m = 1:numel(links)

      link_ID = links(m).link_ID;
      hs_ID = links(m).hs_ID;
      ibasin = [basins.hs_ID] == hs_ID;

      if basins(ibasin).hs_ID == hs_ID
         matches(m) = true;

         % see what slopes says
         % check = getslope(slopesp, hs_ID); % link_ID is 2x the one expected
         % [link_ID, check.link_ID] % 14

         figure;
         plo

         % find the nearest slope
         x = nanmedian(basins(ibasin).X);
         y = nanmedian(basins(ibasin).Y);

         [row, col] = findnearby(xslopes, yslopes, x, y, 1);

         figure;
         plot([basins(ibasin).X], [basins(ibasin).Y]); hold on
         plot([slopes(row).X], [slopes(row).Y]);

         plot(slopesp(ibasin).X, slopesp(ibasin).Y)

         for m = 1:numel(slopes) / 2
            xslope_p = nanmedian(slopes(m).X);
            yslope_p = nanmedian(slopes(m).Y);
            dists(m) = abs(x - xslope_p)
         end

      end
   end
   sum(matches)





   % Confirm if link_ID matches in slopes and links
   matches = false(numel(links), 1);
   for m = 1:numel(links)
      link_ID = links(m).link_ID;

      for m = max(1, m-2):min(m+2, numel(links))
         hs_ID = links(m).hs_ID;
         ibasin = find([slopes.hs_ID] == hs_ID);
         if slopes(ibasin).link_ID == link_ID ...
               || slopes(ibasin).link_ID-1 == link_ID ...
               || slopes(ibasin).link_ID+1 == link_ID

            matches(m) = true;
         else
            % to see the link ID for the slope
            %             slopes(idx).link_ID
            %
            %             idx = find([slopes.hs_ID] == hs_ID-1);
            %             slopes(idx).link_ID
         end
      end
   end
   sum(matches)

   % for a given link_ID, e.g. n = 8, link_ID = 7, get the hs_ID for n = 7, 8,
   % and 9, and for each of those, get the link_ID to see if 0 vs 1 indexing is
   % confounding the association



   % This shows how the bad slope ID doesn't exist because it is not present in
   % the 'slopes' struct, which the hs_ID field is mapped to. It is only in
   % links and basins.
   % rm_slope_ID = links([links.link_ID] == rm_link).hs_ID;

   % This is an alternative way to get the bad node programmatically, but this
   % returns both the upstream and downstream node of the bad link. The one to
   % remove is the downstream node, which it be possible to determine based on
   % the order of nodes.conn i.e. whether the bad link ID is first or laast, but
   % i am not sure
   % rm_node_idx = find(arrayfun(@(node) ismember(info.rm_link_ID, node.conn), nodes));
   % rm_node_ID = [nodes(rm_node_idx).node_ID];

   % Note that none of these are the bad hillslope, because the nodes are not
   % associated with 'slopes', and the bad hillslope doesn't exist in 'slopes'
   % it exists in 'basins'.
   % nodes(rm_node_idx).hs_ID;

   % NOTE: see getOutletFeatures. Depending on when this is called, that
   % function has some checks to verify the outlet is correct.

end

function info = collectInfo(data, field, showinfo)
   % Collects and summarizes the field from the given data structure

   % Count the number of field entries for each entry in data
   count = cellfun(@numel, {data.(field)});

   % Create summary information
   info.(field) = [data.(field)];
   info.([field '_count']) = count;
   info.([field '_num_unique']) = numel(unique([data.(field)])); % Note: includes nan
   info.([field '_num_nan']) = sum(isnan([data.(field)]));
   info.([field '_num_missing']) = sum(count==0);
   info.([field '_num_with_one_elem']) = sum(count==1);
   info.([field '_num_with_extra_elems']) = sum(count>1);

   info.elems_with_nan = data(isnan([data.(field)]));

   if showinfo
      if strcmp(inputname(1), 'links')
         fprintf('Counts for %s:  Zero %s: %d, One %s: %d, >1 %ss: %d, NaN %s: %d\n', ...
            inputname(1), field, sum(count==0), field, sum(count==1), field, ...
            sum(count>1), field, sum(isnan([data.(field)])));
      else
         fprintf('Counts for %s: Zero %s: %d, One %s: %d, >1 %ss: %d, NaN %s: %d\n', ...
            inputname(1), field, sum(count==0), field, sum(count==1), field, ...
            sum(count>1), field, sum(isnan([data.(field)])));
      end
   end
end

%%
function ok = matchslopes(slopesp, slopesn, basins)

   % This confirms that slopes are ordered the same as basins, even though the
   % hs_id fields do not match

   % Jan 2024 - Not sure why I thought hs_id fields do not match, as far as I
   % can tell they match in links, slopes, and basins. It's possible I used the
   % linear index instead of hs_id.

   % Jan 2024 - Received an error b/c numel(basins) = 3250 but slopesp and
   % slopesn have 3249 elements - might depend on when this function is called
   % in the debugging / fixing process. I added the min(numel(basins), ...) fix.

   ok = true;
   plotbasins = false;
   for n = 1:min(numel(basins), numel(slopesp))

      xslopes = rmnan(horzcat(slopesp(n).X, slopesn(n).X));
      yslopes = rmnan(horzcat(slopesp(n).Y, slopesn(n).Y));

      xbasin = rmnan(basins(n).X);
      ybasin = rmnan(basins(n).Y);

      % If more than 1% of the basin verts are not in the combined slope verts
      if sum(~ismember(xbasin, xslopes)) / numel(xbasin) > 1
         ok = false;
         fprintf('bad geometry found at %s', n)
         break
      end

      % To visually check
      if plotbasins
         if n == 1 %#ok<*UNRCH>
            figure
         end
         plot(xbasin, ybasins); hold on
         plot(slopesp(n).X, slopesp(n).Y, '--')
         plot(slopesn(n).X, slopesn(n).Y, '--')
         pause
         clf
      end
   end
end
