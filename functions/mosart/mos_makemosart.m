function [schema,info,data] = mos_makemosart(slopes,ftemplate,fsave,opts)
%MOS_MAKEMOSARTFILE makes a mosart file (frivinp_rtm) i.e. the mosart
%parameter file for E3SM
    
% Inputs: 
%   'slopes' a structure with the following fields:
%       longxy  = latitude of computational unit, scalar
%       latixy  = longitude of computational unit, scalar
%       area    = area in m2

% Outputs:
%   'schema' a netcdf schema structure for the output file
%   'info' the output of ncinfo for the output file, should match schema

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% parse options
   savefile = opts.save_file;

% the variables provided to create the file
   inVars   = fieldnames(slopes);

% number of hillslope units in the domain
   nCells   = numel(slopes);

% replace the outlet ID nan with -9999
   slopes(isnan([slopes.dnID])).dnID  = -9999;

% these are the variables created by this function:
   varInfo  = ncparse(ftemplate);
   outVars  = [varInfo.Name];
   nVars    = length(outVars);
    
% the template file has 72 grid cells, need to replace with ncells
   iReplace    = find(ismember(varInfo.Name,'latixy'));
   sizeReplace = cell2mat(varInfo.Size(iReplace));

% the template file     
for n = 1:nVars
    
   thisVar = outVars(n);
    
   % assign the template schema to the new schema
   theNewSchema.(thisVar)  = ncinfo(ftemplate,thisVar);
    
   iReplace = theNewSchema.(thisVar).Size == sizeReplace;

   theNewSchema.(thisVar).Size(iReplace)  = nCells;
    
   iReplace   = [theNewSchema.(thisVar).Dimensions.Length] == sizeReplace;
    
   theNewSchema.(thisVar).Dimensions(iReplace).Length = nCells;
end

    
%% make the 'ele' array
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
nele  = 11;
ele   = nan(nele,nCells);

for n = 1:length(slopes)
   ele(:,n)       = slopes(n).ele;
   slopes(n).rwid = 50;
   slopes(n).fdir = double(slopes(n).fdir);
end
ele = ele';

for n = 1:length(slopes)
   slopes(n).ele  = ele;
end

%% loop through the remaining variables and replicate donghui's format
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% write the new file
if savefile
    
   % delete the file if it exists, otherwise there will be errors
   if exist(fsave,'file'); delete(fsave); end

   % write all data
   for n = 1:nVars-1

      thisVar = outVars(n);
      iVar    = ismember(inVars,thisVar);
      varData = [slopes.(inVars{iVar})];

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
