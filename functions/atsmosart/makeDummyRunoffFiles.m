function Info = makeDummyRunoffFiles( ...
      site_name, ...
      first_year, ...
      final_year, ...
      path_runoff_files, ...
      save_files, ...
      varargin)
   %MAKEDUMMYRUNOFFFILE
   %
   % this makes dummy runoff files for the year before and after the first and
   % last year to deal with the weird mosart thing where it doesn't run the last
   % year

   withwarnoff('MATLAB:imagesci:netcdf:varExists')

   opts = optionParser('nobackups', varargin(:));
   copy_backups = opts.nobackups == false;

   % process the inputs
   fname_prfx = ['runoff_' site_name];

   start_year = first_year-1;
   extra_year = final_year+1;

   % build file names to copy the first-year file to one before
   fname_first_year = [fname_prfx '_' num2str(first_year) '.nc'];
   fname_start_year = [fname_prfx '_' num2str(start_year) '.nc'];

   % build file names to copy the final-year file to one after
   fname_final_year = [fname_prfx '_' num2str(final_year) '.nc'];
   fname_extra_year = [fname_prfx '_' num2str(extra_year) '.nc'];

   % append the full path
   fname_first_year = fullfile(path_runoff_files, fname_first_year);
   fname_start_year = fullfile(path_runoff_files, fname_start_year);
   fname_final_year = fullfile(path_runoff_files, fname_final_year);
   fname_extra_year = fullfile(path_runoff_files, fname_extra_year);

   % read the schema for the start-year and final-year files that will be copied
   copy_schema_start_year = ncinfo(fname_first_year);
   copy_schema_extra_year = ncinfo(fname_final_year);

   % edit the time schema for the dummy start-year and extra-year files
   time_schema_start_year = ['days since ' num2str(start_year) '-01-01 00:00:00'];
   time_schema_extra_year = ['days since ' num2str(extra_year) '-01-01 00:00:00'];

   % put the edited values in the schema
   copy_schema_start_year.Variables(3).Attributes(3).Value = time_schema_start_year;
   copy_schema_extra_year.Variables(3).Attributes(3).Value = time_schema_extra_year;

   % DO THE COPY
   if save_files == true

      % back up the duplicates if they exist, unless told not to
      if copy_backups == true
         if isfile(fname_start_year)
            fname_start_year_backup = backupfile(fname_start_year);
            copyfile(fname_start_year,fname_start_year_backup);
         end

         if isfile(fname_extra_year)
            fname_extra_year_backup = backupfile(fname_extra_year);
            copyfile(fname_extra_year,fname_extra_year_backup);
         end
      end

      % copy the first/final files to the start/extra files
      copyfile(fname_first_year, fname_start_year);
      copyfile(fname_final_year, fname_extra_year);

      % write the schema - note that the filename will auto-update
      ncwriteschema(fname_start_year, copy_schema_start_year);
      ncwriteschema(fname_extra_year, copy_schema_extra_year);

   end

   % re-read the new schema and send it back
   Info.new_schema_start_year = ncinfo(fname_start_year);
   Info.new_schema_extra_year = ncinfo(fname_extra_year);
end

% % write the data - only needed to write a new file, instead of the copy/paste
% copy_data = ncreaddata(fname_first_year);
% ncwrite(fname_start_year,'xc',copy_data.xc);
% ncwrite(fname_start_year,'yc',copy_data.yc);
% % ncwrite(fname_start_year,'xv',copy_data.xv);
% % ncwrite(fname_start_year,'yv',copy_data.yv);
% ncwrite(fname_start_year,'time',copy_data.time);
% ncwrite(fname_start_year,'QDRAI',copy_data.QDRAI);
% ncwrite(fname_start_year,'QOVER',copy_data.QOVER);

% % repeat for extra year
% copy_data = ncreaddata(fname_final_year);
% ncwrite(fname_extra_year,'xc',copy_data.xc);
% ncwrite(fname_extra_year,'yc',copy_data.yc);
% % ncwrite(fname_extra_year,'xv',copy_data.xv);
% % ncwrite(fname_extra_year,'yv',copy_data.yv);
% ncwrite(fname_extra_year,'time',copy_data.time);
% ncwrite(fname_extra_year,'QDRAI',copy_data.QDRAI);
% ncwrite(fname_extra_year,'QOVER',copy_data.QOVER);

% read the data to check it
% info = ncinfo(pasteFile);
% dat = ncread(['runoff_trib_basin_' num2str(n) '.nc'],'time' );
% dat = dat+1;
% ncwrite(['runoff_trib_basin_' num2str(n) '.nc'],'time',dat);


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% og methods below here

% copyFile    = 'runoff_trib_basin_2002.nc';
% pasteFile   = 'runoff_trib_basin_2003.nc';
% copy_data   = ncreaddata(copyFile);
% copy_schema = ncinfo(copyFile);
% copy_schema.Variables(3).Attributes(3).Value = 'days since 2003-01-01 00:00:00';
%
% ncwriteschema(pasteFile,copy_schema);
%
% % this is only needed if the system copy/paste ahsn't already been done
% ncwrite(pasteFile,'xc',copy_data.xc);
% ncwrite(pasteFile,'yc',copy_data.yc);
% ncwrite(pasteFile,'time',copy_data.time);
% ncwrite(pasteFile,'QDRAI',copy_data.QDRAI);
% ncwrite(pasteFile,'QOVER',copy_data.QOVER);

% % repeat for 1997
% copyFile    = 'runoff_trib_basin_1998.nc';
% pasteFile   = 'runoff_trib_basin_1997.nc';
% copy_data   = ncreaddata(copyFile);
% copy_schema = ncinfo(copyFile);
% copy_schema.Variables(3).Attributes(3).Value = 'days since 1997-01-01 00:00:00';
%
% ncwriteschema(pasteFile,copy_schema);
%
% info = ncinfo(pasteFile);

% dat = ncread(['runoff_trib_basin_' num2str(n) '.nc'],'time' );
% dat = dat+1;
% ncwrite(['runoff_trib_basin_' num2str(n) '.nc'],'time',dat);


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

% test = ncreaddata('runoff_trib_basin_2002.nc');
% info = ncinfo('runoff_trib_basin_2002.nc');
%
% min(test.QDRAI(:))
% max(test.QDRAI(:))
% sum(isnan(test.QDRAI(:)))
% sum(isinf(test.QDRAI(:)))
