

% this can be deleted once its all worked out, but this is more explicit and
% includes more steps to show exactly how the annual drbc sub-basin water use is
% mapped onto the monthly GCAM demand cycle and then onto the mesh cells


for m = 1:size(XV,1)
   
   % The annual consumptive use for the subbasin(s) that this mesh cell is in/on
   cu = CUTW(:,IN{m});
   
   % Scaled by the ratio of the mesh cell area to the subbasin(s) area
   cu = cu * W{m} ; 
   
   % test = cu; % keep for confirming
   
   % analogous to:
   % V2(m) = sum(V(IN{m}).*W{m});
   
   % The monthly demand cycle for the gcam cell nearest this mesh cell (time
   % weights). 
   WT = GCAM_weights(:,igcam(m));
   
   % If W{m} was not applied yet, then I would need to repmat the weights for
   % each subbasin that contributes to this cell
   % WT = repmat(GCAM_weights(:,igcam(m)).',size(cu,2),1);
   
   
   % scale the annual CU by the monthly GCAM cycle to get the monthly CU for the
   % subbasin
   cu = cu * WT';
   
   % if test = cu is active above, this confirms:
   % max(abs(sum(cu,2)-test))
   
   % confirm
   % test1 = cu(:,1) * GCAM_weights(:,igcam(m)).';
   % test2 = cu(:,2) * GCAM_weights(:,igcam(m)).';
   % test3 = test1+test2;
   % dtest = abs((test3-test));
   % max(dtest(:))
   
   V2(m) = sum(V(IN{m}).*W{m});
end