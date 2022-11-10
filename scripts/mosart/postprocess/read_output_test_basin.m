clean

% This is an example of how the MOSART output can be processed using the
% functions in functions/. These functions take the unstructured MOSART
% output and map the runoff onto the hillslopes, locate the hillslope that
% contains the basin outlet, and computes the runoff. 

savedata = true;
sitename = 'trib_basin';
run      = 'trib_basin.1998.2002.run.2022-07-21.ats';

%% set paths

pathdata   = [getenv('MOSARTOUTPUTDIR') run '/run/'];
pathsave   = [getenv('MOSARTOUTPUTDIR') run '/mat/'];

if ~exist(pathsave,'dir'); mkdir(pathsave); addpath(pathsave); end; 
cd(pathdata)

%% read the e3sm output and clip the data to the gaged basin and time

% if h0 and h1 files exist, h1 = daily data saved annually, but depending
% on how the tapes are set up the daily data can be h0 so gotta set this
flist   = getlist(pathdata,'*.mosart.h0*');
mosart  = mos_readoutput(flist);
mosart  = mos_clipbasin(mosart,sag);

% figure; set(gca,'YLim',[0 35]); hold on;
% for n = 1:22
%     plot(mosart.D(:,n)); hold on; 
%     title(num2str(n)); pause; 
% end

figure; 
plot(mosart.gaged.Tavg,mosart.gaged.Dobs_avg); hold on;
plot(mosart.gaged.Tavg,mosart.gaged.Dmod_avg); 
legend('USGS gage','GRFR-MOSART'); datetick;
ylabel('m^3/s','Interpreter','tex');


figure; 
plot(mosart.gaged.Tavg,mosart.gaged.Dobs_avg); hold on;
plot(mosart.gaged.Tavg,mosart.gaged.Dmod_avg); 
legend('USGS gage','ATS-MOSART'); datetick;
ylabel('m^3/s','Interpreter','tex');

%% save it
if savedata == true
    if ~exist(pathsave,'dir'); mkdir(pathsave); end
    save([pathsave 'mosart.mat'],'mosart');
end
