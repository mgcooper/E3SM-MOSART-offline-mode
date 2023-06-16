function [TWD,X,Y] = loadGcamWaterDemand(varargin)

usegeo = varargin{1};

% GCAM
load(fullfile( ...
   getenv('MATLAB_ACTIVE_PROJECT_PATH'),'data','matfiles','GCAM_waterdemand'), ...
   'TWD');

% Pull out the X/Y coordinates
Y = TWD.Properties.CustomProperties.Lat;
X = TWD.Properties.CustomProperties.Lon;

if usegeo == false
   [X,Y] = ll2utm(Y,X,18,'wgs84');
end