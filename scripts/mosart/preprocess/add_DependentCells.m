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
   save(fullfile(pathsave,'icom_dams_dep_cells.mat'),'Dams');
   writetable(Dams,fullfile(pathsave,'icom_dams_dep_cells.xlsx'));
end


test = table2array(Dams(:,26:end));
test = test(~isnan(test(:)));
min(test)
max(test)




