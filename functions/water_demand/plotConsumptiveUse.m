function plotConsumptiveUse(Time, CUSW, CUGW, CUTW)

figure; 
plot(Time,sum(cat(2,CUGW,CUSW),2),'-o'); hold on;
plot(Time,sum(CUSW,2),'-o'); 
plot(Time,sum(CUGW,2),'-o'); formatPlotMarkers; 
legend('Total Water', 'Surface Water', 'Groundwater')
ylabel('Basin-Total Consumptive Use (m3/s)')
% copygraphics(gcf)