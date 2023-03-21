clean

opts = const('save_data',false,'plot_map',true,'plot_slopes',true);

%% set paths and read in the data

pathdata = getenv('USER_MOSART_DOMAIN_DATA_PATH');
pathsave = getenv('USER_MOSART_DOMAIN_DATA_PATH');

load(fullfile(pathdata,'sag_hillslopes'));

% export_fig('temp.png', '-nocrop', '-transparent', '-png','-r400')

% %%%%% stuff from sag_basin version %%%%
% % see notes at end
% pathtopo = '/Users/coop558/mydata/e3sm/topo/topo_toolbox/flow_network/basin/';
% % only needed for plotting
% % load([pathtopo 'sag_dems'],'R5','Z5');    % 160 m dem, for plotting
% % R = R5; Z = Z5; clear R5 Z5
%
% % not sure why this was here
% max([newlinks.us_da_km2])*1000*1000
% find(max([newlinks.us_da_km2])==[newlinks.us_da_km2])
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Step 1: make a newlinks table with upstream/downstream link connectivity

[newlinks,inlet_ID,outlet_ID] = make_newlinks(links,nodes);

% definitions
% hs_id         = id of the hillslope in which a link exists
% us_hs_id      = hillslopes upstream of the upstream node
% ds_hs_id      = hillslopes upstream of the downstream node


%% Step 2: Custom fixes to orphan links


% Step 2: fix orphan links and nodes (detailed notes are in _test_rmlink)
% links 199 and 1396 flow to 1394 instead of 1274
rm_link     = 1274;         % remove link, orphan to be deleted
us_link     = [199, 1396];  % upstream link(s), into orphan at us node
ds_link     = 1275;         % downstream link(s), merge w/orphan at ds node
rp_link     = 1394;         % replacement link, downstream of orphan
slope_flag  = true;         % remove the slope that drains to rm_link?
newlinks    = remove_link   ...
   (   newlinks,   ...
   rm_link,    ...
   us_link,    ...
   ds_link,    ...
   rp_link,    ...
   slope_flag  );

% repeat for links with duplicate hillslopes, meaning slope_flag == false
rm_link     = 1579;
rp_link     = 2477;
us_link     = [121, 2479];  % find these in us_conn_ID
ds_link     = 927;          % find this in ds_conn_ID
slope_flag  = false;
newlinks    = remove_link   ...
   (   newlinks,   ...
   rm_link,    ...
   us_link,    ...
   ds_link,    ...
   rp_link,    ...
   slope_flag  );

% repeat for the next one
rm_link     = 1324;
rp_link     = 2682;
us_link     = [178, 1323];  % find these in us_conn_ID
ds_link     = 2681;         % find these in ds_conn_ID
slope_flag  = false;
newlinks    = remove_link(  ...
   newlinks,   ...
   rm_link,    ...
   us_link,    ...
   ds_link,    ...
   rp_link,    ...
   slope_flag  );

% check the fields (can be used after each function call above to verify)
% idx0        = find([newlinks.link_ID]==rm_link);
% idx1        = find([newlinks.link_ID]==us_link(1));
% idx2        = find([newlinks.link_ID]==us_link(2));
% idx3        = find([newlinks.link_ID]==ds_link);
% idx4        = find([newlinks.link_ID]==rp_link);
% newlinks(idx0)  % should be empty
% newlinks(idx1)  % should not have any rm_link values, ds_link_ID = rp_link
% newlinks(idx2)
% newlinks(idx3)
% newlinks(idx4)  % should not have any rm_link values, us_link_ID = rp_link


%% Step 3: Remove orphan slopes (merge slope 1843 with slope 2010)


% first, remove unneccesary fields
% slopes      = rmfield(slopes,{'link_id','outlet_idx','bp','endbasin'});

% id's of the hillslopes
rm_slope    = 1843;
rp_slope    = 2010;
rp_flag     = 1;

% merge the slopes
newslopes   = remove_slopes(slopes,rm_slope,rp_slope,rp_flag);

% now length(newlinks) = 3266 * 2 = 6532 = length(newslopes)
% length(unique([newlinks.link_ID]))
% length(unique([newslopes.hs_id]))/2


%% Step 4: renumber the ID field to go from 1 -> # slopes

% test - renumber hillslopes to be consecutive
IDs         = [newlinks.link_ID];
dnIDs       = [newlinks.ds_link_ID];

