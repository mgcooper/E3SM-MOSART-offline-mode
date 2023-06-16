function Weights = generateGcamMonthlyWeights(TWD)
%GENERATEGCAMMONTHLYWEIGHTS Get monthly water demand weights from GCAM
% 
% Weights = generateGcamMonthlyWeights(TWD) computes annual average monthly
% water demand weights, i.e., one value per month from multi-year timeseries.
% 
% 

Lat = TWD.Properties.CustomProperties.Lat;
Lon = TWD.Properties.CustomProperties.Lon;

% The DRBC data covers 1990-2017
keep = 1990 <= year(TWD.Time) & year(TWD.Time) <= 2017;
Time = TWD.Time(keep);
GCAM = table2array(TWD);
GCAM = GCAM(keep,:);

GCAM_monthly = squeeze(mean(reshape(GCAM,12,[],size(GCAM,2)),2));

% find GCAM cells that are unique and non-nan
[~,okunique] = unique(GCAM_monthly.','rows');
oknotnan = find(all(~isnan(GCAM_monthly),1));
IDX = okunique(ismember(okunique,oknotnan));

% subset the unique cells
W = GCAM_monthly(:,IDX) ./ sum(GCAM_monthly(:,IDX),1);

% compute monthly weights for each GCAM cell
Weights.W = W;
Weights.IDX = IDX;
Weights.Lat = Lat(IDX);
Weights.Lon = Lon(IDX);
Weights.Time = Time;

% Anomalies
% A = GCAM_monthly(:,I) - mean(GCAM_monthly(:,I));


% plot all the months, but see plotGcamWeigths, they can all be plotted on one
% figure; hold on;
% for n = 1:size(GCAM_monthly,2)
%    dat = GCAM_monthly(:,n) - mean(GCAM_monthly(:,n));
%    plot(dat);
%    pause;
% end



















