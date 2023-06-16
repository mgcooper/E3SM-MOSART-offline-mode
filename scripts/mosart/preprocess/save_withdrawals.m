clean

% save the DRBC water withdrawal data by subbasin

% need to re-run this for all sheets

% NOTE consumptive use (CU) is water demand (WD) divided by 10. In sheet A-1 I
% had a column where I divided WD by 10 and confirmed it equaled the CU column,
% but I deleted it b/c it interferes with the filereader belwo

pathdata = setpath('icom/DRBC','data');
pathsave = setpath('icom/dams/drbc/withdrawals','data');
filename = '2060report_data-release_v2110.xlsx';
filepath = fullfile(pathdata,filename);

% read all sheet names
allsheets = sheetnames(filepath);

%% read the first three sheet which are metadata

% Sheet 1 - the table index
opts = detectImportOptions(filepath,'Sheet',allsheets(1),'NumHeaderLines',3);
Index = readfiles(filepath,'dataoutputtype','table','importopts',opts);

% the Index can be used as a lookup table to associate the remaining sheet names
% with the information contained in them. For example:
% Index.Table(1) % A-1
% Index.Sector(1) % PWS, the demand sector for the data in sheet A-1
% Index.Details(1) % more information about the data that sheet A-1 contains

% the sheet has missing values for Sector after each first entry, fill them in:
Index = fillmissing(Index,"previous");

% Sheet 2 - Definitions
opts = detectImportOptions(filepath,'Sheet',allsheets(2));
Definitions = readfiles(filepath,'dataoutputtype','table','importopts',opts);

% Sheet 3 - Version, skip this

% Sheet 3 - Metadata table with sub-basin IDs and stream names
opts = detectImportOptions(filepath,'Sheet',allsheets(4));
Meta = readfiles(filepath,'dataoutputtype','table','importopts',opts);

%% read the data sheets

% Each sector has:
% - one sheet for historical water demand and use for the DRB
% - one sheet for projected water demand and use for the DRB
% - one sheet for projected water demand and use for the Southeastern
% Pennsylvania Groundwater Protected Area (SEPA-GWPA)
%
% The power sector has two sub-categories:
% - Thermoelectric
% - Hydroelectric


% datasheets = sheets(5:end); % also Index.Table

% Sheets below have BASIN_ID, DESIGNATION (GW vs SW), WD_MGD, CU_MGD columns

% we may not want self-supplied domestic. also its the only one without the
% SW/GW designation
sheets_historic = { ...
   'A-1', ...  % public water supply
...'A-4', ...  % self-supplied domestic
   'A-6', ...  % thermoelectric
   'A-9', ...  % hydroelectric
   'A-11', ... % industrial
   'A-14', ... % mining
   'A-17', ... % irrigation
   'A-22', ... % other
   };

% get all common headers - runs slow so below sets them
% headers = readtableheaders(filepath,sheets_historic);
headers = ["BASIN_ID","CATEGORY","CU_MGD","DESIGNATION","GWPA_ID","SECTOR", ...
   "STATE","WD_MGD","YEAR"];

% read the data
for n = 1:numel(sheets_historic)
   sheet = sheets_historic{n};
   sector = cell2mat(Index.Sector(ismember(Index.Table,sheet)));
   Data.(sector) = readWithdrawalDataSheet(filepath,sheet);
end

%% check the data

% from the report, not considering out-of-basin diversions, the annual average
% CU should be ~286 mgd, and they get CU by dividing WD by 10, so this shows
% we're about on target b/c I did not save the SSD is not

sectors = fieldnames(Withdrawals);
WDSW_mgd = nan(size(Withdrawals.PWS.WDGW,1),numel(sectors));
for n = 1:numel(sectors)
   wdsw = table2array(Withdrawals.(sectors{n}).WDSW);
   WDSW_mgd(:,n) = sum(wdsw,2,'omitnan');
end

% this shows the annual average CU is ~240 mgd so with SSD it would probably be
% close to the reported value
WDSW_mgd_Sum = rowsum(WDSW_mgd);
mean(WDSW_mgd_Sum./10)



%% save the data

Withdrawals = Data;
if savedata == true
   save(fullfile(pathsave,'withdrawals'),'Withdrawals','Meta');
end

%%

% I think the reason I only read A-1 originally is b/c I thought it was the
% "total water use" but it is public water supply (PWS) so maybe not ... also
% some sheets are not related to water demand at all, such as A5 which is power
% generation, but others like A6 are the water demand by the power sector,
%
% I think I can loop over all sheets and exclude those without WD_MGD and/or
% CU_MGD variable names. Also, MOD_WD_MGD and MOD_CU_MGD are the modeled
% (projected) demands


% plot an example
basins = {'DB001','DB038','DB044','DB147'};
vars   = {'WDGW','WDSW','CUGW','CUSW'};
labels = {'GW withdrawals (MGD)','SW withdrawals (MGD)', ...
   'GW consumption (MGD)','SW consumption (MGD)'};

macfig;
for n = 1:4

   subtight(2,2,n,'style','fitted');

   var = vars{n};

   for m = 1:numel(basins)
      plot(Data.(var).Time,Data.(var).(basins{m}),'-o'); hold on;
   end

   formatPlotMarkers;
   ylabel(labels{n});
   legend(basins,'Location','northeast','Orientation','horizontal');
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


% test = grouptransform(Data,ID,
