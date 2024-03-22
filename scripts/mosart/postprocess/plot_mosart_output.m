clean

sitename = 'sag_basin';
runid = 'sag_basin.2013.2019.run.2024-01-19-105008.ats';

setenv('MOSART_SITENAME', sitename)
setenv('MOSART_RUNID', runid);

pathdata = fullfile(getenv('E3SMOUTPUTPATH'), getenv('MOSART_RUNID'), 'run');
pathsave = fullfile(getenv('E3SMOUTPUTPATH'), getenv('MOSART_RUNID'), 'mat');

%%
data = mosart.loadoutput();

%%

colors = defaultcolors;

figure('Position', [234   233   715   384]);
plot(data.gaged.Tmod, data.gaged.Rats, '-', 'Color', colors(7, :), ...
   'LineWidth', 1); hold on
plot(data.gaged.Tmod, data.gaged.Dmod, 'Color', colors(1, :));
legend('unrouted', 'routed', 'location', 'north')
ylabel('m^3/s')

figure;
plot(data.gaged.Tavg, data.gaged.Rats_avg, '-', 'Color', colors(7, :), ...
   'LineWidth', 1); hold on
plot(data.gaged.Tavg, data.gaged.Dmod_avg, 'Color', colors(1, :));
legend('unrouted', 'routed', 'location', 'north')
ylabel('m^3/s')
datetick


figure;
plot(cumsum(data.gaged.Dmod_avg)); hold on;
plot(cumsum(data.gaged.Rats_avg))
legend('routed', 'unrouted')

if savefigs == true
   exportgraphics(gcf, fullfile(pathsave, 'ats-mosart-unrouted.png'),'Resolution',300);
end

%%
figure; hold on
plot(cumsum(data.gaged.Dmod))
plot(cumsum(data.gaged.Rats), ':')
legend('routed', 'unrouted')

% Cumulative difference
dR = cumsum(data.gaged.Dmod) - cumsum(data.gaged.Rats);
dR (end)

% Percent difference at final timestep
dR(end) /

% Channel storage on final timestep
% sum(mosart.S(end, :), 2) / 3600;
% (sum(mosart.S(end, :), 2) - sum(mosart.S(end-1, :), 2))  / 3600;


% resized it by hand
% exportgraphics(gcf, fullfile(pathsave, 'ats-mosart-timeseries-wide.png'),'Resolution',300);



