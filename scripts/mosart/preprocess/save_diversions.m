clean

% save the DRBC out-of-basin diversions by subbasin

% NOTE, I saved the out-of-basin diversions using the web map
% https://www.state.nj.us/drbc/programs/supply/use-demand-projections2060.html
% only four sub-basins have out-of-basin diversions


setpath('icom','data');

savedata = false;
pathdata = setpath('icom/DRBC','data');
pathsave = setpath('icom/dams/drbc/withdrawals','data');
filename = '2060report_data-release_v2110_DIV.xlsx';
filepath = fullfile(pathdata,filename);

% load the subbasins
load('drbc_subbasins.mat','Basins');

% the data is from 1990-2060
years = tocolumn(1990:2060);
Dates = datetime(years,1,1);

% the sheets are the huc-8 names
sheets = {'East Branch Delaware','Middle Delaware-Mongaup-Brodhea',   ...
   'Middle Delaware-Musconetcong','Upper Delaware'};
varnames = makevalidvarnames(sheets);

% init the data table
nyears = numel(years);
nhuc8s = numel(sheets);
Data = nan(nyears,nhuc8s);

% read the table of withdrawal data
for n = 1:nhuc8s
   
   sheet = sheets{n};
   opts = detectImportOptions(filepath,'Sheet',sheet);
   data = readfiles(filepath,'dataoutputtype','table','importopts',opts);
   Data = addcolumns(Data,data.Withdrawal,n);
   
end
clear data opts sheet

% the excel tab limits character length, so fix it here
irep = find(ismember(varnames,'Middle_DelawareMongaupBrodhea'));
varnames{irep} = 'Middle_DelawareMongaupBrodhead';

Diversions = array2timetable(Data,'RowTimes',Dates,'VariableNames',varnames);

if savedata == true
   save(fullfile(pathsave,'diversions.mat'),'Diversions');
end


%%

% added this june 2023 to write the table to file for tian

% load('/Users/coop558/work/data/icom/DRBC/withdrawals/diversions.mat')

% convert from MGD to m3/s
Diversions.East_Branch_Delaware = mgd2cms(Diversions.East_Branch_Delaware);
Diversions.Middle_DelawareMongaupBrodhead = mgd2cms(Diversions.Middle_DelawareMongaupBrodhead);
Diversions.Middle_DelawareMusconetcong = mgd2cms(Diversions.Middle_DelawareMusconetcong);
Diversions.Upper_Delaware = mgd2cms(Diversions.Upper_Delaware);

writetable(Diversions,'DRBC_IBT_cms.xlsx')



%% below here is in-basin demand

% % this confirms the subbasin names match those in the shapefile:
% basins = makevalidvarnames(unique({Basins.Meta.HUC8_Name}))';
% sum(ismember(varnames,basins))


% reformat the data to a consistent time period
yrmin = min(data.YEAR);
yrmax = max(data.YEAR);
Dates = datetime(yrmin,1,1):calyears(1):datetime(yrmax,1,1);

nhuc8s = numel(ID);
nyears = numel(Dates);
WDGW = nan(nyears,nhuc8s);
WDSW = nan(nyears,nhuc8s);
CUGW = nan(nyears,nhuc8s);
CUSW = nan(nyears,nhuc8s);
   
for n = 1:nhuc8s
   
   idxdata  = ismember(data.BASIN_ID,ID.BASIN_ID{n});
   data     = data(idxdata,:);
   
   idxGW    = data.DESIGNATION == "GW";
   idxSW    = data.DESIGNATION == "SW";
   
   dataGW   = data(idxGW,{'WD_MGD','CU_MGD'});
   dataSW   = data(idxSW,{'WD_MGD','CU_MGD'});
   timeGW   = datetime(data.YEAR(idxGW),1,1);
   timeSW   = datetime(data.YEAR(idxSW),1,1);
   
   dataGW   = retime(table2timetable(dataGW,'RowTimes',timeGW),Dates);
   dataSW   = retime(table2timetable(dataSW,'RowTimes',timeSW),Dates);
   
   WDGW(:,n)  = dataGW.WD_MGD;
   WDSW(:,n)  = dataSW.WD_MGD;
   CUGW(:,n)  = dataGW.CU_MGD;
   CUSW(:,n)  = dataSW.CU_MGD;

end

clear Data

vars        = makevalidvarnames(ID.BASIN_ID);
data.WDGW   = array2timetable(WDGW,'RowTimes',Dates,'VariableNames',vars);
data.WDSW   = array2timetable(WDSW,'RowTimes',Dates,'VariableNames',vars);
data.CUGW   = array2timetable(CUGW,'RowTimes',Dates,'VariableNames',vars);
data.CUSW   = array2timetable(CUSW,'RowTimes',Dates,'VariableNames',vars);


% plot an example
basins   = {'DB001','DB038','DB044','DB147'};
vars     = {'WDGW','WDSW','CUGW','CUSW'};
labels   = {'GW withdrawals (MGD)','SW withdrawals (MGD)', ...
            'GW consumption (MGD)','SW consumption (MGD)'};

macfig;
for n = 1:4
   
   subtight(2,2,n,'style','fitted');
   
   var   = vars{n};
   
   for m = 1:numel(basins)
      plot(data.(var).Time,data.(var).(basins{m}),'-o'); hold on;
   end
   
   formatPlotMarkers;
   ylabel(labels{n});
   legend(basins,'Location','northeast','Orientation','horizontal');
end



if savedata == true
   save([pathsave 'withdrawals'],'Data','Meta');
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% macfig;
% for n = 1:nbasins
%    
%    idxdata  = ismember(Data.BASIN_ID,ID.BASIN_ID{n});
%    idxmeta  = ismember(Meta.BASIN_ID,ID.BASIN_ID{n});
%    data      = Data(idxdata,:);
%    name     = Meta.STREAMS(idxmeta);
%    
%    plot(data.YEAR,data.WD_MGD,'-o'); title(name); pause; clf;
% end


% test     = grouptransform(Data,ID,

