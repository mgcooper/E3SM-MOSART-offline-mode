function H = plotatsmosart(varargin)

if nargin < 1
   pathdata = fullfile(getenv('E3SMOUTPUTPATH'),getenv('MOSART_RUNID'),'mat');
   load(fullfile(pathdata,'mosart.mat'),'mosart');
else
   mosart = varargin{1};
end

% for plotting
Tavg = mosart.gaged.Tavg;
T = mosart.gaged.Tmod;

% plot the ATS data
H.f1 = figure; 
plot(mosart.gaged.Tavg,mosart.gaged.Dobs_avg); hold on;
plot(mosart.gaged.Tavg,mosart.gaged.Dmod_avg); 
legend('USGS gage', 'ATS-MOSART'); datetick;
ylabel('m^3/s','Interpreter','tex');

H.f2 = figure;
plot(T,mosart.gaged.Dobs); hold on;
plot(T,mosart.gaged.Dmod);
legend('USGS gage', 'ATS-MOSART'); datetick;
ylabel('Daily Discharge [m$^3$s$^{-1}$]');
% title('daily flow, 1983-2008'); datetick
% text(T(100),850,['\it{NSE}=',printf(Dnse,2)])
figformat('linelinewidth',2)

% % This plots the ming pan runoff, but it is not very good and obscures the
% compareison with usgs

% % plot the ATS data
% H.f1 = figure; 
% plot(mosart.gaged.Tavg,mosart.gaged.Dobs_avg); hold on;
% plot(mosart.gaged.Tavg,mosart.gaged.Dmod_avg); 
% plot(mosart.gaged.Tavg,mosart.gaged.Dpan_avg);
% legend('USGS gage', 'ATS-MOSART', 'VIC-RAPID'); datetick;
% ylabel('m^3/s','Interpreter','tex');
% 
% H.f2 = figure;
% plot(T,mosart.gaged.Dobs); hold on;
% plot(T,mosart.gaged.Dmod);
% plot(T,mosart.gaged.Dpan);
% legend('USGS gage', 'ATS-MOSART', 'VIC-RAPID'); datetick;
% ylabel('Daily Discharge [m$^3$s$^{-1}$]');
% % title('daily flow, 1983-2008'); datetick
% % text(T(100),850,['\it{NSE}=',printf(Dnse,2)])
% figformat('linelinewidth',2)


% % load the sag river basin data
% sitename = getenv('USER_MOSART_RUNOFF_PATH');
% load('/Users/coop558/work/data/interface/sag_basin/sag_data');
% 
% % for the trib basin, load that data and replace the data in 'sag'
% sag      = setfield(sag,'site_name',sitename);
% flow     = bfra_loadflow('SAGAVANIRKTOK R TRIB NR PUMP STA 3 AK');
% sag.time = flow.Time;
% sag.flow = flow.Q;
% 
% % this was from save routed flow csv
% discharge_slopes  = mosart.gaged.Dtiles;
% discharge_outlet  = mosart.gaged.Dmod;
% discharge_gaged   = mosart.gaged.Dobs;
% Time              = mosart.gaged.Tmod;
% 
% 
% figure; set(gca,'YLim',[0 35]); hold on;
% for n = 1:22
%     plot(mosart.D(:,n)); hold on; 
%     title(num2str(n)); pause; 
% end

% plot the GRFR data
% figure; 
% plot(mosart.gaged.Tavg,mosart.gaged.Dobs_avg); hold on;
% plot(mosart.gaged.Tavg,mosart.gaged.Dmod_avg); 
% legend('USGS gage','GRFR-MOSART'); datetick;
% ylabel('m^3/s','Interpreter','tex');

