clean

% This works for the latest full Sag config, but is not fully cleaned up.
% There is still some random stuff at the end, but it's sufficient for now.

% See checks at end that confirm "Data" (the ats data) and "basins" are ordered
% the same, and the hs_ID field of "basins", "links", and "slopes" match once
% the topology is fixed.

%% Set options
opts = const( ...
   'save_data', false, ...
   'plot_map', true, ...
   'plot_slopes', false ...
   );

debug = false; % to control the random stuff at the end

%% Set paths

sitename = getenv('USER_MOSART_DOMAIN_NAME');
pathdata = getenv('USER_MOSART_DOMAIN_DATA_PATH');
pathsave = getenv('USER_MOSART_DOMAIN_DATA_PATH');

%% Read in the data

% Read in the hillsloper data
[basins, slopes, links, nodes, boundary] = readHillsloperData(sitename, ...
   ["basins", "slopes", "links", "nodes", "boundary"]);

% Read in the ATS data
filepath = '/Users/coop558/work/data/interface/ATS/sag_basin';
filename = fullfile(filepath, 'sag_hillslope_discharge.mat');
load(filename, "Data")

%% Plot the hillslopes

% Probably very slow with full Sag basin
if opts.plot_slopes
   mapslopes(basins, links, nodes, boundary, 'worldmap')

   % plothillsloper(slopes, links); % inletID, outletID mapslopes is faster
end

% Compute topo. This is only here b/c it's the only item from a_save_hillsloper
% that was not here. This is not needed with latest full Sag config, it is
% needed for prior versions that did not have elevation and/or slope.
% slopes = computeHillslopeTopo(slopes, ftopo);

% Check for bad hillslope topology
info = verifyTopology(slopes, links, basins, 'hs_ID', true);

%% Fix topology if necessary

rm_link_ID = info.rm_link_ID;
rm_node_ID = info.rm_node_ID;

