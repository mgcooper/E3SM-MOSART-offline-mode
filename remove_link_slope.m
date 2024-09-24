function newlinks = remove_link_slope(newlinks,rm_link,us_link,ds_link,   ...
                        rp_link)

   % 1 Aug 2024
   % This was last edited 23 Oct 2021. It was in
   % myprojects/interface/matlab/archive/ , i.e., the project folder I never
   % used for actual code development (I moved the few functions in there to
   % +activelayer) 
   %
   % almost certainly can delete this.
   %
   % Below here are the notes which were already here.

    % NOTE: this version contains detailed notes that were removed from the
    % version i kept, regarding how to edit this function so that 'nodes'
    % would be updated so that the make_newlinks could be run again
                    
    %REMOVE_LINK Removes a link from a flow network and updates the
    %attributes to maintain connectivity
    %   rm_link     = id(s) to be removed
    %   us_links    = id(s) of links that flow into rm_link's upstream node
    %   ds_links    = id(s) of links that merge with rm_link's downstream node
    %   us_nodes    = rm_link's upstream node id
    %   ds_nodes    = rm_link's downstream node id
    %   rp_link     = id of link that replaces rm_link 
    
    % NOTE: if i want to first run these functions, then re-run the
    % make_newlinks function, then I might need to return edits to the
    % nodes shapefile that fix the connections between those fields and the
    % ones here
    
    % get the indices of the link to be removed and its replacement
    idxrm       = ismember([newlinks.link_ID],rm_link);
    idxrp       = ismember([newlinks.link_ID],rp_link);
    
    % get the id of the node to be removed and its replacement
    rm_node     = newlinks(idxrm).us_node_ID;
    rp_node     = newlinks(idxrp).us_node_ID;
    
    % get the id of the slope that drains to rm_link
    % not implemented at this time, see ds_link loop below
    % rm_slope    = newlinks(idxrm).ds_hs_ID;
    % the hs_id is the field that comes from jon's new script; the ds_hs_ID
    % above is from my post-processing using us/ds nodes. I might be able to
    % ignore us/ds hillslopes
    rm_slope    = newlinks(idxrm).hs_id;
    
% regarding rm_slope, the us_link(s) are not affected because their
% us_hs_ID are slopes upstream of their own slope, and their ds_hs_ID are
% their own slope and other slopes that drain into the us node of rm_link 

% however, ds_link(s) are affected, since their us_hs_ID includes the slope
% that is being removed

    for i = 1:length(us_link)
        idx     = ismember([newlinks.link_ID],us_link(i));
        idxi    = ismember([newlinks(idx).ds_conn_ID],rm_link);
        
        % make the replacements
        newlinks(idx).ds_link_ID   = rp_link;
        newlinks(idx).ds_node_ID   = rp_node;
        newlinks(idx).ds_conn_ID(idxi)    = rp_link;
    end

    % i don't think i have to have an ideal trifluence, as long as ds_hs_ID
    % and ds_conn_ID are consistent, meaning ds_conn_ID contains the links
    % that are attached to the hillslopes with ds_hs_ID
    
    % deal with links that merge with rm_link at its downstream node
    for i = 1:length(ds_link)
        idx     = ismember([newlinks.link_ID],ds_link(i));
        idxi    = ismember([newlinks(idx).ds_conn_ID],rm_link);
        idxia   = ismember([newlinks(idx).ds_hs_ID],rm_slope);
        idxib   = ismember([newlinks(idx).ds_hs_ID],-rm_slope);
        newlinks(idx).ds_conn_ID(idxi)    = [];       % remove entirely
        newlinks(idx).ds_hs_ID(idxia)     = [];       % remove entirely
        newlinks(idx).ds_hs_ID(idxib)     = [];       % remove entirely
    end

    % us_conn_id is supposed to have the links this link is connected to at
    % the us_node, and should match the values in nodes.conn
    % pretty sure i need to edit rp_link.us_conn_id
    % this is where the issue of defining this as a confluence vs
    % trifluence becomes important. for now, just remove the rm_link
    idxi        = ismember([newlinks(idxrp).us_conn_ID],rm_link);
    newlinks(idxrp).us_conn_ID(idxi)    = [];
 
    % also edit the us_hs_ID for the rp_link. this is where there could be
    % serious problems, if i need to reconstruct all upstream hillslopes
    % using us_hs_ID
    
    % the rp_link needs to have the rm_slope removed from its us_hs_ID and
    % replaced with the hs_ID of rp_node 
