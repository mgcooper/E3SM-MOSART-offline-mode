function Setup()
   % SETUP set paths etc.
   %
   % See also Config

   % temporarily turn off warnings about paths not already being on the path
   withwarnoff('MATLAB:rmpath:DirNotFound');

   % Get the path to this file
   thispath = fileparts(mfilename('fullpath'));

   % add all paths then remove git paths
   pathadd(thispath);

   % add paths set in Config
end
