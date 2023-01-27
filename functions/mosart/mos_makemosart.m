function [schema,info,data] = mos_makemosart(tiles,ftemplate,fsave,opts)
%MOS_MAKEMOSARTFILE make mosart parameter file for E3SM (frivinp_rtm)
% 
%     [schema,info,data] = mos_makemosart(tiles,ftemplate,fsave,opts)
% 
% Inputs
% 
%     tiles    a structure with the following fields
% 
%        longxy   latitude of computational unit, scalar
%        latixy   longitude of computational unit, scalar
%        area     area in m2
%        
% 
% Outputs
% 
%   'schema' a netcdf schema structure for the output file
%   'info' the output of ncinfo for the output file, should match schema
% 
% 

%-------------------------------------------------------------------------------

% parse options
savefile = opts.savefile;

% the variables provided to create the file
inVars = fieldnames(tiles);

% number of hillslope units in the domain
nCells = numel(tiles);

% replace the outlet ID nan with -9999
try
   tiles(isnan([tiles.dnID])).dnID = -9999;
catch ME
   if strcmp(ME.identifier,'MATLAB:index:expected_one_output_for_assignment')
      % should indicate the outlets are already -9999
   end
end

% for comparing hexwatershed to hillslloper
% sum(isnan([tiles.dnID]))
% sum([tiles.dnID] == -9999) % 2412

% these are the variables created by this function:
varInfo = ncparse(ftemplate);
outVars = [varInfo.Name];
nVars  = length(outVars);

% the template file has 72 grid cells, need to replace with ncells
iReplace = find(ismember(varInfo.Name,'latixy'));
sizeReplace = cell2mat(varInfo.Size(iReplace));

% initialize the new file from the template file and update the dimension size
for n = 1:nVars

   thisVar = outVars(n);

   % assign the template schema to the new schema
   theNewSchema.(thisVar) = ncinfo(ftemplate,thisVar);

   iReplace = theNewSchema.(thisVar).Size == sizeReplace;

   theNewSchema.(thisVar).Size(iReplace) = nCells;

   iReplace = [theNewSchema.(thisVar).Dimensions.Length] == sizeReplace;

   theNewSchema.(thisVar).Dimensions(iReplace).Length = nCells;
end


%% make the 'ele' array
nele = 11;
ele = nan(nele,nCells);

for n = 1:length(tiles)
   ele(:,n) = tiles(n).ele;
   tiles(n).rwid = 30; % 20 Jan 2023 changed 50 to 30 to test
%    tiles(n).rwid0 = 30; % 20 Jan 2023 changed 50 to 30 to test
   tiles(n).rdep = 4; % 20 Jan 2023 changed 2 to 4 to test
   tiles(n).nr = 0.5;
   tiles(n).fdir = double(tiles(n).fdir);
end
ele = ele';

for n = 1:length(tiles)
   tiles(n).ele  = ele;
end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % this was 
% %% convert area from km2 to m2 (should have done this in make_newtiles)

% this is incorrect. area should be in km2.

% for i = 1:length(tiles)
%     tiles(i).area          = tiles(i).area.*1e6;
%     tiles(i).areaTotal     = tiles(i).areaTotal.*1e6;
%     tiles(i).areaTotal0    = [tiles(i).areaTotal0].*1e6;
%     tiles(i).areaTotal2    = tiles(i).areaTotal2.*1e6;
% end

%% loop through the remaining variables and replicate donghui's format

% write the new file
if savefile

   % delete the file if it exists, otherwise there will be errors
   if isfile(fsave); delete(fsave); end

   % write all data
   for n = 1:nVars-1

      thisVar = outVars(n);
      iVar    = ismember(inVars,thisVar);
      varData = [tiles.(inVars{iVar})];

      ncwriteschema(fsave,theNewSchema.(thisVar));

      if any(strcmp(thisVar,{'lon','longxy'}))
         varData = wrapTo360(varData);
      end

      ncwrite(fsave,outVars{n},varData);

   end

   ncwriteschema(fsave,theNewSchema.ele);
   ncwrite(fsave,'ele',ele);

   % read in the new file to compare with the old file
   varInfo = ncinfo(fsave);
else
   varInfo = 'file not written, see newschema';
end

schema  = theNewSchema;
info    = varInfo;
data    = ncreaddata(fsave);
