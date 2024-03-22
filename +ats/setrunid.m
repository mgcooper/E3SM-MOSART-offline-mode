function atsrunID = setrunid(MOSART_RUNID)
   %SETRUNID Set the ATS run ID
   %
   %  ATSRUNID = SETRUNID(MOSART_RUNID)
   %
   %  Note: This is a custom lookup table. New cases must be added on an
   %  ad-hoc basis by the user.
   %
   % See also:

   arguments
      MOSART_RUNID (1, :) char = getenv('MOSART_RUNID')
   end

   switch MOSART_RUNID
      case 'trib_basin.1997.2003.run.2023-06-16-112625.ats'
         atsrunID = 'huc0802_gauge15906000_frozen_a8';

      case 'trib_basin.1997.2003.run.2023-06-16-120102.ats'
         atsrunID = 'huc0802_gauge15906000_frozen_a5';

      otherwise
         atsrunID = 'sag_basin';
   end
end
