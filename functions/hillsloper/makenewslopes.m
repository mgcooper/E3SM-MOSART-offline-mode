function slopes = makenewslopes(slopes, links, nodes, plotfig)
   %MAKENEWSLOPES add ID->dnID connectivity and hs_ID->link_ID mapping to slopes
   %
   %
   %
   % definitions
   % hs_ID         = id of the hillslope in which a link exists
   % us_hs_ID      = hillslopes upstream of the upstream node
   % ds_hs_ID      = hillslopes upstream of the downstream node
   %
   % Note: Originally, this function did both makenewlinks and makenewslopes,
   % then I separated out makenewlinks content and renamed that
   % findDownstreamLinks, and retained slope-related stuff in this function.
   % Thus the first step below is to call findDownstreamLinks if necessary.

   if nargin < 4
      plotfig = false;
   end

   % Process link connectivity if it hasnt been done yet
   if ~isfield(links,'ds_link_ID')
      links = findDownstreamLinks(links,nodes);
   end

   % Add link_ID and ds_link_ID to slopes
   [slopes(1:numel(slopes)).link_ID] = deal(NaN);
   [slopes(1:numel(slopes)).ds_link_ID] = deal(NaN);

   % add hs_ID->link_ID mapping (find which link associates with each slope)
   hs_IDs = [slopes.hs_ID];
   link_IDs = [links.link_ID];
   ds_link_IDs = [links.ds_link_ID];
   link_hs_IDs = [links.hs_ID];

   % for all hsIDs, find links with link_hsID equal to
   for m = 1:numel(hs_IDs)/2 % m = 3268
      midx = find(abs(hs_IDs) == abs(hs_IDs(m)));
      [slopes(midx).link_ID] = deal(link_IDs(abs(hs_IDs(m))==link_hs_IDs));
      [slopes(midx).ds_link_ID] = deal(ds_link_IDs(abs(hs_IDs(m))==link_hs_IDs));
   end

   % TESTING - this identified extra hillslopes for hillsloper v3 full sag
   isvec = find(cellfun(@numel,{slopes.link_ID})>1);
   for n = 1:numel(isvec)
      if numel([slopes(isvec(n)).link_ID]) == 1
         fprintf('link_ID (%d) is vector: %d\n',isvec(n),[slopes(isvec(n)).link_ID]);
      elseif numel([slopes(isvec(n)).link_ID]) == 2
         fprintf('link_ID (%d) is vector: %d, %d\n',isvec(n),[slopes(isvec(n)).link_ID]);
      else
         fprintf('link_ID (%d) has more than two links',isvec(n))
      end
   end

   % Step in to test_old_method to actually do the comparison.
   % [test_slopes, test_links] = test_old_method(slopes, links);


   % % NOTE dont labelfields with full sag_basin
   % %
   % % this shows that the slopes.link_id field doesn't match the link_ID
   %
   % labelfields = {'links','id','slopes','link_id'};
   % plothillsloper(slopes,links,nodes,'pauseflag',true,'labelfields',labelfields);
   %
   % % this shows that the method above works and now slopes.link_ID matches link_ID
   % labelfields = {'links','link_ID','slopes','link_ID'};
   % plothillsloper(slopes,links,nodes,'pauseflag',true,'labelfields',labelfields);

   % % try plotting select hillslopes
   % test_slopes = slopes(isvec);
   % test_links = links([slopes(isvec).link_ID]+1);
   % labelfields = {'links','link_ID','slopes','link_ID'};
   % plothillsloper(test_slopes,test_links,'pauseflag',true,'labelfields',labelfields);

   % NOTE: once links are removed using removelink, the link_ID numbering will
   % no longer be consecutive, since links are removed. For the latest
   % hillsloper output, link 1391 is removed, so the diff(link_ID) jumps at 1390
   % (link_ID goes from 1390-1392). Therefore I commented out everything bleow
   % b/c we dont need the numbering to be consecutive, we just need correct
   % ID->dnID

   % % % % % % % %
   % Final Checks
   % % % % % % % %

   % 1. Check if the hillslope numbering is consecutive
   %
   % This was the method here:
   % if any(diff(sort([slopes.link_ID])) > 1)
   %    assert(false, ...
   %       'Hillslope ID numbering is not consecutive. Check for nan values in links.hs_ID');
   % end
   %
   % This was in test_makenewslopes, it is in findDownstreamLinks, but maybe
   % useful for sorting out the debugging in test_old_method below.
   % if ~isempty(find(diff([links.link_ID]) > 1, 1))
   %   error('ds ID numbering astray, stop and figure out why');
   % end
   %
   % this was here but no note about why:
   % testdiffs = [0, diff(sort([slopes.link_ID]))];
   % links(find(isnan([links.hs_ID])))
   %
   % test_hs_link_IDs = sort([slopes.link_ID]);
   % bad_link_idx = find([0, diff(test_hs_link_IDs)] > 1);
   % bad_link_ID = test_hs_link_IDs(bad_link_idx);
   % bad_link_idx = find([links.link_ID]==bad_link_ID);
   % bad_hs_idx = find([slopes.link_ID]==bad_link_ID);
   % links(bad_link_idx)


   % % 2. Renumber the slopes.link_ID field to start at 1, rather than zero
   %
   % Jan 2024: This was the method here:
   % if any([slopes.link_ID]==0)
   %    for n = 1:numel(slopes)
   %       slopes(n).link_ID = slopes(n).link_ID+1;
   %       slopes(n).ds_link_ID = slopes(n).ds_link_ID+1;
   %    end
   % end
   %
   % This was the method in test_makenewslopes. The links part is in
   % findDownstreamLinks, but was commented out with a note that it "complicates
   % comparison with the og shapefiles e.g. in qgis trying to sort out orphan
   % links/nodes". Thus I kept it here for now in case it is useful for sorting
   % out the debugging in test_old_method below.
   %
   % 2. ensure ID field starts at 1, rather than zero
   % if any([links.link_ID]==0)
   %    for n = 1:numel(links)
   %       links(n).link_ID = links(n).link_ID+1;
   %       links(n).ds_link_ID = links(n).ds_link_ID+1;
   %    end
   %    for n = 1:numel(slopes)
   %       slopes(n).link_ID = slopes(n).link_ID + 1;
   %       slopes(n).ds_link_ID = slopes(n).ds_link_ID + 1;
   %    end
   %    inletID = inletID + 1;
   %    outletID = outletID + 1;
   % end
   % % Assign info
   % info.inlet_ID = inletID;
   % info.outlet_ID = outletID;

   % plot the slopes if requested
   if plotfig == true
      plothillsloper(slopes,links,nodes);
   end
