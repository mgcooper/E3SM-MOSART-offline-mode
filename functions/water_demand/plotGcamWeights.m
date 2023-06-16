function plotGcamWeights(GCAM_weights,GCAM_anomalies)

% Plot the monthly anomalies
figure;
subplot(1,2,1)

plot(GCAM_anomalies); hold on;
h = plot(mean(GCAM_anomalies,2),'LineWidth',6);
xlabel('Month'); ylabel('Total Demand (anomaly)')
title('GCAM Water Demand Monthly Cycle')
legend(h,'Mean Monthly Cycle','Location','nw')
% copygraphics(gcf)

% Plot the monthly weights
subplot(1,2,2)

plot(GCAM_weights); hold on;
h = plot(mean(GCAM_weights,2),'LineWidth',6);
xlabel('Month'); ylabel('Fraction of Annual Demand (monthly weights)')
title('GCAM Water Demand Monthly Cycle')
legend(h,'Mean Monthly Cycle','Location','nw')
% copygraphics(gcf)