% figure out where the numbering goes astray
dIDs        = diff(IDs); find(dIDs>1)
idx1        = IDs<1274;
idx2        = dnIDs<1274;
IDs(idx1)   = IDs(idx1)+1;
dnIDs(idx2) = dnIDs(idx2)+1;

% repeat. this time, numbering is good up to 1323, then needs -1 up to 1577
dIDs        = diff(IDs); find(dIDs>1)
idx1        = IDs>1323 & IDs<1578;
idx2        = dnIDs>1323 & dnIDs<1578;
IDs(idx1)   = IDs(idx1)-1;
dnIDs(idx2) = dnIDs(idx2)-1;

% repeat. this time, numbering is good up to 1577, needs -1
dIDs        = diff(IDs); find(dIDs>1)
idx1        = find(IDs==1578);
idx2        = find(dnIDs==1578);
IDs(idx1)   = IDs(idx1)-1;
dnIDs(idx2) = dnIDs(idx2)-1;

% repeat. this time, numbering is good up to 1577, then needs -2 to the end
dIDs        = diff(IDs); find(dIDs>1)
idx1        = find(IDs>1577);
idx2        = find(dnIDs>1577);
IDs(idx1)   = IDs(idx1)-2;
dnIDs(idx2) = dnIDs(idx2)-2;

% check, then reassign
dIDs        = diff(IDs); find(dIDs>1)

for i = 1:length(IDs)
   newlinks(i).link_ID     = IDs(i);
   newlinks(i).ds_link_ID  = dnIDs(i);
end


%% Step 5: build a table with the MOSART input file information


% modify the mosart_hillslopes to be a mapstruct
proj    = projcrs(3338,'Authority','EPSG');

for i = 1:length(links)
   xi          = mosart(i).X_hs;
   yi          = mosart(i).Y_hs;
   [lati,loni] = projinv(proj,xi,yi);

   mosart(i).Lat       = lati;
   mosart(i).Lon       = loni;
   mosart(i).Geometry  = 'Polygon';
end


for i = 1:length(newlinks)

   % hillslope associated with this reach
   slope_id            = newlinks(i).hs_id;
   slope_info          = merge_slopes(slopes,slope_id);
   %   idxp                = find(ismember([newslopes.hs_id],slope_id));
   %   idxm                = find(ismember([newslopes.hs_id],-slope_id));

   % pull out values needed for input file, convert km to m where needed
   lat                 = mean([newlinks(i).Lat]);
   lon                 = mean([newlinks(i).Lon]);
   id                  = newlinks(i).link_ID;
   dnid                = newlinks(i).ds_link_ID;
   rslp                = roundn(newlinks(i).slope,-4);
   rlen                = roundn(newlinks(i).len_km*1e3,0);
   hslp                = roundn(double(slope_info.hslp),-4);
   harea               = roundn(double(slope_info.harea),0);
   helev               = roundn(double(slope_info.helev),0);
   usarea              = roundn(newlinks(i).us_da_km2*1e6,-4);

   % previously i divided hslp/tslp by 100, but i think that's wrong

   % put the values into a structure
   mos(i).bbox         = slope_info.BoundingBox;
   mos(i).X_hs         = slope_info.X;
   mos(i).Y_hs         = slope_info.Y;
   mos(i).X_link       = newlinks(i).X;
   mos(i).Y_link       = newlinks(i).Y;
   mos(i).latixy       = lat;
   mos(i).longxy       = lon;
   mos(i).ID           = id;
   mos(i).dnID         = dnid;
   mos(i).hsID         = slope_id; % hillslope id, not needed for model
   mos(i).fdir         = 4;        % flow direction
   mos(i).lat          = lat;
   mos(i).lon          = lon;
   mos(i).frac         = 1;        % fraction of cell included in study area
   mos(i).rslp         = rslp;     % river slope               [-]
   mos(i).rlen         = rlen;     % river width               [m]
   mos(i).rdep         = 2;        % dummy, bankfull depth     [m]
   mos(i).rwid         = 50;       % dummy, bankfull width     [m]
   mos(i).rwid0        = 50;       % dummy, floodplain width   [m]
   mos(i).gxr          = 1;        % dummy, drainage density   [-]
   mos(i).hslp         = hslp;     % hillslope slope           [-]
   mos(i).twid         = 2;        % dummy, trib width         [m]
   mos(i).tslp         = hslp;     % trib slope                [-]
   mos(i).area         = harea;    % hillslope area            [m2]
   mos(i).areaTotal0   = usarea;   % upstream
   mos(i).areaTotal    = usarea;   % upstream drainage area    [m2]
   mos(i).areaTotal2   = usarea;   % 'computed' upstream d.a.  [m2]
   mos(i).nr           = 0.05;     % manning's, river
   mos(i).nt           = 0.05;     % manning's, trib
   mos(i).nh           = 0.075;    % manning's, hillslope
   mos(i).ele0         = helev;
   mos(i).ele1         = helev;
   mos(i).ele2         = helev;
   mos(i).ele3         = helev;
   mos(i).ele4         = helev;
   mos(i).ele5         = helev;
   mos(i).ele6         = helev;
   mos(i).ele7         = helev;
   mos(i).ele8         = helev;
   mos(i).ele9         = helev;
   mos(i).ele10        = helev;
   mos(i).ele          = helev;


   % if I wanted to compute a 'node' on the link at the location nearest
   % the hillslope center of mass:
   %     xpc                 = nanmean(links(ilink).X);
   %     ypc                 = nanmean(links(ilink).Y);
   %     polyriv             = polyshape(links(ilink).X,links(ilink).Y);
   %     [vid,bid,i]         = nearestvertex(polyriv,xpc,ypc);
   %     xrc                 = polyriv.Vertices(vid,1);
   %     yrc                 = polyriv.Vertices(vid,2);
   %     newslopes(n).X_node = xrc;
   %     newslopes(n).Y_node = yrc;

