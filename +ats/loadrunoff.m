function varargout = loadrunoff(filename, outputformat)

   % Note: There is also a file "ats_runoff" in this folder which has basin-sum
   % runoff in m3/s for ATS and the Ming Pan runoff, created in another script
   % or function.
   if nargin < 1 || isempty(filename)
      filename = fullfile(getenv('USERDATAPATH'), 'interface', 'ATS', ...
         'sag_basin', 'sag_hillslope_discharge.mat');
   end
   if nargin < 2
      outputformat = "astable";
   end

   if ~isfile(filename)
      warning('File not found: %s', filename)
      data = [];
      return
   else

      try
         Data = load(filename).('Data');
      catch e
         rethrow(e)
      end
   end

   Data{:, :} = Data{:, :} / (24 * 3600); % m3/d -> m3/s

   Data = settableunits(Data, 'm3 s-1');

   % This was before I realized Runoff is the sum over all columns to get the
   % basin-sum runoff. For a general purpose, I probably just want to return the
   % full data table.
   switch outputformat

      case "astable"
         varargout{1} = Data;

      case "asarray"

   end
end
