function mslopes = hillsloperToMosart(links, slopes, basins)
   %HILLSLOPERTOMOSART Convert hillsloper data tables to mosart data table.
   %
   % VERY IMPORTANT: If there is non-consecutive hs_ID numbering (which there
   % is for the full sag, hs_ID 427 is missing), then one cannot index into
   % slopes or basins in a loop from 1:numel(slopes) - possibly more
   % importantly, one cannot index into Data.Properties.CustomProperties.Area
   % using the hs_ID i.e., for i = 1:426, basins(i).area_km2 == Area(i), but
   % from 427:end, basins(i).area_km2 != Area(i). Thus, one has to use the hs_ID
   % and find the index in basins: basins([basins.hs_ID] == hs_ID).area_km2,
   % where hs_ID = links(i).hs_ID.
   %
   % TLDR: The loop is over links, so use hs_ID = links(n).hs_ID, then find the
   % element of slopes or basins with that hs_ID, don't indx into them with n

   % For the huc 12 I used the NAD 83 (2011) alaska albers which is 6393
   proj = projcrs(3338, 'Authority', 'EPSG');
   % projcrs(6393,'Authority','EPSG');

   % Define the fields
   fields = {
      'Geometry', 'BoundingBox', 'X_hs', 'Y_hs', 'X_link', 'Y_link', ...
      'Lat_hs', 'Lon_hs', 'Lat_link', 'Lon_link', 'latixy', 'longxy', ...
      'ID', 'dnID', 'hs_ID', 'fdir', 'frac', 'rslp', 'rlen', 'rdep', ...
      'rwid', 'rwid0', 'gxr', 'hslp', 'twid', 'tslp', 'area', ...
      ... 'areaTotal0', 'areaTotal', 'areaTotal2', ...
      'nr', 'nt', 'nh'};

   % Initialize the structure
   mslopes = geostructinit('Polygon', numel(links), 'fieldnames', fields);

   for n = 1:numel(links)

      % Get the hillslope ID associated with this reach and the hillslope att's
      hs_ID = links(n).hs_ID;

      % Get the basin (the merged +/- hillslope)
      hs_info = hillsloper.getslope(basins, hs_ID);

      % Compute combined area, area-weighted slope and elevation. Also use this
      % method for earlier versions where the "basins" table is unavailable.
      hs_merged = hillsloper.mergeslopes(slopes, hs_ID);

      % Get the positive and negative slope from "slopes". This method replaced
      % by area-weighted slope and elevation in mergeslopes.
      % [hs_p, hs_n] = hillsloper.getslope(slopes, hs_ID);

      % Pull out the area-weighted slope and elevation
      hslp = hs_merged.hslp;
      helev = hs_merged.helev_m;
      harea = hs_merged.harea_m2;

      % Can use this to double check
      % hillsloper.plotBasinLinks(basins, links, hs_ID); hold on
      % plot(rmnan([hs_merged.Lon]), rmnan([hs_merged.Lat]), ':')

      % pull out values needed for input file, convert km to m where needed
      id = links(n).link_ID;                       % -
      lati = nanmean([links(n).Lat]);              % degN
      long = nanmean([links(n).Lon]);              % degE
      dnid = links(n).ds_link_ID;                  % -
      rslp = round(links(n).slope, 8);             % 1
      rlen = round(links(n).len_km * 1e3, 0);      % m
      hslp = round(hslp, 8);                       % 1
      harea = round(harea, 0);                     % m2
      helev = round(helev, 0);                     % m
      uarea = round(hs_info.da, 0);                % m2

      % These fields are added in computeHillslopeTopo, not used in Sag v2.
      % hslp = round(double(hs_info.hslp), 4);
      % harea = round(double(hs_info.harea), 0);
      % helev = round(double(hs_info.helev), 0);

      % This wasn't in sag_basin version
      % Get lat/lon of the merged slopes. Do this here rather than mergeslopes
      % because the projection could change. The poly2cw thing prevents an extra
      % 90o from being appended to hslat, not sure why it happens.
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
      mslopes(n).Geometry     = hs_info.Geometry;
      mslopes(n).BoundingBox  = hs_info.BoundingBox;
      mslopes(n).X_hs         = hs_info.X;
      mslopes(n).Y_hs         = hs_info.Y;
      mslopes(n).X_link       = links(n).X;
      mslopes(n).Y_link       = links(n).Y;
      mslopes(n).Lat_hs       = hslt;
      mslopes(n).Lon_hs       = hsln;
      mslopes(n).Lat_link     = links(n).Lat;
      mslopes(n).Lon_link     = links(n).Lon;
      mslopes(n).latixy       = lati;
      mslopes(n).longxy       = long;
      mslopes(n).ID           = id;
      mslopes(n).dnID         = dnid;
      mslopes(n).hs_ID        = hs_ID;    % hillslope id, not needed for model
      mslopes(n).fdir         = 4;        % flow direction
      mslopes(n).Lat          = lati;
      mslopes(n).Lon          = long;
      mslopes(n).frac         = 1;        % fraction of cell included in study area
      mslopes(n).rslp         = rslp;     % river slope                     [-]
      mslopes(n).rlen         = rlen;     % main channel length             [m]
      mslopes(n).rdep         = rdep;     % main channel bankfull depth     [m]
      mslopes(n).rwid         = rwid;     % main channel bankfull width     [m]
      mslopes(n).rwid0        = rwid0;    % floodplain width                [m]
      mslopes(n).gxr          = 1;        % dummy, drainage density         [-]
      mslopes(n).hslp         = hslp;     % hillslope slope                 [-]
      mslopes(n).twid         = 2;        % dummy, trib width               [m]
      mslopes(n).tslp         = hslp;     % trib slope                      [-]
      mslopes(n).area         = harea;    % hillslope area                  [m2]
      % mosart(n).areaTotal0   = uarea;    % upstream
      % mosart(n).areaTotal    = uarea;    % upstream drainage area    [m2]
      % mosart(n).areaTotal2   = uarea;    % 'computed' upstream d.a.  [m2]
      mslopes(n).nr           = 0.05;     % manning's, river
      mslopes(n).nt           = 0.05;     % manning's, trib
      mslopes(n).nh           = 0.075;    % manning's, hillslope
   end

   % QA/QC checks
   mslopes = struct2table(mslopes);
   mslopes.rslp = max(min(mslopes.rslp(mslopes.rslp > 0)), mslopes.rslp);
   mslopes.hslp = max(min(mslopes.hslp(mslopes.hslp > 0)), mslopes.hslp);
end

%{

Just in case its useful or ends up being necessary, this is the full list. 

fields = {
      'Geometry', 'BoundingBox', 'X_hs', 'Y_hs', 'X_link', 'Y_link', ...
      'Lat_hs', 'Lon_hs', 'Lat_link', 'Lon_link', 'latixy', 'longxy', ...
      'ID', 'dnID', 'hs_ID', 'fdir', 'frac', 'rslp', 'rlen', 'rdep', ...
      'rwid', 'rwid0', 'gxr', 'hslp', 'twid', 'tslp', 'area', 'areaTotal0', ...
      'areaTotal', 'areaTotal2', 'nr', 'nt', 'nh', 'ele0', 'ele1', 'ele2', ...
      'ele3', 'ele4', 'ele5', 'ele6', 'ele7', 'ele8', ...
      'ele9', 'ele10', 'ele'
      };

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

%}
