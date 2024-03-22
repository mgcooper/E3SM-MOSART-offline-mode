function sagData = loadSagData(sitename)

   arguments
      sitename (1, :) char { ...
         mustBeTextScalar, ...
         mustBeMember(sitename, ...
         {'sag_basin', 'trib_basin', 'test_basin'})} ...
         = 'sag_basin'
   end

   % Note: This is a hacky way to load the separate data structures I saved for
   % the trib basin and the full sag basin. Needs to be refined later.

   switch sitename
      case "trib_basin"

         % This is the one I modified for trib basin:
         sagData = load(fullfile( ...
            getenv("MATLAB_ACTIVE_PROJECT_DATA_PATH"), ...
            "trib_discharge.mat")).("sag");

      case "sag_basin"

         sagData = load(fullfile( ...
            getenv("USERDATAPATH"), ...
            'interface', 'sag_basin', "sag_data.mat")).("sag");
   end

   sagData.site_name = sitename;
end
