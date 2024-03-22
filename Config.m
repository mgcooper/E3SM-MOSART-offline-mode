function Config(sitename)
   % CONFIG set user configuration, environment variables, etc.
   %
   %  See also Setup

   % set environment variables to find data

   % NOTE: _v2 is the latest hillsloper

   % NOTE: For an ats runoff configuration, need to set:
   % USER_MOSART_DOMAIN_NAME
   % USER_ATS_VERSION
   % USER_ATS_DATA_PATH

   arguments
      sitename (1, :) char = 'sag_basin'
   end

   thispath = fileparts(mfilename('fullpath'));

   % domain name
   setenv('USER_MOSART_DOMAIN_NAME', ...
      sitename ...
      );

   % root path where data exists
   setenv('USER_DATA_PATH', ...
      '/Users/coop558/work/data' ...
      );

   % path to mosart template files
   setenv('USER_MOSART_TEMPLATE_PATH', ...
      '/Users/coop558/work/data/e3sm/templates' ...
      );

   % path to runoff forcing files
   setenv('USER_MOSART_RUNOFF_PATH', ...
      '/Users/coop558/work/data/e3sm/forcing' ...
      );

   % march 2024 - makes more sense to call it E3SM_FORCING
   setenv('USER_E3SM_FORCING_PATH', ...
      '/Users/coop558/work/data/e3sm/forcing' ...
      );

   % path to domain/mosart config files
   setenv('USER_E3SM_CONFIG_PATH', ...
      '/Users/coop558/work/data/e3sm/config' ...
      );

   % testbed folder ignored by git (see .git/info/exclude)
   setenv('MOSART_TESTBED', ...
      fullfile( ...
      thispath,'testbed') ...
      );

   % [keys,vals] = getuserpaths;


   % -------- INTERFACE CONFIG --------

   % Note: rather than append subdirs to getenv('USER_DATA_PATH'), all paths below
   % here are defined explicitly for clarity.

   % ATS output version
   setenv('USER_ATS_VERSION', ...
      'huc0802_gauge15906000_frozen' ...
      );

   % path to ATS runoff data
   setenv('USER_ATS_DATA_PATH', ...
      '/Users/coop558/work/data/interface/ATS' ...
      );

   % path to HILLSLOPER data files
   switch getenv('USER_MOSART_DOMAIN_NAME')

      case 'sag_basin'

         % hillsloper data files
         setenv('USER_HILLSLOPER_DATA_PATH', ...
            ['/Users/coop558/work/data/interface/hillsloper/sag_basin/' ...
            'IFSAR-Hillslopes-v2']);

         % post-processed hillsloper (used to define the mosart domain)
         setenv('USER_MOSART_DOMAIN_DATA_PATH', ...
            ['/Users/coop558/work/data/interface/hillsloper/sag_basin/' ...
            'IFSAR-Hillslopes-v2/mosart']);

         % elevation data
         setenv('USER_DOMAIN_TOPO_DATA_PATH', ...
            '/Users/coop558/work/data/interface/GIS_data/IFSAR/IfSAR_basin');

      case 'trib_basin'

         % hillsloper output files
         setenv('USER_HILLSLOPER_DATA_PATH', ...
            '/Users/coop558/work/data/interface/hillsloper/trib_basin/Data');

         % post-processed hillsloper (used to define the mosart domain)
         setenv('USER_MOSART_DOMAIN_DATA_PATH', ...
            '/Users/coop558/work/data/interface/hillsloper/trib_basin/mosart');

         % elevation data
         setenv('USER_DOMAIN_TOPO_DATA_PATH', ...
            getenv('USER_HILLSLOPER_DATA_PATH'));

      case 'test_basin'

         % hillsloper output files
         setenv('USER_HILLSLOPER_DATA_PATH', ...
            ['/Users/coop558/work/data/interface/hillsloper/test_basin/' ...
            'hillsloper-master-4/Data/huc_190604020404/akalbers']);

         % post-processed hillsloper (used to define the mosart domain)
         setenv('USER_MOSART_DOMAIN_DATA_PATH', ...
            ['/Users/coop558/work/data/interface/hillsloper/test_basin/' ...
            'hillsloper-master-4/mosart']);

         % elevation data
         setenv('USER_DOMAIN_TOPO_DATA_PATH', ...
            getenv('USER_HILLSLOPER_DATA_PATH'));
   end

   % % path to MOSART template files
   % setenv('USER_MOSART_TEMPLATE_PATH', ...
   %    '/Users/coop558/work/data/interface/ATS/' ...
   %    );

end
