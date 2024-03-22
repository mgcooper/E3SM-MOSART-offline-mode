function H = plotatsmosart(mosartData, opts)
   %PLOTATSMOSART Plot to compare ATS runoff and MOSART discharge

   arguments
      mosartData = [] % the output of mosart.readoutput
      opts.plot_ming_pan = false
   end

   if isempty(mosartData)
      mosartData = mosart.loadoutput(); % uses environment variable MOSART_RUNID
   end

   colors = defaultcolors;

   % for plotting
   Tavg = mosartData.gaged.Tavg;
   T = mosartData.gaged.Tmod;

   % Compute nse
   nse1 = nashsutcliffe(mosartData.gaged.Dobs_avg, mosartData.gaged.Dmod_avg);
   rmse1 = sqrt(mean( (mosartData.gaged.Dobs_avg - mosartData.gaged.Dmod_avg) .^2 ));
   nse2 = nashsutcliffe(mosartData.gaged.Dobs, mosartData.gaged.Dmod);
   rmse2 = sqrt(mean( (mosartData.gaged.Dobs - mosartData.gaged.Dmod) .^2 ));


   % This is here b/c I accidentally plotted the ats runoff and the mosart
   % routed discharge and thought wow the fit is so good, there must be a
   % mistake in plotatsmosart, but i kept this anyway b/c it does verify that
   % whatever happens in mosart.readoutput (which creates the "gaged"
   % sub-struct) is correct.
   % figure; hold on
   % plot(mosartData.T, mosartData.D(:, mosartData.outID));
   % plot(mosartData.T, mosartData.gaged.Dmod);
   % plot(mosartData.T, mosartData.gaged.Dobs, ':');


   % set colors
   c_mosart = colors(7, :); % colors(1, :)
   c_usgs = colors(1, :);

   % plot the ATS data
   H.f1 = figure;
   plot(mosartData.gaged.Tavg, mosartData.gaged.Dobs_avg, ...
      'Color', c_usgs, 'LineWidth', 1.5); hold on
   plot(mosartData.gaged.Tavg, mosartData.gaged.Dmod_avg, ...
      'Color', c_mosart, 'LineWidth', 1.5);
   legend('USGS gage', 'ATS-MOSART');
   datetick;
   ylabel('m^3/s','Interpreter','tex');
   textbox("NSE = " + round(nse1, 2), 5, 90)
   textbox("rmse = " + round(rmse1) + " m3/s", 5, 80)


   H.f2 = figure; hold on
   h(1) = plot(T, mosartData.gaged.Dmod, 'Color', c_mosart, 'LineWidth', 1.5);
   h(2) = plot(T, mosartData.gaged.Dobs, 'Color', c_usgs, 'LineWidth', 1.5);
   legend([h(2) h(1)], 'USGS gage', 'ATS-MOSART', 'location', 'north');
   datetick;
   ylabel('Daily Discharge [m^3 s^{-1}]', 'Interpreter', 'tex');
   textbox("NSE = " + round(nse2, 2), 5, 90)
   textbox("rmse = " + round(rmse2) + " m3/s", 5, 80)
   % title('daily flow, 1983-2008'); datetick
   % text(T(100),850,['\it{NSE}=',printf(Dnse,2)])
   % figformat('linelinewidth',2)


   try
      h = scatterfit(mosartData.gaged.Dobs, mosartData.gaged.Dmod);
      xylabel('USGS gage', 'ATS-MOSART')
      addOnetoOne
      legend('data', 'linear fit', '1:1', 'location', 'eastoutside')
      formatPlotMarkers('markersize', 6)
      H.f3 = h.figure;
   catch e
      % license checkout error
      H.f3 = [];
   end

   try
      h = scatterfit(mosartData.gaged.Dobs_avg, mosartData.gaged.Dmod_avg);
      xylabel('USGS gage', 'ATS-MOSART')
      addOnetoOne
      legend('data', 'linear fit', '1:1', 'location', 'eastoutside')
      formatPlotMarkers('markersize', 6)
      H.f4 = h.figure;
   catch e
      % license checkout error
      H.f4 = [];
   end

   % figure
   % plotLinReg(mosart.gaged.Dobs, mosart.gaged.Dmod);

   %% Ming Pan runoff

   if opts.plot_ming_pan
      % This plots the ming pan runoff, but it is not very good and obscures the
      % compareison with usgs

      % plot the ATS data
      H.f1 = figure; hold on
      plot(mosartData.gaged.Tavg, mosartData.gaged.Dobs_avg);
      plot(mosartData.gaged.Tavg, mosartData.gaged.Dmod_avg);
      plot(mosartData.gaged.Tavg, mosartData.gaged.Dpan_avg);
      legend('USGS gage', 'ATS-MOSART', 'VIC-RAPID'); datetick;
      ylabel('m^3/s','Interpreter','tex');

      H.f2 = figure; hold on
      plot(T, mosartData.gaged.Dobs);
      plot(T, mosartData.gaged.Dmod);
      plot(T, mosartData.gaged.Dpan);
      legend('USGS gage', 'ATS-MOSART', 'VIC-RAPID'); datetick;
      ylabel('Daily Discharge [m$^3$s$^{-1}$]');
      % title('daily flow, 1983-2008'); datetick
      % text(T(100),850,['\it{NSE}=',printf(Dnse,2)])
      figformat('linelinewidth',2)

      % plot the GRFR data
      figure; hold on
      plot(Tavg, mosartData.gaged.Dobs_avg);
      plot(Tavg, mosartData.gaged.Dmod_avg);
      legend('USGS gage','GRFR-MOSART'); datetick;
      ylabel('m^3/s','Interpreter','tex');

      figure; hold on
      plot(Tavg, cumsum(mosartData.gaged.Dobs_avg));
      plot(Tavg, cumsum(mosartData.gaged.Dmod_avg));
      legend('USGS gage','GRFR-MOSART'); datetick;
      ylabel('m^3/s','Interpreter','tex');

      % % Mar 2024, commented out below, I think I made a script or maybe
      % hand-copied the modified data to data/trib_discharge
      %
      % % load the sag river basin data
      % sitename = getenv('USER_MOSART_RUNOFF_PATH');
      % load('/Users/coop558/work/data/interface/sag_basin/sag_data');
      %
      % % for the trib basin, load that data and replace the data in 'sag'
      % sag      = setfield(sag,'site_name',sitename);
      % flow     = bfra_loadflow('SAGAVANIRKTOK R TRIB NR PUMP STA 3 AK');
      % sag.time = flow.Time;
      % sag.flow = flow.Q;
      %
      % % this was from save routed flow csv
      % discharge_slopes  = mosart.gaged.Dtiles;
      % discharge_outlet  = mosart.gaged.Dmod;
      % discharge_gaged   = mosart.gaged.Dobs;
      % Time              = mosart.gaged.Tmod;
      %
      % figure; set(gca,'YLim',[0 35]); hold on;
      % for n = 1:22
      %     plot(mosart.D(:,n)); hold on;
      %     title(num2str(n)); pause;
      % end

   end
end
