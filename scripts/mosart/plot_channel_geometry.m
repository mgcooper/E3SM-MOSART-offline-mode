clean
load('sag_data.mat')

width = [sag.tiles_hs.rwid];
depth = [sag.tiles_hs.rdep];
harea = [sag.tiles_hs.areaTotal] / 1e6;

figure('Position', [212   113   833   386])
TL = tiledlayout(1, 2); 

nexttile
plot(harea, width, 'o')
formatPlotMarkers
xlabel('upstream area (km^2)')
ylabel('bankfull width (m)')

nexttile
plot(harea, depth, 'o')
formatPlotMarkers
xlabel('upstream area (km^2)')
ylabel('bankfull depth (m)')

TL.Title.String = 'Sag River Hydraulic Geometry';
TL.Title.FontSize = 18;

exportgraphics(gcf, 'area_width_depth.png')

%%
figure
plot(depth, width, 'o')
formatPlotMarkers
xlabel('bankfull depth (m)')
ylabel('bankfull width (m)')
title('Sag River Hydraulic Geometry')

exportgraphics(gcf, 'width_depth.png')


%% this was in b_make_newslopes 

% Quick plot of channel width

alpha = 10;
c = 1/2;
A = [links.us_da_km2] ./ (1000 ^2);
W = alpha * A .^ c;

figure; plot(A, W, 'o')
xlabel('Area (km^2)')
ylabel('Channel Width (m)')

A = [links.us_da_km2];
W = alpha * A .^ c;

figure; plot(A, W, 'o')
xlabel('Area (km^2)')
ylabel('Channel Width (m)')

figure
histogram(A)
