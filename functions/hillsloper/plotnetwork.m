function H = plotnetwork(nodes, links, slopes, inletID, makeplot)

   inletID = info.inlet_ID;
   outletID = info.outlet_ID;

   specs = createSymbolSpecs();

   [inletNodes, outletNodes, ...
      interiorNodes, inletLinks, outletLinks, outletBasin] = getfeatures( ...
      newlinks, newslopes, nodes);

   switch makeplot

      case 'outlet'

         geomap(outletBasin.Lat, outletBasin.Lon, 5);
         geoshow(outletNodes, 'SymbolSpec', specs.outletnode);
         geoshow(outletLinks, 'SymbolSpec', specs.outletlink);
         geoshow(outletBasin, 'SymbolSpec', specs.slopes);

      case 'links'

         geomap([inletNodes.Lat], [inletNodes.Lon], 2);
         geoshow(links, 'SymbolSpec', specs.links);

      case 'upstreamwalk'
         
         % Confirm dnid is correct by plotting the links one by one from id->dn_id
         figontop

         ids     = [newlinks.link_ID];
         i       = 1;
         idx     = outletLinks.link_ID;
         id_done = 0;    % for idx = 1, link_id = 0, i.e. the first link_id is 0
         id_left = [];
         id_done_p = [];
         while i <= length(links)
         
            lati = [newlinks(idx).Lat];
            long = [newlinks(idx).Lon];

            geoshow(lati(1:end-1), long(1:end-1))

            dnid  = newlinks(idx).ds_link_ID;         % get the ds link id
            idx   = find([newlinks.link_ID]==dnid);   % get the ds link index
            id_done = [id_done; dnid];                   % track finished links
            if isempty(idx) || ismember(dnid,id_done_p) % outlet links have no dnid
               id_done = id_done(~isnan(id_done));     % remove the nan
               id_left = ids(~ismember(ids,id_done));  % links that remaining
               idx = find([newlinks.link_ID]==id_left(1)); % start over at some other link
               id_done = [id_done;id_left(1)];
            end
            i = i+1;
            id_done_p = id_done; % id_done_previous
            pause
         end

      case 'downstreamwalk'

         % this suggests the algorithm for inletID is not quite right, but that's
         % probably ok as long as id->dnid is correct

         % Confirm dnid is correct by plotting the links one by one from id->dn_id
         figontop
         % ax = geomap(outletBasin.Lat, outletBasin.Lon, 5);
         hold on

         ids = [newlinks.link_ID];
         i       = 1;
         idx     = 1;
         id_done = 0;    % for idx = 1, link_id = 0, i.e. the first link_id is 0
         id_left = [];
         id_done_p = [];
         while i <= length(links)
            
            lati = [newlinks(idx).Lat];
            long = [newlinks(idx).Lon];

            geoshow(lati, long);

            dnid  = newlinks(idx).ds_link_ID;         % get the ds link id
            idx   = find([newlinks.link_ID]==dnid);   % get the ds link index
            id_done = [id_done; dnid];                   % track finished links
            if isempty(idx) || ismember(dnid,id_done_p) % outlet links have no dnid
               id_done = id_done(~isnan(id_done));     % remove the nan
               id_left = ids(~ismember(ids,id_done));  % links that remaining
               idx = find([newlinks.link_ID]==id_left(1)); % start over at some other link
               id_done = [id_done;id_left(1)];
            end
            i = i+1;
            id_done_p = id_done; % id_done_previous
            pause
         end

      otherwise

         latlims = [min([nodes.Lat]) max([nodes.Lat])] + [-0.001 0.001];
         lonlims = [min([nodes.Lon]) max([nodes.Lon])] + [-0.001 0.001];


         figure;
         geomap(inletNodes.Lat, inletNodes.Lon);
         geoshow(inletNodes, 'SymbolSpec', specs.nodes); hold on;
         geoshow(outletNodes, 'SymbolSpec', specs.outletnode);
         geoshow(interiorNodes, 'SymbolSpec', specs.interiornode);


         geoshow(outletLinks, 'SymbolSpec', specs.outletlink);
         geoshow(outletBasin, 'SymbolSpec', specs.slopes);
   end
end

%%
function [inletNodesID, outletNodesID, inletNodes, outletNodes, ...
      interiorNodes,inletLinks, outletLinks, outletBasin] = getfeatures( ...
      newlinks, newslopes, nodes)


   inletNodesID = [newlinks([newlinks.isInlet]).us_node_ID];
   outletNodesID = [newlinks([newlinks.isOutlet]).ds_node_ID];

   inletNodes = nodes(ismember([nodes.node_ID], inletNodesID));
   outletNodes = nodes(ismember([nodes.node_ID], outletNodesID));
   interiorNodes = nodes(~ismember([nodes.node_ID], [inletNodesID outletNodesID]));

   inletLinks = links([links.isInlet]);
   outletLinks = links([links.isOutlet]);

   outletSlope = newslopes([newslopes.hs_ID] == outletLinks.hs_ID);
   outletBasin = basins([basins.hs_ID] == outletLinks.hs_ID);
end
