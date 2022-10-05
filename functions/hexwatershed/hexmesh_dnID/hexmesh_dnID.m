function [ID,dnID] = hexmesh_dnID(Mesh)
%HEXMESH_DNID returns the ID and downstream ID (dnID) of each cell in Mesh.
%Works for global Mesh or flowline Mesh
% 
% Syntax:
% 
%  [ID,dnID] = HEXMESH_DNID(Mesh);
% 
% Author: Matt Cooper, 04-Oct-2022, https://github.com/mgcooper

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'hexmesh_dnID';

addRequired(p,    'Mesh',                 @(x)isstruct(x)      );

parse(p,Mesh);
   
%------------------------------------------------------------------------------

globalID    = [Mesh(:).lCellID]';
globaldnID  = [Mesh(:).lCellID_downslope]';

% Convert ID
N  = numel(globalID);
ID = (1:N)';
dnID = nan(N,1);

for n = 1:N
   if globaldnID(n) == -9999
      dnID(n) = -9999;
   else
      idx = find(globalID == globaldnID(n));
      if isempty(idx)
         dnID(n) = -9999;
      else
         dnID(n) = ID(idx);
      end
   end
end





