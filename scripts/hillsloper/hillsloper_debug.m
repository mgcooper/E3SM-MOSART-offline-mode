function  hillsloper_debug

   % I moved the various debugging stuff out of the other scripts but I need to
   % figure out what is essential and how to simplify it. Or, just keep it all
   % in here and treat it like snippets

   %%
   % This was right after calling findDownstreamLinks to build the newlinks, but
   % before calling removelink. But i think I also used the manual
   % link(bad_link) = [] thing to get them the same size then ran it again

   % at this point links and newlinks are the same size, but newlinks has
   % ds_link_ID field added by findDownstreamLinks, which uses the information
   % in nodes to construct the topology, and is wrong b/c that info is wrong. I
   % forgot that the new links from hillsloper has the us/ds connectivity
   % already.

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
   test = catstructs(links(idx), newlinks(idx));

   setdiff([links.ds_link_ID], [newlinks.ds_link_ID])
   setdiff([newlinks.ds_link_ID], [links.ds_link_ID])
end

function debug_basins %#ok<*DEFNU>

   % How to remove the bad hillslope in 'basins'?

   % How to find the bad index (427) in basins? Turns out we cannot. Maybe we
   % could have before John reprocessed the data, but with the data I have it
   % cannot be done programmatically because slopes and links don't have the bad
   % slope (427), so the bad hs_ID cannot be retrieved from them, and 'basins'
   % does not have the link_ID field, so the bad link_ID cannot be used to find
   % the bad basin.

   % For N links, there should be N basins, 2*N slopes, and N+1 nodes

   dropbasin = find([basins.ncells] < 5);
   droplinks = find(isnan([links.hs_ID]));
   dropnodes = find(arrayfun(@(node) any(isnan(node.hs_ID)) ...
      && numel(node.conn) > 1, nodes));

   % Note: inlet nodes have nan for hs_ID, so isnan cannot be used to find bad
   % nodes. This shows that:
   sum([newlinks.isInlet])
   sum(arrayfun(@(node) any(isnan(node.hs_ID)) && numel(node.conn) == 1, nodes))

   % Inspect the bad basin / links
   basins(dropbasin)
   links(droplinks)

   newlinks(isnan([newlinks.hs_ID]))

   % The bad hs_ID is nan in links, so we cannot get the hs_ID from it From
   % links, we can get the us/ds_node_ID and us/ds_link_ID of the bad link From
   % nodes, we can get hs_ID, but the bad hs_ID is not in nodes because the node
   % inside the bad hillslope is actually associated with the good upstream
   % hillslope, see the diagram if confused. From nodes we can also get the
   % 'conn' which is the upstream and downstream links, meaning we can get the
   % node associated wtih the bad link, but there still is no way to then get
   % the bad basin id 427.

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
end

function verify_newslopes

   % this section comes after fixing the topology and making new slopes

   % the hillslopes should have only one link
   numLinksPerSlope = cellfun(@numel,{newslopes.link_ID});
   sum(numLinksPerSlope > 1)

   % confirm that all link_IDs are present in newslopes.link_ID
   setdiff(unique([newslopes.link_ID]), unique([links.link_ID]))
   setdiff(unique([links.link_ID]), unique([newslopes.link_ID]))

   % repeat with newlinks
   setdiff(unique([newslopes.link_ID]), unique([newlinks.link_ID]))
   setdiff(unique([newlinks.link_ID]), unique([newslopes.link_ID]))

   % This is not needed b/c slopes link ID is setdiff(unique([slopes.link_ID]),
   % unique([links.link_ID])) setdiff(unique([links.link_ID]),
   % unique([slopes.link_ID]))

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
end

