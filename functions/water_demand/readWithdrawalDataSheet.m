function Data = readWithdrawalDataSheet(filepath,sheet)
%readWithdrawalDataSheet read the table of withdrawal data

fopts = detectImportOptions(filepath,'Sheet',sheet);
iData = readfiles(filepath,'dataoutputtype','table','importopts',fopts);
iData = sortrows(iData,'BASIN_ID');
hucID = unique(iData(:,'BASIN_ID'));

% reformat the data to a consistent time period
yrmin = min(iData.YEAR);
yrmax = max(iData.YEAR);
Dates = datetime(yrmin,1,1):calyears(1):datetime(yrmax,1,1);

nbasins = numel(hucID);
nyears = numel(Dates);
WDGW = nan(nyears,nbasins);
WDSW = nan(nyears,nbasins);
CUGW = nan(nyears,nbasins);
CUSW = nan(nyears,nbasins);

% % just to confirm sheet A-1 is just PWS
% sectors = unique(Data.SECTOR);
% cats = unique(Data.CATEGORY);

for n = 1:nbasins

   % read the rows for this basin
   idx = ismember(iData.BASIN_ID,hucID.BASIN_ID{n});
   dat = iData(idx,:);

   % subset the GW and SW data for this basin, 
   try
      idxGW = dat.DESIGNATION == "GW";
      idxSW = dat.DESIGNATION == "SW";
   catch
      % for now don't deal with self-supplied domestic, its the only case where
      % we will end up here
   end

   dataGW = dat(idxGW,{'WD_MGD','CU_MGD'});
   dataSW = dat(idxSW,{'WD_MGD','CU_MGD'});
   timeGW = datetime(dat.YEAR(idxGW),1,1);
   timeSW = datetime(dat.YEAR(idxSW),1,1);

   dataGW = retime(table2timetable(dataGW,'RowTimes',timeGW),Dates);
   dataSW = retime(table2timetable(dataSW,'RowTimes',timeSW),Dates);

   WDGW(:,n) = dataGW.WD_MGD;
   WDSW(:,n) = dataSW.WD_MGD;
   CUGW(:,n) = dataGW.CU_MGD;
   CUSW(:,n) = dataSW.CU_MGD;

end

% package output
vars = makevalidvarnames(hucID.BASIN_ID);
Data.WDGW = array2timetable(WDGW,'RowTimes',Dates,'VariableNames',vars);
Data.WDSW = array2timetable(WDSW,'RowTimes',Dates,'VariableNames',vars);
Data.CUGW = array2timetable(CUGW,'RowTimes',Dates,'VariableNames',vars);
Data.CUSW = array2timetable(CUSW,'RowTimes',Dates,'VariableNames',vars);
