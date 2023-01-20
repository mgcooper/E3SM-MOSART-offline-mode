function plotDamDependency(Dams,DependentCells,Mesh,FlowLine,Mask,varargin)
%PLOTDAMDEPENDENCY plot the result of the Dam Dependency algorithm

if nargin == 5
   idams = 1:height(Dams);
elseif nargin == 6
   idams = varargin{1};
else
   error('incorrect input')
end

try
   latdams = Dams.Lat;
   londams = Dams.Lon;
catch
   latdams = Dams.LATITUDE;
   londams = Dams.LONGITUDE;
end

% plot all in a loop
figure('Position', [50 60 1200 1200]); hold on; 

for n = 1:numel(idams)
      
   idam = idams(n);

   fprintf('\n plotting %d out of %d results',n,numel(idams))

   % if the older method is used that added these to the Dams table:
   % IDdepends = Dams.ID_DependentCells{idam};
   % idepends = Dams.i_DependentCells{idam};
   
   IDdepends = rmnan(DependentCells(idam,:));
   idepends = ismember([Mesh.lCellID],IDdepends);
   
   patch_hexmesh(Mesh); % use 'FaceMapping','Elevation' to see the elevation
   patch_hexmesh(Mesh(idepends),'FaceColor','g'); 
   % patch_hexmesh(Mesh([Mesh.iflowline]),'FaceColor','b'); 
   scatter(londams,latdams,'m','filled'); geoshow(FlowLine);
   if ~isempty(Mask)
      plot(Mask(:,2),Mask(:,1),'k');
   end
   scatter(londams(idam),latdams(idam),100,'r','filled');

   if n < numel(idams)
      pause; clf
   end
end
