clean

% load the sag river basin data
load('/Users/coop558/work/data/interface/sag_basin/sag_data');

sag.site_name = getenv('MOSART_SITENAME');

% for the trib basin, load that data and replace the data in 'sag'
flow = bfra.loadflow('SAGAVANIRKTOK R TRIB NR PUMP STA 3 AK');
sag.time = flow.Time;
sag.flow = flow.Q;

% figure; plot(sag.time,sag.flow);

save(fullfile(getenv("MATLAB_ACTIVE_PROJECT_DATA_PATH"),"sag_discharge"), "sag")

%% Update Feb 2024

% Need to confirm what data exists in Sag basin

% 'SAGAVANIRKTOK R NR PUMP STA 3 AK'	 '15908000' 
% 'SAGAVANIRKTOK R TRIB NR PUMP STA 3 AK'	 '15906000'