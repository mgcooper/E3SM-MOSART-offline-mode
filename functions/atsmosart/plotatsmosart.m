function H = plotatsmosart(mosart, opts)
   %PLOTATSMOSART Plot to compare ATS runoff and MOSART discharge

   arguments
      mosart = [] % the output of mosart.readoutput
      opts.plot_ming_pan = false
   end

   if isempty(mosart)
      pathdata = fullfile( ...
         getenv('E3SMOUTPUTPATH'), getenv('MOSART_RUNID'), 'mat');
      load(fullfile(pathdata, 'mosart.mat'), 'mosart');
   end

   colors = defaultcolors;

   % for plotting
   Tavg = mosart.gaged.Tavg;
   T = mosart.gaged.Tmod;

   % Compute nse
   nse1 = nashsutcliffe(mosart.gaged.Dobs_avg, mosart.gaged.Dmod_avg);
   rmse1 = sqrt(mean( (mosart.gaged.Dobs_avg - mosart.gaged.Dmod_avg) .^2 ));
   nse2 = nashsutcliffe(mosart.gaged.Dobs, mosart.gaged.Dmod);
   rmse2 = sqrt(mean( (mosart.gaged.Dobs - mosart.gaged.Dmod) .^2 ));

   % set colors
   c_mosart = colors(7, :); % colors(1, :)
   c_usgs = colors(1, :);

   % plot the ATS data
   H.f1 = figure;
   plot(mosart.gaged.Tavg, mosart.gaged.Dobs_avg, ...
      'Color', c_usgs, 'LineWidth', 1.5); hold on
   plot(mosart.gaged.Tavg, mosart.gaged.Dmod_avg, ...
      'Color', c_mosart, 'LineWidth', 1.5);
   legend('USGS gage', 'ATS-MOSART');
   datetick;
   ylabel('m^3/s','Interpreter','tex');
   textbox("NSE = " + round(nse1, 2), 5, 90)
   textbox("rmse = " + round(rmse1) + " m3/s", 5, 80)


   H.f2 = figure; hold on
   h(1) = plot(T, mosart.gaged.Dmod, 'Color', c_mosart, 'LineWidth', 1.5);
   h(2) = plot(T, mosart.gaged.Dobs, 'Color', c_usgs, 'LineWidth', 1.5);
   legend([h(2) h(1)], 'USGS gage', 'ATS-MOSART', 'location', 'north');
   datetick;
   ylabel('Daily Discharge [m^3 s^{-1}]', 'Interpreter', 'tex');
   textbox("NSE = " + round(nse2, 2), 5, 90)
   textbox("rmse = " + round(rmse2) + " m3/s", 5, 80)
   % title('daily flow, 1983-2008'); datetick
   % text(T(100),850,['\it{NSE}=',printf(Dnse,2)])
   % figformat('linelinewidth',2)


   try
      h = scatterfit(mosart.gaged.Dobs, mosart.gaged.Dmod);
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
      h = scatterfit(mosart.gaged.Dobs_avg, mosart.gaged.Dmod_avg);
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
      plot(mosart.gaged.Tavg, mosart.gaged.Dobs_avg);
      plot(mosart.gaged.Tavg, mosart.gaged.Dmod_avg);
      plot(mosart.gaged.Tavg, mosart.gaged.Dpan_avg);
      legend('USGS gage', 'ATS-MOSART', 'VIC-RAPID'); datetick;
      ylabel('m^3/s','Interpreter','tex');

      H.f2 = figure; hold on
      plot(T, mosart.gaged.Dobs);
      plot(T, mosart.gaged.Dmod);
      plot(T, mosart.gaged.Dpan);
      legend('USGS gage', 'ATS-MOSART', 'VIC-RAPID'); datetick;
      ylabel('Daily Discharge [m$^3$s$^{-1}$]');
      % title('daily flow, 1983-2008'); datetick
      % text(T(100),850,['\it{NSE}=',printf(Dnse,2)])
      figformat('linelinewidth',2)

      % plot the GRFR data
      figure; hold on
      plot(Tavg, mosart.gaged.Dobs_avg);
      plot(Tavg, mosart.gaged.Dmod_avg);
      legend('USGS gage','GRFR-MOSART'); datetick;
      ylabel('m^3/s','Interpreter','tex');

      figure; hold on
      plot(Tavg, cumsum(mosart.gaged.Dobs_avg));
      plot(Tavg, cumsum(mosart.gaged.Dmod_avg));
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
