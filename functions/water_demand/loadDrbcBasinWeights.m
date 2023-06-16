function Weights = loadDrbcBasinWeights(filepath)

if nargin == 1
   try
      load(fullfile(filepath,'weights.mat'), ...
         'W','IN','XC','YC','XV','YV','PX','PY','IMesh');
   catch
   end
else
   try
      load(fullfile( ...
         setpath('icom/DRBC','data'),'weights.mat'), ...
         'W','IN','XC','YC','XV','YV','PX','PY','IMesh');
   catch
      try
         load(fullfile( ...
         getenv('MATLAB_ACTIVE_PROJECT_DATA_PATH'),'matfiles','weights.mat'), ...
         'W','IN','XC','YC','XV','YV','PX','PY','IMesh');
      catch
      end
   end
end

Weights.W = W;
Weights.IN = IN;
Weights.XC = XC;
Weights.YC = YC;
Weights.XV = XV;
Weights.YV = YV;
Weights.PX = PX;
Weights.PY = PY;
Weights.IMesh = IMesh;

% switch nargout
%    case 1
%       varargout{1} = Weights;
%    else
%       [1:varargout{:}] = deal([W,IN,XC,YC,XV,YV,PX,PY]);
% end