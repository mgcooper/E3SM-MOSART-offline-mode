clean

opts    = const('save_data',false,'plot_map',true,'plot_slopes',true);


%% set paths and read in the data

pathdata = setpath('interface/data/sag/hillsloper/trib_basin/newslopes/');
pathsave = setpath('interface/data/sag/hillsloper/trib_basin/newslopes/');

load([pathdata 'sag_hillslopes']);

% export_fig('temp.png', '-nocrop', '-transparent', '-png','-r400')


%% Step 1: make a newlinks table with upstream/downstream link connectivity

[slopes,links,info] = mos_makeslopes(slopes,links,nodes,opts.plot_slopes);

% note that the slopes table that comes from this is not the mosart slopes
% table, it still has 2 'slopes' per link, but it is cleaned up relative to
% the prior version and has the link connectivity fields

% Step 2 and 3 are fixing orphan links/nodes, see examples at the very end
% that were for the Sag basin. Step 4 was to ensure the slopes / links ID
% numbering went from 1 -> # slopes and was moved into mos_makslopes


%% Step 5: build a table with the MOSART input file information

proj    = projcrs(3338,'Authority','EPSG');

for n = 1:length(links)
    
    % hillslope associated with this reach
    slope_id    = links(n).hs_id;
    slope_info  = mos_mergeslopes(slopes,slope_id);

    % pull out values needed for input file, convert km to m where needed
    lat         = mean([links(n).Lat]);
    lon         = mean([links(n).Lon]);
    id          = links(n).link_ID;
    dnid        = links(n).ds_link_ID;
    rslp        = roundn(links(n).slope,-4);
    rlen        = roundn(links(n).len_km*1e3,0);
    hslp        = roundn(double(slope_info.hslp),-4);
    harea       = roundn(double(slope_info.harea),0);
    helev       = roundn(double(slope_info.helev),0);
    usarea      = roundn(links(n).us_da_km2*1e6,-4);
    
    % get the lat/lon of the merged slopes. this is done here rather than
    % mos_mergeslopes because the projection could change. The poly2cw
    % thing prevents an extra 90o from being appended to hslat, not sure
    % why it happens. 
    [xn,yn]     = poly2cw(slope_info.X,slope_info.Y);
    [xn,yn]     = closePolygonParts(xn,yn);
    [hslt,hsln] = projinv(proj,xn,yn);
    idx         = find(hslt==90);
    hslt(idx)   = [];
    hsln(idx)   = [];
    
    
    % previously i divided hslp/tslp by 100, but i think that's wrong
    
    % put the values into a structure
    mos(n).Geometry     = slope_info.Geometry;
    mos(n).BoundingBox  = slope_info.BoundingBox;
    mos(n).X_hs         = slope_info.X;
    mos(n).Y_hs         = slope_info.Y;
    mos(n).X_link       = links(n).X;
    mos(n).Y_link       = links(n).Y;
    mos(n).Lat_hs       = hslt;
    mos(n).Lon_hs       = hsln;
    mos(n).Lat_link     = links(n).Lat;
    mos(n).Lon_link     = links(n).Lon;
    mos(n).latixy       = lat;
    mos(n).longxy       = lon;
    mos(n).ID           = id;
    mos(n).dnID         = dnid;
    mos(n).fdir         = 4;        % flow direction
    mos(n).lat          = lat;
    mos(n).lon          = lon;
    mos(n).frac         = 1;        % fraction of cell included in study area
    mos(n).rslp         = rslp;     % river slope               [-]
    mos(n).rlen         = rlen;     % river width               [m]
    mos(n).rdep         = 2;        % dummy, bankfull depth     [m]
    mos(n).rwid         = 50;       % dummy, bankfull width     [m]
    mos(n).rwid0        = 50;       % dummy, floodplain width   [m]
    mos(n).gxr          = 1;        % dummy, drainage density   [-]
    mos(n).hslp         = hslp;     % hillslope slope           [-]
    mos(n).twid         = 2;        % dummy, trib width         [m]
    mos(n).tslp         = hslp;     % trib slope                [-]
    mos(n).area         = harea;    % hillslope area            [m2]
    mos(n).areaTotal0   = usarea;   % upstream   
    mos(n).areaTotal    = usarea;   % upstream drainage area    [m2]
    mos(n).areaTotal2   = usarea;   % 'computed' upstream d.a.  [m2]
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


