clean

pathsave = setpath('icom/dams','data');

load(setpath('E3SM-MOSART-offline-mode/data/matfiles/DependentCellsArray.mat','project'))
load(setpath('E3SM-MOSART-offline-mode/data/matfiles/Dams_with_Dependency.mat','project'),'Dams')

oldDams = Dams;

load(setpath('icom/dams/matfiles/icom_dams.mat','data'),'Dams')

%% convert the table to an array, append the dependent cells

Dams.DAM_NAME(37) = {'MARSH CREEK'};

Dams = addDependentCells(Dams,DependentCells,oldDams);

%% save it

if savedata == true
   save([pathsave 'icom_dams_dep_cells.mat'],'Dams');
   writetable(Dams,[pathsave 'icom_dams_dep_cells.xlsx']);
end




