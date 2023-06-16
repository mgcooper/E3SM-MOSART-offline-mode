clean

% This makes the bar chart of demand by sector. It was in mk_wm_demand. I
% resaved here, and removed from there and replaced mk_wm_demand with the new
% remapped weights and consumptive use stuff.

%% read in the data

% GCAM
load(fullfile( ...
   getenv('ACTIVE_PROJECT_DATA_PATH'),'matfiles','GCAM_waterdemand'), ...
   'TWD');

% DRBC
load(fullfile( ...
   setpath('icom/dams/drbc/withdrawals','data'),'withdrawals'), ...
   'Withdrawals','Meta');

% % plot the GCAM data
Lat = TWD.Properties.CustomProperties.Lat;
Lon = TWD.Properties.CustomProperties.Lon;

% figure; 
% scatter(Lon,Lat,20,mean(table2array(TWD),1),'filled');
% colorbar;

%% process the GCAM data

% the GCAM data is m3/s posted monthly, convert to m3/s posted annually
GCAM = retime(TWD,'yearly','mean');
GCAM = rowsum(GCAM,'addcolumn',true);

% % confirm I do the calculation correctly
% test = sum(table2array(TWD),2,'omitnan'); % m3/s for the basin, monthly
% test = reshape(test,12,[]);
% test = sum(test.*86400.*30)./(365.25*86400);


%% process the DRBC data

% use the sectors that overlap:
% DRBC: PWS (w/wo SSD), PWR, IND, IRR
% GCAM: municipal, electricity, industrial, agriculture+livestock
sectors = {'PWS','PWR','IND','IRR'};
DRBC = nan(size(Withdrawals.PWS.WDGW,1),numel(sectors));
for n = 1:numel(sectors)
   wdws = table2array(Withdrawals.(sectors{n}).WDSW);
   DRBC(:,n) = mgd2cms(sum(wdws,2,'omitnan'));
end

% convert to cms then sum for comparison with GCAM
Time = Withdrawals.PWS.WDSW.Time;
DRBC = array2timetable(DRBC,'RowTimes',Time,'VariableNames',sectors);
DRBC = rowsum(DRBC,'addcolumn',true);

DRBC_PWS = sum(mgd2cms(table2array(Withdrawals.PWS.WDSW)),2,'omitnan');

%%

figure; 
bar(year(DRBC.Time),[DRBC.PWS DRBC.PWR DRBC.IND DRBC.IRR],0.5,'stack'); hold on;
plot(year(DRBC.Time),DRBC.RowSum,'k-o','Marker','square');
plot(year(GCAM.Time),GCAM.RowSum,'m-o','Marker','square'); formatPlotMarkers;
legend('Public Water Supply (DRBC)','Power Generation (DRBC)', ...
   'Industrial (DRBC)','Irrigation (DRBC)','All Sectors (DRBC)',...
   'All Sectors (GCAM)','Location','nw','FontSize',12);
xlim([1989 2018])
ylim([0 150])
ylabel('Total Water Demand (m3/s)')
title('Delaware River Basin')
% copygraphics(gcf);

%% exclude PWS and IND

figure; 
bar(year(DRBC.Time),[DRBC.PWS DRBC.IRR],0.5,'stack'); hold on;
plot(year(GCAM.Time),GCAM.RowSum,'m-o','Marker','square'); formatPlotMarkers;
legend('Public Water Supply (DRBC)','Irrigation (DRBC)',...
   'All Sectors (GCAM)','Location','nw','FontSize',12);
xlim([1989 2018])
ylim([0 30])
ylabel('Water Demand (m3/s)')
title('Delaware River Basin')
% copygraphics(gcf);


%%

% figure;
% plot(year(GCAM.Time),GCAM.RowSum,'m-o','Marker','square'); formatPlotMarkers;

% % for testing:
% % stackedData = [DRBC.PWS DRBC.PWR DRBC.IND DRBC.IRR];
% % stackedData = cat(3,stackedData,stackedData);
% % stackedData = permute(stackedData,[1,3,2]);
% % stackedBarPlot(stackedData,{'one','two'});

% %%

% % plot one basin
% figure; plot(Withdrawals.PWS.WDGW,'Time','DB001')

% % basin sum 
% PWS_mgd = sum(table2array(Withdrawals.PWS.WDSW),2,'omitnan');
% PWS_cms = mgd2cms(PWS_mgd);






% %% read in the GCAM data

% pathdata = setpath('e3sm/compyfs/inputdata/waterdemand/','data');

% list = dir(fullfile([pathdata '*.nc']));
% info = ncinfo([pathdata list(1).name]);
% lat = ncread([pathdata list(1).name],'lat');
% lon = ncread([pathdata list(1).name],'lon');

