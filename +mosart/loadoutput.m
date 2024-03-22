function data = loadoutput(filename)
   %LOADOUTPUT Load saved mosart output into memory
   %
   %  DATA = LOADOUTPUT() Loads output using environment variable MOSART_RUNID.
   %  DATA = LOADOUTPUT(FILENAME) Loads output directly using FILENAME.
   %
   % See also: mosart.readoutput

   if nargin < 1 || isempty(filename)
      filename = fullfile( ...
         getenv('E3SMOUTPUTPATH'), getenv('MOSART_RUNID'), 'mat', 'mosart.mat');
   end

   if ~isfile(filename)
      warning('File not found: %s', filename)
      data = [];
      return
   end

   [data, e] = try_(@() load(filename).('mosartData'));
   if notempty(e)
      try
         data = load(filename).('mosart');
      catch
         rethrow(e)
      end
   end
end
