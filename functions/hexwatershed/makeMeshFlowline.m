function [latline,lonline] = makeMeshFlowline(dnID,lat,lon)

%-------------------------------------------------------------------------------
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

%-------------------------------------------------------------------------------

plotfig = false;

ioutlets = find(dnID==-9999);
noutlets = numel(ioutlets);

latline = cell(noutlets,1);
lonline = cell(noutlets,1);

for m = 1:noutlets

   % upstream cells are those that have this outlet as their downstream cell
   iupstream = find(ismember(dnID,ioutlets(m)));
   nupstream = numel(iupstream);

   % walk up each branch
   while nupstream > 0

      for n = 1:nupstream

         % get the downstream cell for this upstream cell
         thisoutlet = dnID(iupstream(n));
         latline{m} = [latline{m};lat(iupstream(n));lat(thisoutlet);nan];
         lonline{m} = [lonline{m};lon(iupstream(n));lon(thisoutlet);nan];

         if plotfig == true
            plot([lon(iupstream(n)),lon(thisoutlet)],[lat(iupstream(n)),lat(thisoutlet)]);
         end

      end
      iupstream = find(ismember(dnID,iupstream));
      nupstream = numel(iupstream);
   end
end

% to keep as cell arrays:
latline = latline(~cellfun(@isempty,latline));
lonline = lonline(~cellfun(@isempty,lonline));

% % to convert to nan-separated lists:
% [latline,lonline] = polyjoin(latline,lonline);
% [lonline,latline] = removeExtraNanSeparators(lonline,latline);

% plot it
% figure; geoshow(latline,lonline);

% for reference, these were the coordinate pairs I was using to debug, these
% should be separated by nan, the problem was they were not so geoshow was
% drawing a line between them. now that the algo is working, probably delete.
% -78.582, 42.821 to -78.604, 42.733

% use this to find all outlets that have at least one upstream cell, or more
% than one for testing purposes (17 has more than one)
% notempty = [];
% for m = 1:noutlets
%    if sum(ismember(dnID,ioutlet(m))) > 1
%       notempty = [notempty; m];
%    end
% end
