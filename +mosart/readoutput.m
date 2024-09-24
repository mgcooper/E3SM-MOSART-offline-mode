function mosartData = readoutput(pathname, kwargs)
   %READOUTPUT Read mosart .nc files and return the outlet discharge in m3/s
   %
   %  DATA = READOUTPUT(PATHNAME) returns the RIVER_DISCHARGE_OVER_LAND_LIQ
   %  data in the mosart nc output files saved in folder PATHNAME. The files
   %  are assumed to contain daily data with one file per year (annual files).
   %
   %  DATA = READOUTPUT(PATHNAME, VARNAME=VARLIST) returns the data for all
   %  variables in VARLIST which exist in the nc mosart output files.
   %
   %  DATA = READOUTPUT(_, 'monthly') returns the data for variable VAR
   %  in the in the nc mosart output files in PATHNAME.
   %
   % See also

   % this works if the data are daily, organized as annual files,
   % need to modify for monthly averages

   arguments
      pathname char {mustBeFolder} % the run/ dir
      kwargs.varname char = 'RIVER_DISCHARGE_OVER_LAND_LIQ'
      kwargs.filetype char {mustBeMember(kwargs.filetype, {'h1','h0'})} = 'h0'
      kwargs.basinOutletID double = []
      kwargs.subbasinOutletID double = []
      kwargs.basinOutletVarname = 'RIVER_DISCHARGE_TO_OCEAN_LIQ'
   end
   basinOutletID = kwargs.basinOutletID;
   subbasinOutletID = kwargs.subbasinOutletID;

   % main code
   filelist = dir(fullfile(pathname, ['*.mosart.' kwargs.filetype '*']));

   if isempty(filelist)
      error('no files found');
   end

   % read the nc info, make a list of variables, get lat/lon
   numfiles = numel(filelist);
   fileinfo = ncinfo(fullfile(filelist(1).folder, filelist(1).name));
   varnames = {fileinfo.Variables.Name};

   [lat, lon, x, y] = readCoordinates(filelist);

   % Read all of the data into one struct array.
   for n = numfiles:-1:1
      data(n) = ncreaddata( ...
         fullfile(pathname, filelist(n).name), varnames=varnames);
   end

   % Obtain the ID and dsID for each link, and set the outlet dsID nan.
   ID = data(1).GINDEX(:, 1);
   dsID = data(1).DSIG(:, 1);
   dsID(dsID == 0) = nan;

   % Locate the basin outlet ID
   basinOutletID = findbasinOutletID(basinOutletID, data(1));

   % Extract the RIVER_DISCHARGE_OVER_LAND_LIQ
   [Time, Discharge, Storage] = extractDischargeData(data, filelist, ...
      kwargs.varname, basinOutletID, kwargs.basinOutletVarname);
   
   % Reset numfiles to account for any missing data (see subfunction)
   numfiles = size(Discharge, 1);

   % If the data files are monthly, reshape to annual
   if size(Discharge, 2) == 30
      % This may require refactoring due to refactored ncreaddata which
      % automatically transposes the data with the time dimension last. 
      % All code outside this monthly data section has been refactored.
      [Time, Discharge, Davg, Dstd] = reshapeMonthlyData(Time, Discharge);
   else
      [Time, Discharge, Davg, Dstd] = reshapeDailyData(Time, Discharge);
   end

   % Subset the subbasin outlets
   try
      subbasinDischarge = Discharge(:, subbasinOutletID);
   catch
   end

   % Package output
   
   % Apr 2024 - do not assign the full "data" struct, which contains all of the
   % nc file data. Need to refactor this function to read all of the relevant 
   % mosart variables into a timetable. 
   % mosartData.data = data; 

   mosartData.T = Time;
   mosartData.outletDischarge = Discharge(:, basinOutletID);
   mosartData.D = Discharge;
   mosartData.Davg = Davg;
   mosartData.Dstd = Dstd;
   mosartData.info = fileinfo;
   mosartData.lat = lat;
   mosartData.lon = lon;
   mosartData.x = x;
   mosartData.y = y;
   mosartData.outID = basinOutletID;
   mosartData.units = 'm3 s-1';
   mosartData.S = Storage;
   mosartData.S_units = 'm3';
   mosartData.subbasinDischarge = subbasinDischarge;
   mosartData.subbasinOutletID = subbasinOutletID;
   
   % Convert the data to a timetable.
