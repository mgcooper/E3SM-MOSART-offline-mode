function [i_downstream,ID_downstream] = findDownstreamCells(ID,dnID,points)
%FINDDOWNSTREAMCELLS finds all Mesh cells downstream of each point in points
% 
% Syntax:
% 
%  [i_downstream,ID_downstream] = findDownstreamCells(ID,dnID,points);
% 
% Author: Matt Cooper, 05-Oct-2022, https://github.com/mgcooper

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
   p                 = inputParser;
   p.FunctionName    = 'findDownstreamCells';
   
   addRequired(p,    'ID',     @(x)isnumeric(x));
   addRequired(p,    'dnID',   @(x)isnumeric(x));
   addRequired(p,    'points', @(x)islogical(x) | isnumeric(x));
   
   parse(p,ID,dnID,points);
   
%------------------------------------------------------------------------------

% if points is logical, convert to linear idx
if islogical(points)
   points = find(points);
end
numpoints = numel(points);

% locate the outlet cell from the global dn_ID
% ioutlet  = find(dnID==-1);
ioutlet = find(dnID==-9999);

% init the outputs
ID_downstream = cell(numpoints,1);
i_downstream = cell(numpoints,1);

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
   ID_downstream{n} = dnID_n;
   i_downstream{n} = dnidx_n;
end
