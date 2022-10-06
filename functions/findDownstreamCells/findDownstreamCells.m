function [dnidx,dnIDs] = findDownstreamCells(Mesh,points)
%FINDDOWNSTREAMCELLS finds all Mesh cells downstream of each point in points
% 
% Syntax:
% 
%  [dnidx,dnID] = findDownstreamCells(Mesh,points);
% 
% Author: Matt Cooper, 05-Oct-2022, https://github.com/mgcooper

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
   p                 = inputParser;
   p.FunctionName    = 'findDownstreamCells';
   
   addRequired(p,    'Mesh',                 @(x)isstruct(x));
   addRequired(p,    'points',               @(x)islogical(x) | isnumeric(x));
   
   parse(p,Mesh,points);
   
%------------------------------------------------------------------------------

% if points is logical, convert to linear idx
if islogical(points)
   points = find(points);
end
numpoints = numel(points);

% pull out the global ID and dnID and locate the outlet
ID       = [Mesh.global_ID];
dnID     = [Mesh.global_dnID];
% ioutlet  = find(dnID==-1);
ioutlet = find([Mesh.global_dnID]==-9999);

% init the outputs
dnIDs = cell(numpoints,1);
dnidx = cell(numpoints,1);

% loop over all points and find all downstream cells
for n = 1:numpoints
   idn      = points(n);
   dnID_n   = [];
   dnidx_n  = [];
   while idn ~= ioutlet
      idn      = find(ID==dnID(idn));
      dnID_n   = [dnID_n; dnID(idn)];  %#ok<AGROW>
      dnidx_n  = [dnidx_n; idn];       %#ok<AGROW>
   end
   dnIDs{n} = dnID_n;
   dnidx{n} = dnidx_n;
end
