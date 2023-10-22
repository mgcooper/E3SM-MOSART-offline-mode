function datatable = atsmosarttable(varargin)

   % This makes the xlsx file for Bo. Save this file to the testbed folder.

   if nargin < 1
      pathdata = fullfile(getenv('E3SMOUTPUTPATH'),getenv('MOSART_RUNID'),'mat');
      load([pathdata 'mosart.mat'],'mosart');
   else
      mosart = varargin{1};
   end

   discharge_slopes  = mosart.gaged.Dtiles;
   discharge_outlet  = mosart.gaged.Dmod;
   discharge_gaged   = mosart.gaged.Dobs;
   Time              = mosart.gaged.Tmod;

   % rename the table variable names to match the hillslopes
   N = size(discharge_slopes,2); % N=36
   vars = cell(N,1);
   for n = 1:N
      vars{n} = ['slope_' num2str(n)];
   end
   vars{n+1} = 'outlet_modeled';
   vars{n+2} = 'outlet_gaged';

   % convert to a timetable and write to a file
   datatable = horzcat(discharge_slopes,discharge_outlet,discharge_gaged);
   datatable = array2timetable(datatable,'RowTimes',Time,'VariableNames',vars);

   % % =======================================
   % % temporary hack to reorder the data in the correct years
   %
   % t1    = datetime(1998,1,1);
   % t2    = datetime(2002,12,31);
   % idx   = isbetween(Time,t1,t2);
   % Time  = Time(idx);
   %
   % Dmod = discharge_slopes;
   % Dobs = mosart.gaged.Dobs;
   % [ndays,ntiles] = size(Dmod);
   % nyrs = ndays/365;
   % Dmod = reshape(Dmod,365,nyrs,ntiles);
   % Dmod = Dmod(:,[5 6 7 1 2],1:ntiles);
   % Dmod = reshape(Dmod,365*(nyrs-2),ntiles);
   % Dobs = reshape(Dobs,365,nyrs,1);
   % Dobs = Dobs(:,[2 3 4 5 6],1);
   % Dobs = reshape(Dobs,365*(nyrs-2),1);
   %
   %
   % discharge_slopes = Dmod;
   % discharge_gaged = Dobs;
   % discharge_outlet = Dmod(:,5);
   %
   % figure; plot(Dmod(:,5)); hold on; plot(Dobs,':');
   % legend('ATS','USGS')
   %
   % figure; plot(Dmod(:,5)); hold on; plot(discharge_outlet,':');
   % plot(discharge_gaged);
   %
   % figure; plot(discharge_outlet,':'); hold on;
   % plot(discharge_gaged);legend('ATS','USGS')
   % % =======================================
end
