
% this makes dummy runoff files for the year before and after the first and
% last year to deal with the weird mosart thing where it doesn't run the
% last year

cd('/Users/coop558/myprojects/e3sm/sag/input/hru/trib_basin/ats/huc0802_gauge15906000_nopf');

% first copy the 1998 file to 1997 and 2002 to 2003 if htey have not been already
% system('cp runoff_trib_basin_1998.nc runoff_trib_basin_1997.nc');
% system('cp runoff_trib_basin_2002.nc runoff_trib_basin_2003.nc');

% % I COMMENTED THIS OUT SINCE THE NEXT PART BELOW SHOWS THAT THE ATTRIBUTE
% FIELD IS DAYS SINCE YYYY-01-01 00:00:00 THEREFORE DAY 1 SHOULD BE 0 NOT 1

% % the 'time' variable is just 0:364, this loop just adds 1 to each day and
% % rewrites the time variable only
% for n = 1997:2003
%     
%    sch = ncinfo(['runoff_trib_basin_' num2str(n) '.nc'] );
%    dat = ncread(['runoff_trib_basin_' num2str(n) '.nc'],'time' );
%    dat = dat+1;
%    
%    ncwrite(['runoff_trib_basin_' num2str(n) '.nc'],'time',dat);
% end

test = ncreaddata('runoff_trib_basin_2002.nc');
info = ncinfo('runoff_trib_basin_2002.nc');

min(test.QDRAI(:))
max(test.QDRAI(:))
sum(isnan(test.QDRAI(:)))
sum(isinf(test.QDRAI(:)))

% this 
copyFile    = 'runoff_trib_basin_2002.nc';
pasteFile   = 'runoff_trib_basin_2003.nc';
copyData    = ncreaddata(copyFile);
sch         = ncinfo(copyFile);
sch.Variables(3).Attributes(3).Value = 'days since 2003-01-01 00:00:00';

ncwriteschema(pasteFile,sch);

% % this is only needed if the system copy/paste ahsn't already been done
% ncwrite(pasteFile,'xc',copyData.xc);
% ncwrite(pasteFile,'yc',copyData.yc);
% ncwrite(pasteFile,'time',copyData.time);
% ncwrite(pasteFile,'QDRAI',copyData.QDRAI);
% ncwrite(pasteFile,'QOVER',copyData.QOVER);

% repeat for 1997
copyFile    = 'runoff_trib_basin_1998.nc';
pasteFile   = 'runoff_trib_basin_1997.nc';
copyData    = ncreaddata(copyFile);
sch         = ncinfo(copyFile);
sch.Variables(3).Attributes(3).Value = 'days since 1997-01-01 00:00:00';

ncwriteschema(pasteFile,sch);


info = ncinfo(pasteFile);

% dat = ncread(['runoff_trib_basin_' num2str(n) '.nc'],'time' );
% dat = dat+1;
% ncwrite(['runoff_trib_basin_' num2str(n) '.nc'],'time',dat);