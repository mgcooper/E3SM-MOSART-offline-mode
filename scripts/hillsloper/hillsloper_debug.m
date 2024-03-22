
% I moved the various debugging stuff out of the other scripts but I need to
% figure out what is essential and how to simplify it. Or, just keep it all in
% here and treat it like snippets 

%%

% This was right after calling findDownstreamLinks to build the newlinks, but
% before calling removelink. But i think I also used the manual link(bad_link) =
% [] thing to get them the same size then ran it again

% at this point links and newlinks are the same size, but newlinks has
% ds_link_ID field added by findDownstreamLinks, which uses the information in
% nodes to construct the topology, and is wrong b/c that info is wrong. I forgot
% that the new links from hillsloper has the us/ds connectivity already.

figure; 
plot([links.ds_link_ID], [newlinks.ds_link_ID], 'o')

tf = true(numel(links), 1);
for n = 1:numel(links)
   if ~isequal(links(n).ds_link_ID, newlinks(n).ds_link_ID)
      tf(n) = false;
   end
end
check = find(~tf);
idx = check(1);

links(idx).ds_link_ID
newlinks(idx).ds_link_ID
test = catstructs(links(idx), newlinks(idx))

setdiff([links.ds_link_ID], [newlinks.ds_link_ID])
setdiff([newlinks.ds_link_ID], [links.ds_link_ID])


%% how to remove the bad hillslope in 'basins'?

% How to find the bad index (427) in basins? Turns out we cannot. Maybe we could
% have before John reprocessed the data, but with the data I have it cannot be
% done programmatically because slopes and links don't have the bad slope (427),
% so the bad hs_ID cannot be retrieved from them, and 'basins' does not have the
% link_ID field, so the bad link_ID cannot be used to find the bad basin. 

% For N links, there should be N basins, 2*N slopes, and N+1 nodes

dropbasin = find([basins.ncells] < 5);
droplinks = find(isnan([links.hs_ID]));
dropnodes = find(arrayfun(@(node) any(isnan(node.hs_ID)) && numel(node.conn) > 1, nodes));

% Note: inlet nodes have nan for hs_ID, so isnan cannot be used to find bad
% nodes. This shows that:
sum([newlinks.isInlet])
sum(arrayfun(@(node) any(isnan(node.hs_ID)) && numel(node.conn) == 1, nodes))

% Inspect the bad basin / links
basins(dropbasin)
links(droplinks)

newlinks(isnan([newlinks.hs_ID]))

% The bad hs_ID is nan in links, so we cannot get the hs_ID from it
% From links, we can get the us/ds_node_ID and us/ds_link_ID of the bad link
% From nodes, we can get hs_ID, but the bad hs_ID is not in nodes because the
% node inside the bad hillslope is actually associated with the good upstream
% hillslope, see the diagram if confused. 
% From nodes we can also get the 'conn' which is the upstream and downstream
% links, meaning we can get the node associated wtih the bad link, but there
% still is no way to then get the bad basin id 427. 

droplinkID = links(droplinks).link_ID;

% from this we can get the 
dropnodes = find(arrayfun(@(node) ismember(droplinkID, node.conn), nodes));


slopes(isnan([links.hs_ID]))

% but it is nan
for n = 1:numel(nodes)
   hsid = nodes(n).hs_ID;
   if ismember(427, hsid) % isnan(hsid) 
      idx = n;
      break
   end
end
nodes(idx)
nodes(2334)

%% this section comes after fixing the topology and making new slopes

% the hillslopes should have only one link
numLinksPerSlope = cellfun(@numel,{newslopes.link_ID});
sum(numLinksPerSlope > 1)

% confirm that all link_IDs are present in newslopes.link_ID
setdiff(unique([newslopes.link_ID]), unique([links.link_ID]))
setdiff(unique([links.link_ID]), unique([newslopes.link_ID]))

% repeat with newlinks
setdiff(unique([newslopes.link_ID]), unique([newlinks.link_ID]))
setdiff(unique([newlinks.link_ID]), unique([newslopes.link_ID]))

% This is not needed b/c slopes link ID is 
% setdiff(unique([slopes.link_ID]), unique([links.link_ID]))
% setdiff(unique([links.link_ID]), unique([slopes.link_ID]))

ismember(427, [newlinks.hs_ID])
ismember(427, [links.hs_ID])
ismember(427, [slopes.hs_ID])
ismember(427, [newslopes.hs_ID])
ismember(427, [basins.hs_ID])

setdiff([links.hs_ID], [newlinks.hs_ID]) % NaN for 
setdiff([newlinks.hs_ID], [links.hs_ID])

setdiff([slopes.hs_ID], [newslopes.hs_ID])
setdiff([newslopes.hs_ID], [slopes.hs_ID])

setdiff([slopes.link_ID], [newslopes.link_ID])
setdiff([newslopes.link_ID], [slopes.link_ID])

% this shows 
minmax([slopes.link_ID])
minmax([newslopes.link_ID])