% Links 185 and 1390 flow to 2663 instead of 1391
rm_link = 1391;         % remove link, orphan to be deleted
us_link = [185, 1390];  % upstream link(s) (flow into orphan's us node)
ds_link = 2665;         % downstream link(s) (flow into orphan's ds node)
rp_link = 2663;         % replacement link, downstream of orphan
rm_flag = true;         % if true, remove the slope that drains to rm_link

[links, nodes] = removelink( ...
   links,   ...
   nodes,      ...
   rm_link,    ...
   us_link,    ...
   ds_link,    ...
   rp_link,    ...
   rm_flag  );

%% Make a new links table with upstream/downstream link connectivity
[links, inletID, outletID] = findDownstreamLinks(links, nodes);

% Do an upstream walk from the link below the bad link
% plotlinks(links, 2661, [rp_link us_link]);

% Check again
newinfo = verifyTopology(slopes, links, basins, 'hs_ID', true);

% Remove the bad hillslope 427 from basins. Note - this cannot be automated.
basins(427) = [];

% Identify the outlet link
outlet = getOutletFeatures(slopes, links, nodes, ...
   'plot', false, 'basin', boundary);

% This shows that the bad node is no longer in the links
links(ismember([links.us_node_ID], rm_node_ID)).link_ID
links(ismember([links.ds_node_ID], rm_node_ID)).link_ID

%% make newslopes

% Add an hs_ID field to the ATS "Data" table
Data = settableprops(Data, "hs_ID", "table", {[basins.hs_ID]});

% TODO: figure out if this is needed and if makenewslopes is needed at all
% and/or can be merged into makenewslopes.

% % before this can be run, it is necessary to identify and fix links without
% % hillslopes and links with multiple hillslopes
% slopes = makenewslopes(slopes, links, nodes, false);
%
% % test rebuilding links to see if the numbering is correct
% [links, inletID, outletID] = findDownstreamLinks(links, nodes);

%%

test = hillsloper.fixda(basins, links, nodes);

%% Build a table with the MOSART input file information

mosartslopes = mosart.hillsloperToMosart(links, slopes, basins, Data);

% h = mos_plotslopes(mosartslopes,slopes,nodes);

%% save the data (don't overwrite the original! use 'mosart_hillslopes')

if opts.save_data == true
   if ~isfolder(pathsave)
      mkdir(pathsave)
   end
   save(fullfile(pathsave, 'mosart_hillslopes'), ...
      'mosartslopes', 'links', 'slopes', 'nodes');
end

%% Checks

if debug == true

   %% Check the min,max width and depth

   % Depth: 0.75 - 16.3 m
   [min([mosartslopes.rdep]) max([mosartslopes.rdep])]

   % Width: 1.6 - 5498 m
   [min([mosartslopes.rwid]) max([mosartslopes.rwid])]

   % Note: although 5500 m is quite large (18000 ft), the engineering report that
   % developed the relations report up to 8000 ft bankful width for the Colville
   % river gage, and the gage likely is not the widest point.

   % Slopes seem a bit high but need to investigate further
   % figure; histogram([mosartslopes.rslp])



   % Load the data:
   % pathsave = getenv('USER_MOSART_DOMAIN_DATA_PATH');
   % load(fullfile(pathsave, 'mosart_hillslopes'),'mosartslopes','links','slopes');
   % [basins, nodes, boundary] = readHillsloperData(sitename, 'basins', 'nodes', 'boundary');


   %% Confirm us_da is correct

   figure
   scatter([links.link_X], [links.link_Y], 40, [links.us_da_km2] * 1e6, 'filled')
   colorbar

   % This shows basins.da is probably the hillslope drainage area
   % figure
   % scatter(link_x, link_y, 40, [basins.da], 'filled')
   % colorbar

   % This suggests slopes.hs_ID, links.hs_ID, and basins.hs_ID are

   %% Confirm basin area is correct

   % The important thing is confirming that "Data" (the ATS data) is ordered the
   % same as the "basins" - after removing 427. Note that "Data" does not
   % contain hs427, thus the linear indexing (columns) go from hs426 in column
   % 426 to hs428 in column 427, just like basins(426).hs_ID and
   % basins(427).hs_ID, so that tells us already the two datasets are ordered
   % the same. The checks below are to be doubly sure and to confirm the area's
   % match.

   % Jan 2024 - compare with Bo's data. Sort links drainage area by hs_ID.
   basins_da = [basins.area_km2] * 1e6;
   ats_da = Data.Properties.CustomProperties.Area;

   figure
   scatter(ats_da, basins_da)
   addOnetoOne

   diffs = ats_da - basins_da;

   [~, md] = findglobalmax(abs(ats_da - basins_da) ./ basins_da);

   % Histogram percent differences - Basins da is always larger than ats.
   figure; histogram(100 * (ats_da - basins_da) ./ basins_da)
   figure; histogram(100 * (basins_da - ats_da) ./ basins_da) % Reverse the order

   % The differences might be due to the water fraction
   figure
   histogram(100 * Data.Properties.CustomProperties.WaterFrac)
   xlim([0 10])

   diffs = Data.Properties.CustomProperties.Area + - basins_da;
   [~, md] = findglobalmax(abs(diffs) ./ basins_da);

   %% conpare

   % Identify the outlet link
   outlet = getOutletFeatures(mosartslopes, links, nodes, ...
      'plot', false, 'basin', boundary);

   % The us_da field for the outlet should equal the total upstream area
   %
   % This shows the problem, the upstream drainage area of the outlet link is an
   % order of magnitude larger than the sum of all ats areas ...
   max([links.us_da_km2])*1000*1000
   outlet.basinarea
   sum(ats_da)


   %% plot the nodes and label them
   %
   % % % only needed for plotting
   % % pathtopo = '/Users/coop558/mydata/e3sm/topo/topo_toolbox/flow_network/basin/';
   % % load([pathtopo 'sag_dems'],'R5','Z5');    % 160 m dem, for plotting
   % % R = R5; Z = Z5; clear R5 Z5
   %
   % % this section replaced by mapslopes()
   %
   % %% The next two plots are for checking the algorithm
   %
   % % replace with call to plotnetwork()
   %
   % %% below here is mostly testing to sort out the links
   %
   % % link id = 319, get the ds link ID (headwater example)
   % idx     = find([links.link_ID] == 319);
   % dsID    = links(idx).ds_link_ID;
   % idx     = find([links.link_ID] == dsID);
   % usHS    = links(idx).us_hs_ID;
   %
   % links(idx)
   %
   % % for headwater links, this will return four values, need to remove the
   %
   % % link id = 318, get the ds link ID (non-headwater example)
   % idx     = find([links.link_ID] == 318);
   % dsID    = links(idx).ds_link_ID;
   % idx     = find([links.link_ID] == dsID);
   % usHS    = links(idx).us_hs_ID;
   %
   % i       = find(ismember([slopes.hs_id],2762))
   % slopes(i)
   %
   % % link 0 drains to link 2605. I have this in my link_ID and ds_link_ID fields.
   % %
   % % these notes were up above in the newlinks loop
   % % notes - us_conn_id will have three values at a confluence, the link
   % % itself, and the two upstream links. Therefore, this link is the
   % % downsteream link for the two values of us_conn_id that are not the
   % % link itself. The while loop goes and adds this link as the ds
   % %
   % % ds_hs_id tells us the hillslopes that contribute to the node that
   % % this link contributes to ... which, if we just want the hillslopes
   % % that contribute to each node, is sufficient ... but we also need to
   % % know the links associated with each hillslope, I think, to compute
   % % the reach-specific values of length, width, slope, etc.
   %
   %
   % %%
   %
   % inletID = info.inlet_ID;
   % outletID = info.outlet_ID;
   %
   % [([links.link_ID])' ([links.link_dnID])']
   % [([slopes.ID])' ([slopes.dnID])']
   %
   % % these were here when I was not using shaperead, before I realized the
   % % benefits of maintaining the geostruct format
   % newlinksT = struct2table(links);
   % newlinksT = movevars(newlinksT,'link_dnID','After','link_ID');
   %
   % % I think at this point the challenge is identifying the headwater reaches
   % % and assigning the correct hillslopes to each link
   %
   % % I think the ones with 4 values in us_hs_id are the ones downstream of
   % % headwater links UPDATE actually these are probably the confluences, but
   % % that might also be helpful
   %
   % % I want a vector of indices for the ones with 4 values and a vector of
   % % indices for the ones with
   % check1 = [];
   % for i = 1:length(links)
   %    if length(links(i).us_hs_ID) == 4
   %       check1  = [check1;i];
   %    end
   % end
   %
   % check2 = [];
   % for i = 1:length(inletID)
   %    % get the index for this inlet ID
   %    this_inlet_idx  = find([links.link_ID] == inletID(i));
   %    this_dnID       = links(this_inlet_idx).link_dnID;
   %    this_dn_idx     = find([links.link_ID] == this_dnID);
   %    check2          = [check2;this_dn_idx];
   % end
   %
   %
   % check1 = [];
   % for i = 1:length(inletID)
   %    % get the index for this inlet ID
   %    this_inlet_idx  = find([links.link_ID] == inletID(i));
   %    this_dnID       = links(this_inlet_idx).link_dnID;
   %    this_dn_idx     = find([links.link_ID] == this_dnID);
   %    inlet_dnID(i,1) = this_dnID;
   %    if length(links(this_dn_idx).us_hs_ID) == 4
   %       check1      = [check1;this_dn_idx];
   %    end
   % end
   %
   % for i = 1:length(links)
   %    if length([links(i).us_hs_ID]) == 4
   %       check2(i,1) = 1;
   %    else
   %       check2(i,1) = 0;
   %    end
   % end
   %
   % % % alternative syntax for better code interpretation
   % % this_link_id = links(n).id;
   % % this_link_us_node_id = links(n).us_node_id;
   % % this_link_ds_node_id = links(n).ds_node_id;
   % % this_link_us_node_idx = find(ismember([nodes.id],us_node_id));
   % % this_link_ds_node_idx = find(ismember([nodes.id],ds_node_id));
   % % this_link_us_slope_id = nodes(i_us).hs_id;
   % % this_link_ds_slope_id = nodes(i_ds).hs_id;
   % % this_link_us_link_conn = nodes(i_us).conn;
   % % this_link_ds_link_conn = nodes(i_ds).conn;

end