end

% reassign the structure name
mosartslopes = mos; clear mos;


%% save the data

if savedata == true
   save([pathsave 'mosart_hillslopes'],'mosartslopes','newlinks','newslopes');
end

if opts.save_data == true
   save(fullfile(pathsave,'mosart_hillslopes'),'mosartslopes','links','slopes');
end


%% notes to keep, until sorted out

% this is based on make_newslopes_test, which is a slightly cleaned-up
% version of make_newslopes, which was left in some disarray after trying
% to convert Jon's hillsloper output to mosart input format

% ID and dnID should be the hillslopes and/or nodes that represent the
% hillslopes, so that runoff is routed from slope to slope even if no link
% exists within a hillslope ... then the link attributes correspond to a
% given hillslope ID, but can be empty and the model will still work, I
% think

% NOTE: use newlinks.ds_hs_ID to determine the hillslopes that contribute
% to the ds_link, because 1) ds_hs_ID is the hillslopes that contribute to
% the downstream node of a link, meaning the hillslopes that contribute to
% the ds_link, 2) it was more complicated to fix us_hs_ID than ds_hs_ID
% in the remove_link function, and 3) us_hs_ID has nan for headwater nodes,
% also see the notes in the remove_link function.

% This might not work though ... otoh, since i know each link, and the
% hillslope in which each link exists, and its ds link, I should be able to
% piece it together


%% plot the nodes and label them

% % jitter for the labels
% jitx        = (R.XWorldLimits(2)-R.XWorldLimits(1))/80;
% jity        = (R.YWorldLimits(2)-R.YWorldLimits(1))/80;
% latlims     = [min([nodes.Lat]) max([nodes.Lat])];
% lonlims     = [min([nodes.Lon]) max([nodes.Lon])];
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

% technically this plots all the link ids on the slopes, but is too slow
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


%% The next two plots are for checking the algorithm


% if plot_check == true
%
% % 1. plot the headwater (inlet) and outlet nodes
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


%% plot the nodes


% this is extremely slow with the entire sag basin

% if plot_map == true
%
% % jitter for the labels
% jitx    = (R.XWorldLimits(2)-R.XWorldLimits(1))/80;
% jity    = (R.YWorldLimits(2)-R.YWorldLimits(1))/80;
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


%% below here is mostly testing to sort out the links

% %     the us_hs_id for a given link is actually the us_hs_id for the
% %     us_link, so if I have a link and the ds link, i can go to the ds
% %     link, get the us-hs-id and put that with the link ... not sure why i
% %     got this idea ... does not appear to wrk
%
% % link id = 319, get the ds link ID (headwater example)
% idx     = find([newlinks.link_ID] == 319);
% dsID    = newlinks(idx).ds_link_ID;
% idx     = find([newlinks.link_ID] == dsID);
% usHS    = newlinks(idx).us_hs_ID;
%
% newlinks(idx)
%
% % for headwater links, this will return four values, need to remove the
%
% % link id = 318, get the ds link ID (non-headwater example)
% idx     = find([newlinks.link_ID] == 318);
% dsID    = newlinks(idx).ds_link_ID;
% idx     = find([newlinks.link_ID] == dsID);
% usHS    = newlinks(idx).us_hs_ID;
%
% i       = find(ismember([slopes.hs_id],2762))
% slopes(i)

