function Config()
% CONFIG set user configuration, environment variables, etc.
% 
%  See also Setup

% set environment variables to find data

% path to ATS runoff data
setenv('USER_ATS_DATA_PATH',[getenv('USERDATAPATH') 'interface/ATS']);

% path to HILLSLOPER data files
setenv('USER_HILLSLOPER_DATA_PATH',[getenv('USERDATAPATH') 'interface/hillsloper/trib_basin/newslopes'])

% path to MOSART template files
% setenv('USER_MOSART_TEMPLATE_PATH',[getenv('USERDATAPATH') 'interface/ATS/'])

% need to organzie this
setenv('USER_MOSART_TEMPLATE_PATH','/Users/coop558/work/data/e3sm/templates')

% path to runoff files
setenv('USER_MOSART_RUNOFF_PATH', '/Users/coop558/work/data/e3sm/forcing');

% set path to domain/mosart config files
setenv('USER_E3SM_CONFIG_PATH', '/Users/coop558/work/data/e3sm/config');

setenv('MOSART_TESTBED', fullfile(pwd,'testbed'));
% [keys,vals] = getuserpaths;