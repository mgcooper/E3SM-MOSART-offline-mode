function [outletID, found] = findoutletID(data)
   %
   %
   %  Note: outletID = unique(OUTLETG(:)), This function finds it from the data
   %  directly, can be used to verify above method.
   %
   % See also: mosart.findgage

   found = true;

   try
      outletID = find(~isnan(data.RIVER_DISCHARGE_TO_OCEAN_LIQ(:, 1)));

   catch ME
      if strcmp(ME.message, ...
            'Unrecognized field name "RIVER_DISCHARGE_TO_OCEAN_LIQ".')
         % This should mean that the mosart files are incl2 or higher and don't
         % contain the RIVER_DISCHARGE_TO_OCEAN_LIQ variable because the
         % frivinp_rtm file didn't request it. The outlet should be the index
         % with all nan data, but the runoff data is missing in this case
         try
            outletID = find(all(isnan(data.RIVER_DISCHARGE_OVER_LAND_LIQ), 1));
         catch ME
            found = false;
            if strcmp(ME.message, ...
                  'Unrecognized field name "RIVER_DISCHARGE_OVER_LAND_LIQ".')
               rethrow(ME)
            end
         end
      end
   end
   
   if ~found
      error('Failed to find outlet ID')
   end
end
