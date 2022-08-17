function newlinks = remove_link(newlinks,rm_link,us_link,ds_link,   ...
                        rp_link,slope_flag)
    %REMOVE_LINK Removes a link from a flow network and updates the
    %attributes to maintain connectivity
    %   rm_link     = id(s) to be removed
    %   us_links    = id(s) of links that flow into rm_link's upstream node
    %   ds_links    = id(s) of links that merge with rm_link's downstream node
    %   us_nodes    = rm_link's upstream node id
    %   ds_nodes    = rm_link's downstream node id
    %   rp_link     = id of link that replaces rm_link 
    %   slope_flag  = remove the slope associated with rm_link
    
    % NOTE: if i want to first run these functions, then re-run the
    % make_newlinks function, then I might need to return edits to the
    % nodes shapefile that fix the connections between those fields and the
    % ones here
    
    % NOTE: the output of this function is such that the two us_links are
    % treated as a confluence with rp_link, whereas the one ds_link is
    % treated as a link that flows directly into rp_link. the fields are
    % consistent in this way, but the linkages between the fields in the
    % original 'nodes', 'links', and 'slopes' tables are broken (but could
    % be fixed, see detailed notes in archive)
    
    % get the indices of the link to be removed and its replacement
    idxrm       = ismember([newlinks.link_ID],rm_link);
    idxrp       = ismember([newlinks.link_ID],rp_link);
    
    % get the us_link's and ds_link. although this works, to be careful, i
    % am keeping us_link and ds_link as inputs
%     idxi        = newlinks(idxrm).us_conn_ID~=rm_link;
%     us_link     = newlinks(idxrm).us_conn_ID(idxi);
%     idxi        = ~ismember(newlinks(idxrm).ds_conn_ID,[rm_link rp_link]);
%     ds_link     = newlinks(idxrm).ds_conn_ID(idxi);
    
    % get the id of the node to be removed and its replacement
    rm_node     = newlinks(idxrm).us_node_ID;
    rp_node     = newlinks(idxrp).us_node_ID;
    
    % get the id of the slope that drains to rm_link
    if slope_flag == true
        rm_slope    = newlinks(idxrm).hs_id;
    end
    
    % replace the ds link/node/conn in the us_link's
    for i = 1:length(us_link)
        idx     = ismember([newlinks.link_ID],us_link(i));
        idxi    = ismember([newlinks(idx).ds_conn_ID],rm_link);
        
        % make the replacements
        newlinks(idx).ds_link_ID        = rp_link;
        newlinks(idx).ds_node_ID        = rp_node;
        newlinks(idx).ds_conn_ID(idxi)  = rp_link;
    end
    
    % deal with links that merge with rm_link at its downstream node
    for i = 1:length(ds_link)
        idx     = ismember([newlinks.link_ID],ds_link(i));
        idxi    = ismember([newlinks(idx).ds_conn_ID],rm_link);
        if slope_flag == true
            idxia   = ismember([newlinks(idx).ds_hs_ID],rm_slope);
            idxib   = ismember([newlinks(idx).ds_hs_ID],-rm_slope);
        else
            idxia   = [];
            idxib   = [];
        end
        newlinks(idx).ds_hs_ID(idxia)     = [];       % remove entirely
        newlinks(idx).ds_hs_ID(idxib)     = [];       % remove entirely
        newlinks(idx).ds_conn_ID(idxi)    = [];       % remove entirely
    end

    % remove rm_link from the us_conn_ID field
    idxi        = ismember([newlinks(idxrp).us_conn_ID],rm_link);
    newlinks(idxrp).us_conn_ID(idxi)    = [];

    % remove rm_slope from rp_link's us_hs_ID
    if slope_flag == true
        idx_p       = ismember(newlinks(idxrp).us_hs_ID,rm_slope);
        idx_m       = ismember(newlinks(idxrp).us_hs_ID,-rm_slope);
        newlinks(idxrp).us_hs_ID(idx_p)     = [];
        newlinks(idxrp).us_hs_ID(idx_m)     = [];
    end

    % remove the orphan link
    newlinks(idxrm)     = [];
    % note that this changes the indices, so if anything were to follow
    % this, they would need to be updated
end

