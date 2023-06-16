function Dams = addDependentCells(Dams,DependentCells,varargin)

% refDams was an older Dams table with 22 dams, the ones for the Susq basin,
% whereas the Dams produced by makeDamDependency had all 40 icom_dams, so I kept
% this option for reference, it was used for the first table I sent Tian, but
% with the new resutls using the mask in makeDamDependency it shouldn't be used
if nargin == 3
   refDams = varargin{1};
else
   refDams = Dams; 
   refDams.Name = refDams.DAM_NAME;
end

Data = removevars(Dams,{'DAM_NAME','NIDID','PURPOSES','SOURCE'});
Vars = gettablevarnames(Data);
Data = table2array(Data);
NumC = size(DependentCells,2);
DepC = nan(size(Data,1),NumC);
Data = horzcat(Data,DepC);

for n = 1:height(refDams)
   idx = find(ismember(Dams.DAM_NAME,refDams.Name(n)));
   Data(idx,size(Data,2)+1:end) = DependentCells(n,:);
end

for n = 1:NumC
   Vars{size(Data,2)+n} = ['cells_' num2str(n)];
end

Data = array2table(Data,'VariableNames',Vars);

Data.DAM_NAME = Dams.DAM_NAME;
Data.NIDID = Dams.NIDID;

Data = movevars(Data,{'DAM_NAME','NIDID'},'Before','LONGITUDE');

Dams = Data;

% % for reference, before I added the cells as rows to the table:
% % add the dependent cells to the Dams table
% for n = 1:numel(xdams)
%    Dams.ID_DependentCells{n} = DependentCells(n,~isnan(DependentCells(n,:)));
%    Dams.i_DependentCells{n} = i_DependentCells(n,~isnan(i_DependentCells(n,:)));
% end