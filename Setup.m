function Setup()
% SETUP set paths etc.
% 
% See also Config

% temporarily turn off warnings about paths not already being on the path
warning off

% Get the path to this file, in case Setup is run from some other folder. More
% robust than pwd(), but assumes the directory structure has not been modified.
thispath = fileparts(mfilename('fullpath'));

% add all paths then remove git paths
addpath(genpath(thispath));
rmpath(genpath([thispath filesep '.git*']));

% add paths set in Config

% turn warning back on
warning on