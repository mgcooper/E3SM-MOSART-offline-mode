function mosart = mos_clipbasin(mosart,sag)
   
   % this function finds the hillslopes in the mosart data saved by
   % 'read_output_sag' that are contained within the gaged basin
   
   Tmod     = mosart.T;
   Dmod     = mosart.D(:,mosart.outID);
   Tobs     = sag.time;
   Dobs     = sag.flow;
   
   % find the start and end of the overlapping period
   if strcmp(sag.site_name,'test_basin')
      t1       = datetime(2011,1,2);
      t2       = datetime(2017,1,1);
      Dtiles   = mosart.D;
   elseif strcmp(sag.site_name,'trib_basin')
      t1       = datetime(1998,1,2);
      t2       = datetime(2002,1,1);
      Dtiles   = mosart.D;
   else
      t1      = datetime(1983,1,1);
      t2      = datetime(2008,12,31);
      Dtiles  = mosart.D(isbetween(Tmod,t1,t2),sag.mask);
   end
   
   
   Dmod    = Dmod(isbetween(Tmod,t1,t2));
   Tmod    = Tmod(isbetween(Tmod,t1,t2));
   Dobs    = Dobs(isbetween(Tobs,t1,t2));
   Tobs    = Tobs(isbetween(Tobs,t1,t2));
   
   
   nyrs    = size(Dmod,1)/365;
   Qobsavg = mean(reshape(Dobs,365,nyrs),2);
   Qmodavg = mean(reshape(Dmod,365,nyrs),2);
   Tavg    = datenum(Tobs(1:365));
   
   mosart.gaged.Dtiles     = Dtiles;
   mosart.gaged.Dmod       = Dmod;
   mosart.gaged.Dobs       = Dobs;
   mosart.gaged.Tmod       = Tmod;
   mosart.gaged.Tobs       = Tobs;
   mosart.gaged.Dmod_avg   = Qmodavg;
   mosart.gaged.Dobs_avg   = Qobsavg;
   mosart.gaged.Tavg       = Tavg;
   
   