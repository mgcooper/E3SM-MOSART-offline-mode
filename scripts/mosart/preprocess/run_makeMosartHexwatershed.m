clean

hexvers  = 'pyhexwatershed20220901014';
casename = 'susquehanna'; % will be appended to mosart filename

% addpath(genpath(getenv('E3SMSCRIPTPATH')));
addpath(genpath(getenv('E3SMTEMPLATEPATH')));
addpath(genpath(['/Users/coop558/mydata/icom/hexwatershed/' hexvers]))

filenames.in_hexwatershed  = 'hexwatershed.json';
filenames.in_template      = 'MOSART_icom_half_c200624.nc';
filenames.out_mosart       = ['mosart_' casename '_' hexvers '.nc'];

status = makeMosartHexwatershed(filenames);


% Input: 
% fhex: HexWaterhsed output
% ftem: Template MOSART input file to intepolate on
% fmos: MOSART input file
% fdom: Domain file
% show_river: show_river = 1, show river net work. Default = 0
% show_attributes: show_attributes = 1, show attributes. Default = 0

% addpath('/Users/xudo627/donghui/CODE/Setup-E3SM-Mac/matlab-scripts-to-process-inputs/');
% addpath('/Users/xudo627/donghui/CODE/Setup-E3SM-Mac/matlab-scripts-for-mosart/');
% addpath('/Users/xudo627/donghui/mylib/m/');