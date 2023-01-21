clean

% % %
sitename = 'trib_basin';
atsrun   = 'huc0802_gauge15906000_nopf'; %'huc0802_gauge15906000';

% workon E3SM-MOSART-offline-mode

% this assumes the mingpan data files have already been created, then reads
% those in and replaces the runoff with the ats runoff

% set the options
opts     = const( 'savefile',       false,                        ...
                  'sitename',       sitename,                     ...
                  'startyear',      1998,                         ...
                  'endyear',        2002                          );
                
nyears   = opts.endyear-opts.startyear+1;


pathdata = setpath(['interface/hillsloper/' sitename '/newslopes/'],'data');
pathroff = setpath(['interface/ATS/' atsrun],'data','goto');
pathtemp = ['/Users/coop558/work/data/e3sm/forcing/' sitename '/mingpan'];
pathsave = ['/Users/coop558/work/data/e3sm/forcing/' sitename '/ats'];

% load the hillsloper data, the ats runoff, and a template runoff .nc file
load([pathdata 'mosart_hillslopes']); slopes = mosartslopes;
load([pathroff 'ats_runoff.mat']); clear mosartslopes

% mos_plotslopes(slopes,links)
plot_hillsloper(slopes,links)

% get the ATS runoff
timeATS  = T.Time;
ndays    = numel(timeATS);
nslopes  = numel(slopes);
roffATS  = nan(ndays,nslopes);

% combine the ats runoff for each hillslope
for n = 1:nslopes
    
    str1 = ['slope_' num2str(2*n-1) ];
    str2 = ['slope_' num2str(2*n)];
    
    roffATS(:,n) = T.(str1) + T.(str2);
end
clear data str1 str2

% convert from m3/d to mm/s
area    = [slopes.area];                    % m2
roffATS = roffATS./area;                    % m/d
roffATS = roffATS*1000/(24*3600);           % mm/s
roffATS = reshape(roffATS,365,nyears,nslopes);
timeATS = reshape(timeATS,365,nyears);

% % % 

%% convert the ats data to a netcdf

roffMP  = nan(size(roffATS));    % initialize ats runoff

for n = 1:nyears
    
    thisyear    = num2str(opts.start_year + n - 1);
    frunoff     = [pathtemp 'runoff_' opts.site_name '_' thisyear '.nc'];
    fsave       = [pathsave 'runoff_' opts.site_name '_' thisyear '.nc'];
    
    % keep the ming pan runoff to compare with ATS
    roffMP(:,n,:)   = permute(ncread(frunoff,'QDRAI'),[3 2 1]);
    
    if ~exist(fsave,'file')
        system(['cp ' frunoff ' ' fsave]);
    end
    
    % QDRAI
    var     = 'QDRAI';
    sch     = ncinfo(frunoff,var);
    Qtmp    = squeeze(roffATS(:,n,:));
    QDRAI   = nan(nslopes,1,365);
    for m = 1:365
        QDRAI(:,1,m) = Qtmp(m,:);
    end

    if opts.save_file
        ncwriteschema(fsave,sch);
        ncwrite(fsave,var,QDRAI);
    end

    % QOVER
    var     = 'QOVER';
    sch     = ncinfo(frunoff,var);
    QOVER   = 0.0.*QDRAI;
    
    if opts.save_file
        ncwriteschema(fsave,sch);
        ncwrite(fsave,var,QOVER);
    end

    newinfo = ncinfo(fsave);

end

% for plotting, reshape back to one timeseries and convert to m3/s
roffATS = reshape(roffATS,365*nyears,nslopes);
roffATS = sum(roffATS.*area,2)/1000;

roffMP  = reshape(roffMP,365*nyears,nslopes);
roffMP  = sum(roffMP.*area,2)/1000;

%% compare ATS roff with ming pan roff

figure('Position',[165   299   762   294]);
subplot(1,2,1);
plot(timeATS(:),roffATS); hold on;
plot(timeATS(:),roffMP);
legend('ATS','Ming Pan');
ylabel('daily runoff [m$^3$ s$^{-1}$]');

subplot(1,2,2);
plot(timeATS(:),cumsum(roffATS.*(3600*24/1e9))); hold on;
plot(timeATS(:),cumsum(roffMP.*(3600*24/1e9)));
l = legend('ATS','Ming Pan');
ylabel('cumulative runoff [km$^3$]');
figformat