%    Discharge = timetable(Time, Discharge, VariableNames=string(ID));
% 
%    mosartData.Time = Time;
%    mosartData.Discharge = Discharge;
% 
%    mosartData.Discharge_annualAverage = Davg;
%    mosartData.Discharge_annualStandardDeviation = Dstd;
%    mosartData.fileinfo = fileinfo;
%    mosartData.lat      = lat;
%    mosartData.lon      = lon;
%    mosartData.x        = x;
%    mosartData.y        = y;
%    mosartData.outID    = basinOutletID;
%    mosartData.units    = 'm3 s-1';
%    mosartData.S        = Storage;
%    mosartData.S_units  = 'm3';
%    mosartData.subbasinD = subbasinDischarge;
%    mosartData.subbasinOutletID = subbasinOutletID;

   % Qmodavg = mean(reshape(Dmod,365,nyrs),2);
   % Tavg = datenum(Tobs(1:365));
   %
   % figure; plot(Davg(:,100)); hold on;
   % plot(Davg(:,100)+(2.*Dstd(:,100)./sqrt(nfiles)));
   % plot(Davg(:,100)-(2.*Dstd(:,100)./sqrt(nfiles)));
   %
   % figure; plot(T,D(:,100)); hold on;
   % for n = 1:nfiles
   %   plot(Tyrs(n,:),squeeze(Dyrs(n,:,100)),':','Color','r');
   % end
end
%%
function [T, D, S] = extractDischargeData(data, filelist, ...
      varname, outletID, outletVarname)
   
   % Retrieve dimensions
   numfiles = numel(data);
   [numcells, numdays] = size(data(1).(varname));
   
   % Initialize arrays to stitch the discharge into one multi-year timeseries.
   D = nan(numfiles, numcells, numdays); % years x cells x days
   S = nan(numfiles, numcells, numdays); % channel storage [m3]
   T = nan(numfiles, numdays);

   % mcdate is the actual calendar date, format is YYYYMMDD
   for n = 1:numel(data)
      try
         D(n, :, :) = data(n).(varname);
         T(n, :) = data(n).mcdate;
      catch
      end

      % Add the basin outlet, which is nan otherwise.
      try
         D(n, outletID, :) = data(n).(outletVarname)(outletID, :);
      catch
      end
   end

   % Mar 2024 - return channel storage too (hard coded for now)
   try
      S = transpose(horzcat(data(:).Main_Channel_STORAGE_LIQ));

      % % If I saved S the same way as D, this would do it:
      % S = permute(S, [2,1,3]);
      % S = reshape(S, size(S, 1) * size(S, 2), []);
      % % Not sure why I save D that way, so keep above for refactoring.
   catch ME
   end

   % % use this to plot one file (should be one year of data)
   % for n = 1:nfiles
   %    test = squeeze(D(n,:,:));
   %    plot(test(:,outID)); hold on; pause;
   % end
   %
   % Discharge = readalldischarge(data,ndays,ncells);

   % check if any files have all nan data
   for n = numfiles:-1:1
      allNan(n) = all(isnan(reshape(D(n, :, :), 1, [])));
   end

   % warn the user if any files have all nan data
   if any(allNan)
      nanfiles = filelist(allNan);
      for n = 1:sum(allNan)
         warning(['data all nan for file ' nanfiles(n).name])
      end
   end

   D = D(~allNan, :, :);
   T = T(~allNan, :);