%% save the data (don't overwrite the original! use 'mosart_hillslopes')

if opts.save_data == true
    save([pathsave 'mosart_hillslopes'],'mosartslopes','links','slopes');
end


% this was just to confirm the boudning box i make in mos_mergeslopes has
% the same format as the shaperead-style bounding box (it does)
% for n = 1:numel(slopes)
%     iLink = slopes(n).link_ID;
%     plotBbox(slopes(n).BoundingBox); hold on;
%     plotBbox(mosartslopes(iLink).BoundingBox,'Color','m');
%     pause;
% end
% h = mos_plotslopes(mosartslopes,slopes,nodes);

% 
% %% plot the nodes and label them
% 
% 
% % jitter for the labels
% latlims     = [min([nodes.Lat]) max([nodes.Lat])] + [-0.001 0.001];
% lonlims     = [min([nodes.Lon]) max([nodes.Lon])] + [-0.001 0.001];
% jitx        = (lonlims(2)-lonlims(1))/80;
% jity        = (latlims(2)-latlims(1))/80;
% nodespec1   = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
%                 6,'MarkerFaceColor','g','MarkerEdgeColor','none'});
% nodespec2   = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
%                 6,'MarkerFaceColor','r','MarkerEdgeColor','none'});            
% linkspec1   = makesymbolspec('Line',{'Default','Color','b','LineWidth',1});
% linkspec2   = makesymbolspec('Line',{'Default','Color','r','LineWidth',1});
% slopespec1  = makesymbolspec('Polygon',{'Default','FaceColor','none',   ...
%                 'EdgeColor','g','LineWidth',1});
% slopespec2  = makesymbolspec('Polygon',{'Default','FaceColor','none',   ...
%                 'EdgeColor','r','LineWidth',1});
%             
% if plot_map == true            
% figure;
% worldmap(latlims,lonlims);
% geoshow(nodes,'SymbolSpec',nodespec1)
% 
% % label nodes.id
% for n = 1:length(nodes)
%     nx  = nodes(n).Lon+jitx/2;
%     ny  = nodes(n).Lat+jity/2;
%     nid = num2str(nodes(n).id);
%     textm(ny,nx,nid,'Color','r','FontSize',12)
% end
% end
% 
% % technically this plots all the link ids on the slopes, but is too slow
% figure;
% for i = 1:length(slopes)
%     plot(slopes(i).Lon,slopes(i).Lat,'Color','g'); hold on;
%     % label link_id
%     xi      = [slopes(i).Lon];
%     yi      = [slopes(i).Lat];
%     jitx    = rand*(max(xi)-min(xi));
%     jity    = rand*(max(yi)-min(yi));
%     nx      = nanmean(xi)-(rand*jitx/2);
%     ny      = nanmean(yi)-(rand*jity/2);
%     nid = num2str(slopes(i).link_id);
%     text(nx,ny,nid,'Color','r','FontSize',12);
% end
% 
% 
% 
% %% The next two plots are for checking the algorithm
% 
% 
% if plot_check == true
%     
% % 1. plot the headwater (inlet) and outlet nodes
% 
%     latlims = [min([nodes.Lat]) max([nodes.Lat])];
%     lonlims = [min([nodes.Lon]) max([nodes.Lon])];
% 
% % symbolspec for outlet nodes
%     nodespec2   = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
%                     6,'MarkerFaceColor','r','MarkerEdgeColor','none'});
% 
%     figure;
%     worldmap(latlims,lonlims);
%     geoshow(nodes(inlet_ID),'SymbolSpec',nodespec1); hold on;
%     geoshow(links,'SymbolSpec',linkspec1);
%     geoshow(nodes(~inlet_ID),'SymbolSpec',nodespec2);
% % this suggests the algorithm for inletID is not quite right, but that's
% % probably ok as long as id->dnid is correct
% 
% % 2. confirm dnid is correct by plotting the links one by one from id->dn_id
%     figure;
%     worldmap(latlims,lonlims); hold on;
%     ids     = [newlinks.link_ID];
%     i       = 1;
%     idx     = 1;
%     id_done = 0;    % for idx = 1, link_id = 0, i.e. the first link_id is 0
%     id_left = [];
%     while i <= length(links)
%     % while i <= 63 % the first oulet, for testing
%         geoshow(newlinks(idx),'SymbolSpec',linkspec1); % plot this link
%         dnid    = newlinks(idx).ds_link_ID;         % get the ds link id
%         idx     = find([newlinks.link_ID]==dnid);   % get the ds link index
%         id_done = [id_done;dnid];                   % track finished links
%         if isempty(idx) || ismember(dnid,id_done_p) % outlet links have no dnid
%             id_done = id_done(~isnan(id_done));     % remove the nan
%             id_left = ids(~ismember(ids,id_done));  % links that remaining
%             idx     = find([newlinks.link_ID]==id_left(1)); % start over at some other link
%             id_done = [id_done;id_left(1)];
%         end    
%         i           = i+1;
%         id_done_p   = id_done; % id_done_previous
%         pause
%     end
% end
% 
% 
% %% plot the nodes
% 
% 
% % this is extremely slow with the entire sag basin
% 
% if plot_map == true
% 
% % jitter for the labels
% % jitx    = (R.XWorldLimits(2)-R.XWorldLimits(1))/80;
% % jity    = (R.YWorldLimits(2)-R.YWorldLimits(1))/80;
% latlims = [min([nodes.Lat]) max([nodes.Lat])];
% lonlims = [min([nodes.Lon]) max([nodes.Lon])];
% freq    = 1;
% 
% figure;
% worldmap(latlims,lonlims);
% 
% % plot the hillslope outlines
% for n = 1:length(slopes)
%     plotm(slopes(n).Lat,slopes(n).Lon,'Color','b');
% end
% 
% % plot the river network ('links')
% for n = 1:length(links)
%     plotm(links(n).Lat,links(n).Lon,'-','Color','g');
% end
% 
% % plot the river network nodes
% for n = 1:length(nodes)
%     plotm(nodes(n).Lat,nodes(n).Lon,'.','Color','r','MarkerSize',20);
% end
% 
% % label the hillslopes
% for n = 1:freq:length(slopes)
%     shpn = polyshape(slopes(n).Lon,slopes(n).Lat);
%     [cx,cy] = centroid(shpn);
%     textm(cy,cx,int2str(slopes(n).hs_id),'Color','b','FontSize',14)
% end
% 
% % label the river reaches
% for n = 1:freq:length(links)
%     % links.id
%     ry  = nanmean(links(n).Lat)+jity;
%     rx  = nanmean(links(n).Lon)+jitx;
%     rid = int2str(links(n).id);
%     textm(ry,rx,rid,'Color',rgb('dark green'),'FontSize',12)
% end
% 
% % label nodes.id
% for n = 1:freq:length(nodes)
%     nx  = nodes(n).Lon+jitx/2;
%     ny  = nodes(n).Lat+jity/2;
%     nid = num2str(nodes(n).id);
%     textm(ny,nx,nid,'Color','r','FontSize',12)
% end
% 
% % label nodes.sbasins
% % for n = 1:freq:length(nodes)
% %     nx  = nodes(n).Lon-jitx;
% %     ny  = nodes(n).Lat-jity;
% %     nid = nodes(n).sbasins;
% %     textm(ny,nx,nid,'Color',rgb('dark red'),'FontSize',12)
% % end
% end
% 
% 
% 
% 
% 
% 
% %% below here is mostly testing to sort out the links
% 
% % %     the us_hs_id for a given link is actually the us_hs_id for the
% % %     us_link, so if I have a link and the ds link, i can go to the ds
% % %     link, get the us-hs-id and put that with the link ... not sure why i
% % %     got this idea ... does not appear to wrk
% % 
% % % link id = 319, get the ds link ID (headwater example)
% % idx     = find([newlinks.link_ID] == 319);
% % dsID    = newlinks(idx).ds_link_ID;
% % idx     = find([newlinks.link_ID] == dsID);
% % usHS    = newlinks(idx).us_hs_ID;   
% % 
% % newlinks(idx)
% % 
% % % for headwater links, this will return four values, need to remove the 
% % 
% % % link id = 318, get the ds link ID (non-headwater example)
% % idx     = find([newlinks.link_ID] == 318);
% % dsID    = newlinks(idx).ds_link_ID;
% % idx     = find([newlinks.link_ID] == dsID);
% % usHS    = newlinks(idx).us_hs_ID;   
% % 
% % i       = find(ismember([slopes.hs_id],2762))
% % slopes(i)
% 
% % link 0 drains to link 2605. I have this in my link_ID and ds_link_ID
% % fields. 
% 
% % these notes were up above in the newlinks loop
%     % notes - us_conn_id will have three values at a confluence, the link
%     % itself, and the two upstream links. Therefore, this link is the
%     % downsteream link for the two values of us_conn_id that are not the
%     % link itself. The while loop goes and adds this link as the ds
%     
% %     ds_hs_id tells us the hillslopes that contribute to the node that
% %     this link contributes to ... which, if we just want the hillslopes
% %     that contribute to each node, is sufficient ... but we also need to
% %     know the links associated with each hillslope, I think, to compute
% %     the reach-specific values of length, width, slope, etc. 
% 
% %     can I start with a link, go to the ds_node, get the us conn
% %     link = 319
% 
% %     the problem is that the link ID 
% 
% 
% %%
% 
% % commenting this out for now
% % newlinks    = rmfield(newlinks,{'id','ds_node_id','us_node_id'});
% 
% % [([newlinks.link_ID])' ([newlinks.link_dnID])']
% % [([newslopes.ID])' ([newslopes.dnID])']
% 
% % these were here when I was not using shaperead, before I realized the
% % benefits of maintaining the geostruct format
% % newlinksT   = struct2table(newlinks);
% % newlinksT   = movevars(newlinksT,'link_dnID','After','link_ID');
% 
% 
% % % I think at this point the challenge is identifying the headwater reaches
% % % and assigning the correct hillslopes to each link
% % 
% % % I think the ones with 4 values in us_hs_id are the ones downstream of
% % % headwater links UPDATE actually these are probably the confluences, but
% % % that might also be helpful
% % 
% % % I want a vector of indices for the ones with 4 values and a vector of
% % % indices for the ones with 
% % check1 = [];
% % for i = 1:length(newlinks)
% %     if length(newlinks(i).us_hs_ID) == 4
% %         check1  = [check1;i];
% %     end 
% % end
% %     
% % check2 = [];
% % for i = 1:length(inlet_ID)    
% %     % get the index for this inlet ID
% %     this_inlet_idx  = find([newlinks.link_ID] == inlet_ID(i));
% %     this_dnID       = newlinks(this_inlet_idx).link_dnID;
% %     this_dn_idx     = find([newlinks.link_ID] == this_dnID);
% %     check2          = [check2;this_dn_idx];
% % end
% % 
% % 
% % check1 = [];
% % for i = 1:length(inlet_ID)    
% %     % get the index for this inlet ID
% %     this_inlet_idx  = find([newlinks.link_ID] == inlet_ID(i));
% %     this_dnID       = newlinks(this_inlet_idx).link_dnID;
% %     this_dn_idx     = find([newlinks.link_ID] == this_dnID);
% %     inlet_dnID(i,1) = this_dnID;
% %     if length(newlinks(this_dn_idx).us_hs_ID) == 4
% %         check1      = [check1;this_dn_idx];
% %     end 
% % end
% % 
% % for i = 1:length(newlinks)
% %     if length([newlinks(i).us_hs_ID]) == 4
% %         check2(i,1) = 1;
% %     else
% %         check2(i,1) = 0;
% %     end
% % end
% 
% % alternative syntax for better code interpretation        
% %     this_link_id            = links(n).id;
% %     this_links_us_node_id   = links(n).us_node_id;
% %     this_links_ds_node_id   = links(n).ds_node_id;
% %     this_links_us_node_idx  = find(ismember([nodes.id],us_node_id));
% %     this_links_ds_node_idx  = find(ismember([nodes.id],ds_node_id));
% %     this_links_us_slope_id  = nodes(i_us).hs_id;
% %     this_links_ds_slope_id  = nodes(i_ds).hs_id;
% %     this_links_us_link_conn = nodes(i_us).conn;
% %     this_links_ds_link_conn = nodes(i_ds).conn;
% 
% 
% 
% 
% 
% 
% % 
% % %% Step 2: Custom fixes to orphan links
% % 
% % 
% % % Step 2: fix orphan links and nodes (detailed notes are in _test_rmlink)
% % % links 199 and 1396 flow to 1394 instead of 1274
% % rm_link     = 1274;         % remove link, orphan to be deleted
% % us_link     = [199, 1396];  % upstream link(s), into orphan at us node
% % ds_link     = 1275;         % downstream link(s), merge w/orphan at ds node
% % rp_link     = 1394;         % replacement link, downstream of orphan
% % slope_flag  = true;         % remove the slope that drains to rm_link?
% % newlinks    = remove_link   ...
% %             (   newlinks,   ...
% %                 rm_link,    ...
% %                 us_link,    ...
% %                 ds_link,    ...
% %                 rp_link,    ...
% %                 slope_flag  );
% % 
% % % repeat for links with duplicate hillslopes, meaning slope_flag == false
% % rm_link     = 1579;
% % rp_link     = 2477;
% % us_link     = [121, 2479];  % find these in us_conn_ID
% % ds_link     = 927;          % find this in ds_conn_ID 
% % slope_flag  = false;
% % newlinks    = remove_link   ...
% %             (   newlinks,   ...
% %                 rm_link,    ...
% %                 us_link,    ...
% %                 ds_link,    ...
% %                 rp_link,    ...
% %                 slope_flag  );
% % 
% % % repeat for the next one
% % rm_link     = 1324;
% % rp_link     = 2682;
% % us_link     = [178, 1323];  % find these in us_conn_ID
% % ds_link     = 2681;         % find these in ds_conn_ID 
% % slope_flag  = false;
% % newlinks    = remove_link   ...
% %             (   newlinks,   ...
% %                 rm_link,    ...
% %                 us_link,    ...
% %                 ds_link,    ...
% %                 rp_link,    ...
% %                 slope_flag  );
% % 
% % % check the fields (can be used after each function call above to verify)
% % % idx0        = find([newlinks.link_ID]==rm_link);   
% % % idx1        = find([newlinks.link_ID]==us_link(1));
% % % idx2        = find([newlinks.link_ID]==us_link(2));
% % % idx3        = find([newlinks.link_ID]==ds_link);
% % % idx4        = find([newlinks.link_ID]==rp_link);
% % % newlinks(idx0)  % should be empty
% % % newlinks(idx1)  % should not have any rm_link values, ds_link_ID = rp_link
% % % newlinks(idx2)
% % % newlinks(idx3)
% % % newlinks(idx4)  % should not have any rm_link values, us_link_ID = rp_link
% % 
% % 
% % %% Step 3: Remove orphan slopes (merge slope 1843 with slope 2010)
% % 
% % 
% % % first, remove unneccesary fields
% % % slopes      = rmfield(slopes,{'link_id','outlet_idx','bp','endbasin'});
% % 
% % % id's of the hillslopes
% % rm_slope    = 1843;
% % rp_slope    = 2010;
% % rp_flag     = 1;
% % 
% % % merge the slopes
% % newslopes   = remove_slopes(slopes,rm_slope,rp_slope,rp_flag);
% % 
% % % now length(newlinks) = 3266 * 2 = 6532 = length(newslopes)
% % % length(unique([newlinks.link_ID]))
% % % length(unique([newslopes.hs_id]))/2
% 
% 
% 
% 
% % 
% % %% Step 4: Example of fixing bad dn numbering
% % 
% % idx1        = IDs<1274;
% % idx2        = dnIDs<1274;
% % IDs(idx1)   = IDs(idx1)+1;
% % dnIDs(idx2) = dnIDs(idx2)+1;
% % 
% % % repeat. this time, numbering is good up to 1323, then needs -1 up to 1577
% % dIDs        = diff(IDs); find(dIDs>1)
% % idx1        = IDs>1323 & IDs<1578;
% % idx2        = dnIDs>1323 & dnIDs<1578;
% % IDs(idx1)   = IDs(idx1)-1;
% % dnIDs(idx2) = dnIDs(idx2)-1;
% % 
% % % repeat. this time, numbering is good up to 1577, needs -1 
% % dIDs        = diff(IDs); find(dIDs>1)
% % idx1        = find(IDs==1578);
% % idx2        = find(dnIDs==1578);
% % IDs(idx1)   = IDs(idx1)-1;
% % dnIDs(idx2) = dnIDs(idx2)-1;
% % 
% % % repeat. this time, numbering is good up to 1577, then needs -2 to the end
% % dIDs        = diff(IDs); find(dIDs>1)
% % idx1        = find(IDs>1577);
% % idx2        = find(dnIDs>1577);
% % IDs(idx1)   = IDs(idx1)-2;
% % dnIDs(idx2) = dnIDs(idx2)-2;
% % 
% % % check if good
% % dIDs        = diff(IDs); find(dIDs>1)
% 
% % % if so, then reassign
% % for i = 1:length(IDs)
% %     newlinks(i).link_ID     = IDs(i);
% %     newlinks(i).ds_link_ID  = dnIDs(i);
% % end
