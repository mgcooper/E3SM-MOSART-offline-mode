function [Withdrawals, Meta] = loadDrbcWaterDemand()
%LOADDRBCWATERDEMAND

try
   load(fullfile( ...
      setpath('icom/DRBC/withdrawals','data'),'withdrawals'), ...
      'Withdrawals','Meta');
catch
   try
      load(fullfile( ...
      getenv('MATLAB_ACTIVE_PROJECT_DATA_PATH'),'withdrawals'), ...
      'Withdrawals','Meta');
   catch
   end
end