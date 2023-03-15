clean

hexvers = 'pyhexwatershed20220901014';

setpath(fullfile('icom/hexwatershed',hexvers,'hexwatershed'),'data');

pathmesh = setpath('icom/hexwatershed/mesh/','data');
pathdams = setpath('ICOM/data/dams/matfiles/');
pathsave = setpath('ICOM/figs/dams/');

% load the Dams and Mesh data
load('mpas_mesh.mat','Mesh');
load('icom_dams.mat','Dams');
% Dams = readtable('icom_dams.xlsx');

% plot it
h = m_map_hexshp(Mesh,Dams);

% save it 
if savefigs == true
   exportgraphics(gcf,'mpas_mesh_dams.png','Resolution',300);
end