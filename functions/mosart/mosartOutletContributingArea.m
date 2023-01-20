% ####################################################################### %
% Description: search the contribuing grid cells in the MOSART domain given
%              the coordinate of a station 
%
% Input:  fname -------> file name of MOSART parameter file
%         lon ---------> longitude of the station
%         lat ---------> latitude of the station
%         target_area -> accurate area of the basin [m^2]
% Output: ioutlet -------> corresponding outlet index in the domain file
%         icontributing -> the indices of the cells that contributing to
%                          the given coordinate
%
%
% Author: Donghui Xu
% Date: 08/13/2020
% ####################################################################### %
% function [ioutlet,icontributing] = mosartOutletContributingArea(        ...
%                                     fname,lon,lat,varargin)
%MOSARTOUTLETCONTRIBUTINGAREA
%

function [ioutlet,icontributing] = mosartOutletContributingArea(ID,dnID)
%--------------------------------------------------------------------------
% % parse inputs
% p = inputParser;
% p.FunctionName = 'mosartOutletContributingArea';
% 
% addRequired(   p,    'fname',                      @(x)ischar(x)     );
% addRequired(   p,    'lat',                        @(x)isnumeric(x)  );
% addRequired(   p,    'lon',                        @(x)isnumeric(x)  );
% addParameter(  p,    'targetarea',     [],         @(x)isnumeric(x)  );
% addParameter(  p,    'searchmethod',   'upstream', @(x)ischar(x)     );
% addParameter(  p,    'debug',          false,      @(x)islogical(x)  );
% 
% parse(p,fname,lat,lon,varargin{:});
% 
% targetarea     = p.Results.targetarea;
% searchmethod   = p.Results.searchmethod;
% debug          = p.Results.debug;

%--------------------------------------------------------------------------

searchmethod = 'upstream'; % tmp for testing

switch searchmethod
   case 'downstream'
      searchmethod = 1;
   case 'upstream'
      searchmethod = 2;
end
% method 1: searching from each cell to see if it flows to the given outlet
% method 2: searching from the outlet <- much quicker!

% % temp commented out for testing
% dnID     = ncread(fname,'dnID');
% ID       = ncread(fname,'ID');
% latixy   = ncread(fname,'latixy');
% longxy   = ncread(fname,'longxy');
% area     = ncread(fname,'area');
% 
% if ~isempty(targetarea)
%    if targetarea < mean(area,'omitnan')
%       disp('watershed is smaller than the grid cell!!!');
%       targetarea = [];
%    end
% end

[m,n] = size(dnID);
numcells = m*n;

dist = pdist2([longxy(:) latixy(:)],[lon lat]);
[~,I] = sort(dist);

if isempty(targetarea)
   searchN = 1;
else
   searchN = 20;
end

for ifound = 1:searchN
   
   ioutlet = I(ifound);
   outletg = ID(ioutlet);
   
   icontributing = [];
   
   if searchmethod == 1
      tenperc = ceil(0.1*numcells);
      
      for n = 1:numcells
         if mod(n,tenperc) == 0
            fprintf(['-' num2str(n/tenperc*10) '%%']);
         end
         found = dnID(n) == ID(outletg);
         m = n;
         while ~found && dnID(m) ~= -9999
            m = find(ID == dnID(m));
            found = dnID(m) == ID(outletg);
         end
         if found
            icontributing = [icontributing; n]; %#ok<*AGROW>
         end
      end
      fprintf('-100%% Done!\n');
   elseif searchmethod == 2
      found = outletg;
      while ~isempty(found)
         found2 = [];
         for n = 1 : length(found)
            upstrm = find(dnID == found(n));
            found2 = [found2; upstrm];
         end
         icontributing = [icontributing; found2];
         found = found2;
      end
   end
   if ~isempty(targetarea)
      drainagearea = sum(area([ioutlet; icontributing]),'omitnan');
      %disp(drainagearea/2.59e+6);
      if drainagearea/targetarea > 0.5 && drainagearea/targetarea < 1.5
         fprintf(['MOSART drainage area is ' num2str(drainagearea/1e6) 'km^{2}\n']);
         fprintf(['GSIM drainage area is ' num2str(targetarea/1e6) 'km^{2}\n']);
         break;
      end
   end
end
if ~isempty(targetarea)
   if drainagearea/targetarea < 0.5 || drainagearea/targetarea > 1.5
      ioutlet = I(1);
      outletg = ID(ioutlet);
      icontributing = [];
      found = outletg;
      while ~isempty(found)
         found2 = [];
         for n = 1:length(found)
            upstrm = find(dnID == found(n));
            found2 = [found2; upstrm];
         end
         icontributing = [icontributing; found2];
         found = found2;
      end
   end
end

if debug
   figure;
   plot(longxy(icontributing),latixy(icontributing),'k+'); hold on;
   plot(longxy(ioutlet), latixy(ioutlet), 'ro');
end

