clean

savedata = false;

%% read in the GCAM water demand for New York lat/lon

[TWD, row, col, dist] = readGcamWaterDemand(40.7128, -74.0060);

Weights = generateGcamMonthlyWeights(TWD);

%% read the IBT

IBT = readtimetable('DRBC_IBT_cms.xlsx');
vars = IBT.Properties.VariableNames;
nyears = height(IBT);
nmonths = nyears*12;
ndiversions = width(IBT);

IBT_monthly = nan(12, nyears, ndiversions);

% secperyear = 365.25*24*3600;
T = datetime(IBT.Time(1):calmonths(1):IBT.Time(end)+calmonths(11));
secperyear = seconds(duration(diff(IBT.Time)));
secperyear(end+1) = seconds(IBT.Time(end)+calyears(1)-IBT.Time(end));
secpermonth = seconds(duration(diff(T))).';
secpermonth(end+1) = seconds(T(end)+calmonths(1)-T(end));


for n = 1:nyears
   i1 = (n-1)*12 + 1;
   i2 = n*12;
   IBT_monthly(:, n, :) = Weights.W * IBT{n, :} .* secperyear(n)./secpermonth(i1:i2);
end

% reshape to monthly timeseries and convert to timetable
IBT_monthly = reshape(IBT_monthly, nmonths, ndiversions);

IBT_monthly = array2timetable(IBT_monthly,'RowTimes',T,'VariableNames', ...
   {'Pepacton', 'Neversink', 'DelawareRaritanCanal', 'Cannonsville'});

% mean(IBT_monthly.Pepacton(1:12))
% mean(IBT_monthly.Neversink(1:12))

% Should be: 12.9836588	4.004240472	3.691887228	7.120170485
mean(IBT_monthly{:,:})

% Pepacton = East Branch
% Cannonsville = Upper Delaware
% Neversink = Mongaup
% Delaware & Raritan Canals = Musconetcong 

writetimetable(IBT_monthly,'DRBC_IBT_cms_monthly.xlsx')

%% confirm

nycstate = loadstateshapefile("New York");

lon = TWD.Properties.CustomProperties.Lon;
lat = TWD.Properties.CustomProperties.Lat;

figure;
subplot(3,1,1)
plot(nycstate.Lon, nycstate.Lat); hold on;
scatter(lon, lat, 60, 'filled');

subplot(3,1,2)
plot(TWD.TWD);

subplot(3,1,3)
plot(Weights.W)

figure
plot(IBT_monthly.Time, IBT_monthly{:,1})

figure
plot(IBT_monthly.Time, sum(IBT_monthly{:,:}, 2))

xlabel('Month')
ylabel('Water Demand (m3/s)')

cms2mgd(35)

