function verify_runoff_balances_discharge

   % To pick up, use the new run which I started on 2014, to see if the change
   % in storage is incorrect when using a spinup year ... Now I've done that and
   % it does not reconcile.

   % Load the saved mosart discharge
   mosartData = mosart.loadoutput();

   % Read the ats data and compute basin-sum runoff
   RunoffData = ats.loadrunoff();
   Runoff = sum(RunoffData{:, :}, 2); % m3/s
   Area = RunoffData.Properties.CustomProperties.Area; % m2
   Time = RunoffData.Time;

   % Clip 2014-2018
   idx = isbetween(mosartData.T, Time(1), Time(end));
   Discharge = mosartData.D(idx, :);
   Storage = mosartData.S(idx, :);

   % Convert storage to sum over all reaches
   Storage = sum(Storage, 2);

   % TEST - see if change in storage at the outlet reach resolves it, even
   % though it seems like it should be the entire basin
   % Storage = Storage(:, MosartData.outID);

   % Confirm the outlet has the max cumulative discharge
   test = cumsum(Discharge, 1);
   assertEqual(findglobalmax(mean(Discharge)), mosartData.outID)

   % Compare the outlet cumulative discharge to the cumulative input runoff
   Discharge = Discharge(:, mosartData.outID); % m3/s

   figure; hold on
   plot(Discharge)
   plot(Runoff, ':')

   figure
   scatterfit(Discharge, Runoff)

   % Based on this, I think it might just be the channel storage
   figure; hold on
   plot(cumsum(Discharge)); plot(cumsum(Runoff))
   legend('D', 'R')

   % Compute cumulative discharge and runoff in units of m3
   Dcumulative = cumsum(Discharge * 3600);
   Rcumulative = cumsum(Runoff * 3600);

   % dR should be zero except for change in storage
   dR = Rcumulative(end) - Dcumulative(end); % 1.33e7

   % Compute change in storage
   dS = Storage(end) - Storage(1); % 1.54e7 - 1.22e7 = 3.19e6

   % dS should be correct, but compute the incremental change in storage
   figure; hold on
   plot(Storage)
   plot(Storage - Storage(1), ':')
   legend('Basin-Sum Channel Storage', '\Delta Basin-Sum Channel Storage')


   % should be: R = D + dS
   balance = Rcumulative(end) - Dcumulative(end) - dS;
   balance = Rcumulative(end) - Dcumulative(end) - Storage(end); % closer

   % Plot Rcumulative and Dcumulative plus Storage, all in units m3
   figure; hold on
   plot(Rcumulative)
   plot(Dcumulative)
   plot(Dcumulative + Storage - Storage(1))


   % Convert the storage on the final day to m3/s
   sum(Storage(end, :)) / 3600

   % figure; hold on plot(cumsum(Discharge) + sum(Storage, 2) / 3600);
   % plot(cumsum(Runoff)) legend('D', 'R')


   %%
   t1 = datetime(2014, 1, 1, 0, 0, 0);
   t2 = datetime(2015, 1, 1, 0, 0, 0);
   idx = isbetween(Time, t1, t2, 'openright');

   figure; hold on
   plot(Time(idx), cumsum(Runoff(idx)))



   %% %%%%%%%%%% TEST - QSUB/QSUR
   roff = RunoffData{:, :};
   qsub = transpose(horzcat(mosartData.data(:).QSUB_LIQ));

   cumsumDischarge = cumsum(Discharge);
   cumsumRunoff = cumsum(Runoff);
   cumsumQsub = cumsum(sum(qsub, 2));

   figure; hold on
   plot(cumsumDischarge);
   plot(cumsumRunoff)
   plot(cumsumQsub)
   legend('Discharge (outlet)', 'Input Runoff', 'QSUB')
   ylabel('Cumulative Runoff')
   xlabel('Days since 2014-01-01')

   % Differences, compare with storage - actually I already know from up above
   % that dR is ~1.3e7, and dS is ~4.4e6, and R matches Qsub.


   % Maybe the outlet hillslope runoff is not going into the channel?
   % STopped here b/c I need to figure out which hillslope is the outlet in the
   % ATS Runoff data table
   % cumsumRunoffOutlet =
   % plot()

   % PICK UP - was gonna load the mosart input files using
   % mosart.readConfigFiles and double check if the ID, dnID is consecutive

   figure
   plot(sum(qsub, 2), sum(roff, 2), 'o');
   addOnetoOne

   figure
   plot(qsub(:), roff(:), 'o');
   addOnetoOne

   figure
   plot(cumsumRunoff); hold on
   plot(cumsumQsub)
   legend('Runoff Input', 'QSUB_LIQ')


   % varnames = {'QGWL_LIQ', 'QSUB_LIQ', 'QSUR_LIQ'};
   % for n = 1:numel(mosartData.data)
   %    for m = 1:numel(varnames)
   %       var = varnames{m};
   %       if sum(mosartData.data(n).(var)(:) ~= 0) > 0
   %          fprintf('not zero: %s\n', var)
   %       end
   %    end
   % end

   %%%%%%%%%% TEST

   %%

   % The domain file is not used, the dlnd file sets the runoff file as the
   % domain, SO ITS POSSIBLE THE PROBLEM IS THAT THE MING PAN RUNOFF FILES ARE
   % USED AS TEMPLATES AND THEY HAVE THE WRONG AREA ... but the runoff files
   % don't have an area field ... so that's not the problem ...
   %
   % runoff_data.info.Name

   % Since the problem is not likely to be the area

end