%     this did not quite work, because us_conn_ID includes the link itself,
%     so this ends up putting the hs_id of the link itself in us_hs_ID,
%     instead what I want is to put the ds_hs_ID from the two us_links that
%     are now feeding into this link, meaning us_hs_ID will have six
%     values, so we're back to the issue of allow a trifluence, the reason
%     is because of the two us_link's, we don't know which one we would
%     want to assign as the us_hs_id
%     us_conn     = newlinks(idxrp).us_conn_ID;
%     idxi        = ismember([newlinks.link_ID],us_conn);
%     idx         = find(idxi);
%     for i = 1:sum(idxi)
%         us_hs   = newlinks(idx(i)).ds_hs_ID;
%         us_hs_p = abs(us_hs(1));
%         us_hs_m = -abs(us_hs(1));
%         % of the idx's, one will already be in us_hs_ID
%         if ~ismember(us_hs,newlinks(idxrp).us_hs_ID)    
%             idxi_p      = ismember([newlinks(idxrp).us_hs_ID],rm_slope);
%             idxi_m      = ismember([newlinks(idxrp).us_hs_ID],-rm_slope);
%             newlinks(idxrp).us_hs_ID(idxi_p)    = us_hs_p;
%             newlinks(idxrp).us_hs_ID(idxi_m)    = us_hs_m;
%         end
%     end

    % at this point, the two us_link's and the ds_link are correct. they
    % are not defined as a trifluence, but there are no repeat hillslopes,
    % in short, the two us_links are a confluence with rp_link as the
    % downstream link, and ds_link is directly linked to rp_link, so the
    % sum of the ds_hs_ID in the two us_links and the ds_link together
    % correctly define the hillslopes upstream of the rp_link, 
    % HOWEVER, the us_hs_ID of the rp_link would need to have all three of
    % these hillslopes, for six entries, to technically be consistent with
    % the way us_hs_id is defined, and rp_node would also need to be
    % updated in the nodes table, 

    % instead of the above method, just remove the rm_slope
    idx_p       = ismember(newlinks(idxrp).us_hs_ID,rm_slope);
    idx_m       = ismember(newlinks(idxrp).us_hs_ID,-rm_slope);
    newlinks(idxrp).us_hs_ID(idx_p)     = [];
    newlinks(idxrp).us_hs_ID(idx_m)     = [];

    % maybe a solution is to make sure ds_hs_ID == rp_slope for the two
    % us_links and the ds_link
    
    
    % remove the orphan link
    newlinks(idxrm)     = [];
    % note that this changes the indices, so if anything were to follow
    % this, they would need to be updated

% notes from before putting the rm_slope back in ... might need two
% functions, one 'rm_link' and another 'rm_link_slope' or 'rm_slope'
%         not sure if this can be generalized to a function ... might need
%         an option, revisit after dealing with the other situation where
%         the link needs to be removed but there is not hillslope
%         idxia   = find([newlinks(idx).ds_hs_ID] == 1843);    % link 1275 (idx3)
%         idxib   = find([newlinks(idx).ds_hs_ID] == -1843);   % link 1275 (idx3)
%         newlinks(idx).ds_hs_ID(idxia)     = [];       % remove 1843
%         newlinks(idx).ds_hs_ID(idxib)     = [];       % remove -1843


    
end

