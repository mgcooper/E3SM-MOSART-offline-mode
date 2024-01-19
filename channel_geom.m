% this was in b_make_newslopes 

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
