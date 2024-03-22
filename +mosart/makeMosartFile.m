function [schema,info,data] = makeMosartFile(slopes,ftemplate,fsave,opts)
   %MAKEMOSARTFILE make mosart parameter file for E3SM (frivinp_rtm)
   %
   %  [SCHEMA,INFO,DATA] = MAKEMOSARTFILE(SLOPES,FTEMPLATE,FSAVE,OPTS)
   %
   % Inputs
   %
   %   'slopes' a structure with the following fields:
   %       longxy  = latitude of computational unit, scalar
   %       latixy  = longitude of computational unit, scalar
   %       area    = area in m2
   %
   % Outputs
   %
   %   'schema' a netcdf schema structure for the output file
   %   'info' the output of ncinfo for the output file, should match schema
   %
   % See also:

   % Cast geostruct to table.
   if isstruct(slopes)
      try
         slopes = struct2table(slopes);
      catch e
         rethrow(e) % throw for now
      end
   end

   % Parse options
   savefile = opts.savefile;
   nobackup = opts.nobackups;
   dobackup = ~opts.nobackups;

   % The variables provided to create the file
   inVars = slopes.Properties.VariableNames;

   % Number of hillslope units in the domain
   nCells = height(slopes);

   % Replace the outlet ID nan with -9999
   slopes.dnID(isnan(slopes.dnID)) = -9999;

   % These are the variables created by this function:
   varInfo = ncparse(ftemplate);
   outVars = [varInfo.Name];
   nVars  = length(outVars);

   % The template file has 72 grid cells, need to replace with ncells
   iReplace = find(ismember(varInfo.Name, 'latixy'));
   sizeReplace = cell2mat(varInfo.Size(iReplace));

   % Redefine the template file dimensions with the slopes dimensions.
   for n = 1:nVars

      thisVar = outVars{n};

      % assign the template schema to the new schema
      theNewSchema.(thisVar) = ncinfo(ftemplate, thisVar);

      iReplace = theNewSchema.(thisVar).Size == sizeReplace;

      theNewSchema.(thisVar).Size(iReplace) = nCells;

      iReplace = [theNewSchema.(thisVar).Dimensions.Length] == sizeReplace;

      theNewSchema.(thisVar).Dimensions(iReplace).Length = nCells;
   end


   %% make the 'ele' array

   % % This is not necessary for hillslope mode, but keep for future reference.
   % nele = 11;
   % ele = nan(nele,nCells);
   % for n = 1:length(slopes)
   %    ele(:,n) = slopes(n).ele;
   % end
   % ele = ele';
   % for n = 1:length(slopes)
   %    slopes(n).ele = ele;
   % end

   %% make the flow direction and other values

   % These are computed with hydraulic geometry now.
   for n = 1:nCells
      % slopes(n).rwid = 30; % 20 Jan 2023 changed 50 to 30 to test
      % slopes(n).rwid0 = 30; % 20 Jan 2023 changed 50 to 30 to test
      % slopes(n).rdep = 4; % 20 Jan 2023 changed 2 to 4 to test
      % slopes(n).nr = 0.5;
   end

   %% loop through the remaining variables and replicate donghui's format

   % write the new file
   if savefile

      % Delete the file if it exists, otherwise there will be errors
      if isfile(fsave)
         backupfile(fsave, dobackup);
         delete(fsave);
      end

      % Write all data
      for n = 1:nVars-1

         thisVar = outVars{n};
         iVar    = ismember(inVars, thisVar);

         if none(iVar)
            continue
         end

         varData = slopes.(inVars{iVar});
         ncwriteschema(fsave, theNewSchema.(thisVar));

         if any(strcmp(thisVar, {'lon','longxy'}))
            varData = wrapTo360(varData);
         end

         ncwrite(fsave, thisVar, varData);
      end

      % % Special case for ele
      % ncwriteschema(fsave, theNewSchema.ele);
      % ncwrite(fsave, 'ele', ele);

      % read in the new file to compare with the old file
      varInfo = ncinfo(fsave);
   else
      varInfo = 'file not written, see newschema';
   end

   schema  = theNewSchema;
   info    = varInfo;
   data    = ncreaddata(fsave);
end
