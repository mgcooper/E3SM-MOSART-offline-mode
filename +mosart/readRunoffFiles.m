function runoff = readRunoffFiles(sitename, simyears, opts)
   %READRUNOFFFILES Read MOSART runoff forcing files
   %
   %  runoff = readRunoffFiles(sitename, simyears)
   %  runoff = readRunoffFiles(sitename, simyears, 'casename', casename)
   %  runoff = readRunoffFiles(sitename, simyears, 'runid', runid)
   %
   % The filenames need to be named with the following protocol:
   %
   %  runoff_<sitename>_<YYYY>.nc
   %
   % The files need to be saved in the following directory:
   %
   %  USER_E3SM_FORCING_PATH/<sitename>/<casename>/<runid>
   %
   % It is fine if CASENAME and/or RUNID are not provided, an empty char will be
   % inserted in their place.
   %
   % See also: mosart.readConfigFiles

   arguments
      sitename (1, :) char
      simyears (1, :) double
      opts.casename = 'ats' % 'ats'
      opts.runid = 'sag_basin' % sag_basin
   end
   filepath = getenv('USER_E3SM_FORCING_PATH');
   casename = opts.casename;
   runid = opts.runid;

   for n = 1:numel(simyears)

      thisyear = num2str(simyears(n));
      filename = ['runoff_' sitename '_' thisyear '.nc'];

      filename = fullfile(filepath, sitename, casename, runid, filename);

      assert(isfile(filename))

      runoff.(['runoff_' thisyear]) = ncreaddata(filename);
   end
end