% link 0 drains to link 2605. I have this in my link_ID and ds_link_ID
% fields.

% these notes were up above in the newlinks loop
% notes - us_conn_id will have three values at a confluence, the link
% itself, and the two upstream links. Therefore, this link is the
% downsteream link for the two values of us_conn_id that are not the
% link itself. The while loop goes and adds this link as the ds

%     ds_hs_id tells us the hillslopes that contribute to the node that
%     this link contributes to ... which, if we just want the hillslopes
%     that contribute to each node, is sufficient ... but we also need to
%     know the links associated with each hillslope, I think, to compute
%     the reach-specific values of length, width, slope, etc.

%     can I start with a link, go to the ds_node, get the us conn
%     link = 319

%     the problem is that the link ID


%%

% commenting this out for now
% newlinks    = rmfield(newlinks,{'id','ds_node_id','us_node_id'});

% [([newlinks.link_ID])' ([newlinks.link_dnID])']
% [([newslopes.ID])' ([newslopes.dnID])']

% these were here when I was not using shaperead, before I realized the
% benefits of maintaining the geostruct format
% newlinksT   = struct2table(newlinks);
% newlinksT   = movevars(newlinksT,'link_dnID','After','link_ID');


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
% for i = 1:length(newlinks)
%     if length(newlinks(i).us_hs_ID) == 4
%         check1  = [check1;i];
%     end
% end
%
% check2 = [];
% for i = 1:length(inlet_ID)
%     % get the index for this inlet ID
%     this_inlet_idx  = find([newlinks.link_ID] == inlet_ID(i));
%     this_dnID       = newlinks(this_inlet_idx).link_dnID;
%     this_dn_idx     = find([newlinks.link_ID] == this_dnID);
%     check2          = [check2;this_dn_idx];
% end
%
%
% check1 = [];
% for i = 1:length(inlet_ID)
%     % get the index for this inlet ID
%     this_inlet_idx  = find([newlinks.link_ID] == inlet_ID(i));
%     this_dnID       = newlinks(this_inlet_idx).link_dnID;
%     this_dn_idx     = find([newlinks.link_ID] == this_dnID);
%     inlet_dnID(i,1) = this_dnID;
%     if length(newlinks(this_dn_idx).us_hs_ID) == 4
%         check1      = [check1;this_dn_idx];
%     end
% end
%
% for i = 1:length(newlinks)
%     if length([newlinks(i).us_hs_ID]) == 4
%         check2(i,1) = 1;
%     else
%         check2(i,1) = 0;
%     end
% end

% alternative syntax for better code interpretation
%     this_link_id            = links(n).id;
%     this_links_us_node_id   = links(n).us_node_id;
%     this_links_ds_node_id   = links(n).ds_node_id;
%     this_links_us_node_idx  = find(ismember([nodes.id],us_node_id));
%     this_links_ds_node_idx  = find(ismember([nodes.id],ds_node_id));
%     this_links_us_slope_id  = nodes(i_us).hs_id;
%     this_links_ds_slope_id  = nodes(i_ds).hs_id;
%     this_links_us_link_conn = nodes(i_us).conn;
%     this_links_ds_link_conn = nodes(i_ds).conn;
%==========================================================================
%% build a table that combines the information needed to determine flow
%==========================================================================

% OK I THINK I KNOW WHAT HAPPENED. The "convoluted way I was doing it"
% comment below is when I just brute-force id'd the dnID and used the
% hs_merge array to merge the hillslopes. Then, at some point, I figured
% out the methods that are above, in newlinks, namely the
% length(us_conn_id)>1 condition, which, I think, was the missing piece of
% the puzzle to determine the flow network (together with the inletID and
% outletID conditions).

% But I stopped there, and did not finish the script to the point where a
% 'newslopes' structure gets built. Instead, I used the brute force
% newslopes, and went full time on getting the model to run.

% SO, to pick up, I need to figure out how to use the info in newlinks
% above to build the input file, ideally without mergin any hillslopes, but
% I think that will be impossible until we get new shapefiles with a link
% in each hillslope


% % this confirms the total area of the slopes in units of m2
% for i = 1:length(newslopes)
%     xi  = newslopes(i).X;
%     yi  = newslopes(i).Y;
%     pi  = polyshape(xi,yi);
%     ai(i) = area(pi);
% end
% sum(ai) = 12962255025
