function A = combineHillslopeArea(fname_area_data,varargin)

% read the area. the negative numbers are underscores in the runoff table
A0 = readtable(fname_area_data);
A1 = sortrows(A0(A0.ID<0,:),'ID','descend');
A2 = sortrows(A0(A0.ID>0,:),'ID','ascend');
A  = A1.area_m2_ + A2.area_m2_;

% hs_id is the hs_id field in the hillsloper links file, becuase the
% mosart_hillslopes are  numbered from 1:numel(links), but the ats data is
% numbered by the hillsloper hs_id field. 
if nargin > 1
   hs_id = varargin{1}; 
else
   hs_id = 1:numel(A);
end

A = A(hs_id(:));

% total area should be 85839108.88 m2

% this would return A as a table
% A = A2;
% A.area_m2_ = A1.area_m2_ + A2.area_m2_;

% % this would be for the runoff file
% for n = 1:nslopes
%     str1 = ['hillslope_' num2str(n) ];
%     str2 = ['hillslope' num2str(n)  ];
%     roffATS(:,n) = T.(str1) + T.(str2);
%     areaATS(n) = A.area_m2_(A.ID==-n) + A.area_m2_(A.ID==n);
% end
% clear data str1 str2