end
%%
function basinOutletID = findbasinOutletID(basinOutletID, data)
   found = notempty(basinOutletID);
   if not(found)
      try
         basinOutletID = unique(data.OUTLETG(:));
         % also: basinOutletID = ID(isnan(dsID) | dsID==0);
      catch
         basinOutletID = mosart.findoutletID(data);
      end
   end
end
%%
function [lat, lon, x, y] = readCoordinates(filelist)
   
   lon = double( ...
      ncread(fullfile(filelist(1).folder, filelist(1).name), 'lon'));
   lat = double( ...
      ncread(fullfile(filelist(1).folder, filelist(1).name), 'lat'));

   % Project the lat/lon to alaska albers or fall back to utm
   % This seems unneccessary and error prone to fall back to utm so I 
   % commented that out and return empty x,y
   try
      proj_alaska_albers = projcrs(3338, 'Authority', 'EPSG');
      [x, y] = projfwd(proj_alaska_albers, lat, lon);
   catch ME
      warning( ...
         'Reprojection to lat lon failed, add Alaska Albers coordinates manually if needed.')
      x = []; y = [];
      % if strcmp(ME.identifier, 'MATLAB:license:checkouterror')
      %    [x, y] = ll2utm([lat, lon]); % use utm
      % end
   end
end
%%
function [T, D, Davg, Dstd] = reshapeDailyData(T, D)
   
   [nyears, ncells, ndays] = size(D);
   
   % D is (years/files x cells x days). If data is annual this computes
   % mean annual D and mean annual std dev (operate on dim 1, then transpose)
   Tyrs = datetime(T, 'ConvertFrom', 'yyyymmdd') - days(1);
   
   assertEqual(nyears, numel(unique(year(Tyrs))));
   
   % Average over years (down the first dimension)
   Davg = transpose(squeeze(mean(D, 1))); % ndays x ncells
   Dstd = transpose(squeeze(std(D, [], 1))); % ndays x ncells

   % Permute then reshape into a daily timeseries.
   D = permute(D, [3, 1, 2]); % ndays x nyears x ncells
   T = permute(T, [2, 1]); % ndays x nyears
   D = reshape(D, nyears * ndays, ncells);
   T = datetime(T(:), 'ConvertFrom', 'yyyymmdd');

   % Shift the calendar back one day
   T = T - days(1);
end

%%
function [T, D, Davg, Dstd] = reshapeMonthlyData(T, D)
   nyears = size(D, 1) * size(D, 2) / 365;

   if mod(nyears, 1) ~= 0
      % the monthly data files truncate the data but I am not sure how. for
      % the 1997-2003 runs the monthly files have 2550 values, but a no-leap
      % calendar has 2555. Prob best to abandon monthly files anyway. UPDATE:
      % the monthly files are written thirty days at a time, so each file
      % isn't a calendar month. There are 7 months with 31 days then subtract
      % two days for february and you get 5 days, which is the number missing
      % but thats for one year, so still not sure. method below is a hacky
      % fix but it appends 5 nan values at the end.
      D = permute(D, [2,1,3]);
      D = reshape(D, [], size(D,3));
      t1 = year(datetime(T(1), 'ConvertFrom', 'yyyymmdd'));
      t2 = year(datetime(T(end), 'ConvertFrom', 'yyyymmdd'));
      TT = transpose(datetime(t1,1,1):caldays(1):datetime(t2,12,31));
      T0 = datetime(reshape(transpose(T),size(D,1),1),'ConvertFrom','yyyymmdd');
      T0 = T0 - days(1);
      DD = array2timetable(D, 'RowTimes', T0);
      DD = retime(DD, TT, 'fillwithmissing');
      nyears = numel(unique(year(T0)));
      ndays = 365;
      D = reshape(table2array(rmleapinds(DD)), ndays, nyears, []);

      Tyrs = reshape(rmleapinds(TT), nyears, ndays);

      Davg = squeeze(mean(D, 2));
      Dstd = squeeze(std(D, [], 2));
      Dyrs = D;

      % put it in a long timeseries
      D = reshape(D, ndays * nyears, ncells);
      T = rmleapinds(TT);
   end
