clean

%% set paths
pathdata = '/Users/coop558/work/data/e3sm/templates/';
pathsave = '/Users/coop558/work/data/e3sm/config/';
pathhslp = getenv('USER_HILLSLOPER_DATA_PATH');
% pathsag  = setpath('interface/data/hillsloper/sag_basin/');
cd(pathsave)

%% load the hillsloper data
% load([pathhslp 'sag_hillslopes']); slopes = newslopes; clear newslopes;
load(fullfile(pathhslp,'mosart_hillslopes'));
slopes          = mosartslopes; clear mosartslopes
sagvars         = fieldnames(slopes);
i               = isnan([slopes.dnID]);
slopes(i).dnID  = -9999;                    % replace nan with -9999

%% read in icom files to use as a template
% see sftp://compy.pnl.gov/compyfs/inputdata/rof/mosart/
fmosart = [pathdata 'MOSART_icom_half_c200624.nc'];
fsave   = [pathsave 'MOSART_sag_test.nc'];

% if exist(fsave,'file'); delete(fsave); end

%% mosart file (frivinp_rtm)
info    = ncparse(fmosart);
vars    = [info.Name];
nvars   = length(vars);
ncells  = length(slopes);

for i = 1:nvars
    vari = vars(i);
    myschema.(vari)             = ncinfo(fmosart,vari);
    irep                        = myschema.(vari).Size == 72;
    myschema.(vari).Size(irep)  = ncells;
    irep                        = [myschema.(vari).Dimensions.Length] == 72;
    myschema.(vari).Dimensions(irep).Length = ncells;
end

%% make the 'ele' array and reset rwid to 50
nele    = 11;
ele     = nan(nele,ncells);

for i = 1:length(slopes)
    ele(:,i)        = slopes(i).ele;
    slopes(i).rwid  = 50;
    slopes(i).fdir  = double(slopes(i).fdir);
end
ele = ele';

for i = 1:length(slopes)
    slopes(i).ele   = ele;
end

% this is incorrect. area should be in km2.
%% convert area from km2 to m2 (should have done this in make_newslopes)
% for i = 1:length(slopes)
%     slopes(i).area          = slopes(i).area.*1e6;
%     slopes(i).areaTotal     = slopes(i).areaTotal.*1e6;
%     slopes(i).areaTotal0    = [slopes(i).areaTotal0].*1e6;
%     slopes(i).areaTotal2    = slopes(i).areaTotal2.*1e6;
% end

%% loop through the remaining variable and replicate don's format

for i = 1:nvars-1
    vari    = vars(i);
    isag    = find(ismember(sagvars,vari));
    sagvar  = sagvars{isag};
    ncwriteschema(fsave,myschema.(vari));
    ncwrite(fsave,vars{i},[slopes.(sagvar)]);
end

ncwriteschema(fsave,myschema.ele);
ncwrite(fsave,'ele',ele);

newinfo.mosart  = ncinfo(fsave);

