function plotGcamTotalDemand(TWD)

GCAM_Lat = TWD.Properties.CustomProperties.Lat;
GCAM_Lon = TWD.Properties.CustomProperties.Lon;

% plot the gridded data
figure; 
scatter(GCAM_Lon,GCAM_Lat,20,mean(table2array(TWD),1),'filled'); hold on;
colorbar;
title('GCAM Water Demand')
copygraphics(gcf)