clean

savefigs = false;
sitename = 'trib_basin';
run      = 'trib_basin.1997.2003.run.2022-11-18.ats';
pathdata = [getenv('E3SMOUTPUTPATH') run '/mat/'];

load([pathdata 'mosart.mat'],'mosart');

% load the sag river basin data
% load('/Users/coop558/work/data/interface/sag_basin/sag_data');


%%  diagnose the bad output

% if the simulation spanned 1997-2003, there would be 7 years, but the output is
% for 6 years
% the issue is that year 2/3 and 4/5 are 

% to pick back up on Bo's routing
% Bo sent me data for 1998-2002. I built runoff files and duplicated 98/02 
% YES - check if the data I sent in the spreadhseet spans 1997-2003
% YES - check if 1997/98 and 2002/03 are identical in the nc input runoff files
% YES - check if 1997/98 and 2002/03 are identical in the nc output runoff files
% I need to rebuild the domain file using her area field
% check the other data files that aren't yearly

data = table2array(readtable('private/ats-mosart.xlsx'));

figure; plot(data.slope_5);


% check the h1 files
pathdata = [getenv('E3SMOUTPUTPATH') run '/run/'];
flist   = getlist(pathdata,'*.mosart.h1*');

dat = [];
for n = 1:numel(flist)
   Dmod = ncreaddata([pathdata flist(1).name]);
   dat = [dat;test.RIVER_DISCHARGE_OVER_LAND_LIQ];
end


% this checks the runoff files I made
% read the runoff data to compare with the routed output
% flist = getlist([runoff_output_path filesep ats_runID],'nc');
pathdata = '/Users/coop558/work/data/e3sm/forcing/trib_basin/ats/huc0802_gauge15906000_nopf/';
flist = getlist(pathdata,'nc');
test = readfiles(flist);

for n = 1:numel(flist)
   thisyear = num2str(1996+n);
   thisdata = test.(['runoff_trib_basin_' thisyear]);
   R_n = transpose(squeeze(thisdata.QDRAI));
   R(:,n) = sum(R_n,2);
   thisdata.info.Units{3}
end
R = R(:); % this is in mm/s

figure; plot(R)

% this should be the correct reordering:
Dmod = mosart.gaged.Dtiles;
Dobs = mosart.gaged.Dobs;
[ndays,ntiles] = size(Dmod);
nyrs = ndays/365;
Dmod = reshape(Dmod,365,nyrs,ntiles);
Dmod = Dmod(:,[5 6 7 1 2],1:ntiles);
Dmod = reshape(Dmod,365*(nyrs-2),ntiles);
Dobs = reshape(Dobs,365,nyrs,1);
Dobs = Dobs(:,[2 3 4 5 6],1);
Dobs = reshape(Dobs,365*(nyrs-2),1);


figure; plot(Dmod(:,5)); hold on; plot(Dobs,':');
legend('ATS','USGS')

%%

% figure; set(gca,'YLim',[0 35]); hold on;
% for n = 1:22
%     plot(mosart.D(:,n)); hold on; 
%     title(num2str(n)); pause; 
% end

% for plotting
Tavg  = mosart.gaged.Tavg;
T     = mosart.gaged.Tmod;

% plot the GRFR data
% figure; 
% plot(mosart.gaged.Tavg,mosart.gaged.Dobs_avg); hold on;
% plot(mosart.gaged.Tavg,mosart.gaged.Dmod_avg); 
% legend('USGS gage','GRFR-MOSART'); datetick;
% ylabel('m^3/s','Interpreter','tex');

% plot the ATS data
f1 = figure; 
plot(mosart.gaged.Tavg,mosart.gaged.Dobs_avg); hold on;
plot(mosart.gaged.Tavg,mosart.gaged.Dmod_avg); 
legend('USGS gage','ATS-MOSART'); datetick;
ylabel('m^3/s','Interpreter','tex');

f2 = figure;
plot(T,mosart.gaged.Dobs); hold on;
plot(T,mosart.gaged.Dmod); %set(gca,'YScale','log')
legend('USGS Gage','ATS-MOSART')
ylabel('Daily Discharge [m$^3$s$^{-1}$]');
% title('daily flow, 1983-2008'); datetick
% text(T(100),850,['\it{NSE}=',printf(Dnse,2)])
figformat('linelinewidth',2)


if savefigs == true
   exportgraphics(f1,'ats-mosart-annual-avg.png','Resolution',300);
   exportgraphics(f2,'ats-mosart-timeseries.png','Resolution',300);
end




% for the trib basin, load that data and replace the data in 'sag'
sag      = setfield(sag,'site_name',sitename);
flow     = bfra_loadflow('SAGAVANIRKTOK R TRIB NR PUMP STA 3 AK');
sag.time = flow.Time;
sag.flow = flow.Q;

% this was from save routed flow csv
discharge_slopes  = mosart.gaged.Dtiles;
discharge_outlet  = mosart.gaged.Dmod;
discharge_gaged   = mosart.gaged.Dobs;
Time              = mosart.gaged.Tmod;
