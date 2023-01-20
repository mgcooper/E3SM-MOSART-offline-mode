function [i_downstream,ID_downstream] = findDownstreamCells(ID,dnID,ipoints,IDtype)
%FINDDOWNSTREAMCELLS finds the index 'i_downstream' and cell ID 'ID_downstream'
%all Mesh cells downstream of each point in ipoints, where ipoints is either a
%logical of size equal to ID/dnID and is true for the requested starting
%points, or a list of indices of the points on 1:numel(ID) (i.e., not on ID).
%ID and dnID are the cell ID and downstream cell ID. Specify 'hexwatershed' as
%the last argument if ID/dnID are the lCellID and lCellID_downslope fields from
%the hexwatershed output, or 'mosart' if ID/dnID are the ID and dnID fields in
%the mosart parameter file, for example as produced by findHexMeshdnID.
% 
% Syntax:
% 
%  [i_downstream,ID_downstream] = findDownstreamCells(ID,dnID,points);
% 
% Author: Matt Cooper, 05-Oct-2022, https://github.com/mgcooper

% NOTE: I think we want to remove the first value in i_downstream OR add that
% value to ID_downstream and then remove -9999 from ID_downstream and then only
% keep one because they are the same. But for hexwatershed ID/dnID they may not
% be the same, so could keep both. 

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'findDownstreamCells';

addRequired(p, 'ID',                @(x)isnumeric(x));
addRequired(p, 'dnID',              @(x)isnumeric(x));
addRequired(p, 'points',            @(x)islogical(x) | isnumeric(x));
addOptional(p, 'IDtype', 'mosart',  @(x)ischar(x));

parse(p,ID,dnID,ipoints,IDtype);
   
%------------------------------------------------------------------------------

% if points is logical, convert to linear idx
if islogical(ipoints)
   ipoints = find(ipoints);
end
numpoints = numel(ipoints);

% locate the outlet cell from the global dn_ID
switch IDtype
   case 'mosart'
      ioutlet = find(dnID==-9999);
   case 'hexwatershed'
   % this would be used if lCellID and lCellID_downslope are passed in as ID/dnID
      ioutlet = find(dnID==-1);
end


% init the outputs
ID_downstream = cell(numpoints,1);
i_downstream = cell(numpoints,1);

% loop over all points and find all downstream cells
for n = 1:numpoints
   idn      = ipoints(n);
   dnID_n   = [];
   dnidx_n  = [];
   
   while ~ismember(idn,ioutlet) % idn ~= ioutlet % use ismember if ioutlet is not scalar
      idn      = find(ID==dnID(idn));  % for 'mosart', idn is just dnID(idn)
      dnID_n   = [dnID_n; dnID(idn)];  %#ok<AGROW>
      dnidx_n  = [dnidx_n; idn];       %#ok<AGROW>
   end
   %ID_downstream{n} = dnID_n(dnID_n~=ioutlet); % don't keep the outlet id
   ID_downstream{n} = dnID_n; % keep the outlet id
   i_downstream{n} = dnidx_n;
end


% % this is the algorithm in hexmesh_dnID:
% for n = 1:N
%    if cell_dnID(n) == -9999
%       dnID(n) = -9999;
%    else
%       idx = find(cell_ID == cell_dnID(n));
%       if isempty(idx)
%          dnID(n) = -9999;
%       else
%          dnID(n) = ID(idx);
%       end
%    end
% end