end

function [oldslopes, oldlinks] = test_old_method(newslopes, newlinks, nodes)

   % Jan 2024 - I never finished reconciling this function (makenewslopes) with
   % a "test_makenewslopes" version. The test_ version existed because the new
   % method above to add link_ID and ds_link_ID to slopes "yields different
   % results than the old method" copied below.
   %
   % To use this, call this from the main function up above (see commented out
   % call) and step in to this function then compare with the new method.

   % This is the original method, double check then delete.
   %
   % NOTE: in test_makenewslopes I first used the old method (below) to create
   % newslopes, then assigned oldslopes = newslopes; then used the new method in
   % the main function to update newslopes. Now that this is in here as a
   % subfunction, the order of operations is reversed: I first create the
   % newslopes/links in the main and then step in here. EITHER WAY, it occurred
   % to me that the assignment of oldslopes=newslopes and then running the
   % old/new method, regardless of which one, might be the cause of confusion or
   % difference, it might be necessary to start with the original slopes in both
   % cases then compare the result.

   oldslopes = newslopes;
   oldlinks = newlinks;

   for n = 1:numel(newlinks)
      thisLink_ID = newlinks(n).link_ID;
      thisLink_dsID = newlinks(n).ds_link_ID;
      thisLink_hsID = newlinks(n).hs_ID;
      for m = 1:numel(newslopes)
         thisSlope_hsID = newslopes(m).hs_ID;
         if any(ismember(thisLink_hsID, thisSlope_hsID))
            oldslopes(m).link_ID = thisLink_ID;
            oldslopes(m).ds_link_ID = thisLink_dsID;
         end
      end
   end

   % Jan 2024 - this was the original note in test_makenewslopes ... I first did
   % the method above, then assigned oldslopes = slopes, then did the new method
   % in the main function, then the following note:
   %
   % PICK UP HERE the two methods yield different results, need to test using
   % trib basin to figure out if it must be done before or after merging slopes


   % this shows that the method above works
   labelfields = {'links', 'link_ID', 'slopes', 'link_ID'};
   plothillsloper(newslopes, newlinks, nodes, ...
      'pauseflag', true, 'labelfields', labelfields);


   setdiff([oldslopes.link_ID], [newslopes.link_ID])
   setdiff([newslopes.link_ID], [oldslopes.link_ID])

   % isequal([test.link_ID], [newslopes.link_ID])
   [mind, maxd] = bounds([oldslopes.link_ID] - [newslopes.link_ID]);

   % isvec_new is the indices of slopes that have non-scalar link_IDs: 998, 3241
   % the fprintf this shows that link
   isvec_new = find(cellfun(@numel, {newslopes.link_ID}) > 1);
   isvec_old = find(cellfun(@numel, {oldslopes.link_ID}) > 1);
   for n = 1:numel(isvec_new)
      % use vec_new for indexing
      fprintf('old: %d, %d\n', [oldslopes(isvec_new(n)).link_ID]);
      if numel([oldslopes(isvec_new(n)).link_ID]) == 1
         % Not sure if oldslopes should be newslopes, but this is how it was:
         fprintf('new: %d\n', [oldslopes(isvec_new(n)).link_ID])
      elseif numel([oldslopes(isvec_new(n)).link_ID]) == 2
         % Not sure if oldslopes should be newslopes, but this is how it was:
         fprintf('new: %d, %d\n', [oldslopes(isvec_new(n)).link_ID])
      end
   end

   % [newslopes(isvec_new).link_ID]
   % [newslopes(isvec_old).link_ID]

   % END TESTING
end