end
%%
function debug

   % loop over all vars and determine which ones have valid data
   testdata = data(1);
   allvars  = fieldnames(testdata);
   isallnanorzero = true(numel(allvars),1);

   for n = 1:numel(allvars)

      thisvar = allvars{n};
      thisdata = testdata.(thisvar);

      % if the var is lowercase or all nan or all zero, continue
      if strcmp(thisvar,lower(thisvar)) || all(isnan(thisdata(:))) || all(thisdata(:)==0)
         continue;
      end
      % otherwise, set isallnanorzero false
      isallnanorzero(n) = false;
   end

   % check the vars that aren't all nan or zero
   checkvars = allvars(~isallnanorzero);

   for n = 1:numel(checkvars)
      thisvar = checkvars{n};
      checkdata.(thisvar) = vertcat(data(:).(thisvar));
   end

   % These are the discharge and storage terms in checkdata
   Dvars = { ...
      'RIVER_DISCHARGE_OVER_LAND_ICE', ...
      'RIVER_DISCHARGE_OVER_LAND_LIQ', ...
      'RIVER_DISCHARGE_TO_OCEAN_ICE', ...
      'RIVER_DISCHARGE_TO_OCEAN_LIQ', ...
      'TOTAL_DISCHARGE_TO_OCEAN_LIQ'};

   Svars = { ...
      'Main_Channel_STORAGE_LIQ', ...
      'QSUB_LIQ', ...
      'STORAGE_LIQ'};

   % TLDR:
   %
   % equal: RIVER_DISCHARGE_TO_OCEAN_LIQ, TOTAL_DISCHARGE_TO_OCEAN_LIQ
   % nan: RIVER_DISCHARGE_OVER_LAND_LIQ, RIVER_DISCHARGE_OVER_LAND_ICE
   % zero: RIVER_DISCHARGE_TO_OCEAN_ICE
   %
   % equal: Main_Channel_STORAGE_LIQ, STORAGE_LIQ
   % zero: QSUB_LIQ

   isequal( ...
      checkdata.TOTAL_DISCHARGE_TO_OCEAN_LIQ(:, outID), ...
      checkdata.RIVER_DISCHARGE_TO_OCEAN_LIQ(:, outID))

   all(isnan( ...
      checkdata.RIVER_DISCHARGE_OVER_LAND_LIQ(:, outID)))
   all(isnan( ...
      checkdata.RIVER_DISCHARGE_OVER_LAND_ICE(:, outID)))

   max(checkdata.RIVER_DISCHARGE_TO_OCEAN_ICE(:, outID))
   min(checkdata.RIVER_DISCHARGE_TO_OCEAN_ICE(:, outID))


   % Plot the D vars
   figure; hold on
   styles = ["-", ":", "--", "-.", ":"];
   for n = 1:numel(Dvars)
      plot(checkdata.(Dvars{n})(:, outID), 'LineStyle', styles(n));
   end
   legend(strrep(Dvars, '_', ' '))

   % Plot the S vars
   figure; hold on
   styles = ["-", ":", "--", "-.", ":"];
   for n = 1:numel(Svars)
      plot(checkdata.(Svars{n})(:, outID), 'LineStyle', styles(n));
   end
   legend(strrep(Svars, '_', ' '))

   S1 = checkdata.Main_Channel_STORAGE_LIQ;
   S2 = checkdata.STORAGE_LIQ;

   % D1 = checkdata.RIVER_DISCHARGE_OVER_LAND_LIQ;
   D1 = checkdata.RIVER_DISCHARGE_TO_OCEAN_LIQ;
   D2 = checkdata.TOTAL_DISCHARGE_TO_OCEAN_LIQ;

   figure; hold on
   plot(S1(:, outID))
   plot(S2(:, outID), ':')
   legend('Main Channel Storage', 'Storage')

   figure; hold on
   plot(D1(:, outID))
   plot(D2(:, outID), ':')
   legend('RIVER DISCHARGE TO OCEAN LIQ', 'TOTAL DISCHARGE TO OCEAN LIQ')

   figure; hold on
   plot(cumsum(D(:, outID)))


   % These are the fieldnames of checkdata:
   % {'DSIG'                         }
   % {'GINDEX'                       }
   % {'MASK'                         }
   % {'Main_Channel_STORAGE_LIQ'     }
   % {'OUTLETG'                      }
   % {'QSUB_LIQ'                     }
   % {'RIVER_DISCHARGE_OVER_LAND_ICE'}
   % {'RIVER_DISCHARGE_OVER_LAND_LIQ'}
   % {'RIVER_DISCHARGE_TO_OCEAN_ICE' }
   % {'RIVER_DISCHARGE_TO_OCEAN_LIQ' }
   % {'STORAGE_LIQ'                  }
   % {'TOTAL_DISCHARGE_TO_OCEAN_LIQ' }

