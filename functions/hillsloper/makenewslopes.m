function slopes = makenewslopes(slopes,links,nodes,plotfig)
%MAKENEWSLOPES add ID->dnID connectivity and hs_ID->link_ID mapping to slopes
% 
% 

% definitions
% hs_ID         = id of the hillslope in which a link exists
% us_hs_ID      = hillslopes upstream of the upstream node
% ds_hs_ID      = hillslopes upstream of the downstream node

% process link connectivity if it hasnt been done yet
if ~isfield(links,'ds_link_ID')
   links = findDownstreamLinks(links,nodes);
end

% add link_ID and ds_link_ID to slopes
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
% 
% % NOTE dont labelfileds with full sag_basin
% % this shows that the slopes.link_id field doesn't match the link_ID
% labelfields = {'links','id','slopes','link_id'};
% plothillsloper(slopes,links,nodes,'pauseflag',true,'labelfields',labelfields);
% 
% % this shows that the method above works and now slopes.link_ID matches link_ID
% labelfields = {'links','link_ID','slopes','link_ID'};
% plothillsloper(newslopes,newlinks,nodes,'pauseflag',true,'labelfields',labelfields);

% % try plotting select hillslopes
% test_slopes = slopes(isvec);
% test_links = links([slopes(isvec).link_ID]+1);
% labelfields = {'links','link_ID','slopes','link_ID'};
% plothillsloper(test_slopes,test_links,'pauseflag',true,'labelfields',labelfields);

% NOTE: once links are removed using removelink, the link_ID numbering will no
% longer be consecutive, since links are removed. For the latest hillsloper
% output, link 1391 is removed, so the diff(link_ID) jumps at 1390 (link_ID goes
% from 1390-1392). Therefore I commented out everything bleow b/c we dont need
% the numbering to be consecutive, we just need correct ID->dnID 

% % Check if the hillslope numbering is consecutive
% if any(diff(sort([slopes.link_ID])) > 1)
%    assert(false, 'Hillslope ID numbering is not consecutive. Check for nan values in links.hs_ID');
% end
% 
% % this 
% testdiffs = [0, diff(sort([slopes.link_ID]))];
% links(find(isnan([links.hs_ID])))
% 
% test_hs_link_IDs = sort([slopes.link_ID]);
% bad_link_idx = find([0, diff(test_hs_link_IDs)] > 1);
% bad_link_ID = test_hs_link_IDs(bad_link_idx);
% bad_link_idx = find([links.link_ID]==bad_link_ID);
% bad_hs_idx = find([slopes.link_ID]==bad_link_ID);
% links(bad_link_idx)


% % Renumber the slopes.link_ID field to start at 1, rather than zero
% if any([slopes.link_ID]==0)
%    for n = 1:numel(slopes)
%       slopes(n).link_ID = slopes(n).link_ID+1;
%       slopes(n).ds_link_ID = slopes(n).ds_link_ID+1;
%    end
% end

% plot the slopes if requested
if plotfig == true
   plothillsloper(slopes,links,nodes);
end