function debug_upstream_area

   % March 2024

   % I used this to determine that the links.us_da_km2 and nodes.da_km2 fields
   % are not correct or at least they are not what I expect them to be - the
   % upstream drainage area of all areas upstream of the link/node ... but the
   % slopes and basins tables have the correct upstream areas

   % Read the mosart config and runoff files
   config_data = mosart.readConfigFiles('sag_basin', ...
      {'domain', 'mosart'});
   runoff_data = mosart.readRunoffFiles('sag_basin', ...
      2013, 'casename', 'ats', 'runid', 'sag_basin');

   % Read the shapefiles
   [basins, slopes, links, nodes] = hillsloper.readfiles('sag_basin', ...
      {'basins', 'slopes', 'links', 'nodes'});

   % Read the ats data Bo provided
   load(fullfile(getenv('USERDATAPATH'), ...
      'interface', 'ATS', 'sag_basin', 'sag_hillslope_discharge.mat'), 'Data');
   Area = Data.Properties.CustomProperties.Area;
   Time = Data.Time;
   Runoff = sum(Data{:, :}, 2) / (24 * 3600); % m3/d -> m3/s
   clear Data

   mosart_data = config_data.mosart;
   domain_data = config_data.domain;
   runoff_data = runoff_data.runoff_2013;

   % The area of "Sag_boundary.shp" file computed in QGIS:
   known_area = 12928358225;

   % The "MOSART area" in the rof.log file:
   mosart_area = 12891807900;

   printf(sum(Area) / known_area, 10)
   printf(sum(Area) / mosart_area, 10)

   %% List the areas that match the known total basin area

   % NOTE: between the ones that match and the ones that don't, all fields
   % related to basin area or upstream drainage area in slopes, basin, nodes,
   % and links are accounted for, meaning they're all considered below, so
   % there's no need to look further.

   % TLDR: nodes and links are incorrect, slopes and basins are correct.

   % Update 20 March 2024, not sure what the take away was! TLDR: there should
   % be no problem related to area, the rof.log file "mosart area" matches the
   % input ats Area used to convert runoff from m3/d to mm/s, so something else,
   % such as channel storage, must explain the difference.
   %
   % I know: - The "harea" field in the mosart input file was assigned directly
   % from the ats Area data in makeMosartSlopes - The "mosart area" in the
   % rof.log file matches sum(Area) - This means the mosart area was computed
   % from the harea field - The "uarea" field, which is
   % round(links(n).us_da_km2, is wrong. This upstream area is assigned to
   % areaTotal, areaTotal0, and areaTotal2, which Tian thought aren't used in
   % the model. - This is consistent with the fact that "mosart area" in rof.log
   % matches the sum over harea, and overall this suggests there is no problem
   % related to area


   % These ones match the known area exactly
   (sum([basins.area_km2]) * 1e6) / known_area

   % These are nearly equal
   printf( ...
      [sum(Area)
      sum(mosart_data.area)
      sum(domain_data.area ./ (4 * pi) * 510099699070762) % convert from steradians
      sum([slopes.area_km2]) * 1e6
      sum([slopes.area0x2CKm2]) * 1e6
      max([slopes.da])              % slightly smaller (by the size of the neg slope?)
      sum([basins.area_km2]) * 1e6  % slightly larger (matches known area)
      max([basins.da])] ...         % slightly larger
      )

   % It makes sense that the first three above match since they are all from
   % Area originally, but I am surprised the 4th and 5th match b/c the Area data
   % should have the lakes area removed, so I am not sure if I overwrote those
   % fields, or if Jon provided the data with the lakes area adjusted.

   %% Which ones are not correct / equal

   % These are equal but are not equal to the ones above, which are correct
   printf( ...
      [max([links.us_da_km2]) * 1e6
      max(mosart_data.areaTotal)
      max(mosart_data.areaTotal2)
      max([links.ds_da_km2]) * 1e6
      max([nodes.da_km2]) * 1e6] ...
      )

   % areaTotal and areaTotal2 are slightly larger b/c they includes the outlet
   % "local hillslope area"

   %% Compare the different possible upstream da's

   % I decided basins.da is the correct upstream drainage area

   figure; hold on
   histogram([basins.da], 'NumBins', 100)
   histogram([links.us_da_km2] * 1e6, 'NumBins', 100)
   % histogram([slopes.da])
   legend('basins', 'links')

   min([basins.da])
   max([basins.da])

   %%

   % this got confusing again ... the hs_ID field skips 427, so I cannot simply
   % index into the "Area" field to find the area of the basin or slope with
   % hs_ID, e.g. use idx = 426 then 427 (fails b/c there's no hs_ID = 427) then
   % from 428 on the areas won't match.

   idx = 429;
   Area(idx)
   basins([basins.hs_ID] == idx).area_km2 * 1e6
   (slopes([slopes.hs_ID] == idx).area_km2 ...
      + slopes([slopes.hs_ID] == -idx).area_km2) * 1e6


   % This confirms that the pos+neg da equals the basins da, more or less

   basins_area = zeros(numel(basins), 1);
   slopes_area = zeros(numel(basins), 1);
   for n = 1:numel(basins)

      idx_p = find([slopes.hs_ID] == n);
      idx_n = find([slopes.hs_ID] == -n);

      if isempty(idx_p)
         continue
      end
      hs_p = slopes(idx_p);
      hs_n = slopes(idx_n);

      b = basins(find([basins.hs_ID] == n));

      basins_area(n) = b.da;
      slopes_area(n) = hs_p.da + hs_n.da;
   end

   figure
   plot(slopes_area, basins_area, 'o')
   addOnetoOne

   %% how many "endbasin"'s da does not match its area?

   iendbasin = logical([basins.endbasin]);
   endbasins = basins(iendbasin);


   %% Clarify anomalies

   % This is the one that is slightly smaller than the others:
   max([slopes.da]) / max([basins.da]) % 98%

   % Confirm the effect of removing lakes (<0.1 %)
   sum(Area) / known_area

   % This clarifies that this da is not the one with the threshold (625 m2 I
   % think)
   min([basins.da])

   % This one is:
   min([links.us_da_km2])
   min([nodes.da_km2])
end

function verify_runoff_balances_discharge

   % Load the saved mosart discharge
   pathsave = fullfile(getenv('E3SMOUTPUTPATH'), getenv('MOSART_RUNID'), 'mat');
   fname = fullfile(pathsave, 'mosart.mat');
   load(fname, 'mosart');

   % Clip 2014-2018
   idx = isbetween(mosart.T, Time(1), Time(end));
   Discharge = mosart.D(idx, :);
   Storage = mosart.S(idx, :);

   % Confirm the outlet has the max cumulative discharge
   test = cumsum(Discharge);
   assertEqual(findglobalmax(Discharge(1, :)), mosart.outID)

   % Compare the outlet cumulative discharge to the cumulative input runoff
   Discharge = Discharge(:, mosart.outID); % m3/s

   figure; hold on
   plot(Discharge)
   plot(Runoff)

   figure
   scatterfit(Discharge, Runoff)

   % Based on this, I think it might just be the channel storage
   figure; hold on
   plot(cumsum(Discharge)); plot(cumsum(Runoff))
   legend('D', 'R')

   Dcumulative = cumsum(Discharge);
   Rcumulative = cumsum(Runoff);
   Rcumulative(end) - Dcumulative(end)

   % Convert the storage on the final day to m3/s
   sum(Storage(end, :)) / 3600

   % figure; hold on plot(cumsum(Discharge) + sum(Storage, 2) / 3600);
   % plot(cumsum(Runoff)) legend('D', 'R')


   %%
   t1 = datetime(2014, 1, 1, 0, 0, 0);
   t2 = datetime(2015, 1, 1, 0, 0, 0);
   idx = isbetween(Time, t1, t2, 'openright');

   figure; hold on
   plot(Time(idx), cumsum(Runoff(idx)))


   %%

   % The domain file is not used, the dlnd file sets the runoff file as the
   % domain, SO ITS POSSIBLE THE PROBLEM IS THAT THE MING PAN RUNOFF FILES ARE
   % USED AS TEMPLATES AND THEY HAVE THE WRONG AREA ... but the runoff files
   % don't have an area field ... so that's not the problem ...
   %
   % runoff_data.info.Name

   % Since the problem is not likely to be the area

end

function plot_endbasins

   % identify the endbasins with da that doesn't equal area_km2

   iendbasin = logical([basins.endbasin]);
   endbasins = basins(iendbasin);

   % check = [endbasins.da] ~= ([endbasins.area_km2] * 1e6);
   check = iendbasin & ([basins.da] - ([basins.area_km2] * 1e6) > 1e-8);
   sum(check)

   %% Plot the us drainage area in links
   lat = [links.link_Lat];
   lon = [links.link_Lon];
   ds_da = [links.ds_da_km2];
   us_da = [links.us_da_km2];

   figure
   scatter(lon, lat, 20, us_da, 'filled')
   colorbar

   %% Plot the us drainage area in basins
   lat = [basins.basin_Lat];
   lon = [basins.basin_Lon];
   us_da = [basins.da];

   figure; hold on
   scatter(lon, lat, 20, us_da, 'filled')
   scatter(lon(check), lat(check), 40, 'm', 'filled')
   colorbar

   %% Plot the local hillslope area in basins
   hs_area = [basins.area_km2];

   figure; hold on
   scatter(lon, lat, 20, hs_area, 'filled')
   scatter(lon(check), lat(check), 40, 'm', 'filled')
   colorbar

   projaka = load('projaka.mat').('projaka');

   [blat, blon] = projinv( projaka, boundary.X, boundary.Y);
   boundary = polyshape(blon, blat);
   plot(blon, blat)

   %% case study

   % TLDR: assuming the area_km2 field is correct, the issue is with the da
   % field. For "endbasins" which have an immediate downstream confluence,
   % meaning the downstream node of the link draining the "endbasin" is a
   % confluence with another upstream link, the da field of the endbasin equals
   % its own area plus the da of the confluence link. In other words, the "da"
   % seems to be node-centric, where the "da" for the endbasin is actually the
   % da for the node.


   % This clarifies that the problem occurs when the link draining an endbasin
   % immediately converges with another upstream link, and the da of the other
   % one is added to the da of the endbasin. The hope was that the pos/neg
   % slopes.da fields were correct but they are not, they also

   % So for a fix, I could start at all endbasins, check if the first downstream
   % node is a confluence, if so, subtract the other upstream da

   % basins:
   fid = 1379;
   da = 14007575;
   area_m2 = 6.3318 * 1e6;

   extra_area = da - area_m2 ; % 7675775 m2

   % slopes:
   fid = [4627, 1872];
   hs_id = [1379, -1379];
   area_m2 = [3.343075, 2.97065] * 1e6;
   da = [7395744.3, 6571844.1];

   % printf(sum(area_m2 - da)) % -7653863

   sum(area_m2) % = 6313725 = basins.area_km2
   sum(da) % = 13967588

   % Next accounts for the fact that basins.da is larger than the sum of
   % slopes.da due to the river corridor area. The difference doesn't quite add
   % up, but the missing difference could be the other hillslope, the one with
   % area 7675775

   (6.3318 - sum([3.343075, 2.97065])) * 1e6 % = 18075
   14007575 - sum(da) % = 39987

   % now for the next one down, it actually should be the total upstream, i.e.,
   % the area of basin 1379, its own local area, plus the 7675775
   fid = 419;
   da = 18550250;
   area_km2 = 4.542675;

   area_km2 * 1e6 + 6.3318 * 1e6 + 7675775 % 18550250, correct
end

function check_basin_area

   % This was I think the first stab I took at this before I understood that
   % Bo's area is slopes_pos + slopes_neg area, which is slightly smaller than
   % basins.area

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
end