end

%%
function Discharge = readalldischarge(data,ndays,ncells)

   Dvars = { ...
      'RIVER_DISCHARGE_OVER_LAND_ICE', ...
      'RIVER_DISCHARGE_OVER_LAND_LIQ', ...
      'DIRECT_DISCHARGE_TO_OCEAN_ICE', ...
      'DIRECT_DISCHARGE_TO_OCEAN_LIQ', ...
      'RIVER_DISCHARGE_TO_OCEAN_ICE', ...
      'RIVER_DISCHARGE_TO_OCEAN_LIQ', ...
      'TOTAL_DISCHARGE_TO_OCEAN_ICE', ...
      'TOTAL_DISCHARGE_TO_OCEAN_LIQ'};

   nvars = numel(Dvars);
   nfiles = numel(data);

   % this would read all the data
   Dtemp = nan(ndays*nfiles,ncells,numel(Dvars));
   for n = 1:nfiles
      si = (n-1)*365+1;
      ei = n*365;
      thisdata = data(n);
      for m = 1:nvars
         thisvar = Dvars{m};
         data_m = thisdata.(thisvar);
         Dtemp(si:ei,:,m) = data_m;
         % to get the sum over all cells:
         % Dtemp(n,m,:) = nansum(data_m,2);
      end
   end

   % convert each tile to a table
   TileSum = nan(ncells,nvars);
   for n = 1:ncells
      thistile = ['tile_' num2str(n)];
      tiledata = squeeze(Dtemp(:,n,:));
      Tiles.(thistile) = array2table(tiledata,'VariableNames',Dvars);
      TileSum(n,:) = nansum(tiledata);
   end
   TileSum = array2table(TileSum,'VariableNames',Dvars);

   % % this would work but would just do it in the loop above
   % % now convert each page to a table
   % for n = 1:nvars
   %    thisvar = Dvars{m};
   %    Discharge.(thisvar) = array2table(Dtemp(:,:,n),'VariableNames',Dvars);
   % end

   % this just sums the data as a check
   Discharge = nan(nfiles,nvars);
   for n = 1:nfiles
      thisdata = data(n);
      for m = 1:nvars
         thisvar = Dvars{m};
         data_m = thisdata.(thisvar);
         Discharge(n,m) = nansum(data_m(:));
         % to get the sum over all cells:
         % Discharge(n,m,:) = nansum(data_m,2);
      end
   end
   Discharge = array2table(Discharge,'VariableNames',Dvars);
end

%%
function tf = skipdata(thisdata)

   % in matlab, a vector is a 2-d array that is either 1xN or Nx1
   tf = false;

   % this may not work b/c is* functions fail if the datatype is incompatible
   while tf == false
      tf = isscalar(thisdata);
      tf = isvector(thisdata);
      tf = istable(thisdata);
      tf = ischar(thisdata);
      tf = isstring(thisdata);
   end

   % if isscalar(thisdata) || istable(thisdata); continue; end
   % if skipdata(thisdata) == true; continue; end
end
