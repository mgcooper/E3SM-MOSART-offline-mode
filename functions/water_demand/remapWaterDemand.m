function CU = remapWaterDemand(CUTW,W,IN,gcam_weights,idx_gcam)
%REMAPWATERDEMAND 

% Initialize the consumptive use array (nyears*12monthsperyear x nmeshcells)
CU = nan(size(CUTW,1)*size(gcam_weights,1), size(W,1));

for m = 1:size(W,1)
   
   % Monthly weights for the gcam cell nearest this mesh cell
   WT = gcam_weights(:,idx_gcam(m));
   
   % Monthly consumptive use (CU) for this mesh cell = the annual consumptive
   % use for the subbasin(s) that this mesh cell is in/on CUTW(:,IN{m}), scaled
   % by the ratio of the mesh cell area to the subbasin(s) area W{m}, and by the
   % ratio of monthly GCAM demand to annual GCAM demand WT'. Some identities:
   % sum(IN{m}) == numel(W{m}), numel(CUTW(:,IN{m}) * W{m}) == size(CUTW,1)
   cu = CUTW(:,IN{m}) * W{m} * WT' ;
   
   % Reshape cu from nyears x nmonths to nyears*nmonths x 1
   CU(:,m) = reshape( cu.', [], 1 ) ;

end


% % for plotting gcam cells on top of the figure and the cell in question
% hold on; 
% scatter(GCAM_X,GCAM_Y,100,'r','filled')
% scatter(GCAM_X(igcam(m)),GCAM_Y(igcam(m)),100,'g','filled')
% scatter(XC(m),YC(m),80,'y','filled')
% 
% test = reshape(cu.',[],1);
% figure; plot(Time,test);
% ylabel('Monthly Consumptive Use (m3/s)')