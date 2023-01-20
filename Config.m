function Config(varargin)

rootpath = '/Users/coop558/work/data/icom';
datapath = fullfile(rootpath,'hexwatershed');
hexvers = 'pyhexwatershed20221115006'; % 'pyhexwatershed20220901014';

setenv('HEXVERS',hexvers);
setenv('DATAPATH',fullfile(datapath,hexvers));
setenv('MESHFILE',fullfile(datapath,hexvers,'hexwatershed/mpas_mesh.shp'));
setenv('LINEFILE',fullfile(datapath,hexvers,'pyflowline/flowline_conceptual.shp'));
setenv('MESHJSONFILE',fullfile(datapath,hexvers,'hexwatershed/hexwatershed.json'));

% these ones are relative to the top-level icom data path
setenv('DAMSFILE',fullfile(rootpath,'dams/matfiles/icom_dams.mat'));
setenv('BOUNDSFILE',fullfile(rootpath,'dams/matfiles/DELW_SUSQ_poly.mat'));

% setenv('BOUNDSFILE',fullfile(rootpath,'GIS/SUSQ_DELW.shp'));
% setenv('DAMSFILE',fullfile(rootpath,'GIS/icom_dams_mesh.shp'));
% setenv('BOUNDSFILE',fullfile(rootpath,'GIS/SUSQ_DELW.shp'));

% % this one is saved in the local data folder
% setenv('MASKFILE',fullfile(rootpath,'GIS/SUSQ_DELW.shp'));

% % when I was only running the Susquehanna domain:
% setenv('DAMSFILE',fullfile(rootpath,'GIS/susq_dams.shp'));
% setenv('BOUNDSFILE',fullfile(rootpath,'GIS/SUSQ.shp'));