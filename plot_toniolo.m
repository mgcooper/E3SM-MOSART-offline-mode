
% % Plot the timeseries - doesn't look good no matter what I tried, too busy
% colors = defaultcolors;
% figure; hold on; box on
% for n = 1:numel(tonioloSitenames)
%    thissite = tonioloSitenames(n);
%
%    Y1 = tonioloDischarge.(thissite);
%    Y2 = mosartDischarge.(thissite);
%
%    % Skip the first year, and set nan so lines are not connected
%    drop = isnan(Y1) & year(mosartDischarge.Time) < 2014;
%    Y2(drop) = nan;
%
%    plot(mosartDischarge.Time, Y1, 'LineWidth', 1, 'Color', colors(n, :))
%    plot(mosartDischarge.Time, Y2, '--', 'LineWidth', 1, 'Color', colors(n, :))
% end
% ylimits = ylim;
% set(gca, 'YScale', 'log', 'YLim', [1 max(ylimits)])
% ylabel("Discharge [m3 s-1]")
% xlabel('Time (Days since 01 Jan 2014)')
% copygraphics(gcf)

idx = year(mosartDischarge.Time) > 2014;
figure; box on
plot(mosartDischarge.Time(idx), mosartDischarge{idx, tonioloSitenames}, ...
   'LineWidth', 1)
% set(gca, 'YScale', 'log')
% legend([sitenames, "Mosart"], 'Location', 'northwest')
ylabel("Discharge [m3 s-1]")
xlabel('Time (Days since 01 Jan 2014)')
copygraphics(gcf)

% Scatter one to one mosart vs observations
figure; hold on; box on
for thissite = tonioloSitenames(:)'
   drop = ~isnan(tonioloDischarge.(thissite));
   if sum(drop) > 0
      % scatterfit(Discharge.Mosart(keep), D(keep));
      plot(mosartDischarge.(thissite)(drop), ...
         tonioloDischarge.(thissite)(drop), 'o', 'DisplayName', thissite);
   end
end
formatPlotMarkers('markersize', 6)
legend('Location', 'southeast', 'NumColumns', 2, 'AutoUpdate', 'off')
lsline
addOnetoOne('Color', rgb('dark grey'))
xlabel("Mosart [m^3 s^{-1}]")
ylabel("Gaged [m^3 s^{-1}]")
title("Toniolo Discharge Data")
copygraphics(gcf)
