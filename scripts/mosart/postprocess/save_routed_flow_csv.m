clean

% THE XLSX FILE I MADE FOR BO:
savedata = false;
run      = 'trib_basin.1997.2003.run.2022-11-22.ats';
pathdata = [getenv('E3SMOUTPUTPATH') run '/mat/'];

load([pathdata 'mosart.mat'],'mosart');

discharge_slopes  = mosart.gaged.Dtiles;
discharge_outlet  = mosart.gaged.Dmod;
discharge_gaged   = mosart.gaged.Dobs;
Time              = mosart.gaged.Tmod;

% =======================================
% temporary hack to reorder the data in the correct years

t1    = datetime(1998,1,1);
t2    = datetime(2002,12,31);
idx   = isbetween(Time,t1,t2);
Time  = Time(idx);

Dmod = discharge_slopes;
Dobs = mosart.gaged.Dobs;
[ndays,ntiles] = size(Dmod);
nyrs = ndays/365;
Dmod = reshape(Dmod,365,nyrs,ntiles);
Dmod = Dmod(:,[5 6 7 1 2],1:ntiles);
Dmod = reshape(Dmod,365*(nyrs-2),ntiles);
Dobs = reshape(Dobs,365,nyrs,1);
Dobs = Dobs(:,[2 3 4 5 6],1);
Dobs = reshape(Dobs,365*(nyrs-2),1);


discharge_slopes = Dmod;
discharge_gaged = Dobs;
discharge_outlet = Dmod(:,5);

figure; plot(Dmod(:,5)); hold on; plot(Dobs,':');
legend('ATS','USGS')

figure; plot(Dmod(:,5)); hold on; plot(discharge_outlet,':');
plot(discharge_gaged);
% =======================================


% rename the table variable names to match the hillslopes 
N        = size(discharge_slopes,2); % N=36
vars     = cell(N,1);
for n = 1:N
   vars{n} = ['slope_' num2str(n)];
end
vars{n+1}   = 'outlet_modeled';
vars{n+2}   = 'outlet_gaged';

% convert to a timetable and write to a file
discharge   = horzcat(discharge_slopes,discharge_outlet,discharge_gaged);
discharge   = array2timetable(discharge,'RowTimes',Time,'VariableNames',vars);

if savedata == true
   writetimetable(discharge,'ats-mosart.xlsx');
end