% %% grid the GCAM data

% [LON,LAT] = meshgrid(lon,lat);
% LAT = flipud(LAT);

% % TWD = nan([size(LAT),numel(list)]);
% TWD = nan([size(LAT),12]);
% for n = 1:12
%    dat = ncread(fullfile(pathdata,list(n).name),'totalDemand');
%    TWD(:,:,n) = flipud(permute(dat,[2,1]));
% end
% TWD0 = mean(TWD,3,'omitnan');

% % confirm the orientiation
% % figure; scatter(LON(:),LAT(:),20,TWD0(:),'filled');

% %% map the data onto the hex mesh

% Mesh = jsondecode(fileread(getenv('USER_HEXWATERSHED_MESH_JSONFILE_FULLPATH')));
% [ID,dnID] = hexmesh_dnID(Mesh);
% [latc,lonc,numc] = hexmesh_centroids(Mesh);
% [latv,lonv,numv] = hexmesh_vertices(Mesh);

% % wrap the lon to 360
% lonc = wrapTo360(lonc);
% lonv = wrapTo360(lonv);

% % for reference
% % [latmin,latmax] = bounds(LAT(:))
% % [lonmin,lonmax] = bounds(LON(:))
% [latmin,latmax] = bounds(latc(:));
% [lonmin,lonmax] = bounds(lonc(:));


% %% plot the data
% try
%    usamap conus
%    scatterm(LAT(:),LON(:),20,TWD0(:),"filled");
%    geobox([latmin,latmax],[lonmin,lonmax]);
% catch
%    figure;
%    scatter(LON(:),LAT(:),20,TWD0(:),"filled");
%    geobox([latmin,latmax],[lonmin,lonmax]);
% end

% %% clip gcam to drb shape

% Sdrbc = loadgis('DELW.shp');
% X = wrapTo360(Sdrbc.X);
% Y = Sdrbc.Y;
% P = polyshape(X,Y);

% % clip one file to get the indices
% [Z0,I] = clipRasterByPoly(TWD0,LON,LAT,P,'sum');
% % nansum(TWD0(I))

% for n = 1:size(TWD,3)
%    %Z(n) = clipRasterByPoly(TWD,LON,LAT,P,'areasum');
%    dat = TWD(:,:,n);
%    dat = dat(:);
%    Z(n) = sum(dat(I),'omitnan');
% end
   
% figure; 
% % geoshow(Sdrbc); hold on; plot(P);
% plot(X,Y); hold on; plot(P);
% scatter(LON(I),LAT(I))

% % Z is in units of m3/s summed over the basin
% % Z is m3/s, summed over all grid cells in the basin. convert to mgd
% Zmgd = cms2mgd(Z);

% % maybe I need to multiply by the number of days per month and then sum?
% sum(Zmgd.*30) % this is the total volume per year in units million gallons

% % annual average water demand in units mgd - 472.6 mgd
% sum(Zmgd.*30)./365.25;

% % so this shows that the total water demand for this month is ~10^9, whereas the
% % WDSW sum is ~10^11, so now I need to figure out if the data is apples to
% % apples

% %% read in the DRBC data

% pathsave = setpath('icom/dams/drbc/withdrawals','data');
% load(fullfile(pathsave,'withdrawals'),'Withdrawals','Meta');

% % use the sectors that overlap:
% % DRBC: PWS (w/wo SSD), PWR, IND, IRR
% % GCAM: municipal, electricity, industrial, agriculture+livestock

% % now I would need to map the GCAM data onto the 127 sub-basins, so instead, I
% % could just compare the entire basin
% sectors = {'PWS','PWR','IND','IRR'};
% DRBC = nan(size(Withdrawals.PWS.WDGW,1),numel(sectors));
% for n = 1:numel(sectors)
%    dat = table2array(Withdrawals.(sectors{n}).WDSW);
%    DRBC(:,n) = sum(dat,2,'omitnan');
% end

% % plot one basin
% figure; plot(Withdrawals.PWS.WDGW,'Time','DB001')

% % basin sum 
% PWS_mgd = sum(table2array(Withdrawals.PWS.WDSW),2,'omitnan');
% PWS_cms = mgd2cms(PWS_mgd);
% % PWS_cmd = convertunits(PWS_mgd.*10^6,'galUS','m^3'); % mgd -> m3/d
% % PWS_cms = convertunits(PWS_cmd,'s','day'); % m3/d -> m3/s

% % copare with gcam:
% figure; plot(DRBC.Time,PWS_cms); 



% % gettableunits(WDSW)
