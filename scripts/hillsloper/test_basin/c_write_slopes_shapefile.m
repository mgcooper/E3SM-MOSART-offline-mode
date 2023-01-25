clean

opts    = const('save_shp',true,'plot_links',true);

% the reason this is needed is because the slopes are split into two from
% Jon, so in b_make_newslopes I combine them into one slope per link and
% save that as mosart_hillslopes so the orginal is preserved. Here I write
% shapefiles including a links file that is one polyline rather than
% individual lines per link. This could probably all be moved into
% b_make_newslopes.

% note that the 'slopes' structure used here is the 'mosart_slopes' whereas
% 'links' is the links that was modified in b_makenewslopes. the analogous
% 'slopes' that is modified in b_makenewslopes isn't dealt with here
% because it has two slopes per link. 

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% set paths
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
p.data  = setpath('interface/data/sag/hillsloper/test_basin/newslopes/');
p.save  = '/Users/coop558/mydata/interface/sag_basin/hillsloper/';
p.save  = [p.save 'test_huc12/slopes/'];

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% this makes a shapefile of the hillslopes in lat-lon and x-y
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% load the hillsloper data
load([p.data 'mosart_hillslopes']);  
slopesgeo   = mosartslopes; 
slopesmap   = slopesgeo;
linksgeo    = links;
linksmap    = links;

clear mosartslopes;

% LINKS
%~~~~~~~~~~~~~~~~~~~~~~~~

% rename fields
linksgeo    = renamestructfields(linksgeo,{'link_ID','ds_link_ID'},{'ID','dnID'});
linksmap    = renamestructfields(linksmap,{'link_ID','ds_link_ID'},{'ID','dnID'});

% remove non-scalar struct fields and unnecessary fields
rmfields    = {'hs_id','us_hs_ID','ds_hs_ID','us_conn_ID','ds_conn_ID','us_node_ID','ds_node_ID'};
linksgeo    = rmfield(linksgeo,rmfields);
linksmap    = rmfield(linksmap,rmfields);

% remove lat/lon from map version and x/y from geo version
linksgeo    = rmfield(linksgeo,{'X','Y'});
linksmap    = rmfield(linksmap,{'Lat','Lon'});

% SLOPES
%~~~~~~~~~~~~~~~~~~~~~~~~

% rename fields
slopesgeo   = renamestructfields(slopesmap,{'Lat_hs','Lon_hs'},{'Lat','Lon'});
slopesmap   = renamestructfields(slopesmap,{'X_hs','Y_hs'},{'X','Y'});

% remove non-scalar struct fields and unnecessary fields
rmfields    = {'X_hs','Y_hs','X_link','Y_link','Lat_link','Lon_link','lat','lon'};
slopesgeo   = rmfield(slopesgeo,rmfields);

% repeat for map data
rmfields    = {'Lat_hs','Lon_hs','X_link','Y_link','Lat_link','Lon_link','lat','lon'};
slopesmap   = rmfield(slopesmap,rmfields);

% remove the extra 'ele' classes - should be able to eventually delete
% these altogether
for n = 1:11
    slopesgeo   = rmfield(slopesgeo,['ele' num2str(n-1)]);
    slopesmap   = rmfield(slopesmap,['ele' num2str(n-1)]);
end

% this shows the links and slopes are ordered the same so I can copy ID and
% dnID fields from slopes to links 
if opts.plot_links == true
    for n = 1:numel(links)
        x_hs    = [slopesmap(n).X];
        y_hs    = [slopesmap(n).Y];
        x_ln    = [linksmap(n).X];
        y_ln    = [linksmap(n).Y];

        plot(x_hs,y_hs,'b'); hold on;
        plot(x_ln,y_ln,'r'); pause; 

    end
end


%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% this makes a shapefile of all the links as a single geometry
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% not sure this is needed
proj        = projcrs(3338,'Authority','EPSG');

% go through and create one list of all links with nan-separators
xmap = []; ymap = []; xgeo = []; ygeo = [];
for n = 1:numel(slopesgeo)
    ymap    = vertcat(ymap,nan,linksmap(n).Y');
    xmap    = vertcat(xmap,nan,linksmap(n).X');
    
    ygeo    = vertcat(ygeo,nan,linksgeo(n).Lat');
    xgeo    = vertcat(xgeo,nan,linksgeo(n).Lon');
end
% note: can't add metdata b/c it's a single polyline, so write two files

linegeo     = geoshape;
linegeo.Lat = ygeo;
linegeo.Lon = xgeo;

linemap     = mapshape;
linemap.X   = xmap;
linemap.Y   = ymap;

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% write the shapefiles, then use Qgis to define the projection
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if opts.save_shp == true
    shapewrite(slopesgeo,[p.save 'slopes_mosart_tmp_geo.shp']);
    shapewrite(linksgeo,[p.save 'links_mosart_tmp_geo.shp']);
    shapewrite(linegeo,[p.save 'streams_mosart_tmp_geo.shp']);
    
    shapewrite(slopesmap,[p.save 'slopes_mosart_tmp_aka.shp']);
    shapewrite(linksmap,[p.save 'links_mosart_tmp_aka.shp']);
    shapewrite(linemap,[p.save 'streams_mosart_tmp_aka.shp']);
end

