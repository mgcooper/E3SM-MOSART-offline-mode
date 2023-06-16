clean

usegeo = false;

%% Load the data

BasinWeights = loadDrbcBasinWeights();
[Demand, Meta] = loadDrbcWaterDemand();
[TWD,XGcam,YGcam] = loadGcamWaterDemand(usegeo);

% [W,IN] = load_drb_subbasin_weights();
% [Withdrawals, Meta] = load_drbc_water_demand();
% [TWD,LonGcam,LatGcam] = load_gcam_water_demand(usegeo);

%% Generate regularly-shaped arrays of consumptive water use

[CUTW, CUSW, CUGW, Time] = processWithdrawalData(Demand);

%% Generate monthly GCAM weights for temporal remapping

GcamWeights = generateGcamMonthlyWeights(TWD);

%% Find the GCAM grid cell nearest each mesh cell

% Subset the GCAM coordinates
XGcam = XGcam(GcamWeights.IDX);
YGcam = YGcam(GcamWeights.IDX);

% Get the GCAM grid cell nearest each mesh cell
I = nearestGridCell(XGcam,YGcam,BasinWeights.XC,BasinWeights.YC);

%% Remap the demand data (apply the weights)

CU = remapWaterDemand(CUTW,BasinWeights.W,BasinWeights.IN,GcamWeights.W,I);

% compare the total remapped demand and original polygon-based demand
[sum(CU(:)) sum(CUTW(:))]

%% convert the coordinates back to latlon

[XC,YC,XV,YV] = read_e3sm_domain_file( ...
   getenv('USER_E3SM_DOMAIN_NCFILE_FULLPATH'));

CU2 = zeros(numel(BasinWeights.IMesh),size(CU,1));
CU2(BasinWeights.IMesh,:) = CU.';

% Plot the data to confirm
% check = mean(CU2,2,'omitnan');
% figure; plotMeshVertices(XV,YV); hold on;
% scatter(XC(check>0),YC(check>0),30,check(check>0),'filled'); 
% colorbar;

%% make the files

pathsave = "/Users/coop558/work/data/e3sm/forcing/icom_domain";
filenames = strcat("icom_domain_water_use_",string(GcamWeights.Time),".nc");
filenames = fullfile(pathsave,filenames);

if savedata == true
   createWaterDemandFiles(XC, YC, 1:numel(XC), CU2, filenames);
end

test = ncreaddata(filenames(1));
% read one file to use as a template
% template = ncinfo("RCP8.5_GCAM_water_demand_1980_01.nc");


%% for now, save the data

if savedata == true
   f = fullfile(getenv('ACTIVE_PROJECT_DATA_PATH'),'matfiles','water_use');
   save(f,'CU','CUTW');
end

%% Test plots

% Plot the DRBC demand data
plotConsumptiveUse(Time, CUSW, CUGW, CUTW);

% plot (basin map) the GCAM total demand grid centroids
plotGcamTotalDemand(TWD);

% Plot the monthly weights
plotGcamWeights(GcamWeights,GCAM_anomalies)


figure; plot(XGcam,YGcam,'o'); hold on;
plot(BasinWeights.XC,BasinWeights.YC,'o')

