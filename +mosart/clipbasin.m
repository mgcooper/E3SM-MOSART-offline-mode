function mosart = clipbasin(mosart,sag,varargin)

   % this function finds the hillslopes in the mosart data saved by
   % 'read_output_sag' that are contained within the gaged basin

   % need to update sag.mask with the new full sag hillsloper ... the current
   % sag.mask is for the old one with 3266 slopes

   % NOTE: mosart.outID is the linear index, not the link ID. This is set in
   % z_save_Sag_data. Need to rename that script and the field to outlet_index

   Tmod = mosart.T;
   Dmod = mosart.D(:, mosart.outID);
   Tobs = sag.time;
   Dobs = sag.flow;

   % nov 2022 fixed the time shift problem on trib-basin and 1997 should be
   % spinup and 2003 should be duplicate of 2002 so clip to 1998/1/1 -
   % 2002/12/31

   % find the start and end of the overlapping period
   switch sag.site_name

      case 'test_basin'
         t1 = datetime(2011, 1, 2);
         t2 = datetime(2017, 1, 1);
         Dtiles = mosart.D;

      case 'trib_basin'
         t1 = datetime(1998, 1, 1);
         t2 = datetime(2002, 12, 31);
         Dtiles = mosart.D;

      case 'sag_basin'

         % t1 = datetime(1983,1,1);
         % t2 = datetime(2008,12,31);
         % Dtiles = mosart.D(isbetween(Tmod,t1,t2),sag.mask);

         t1 = datetime(2014, 1, 1);
         t2 = datetime(2018, 12, 31);
         Dtiles = mosart.D;

         % This is the part that needs to be fixed with a new mask
         % Dtiles = mosart.D(isbetween(Tmod,t1,t2), sag.mask);
   end

   Dmod = Dmod(isbetween(Tmod, t1, t2));
   Tmod = Tmod(isbetween(Tmod, t1, t2));
   Dobs = Dobs(isbetween(Tobs, t1, t2));
   Tobs = Tobs(isbetween(Tobs, t1, t2));

   % nov 2022 clipping Dtiles not sure why they weren't before
   Dtiles = Dtiles(isbetween(Tmod,t1,t2), :);

   assert(mod(size(Dmod, 1), 365) == 0); % ensure no-leap timeseries
   try
      Qobsavg = mean(reshape(Dobs, 365, []), 2); % reshapes to 365 x nyears
      Tavg = Tobs(1:365);
   catch
      Qobsavg = Dobs;
   end
   try
      Qmodavg = mean(reshape(Dmod, 365, []), 2); % reshapes to 365 x nyears
      Tavg = Tmod(1:365);
   catch
      Qmodavg = Dmod;
   end

   mosart.gaged.Dtiles     = Dtiles;
   mosart.gaged.Dmod       = Dmod;
   mosart.gaged.Dobs       = Dobs;
   mosart.gaged.Tmod       = Tmod;
   mosart.gaged.Tobs       = Tobs;
   mosart.gaged.Dmod_avg   = Qmodavg;
   mosart.gaged.Dobs_avg   = Qobsavg;
   mosart.gaged.Tavg       = Tavg;
end
