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

%% Set paths

sitename = getenv('USER_MOSART_DOMAIN_NAME');
pathdata = getenv('USER_MOSART_DOMAIN_DATA_PATH');
pathsave = getenv('USER_MOSART_DOMAIN_DATA_PATH');

%% Read in the data

% Read in the hillsloper data
[basins, slopes, links, nodes, boundary, ftopo] = readHillsloperData(sitename);

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

% Make a new links table with upstream/downstream link connectivity
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

%% Build a table with the MOSART input file information

% For the huc 12 I used the NAD 83 (2011) alaska albers which is 6393
proj = projcrs(3338, 'Authority', 'EPSG'); % projcrs(6393,'Authority','EPSG');

for n = 1:numel(links)

   % Get the hillslope ID associated with this reach and the hillslope att's
   hs_ID = links(n).hs_ID;
   
   % Get the basin (the merged +/- hillslope)
   hs_info = getslope(basins, hs_ID);

   % Use mergeslopes to get the area-weighted slope and elevation. Also use 
   % this method for earlier versions where the "basins" table is unavailable:
   hs_merged = mergeslopes(slopes, hs_ID);

   % Get the positive and negative slope from "slopes". Not used now that
   % area-weighted slope and elevation are computed in mergeslopes.
   % [hs_p, hs_n] = getslope(slopes, hs_ID);
   
   % Pull out the area-weighted slope and elevation
   hslp = hs_merged.hslp;
   helev = hs_merged.helev_m;

   % Get area from the ATS "Data". Note that linear indexing into "Data" is
   % equivalent to linear indexing into "basins". And this won't work except 
   % for the "final" full-Sag config. 
   idx = Data.Properties.CustomProperties.hs_ID == hs_ID;
   harea = Data.Properties.CustomProperties.Area(idx);
   % harea = (hs_p.area_km2 + hs_n.area_km2) * 1e6; % confirm they match

   % Can use this to double check
   % hs_test = mergeslopes(slopes, hs_ID);
   % plotBasinLinks(basins, links, hs_ID); hold on
   % plot(rmnan([hs_test.Lon]), rmnan([hs_test.Lat]), ':')

   % pull out values needed for input file, convert km to m where needed
   id = links(n).link_ID;
   lati = nanmean([links(n).Lat]);
   long = nanmean([links(n).Lon]);
   dnid = links(n).ds_link_ID;
   rslp = round(links(n).slope, 4);
   rlen = round(links(n).len_km * 1e3, 0);
   hslp = round(hslp, 4);
   harea = round(harea, 0);
   helev = round(helev, 0);
   uarea = round(links(n).us_da_km2 * 1e6, 4);

   % Deal with the accumulation area threshold in headwater links. 
   if isequaltol(uarea, 625)
      % Set the upstream drainage area equal to the local hillslope area
      uarea = harea;
   else
      % Add the local hillslope area to the upstream drainage area
      uarea = uarea + harea;
   end

   % % These fields are added in computeHillslopeTopo, not used in _v2 full Sag.
   % hslp = round(double(slope_info.hslp), 4);
   % harea = round(double(slope_info.harea), 0);
   % helev = round(double(slope_info.helev), 0);

   % % This wasn't in sag_basin version
   % get the lat/lon of the merged slopes. this is done here rather than
   % mos_mergeslopes because the projection could change. The poly2cw
   % thing prevents an extra 90o from being appended to hslat, not sure
   % why it happens.
   [xn, yn] = poly2cw(hs_info.X, hs_info.Y);
   [xn, yn] = closePolygonParts(xn, yn);
   [hslt, hsln] = projinv(proj, xn, yn);

   idx = find(hslt == 90);
   hslt(idx) = [];
   hsln(idx) = [];

   % previously i divided hslp/tslp by 100, but i think that's wrong

   % Compute hydraulic geometry
   % rdep = 2; % dummy value = 2
   % rwid = 20; % dummy value = 20

   % [rwid, rdep] = hydraulicGeometry('mass', uarea / 1e6);
   % [rwid, rdep] = hydraulicGeometry('mass', uarea / 1e6, rslp * 100);
   [rwid, rdep] = hydraulicGeometry('ak', uarea / 1e6);
   
   % Limit rwid to between 1 and 10000 m, and rdep to > 0.1 m
   % rwid = max(min(rwid, 10000), 1);
   % rdep = max(rdep, 0.1);
   
   % Compute floodplain width using recommended 5x scale.
   rwid0 = 5 * rwid;

   % Put the values into a structure
   mos(n).Geometry     = hs_info.Geometry;
   mos(n).BoundingBox  = hs_info.BoundingBox;
   mos(n).X_hs         = hs_info.X;
   mos(n).Y_hs         = hs_info.Y;
   mos(n).X_link       = links(n).X;
   mos(n).Y_link       = links(n).Y;
   mos(n).Lat_hs       = hslt;
   mos(n).Lon_hs       = hsln;
   mos(n).Lat_link     = links(n).Lat;
   mos(n).Lon_link     = links(n).Lon;
   mos(n).latixy       = lati;
   mos(n).longxy       = long;
   mos(n).ID           = id;
   mos(n).dnID         = dnid;
   mos(n).hs_ID        = hs_ID;    % hillslope id, not needed for model
   mos(n).fdir         = 4;        % flow direction
   mos(n).lat          = lati;
   mos(n).lon          = long;
   mos(n).frac         = 1;        % fraction of cell included in study area
   mos(n).rslp         = rslp;     % river slope                     [-]
   mos(n).rlen         = rlen;     % main channel length             [m]
   mos(n).rdep         = rdep;     % main channel bankfull depth     [m]
   mos(n).rwid         = rwid;     % main channel bankfull width     [m]
   mos(n).rwid0        = rwid0;    % floodplain width                [m]
   mos(n).gxr          = 1;        % dummy, drainage density         [-]
   mos(n).hslp         = hslp;     % hillslope slope                 [-]
   mos(n).twid         = 2;        % dummy, trib width         [m]
   mos(n).tslp         = hslp;     % trib slope                [-]
   mos(n).area         = harea;    % hillslope area            [m2]
   mos(n).areaTotal0   = uarea;    % upstream
   mos(n).areaTotal    = uarea;    % upstream drainage area    [m2]
   mos(n).areaTotal2   = uarea;    % 'computed' upstream d.a.  [m2]
   mos(n).nr           = 0.05;     % manning's, river
   mos(n).nt           = 0.05;     % manning's, trib
   mos(n).nh           = 0.075;    % manning's, hillslope
   mos(n).ele0         = helev;
   mos(n).ele1         = helev;
   mos(n).ele2         = helev;
   mos(n).ele3         = helev;
   mos(n).ele4         = helev;
   mos(n).ele5         = helev;
   mos(n).ele6         = helev;
   mos(n).ele7         = helev;
   mos(n).ele8         = helev;
   mos(n).ele9         = helev;
   mos(n).ele10        = helev;
   mos(n).ele          = helev;
end

% reassign the structure name
mosartslopes = mos; clear mos;

% h = mos_plotslopes(mosartslopes,slopes,nodes);

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

%% save the data (don't overwrite the original! use 'mosart_hillslopes')

if opts.save_data == true
   if ~isfolder(pathsave)
      mkdir(pathsave)
   end
   save(fullfile(pathsave, 'mosart_hillslopes'),'mosartslopes','links','slopes');
end

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
% same as the "basins" - after removing 427. Note that "Data" does not contain
% hs427, thus the linear indexing (columns) go from hs426 in column 426 to hs428
% in column 427, just like basins(426).hs_ID and basins(427).hs_ID, so that
% tells us already the two datasets are ordered the same. The checks below are
% to be doubly sure and to confirm the area's match.

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
