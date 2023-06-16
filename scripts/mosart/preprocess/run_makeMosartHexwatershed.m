clean

% 26 Jan I generated the domain_icom.nc and MOSART_icom.nc files using the code
% below and sent to Tian. 
% 
% makeMosartHexwatershed is based on generate_mosart_from_hexwateshed in Setup-E3SM
% 
% I wasn't quite able to reconcile it with mos_makemosart. the key thing is it 
% will require a pre-processing step that adds the necessary fields to Mesh like
% b_make_newslopes adds the info to the slopes struct. 


sitename = 'icom';
fhex = fullfile(getenv('USER_E3SM_DOMAIN_DATA_PATH'),'hexwatershed.json');
ftem = fullfile(getenv('USER_E3SM_TEMPLATE_PATH'),'MOSART_icom_half_c200624.nc');
fout = fullfile(getenv('USER_E3SM_CONFIG_PATH'),['MOSART_' sitename '.nc']);
fdom = fullfile(getenv('USER_E3SM_CONFIG_PATH'),['domain_' sitename '.nc']);

% this won't work until get_geometry is setup 
makeMosartHexwatershed(fhex,ftem,fout,'fdom',fdom);

% read in the file 
data = ncreaddata(fout);


%% below here is the version I was working on previously

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