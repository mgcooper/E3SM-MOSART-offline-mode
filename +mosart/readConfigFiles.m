function config = readConfigFiles(sitename, whichfiles, opts)
   %READCONFIGFILES

   arguments
      sitename = 'sag_basin'
      whichfiles (1, :) cell {mustBeMember(whichfiles, ...
         {'domain', 'mosart'})} = {'domain', 'mosart'}
      opts.casename = '' % 'ats'
      opts.runid = '' % sag_basin
   end
   filepath = getenv('USER_E3SM_CONFIG_PATH');
   casename = opts.casename;
   runid = opts.runid;

   for n = 1:numel(whichfiles)

      thisfile = whichfiles{n};

      switch lower(thisfile)

         case 'domain'

            filename = ['domain_' sitename '_' casename '.nc'];

         case 'mosart'

            filename = ['MOSART_' sitename '_' casename '.nc'];

         otherwise
            error('unrecognized file')
      end

      % Remove empty casename
      filename = strrep(filename, '_.nc', '.nc');
      filelist.(thisfile) = fullfile(filepath, filename);
   end

   for n = 1:numel(whichfiles)
      thisfile = whichfiles{n};
      config.(thisfile) = ncreaddata(filelist.(thisfile));
   end

   % Also return the filelist
   config.filelist = filelist;

   % % This is how I hand coded it before automating it as above
   % mosart_file = fullfile(filepath, ['MOSART_' sitename '.nc']);
   % domain_file = fullfile(filepath, ['domain_' sitename '.nc']);
   % mosart_data = ncreaddata(mosart_file);
   % domain_data = ncreaddata(domain_file);
end
