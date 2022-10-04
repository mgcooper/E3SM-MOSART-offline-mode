function patch_hexmesh(Mesh,varargin)
%patch_hexmesh plots the hexwatershed mesh 

%------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'patch_hexmesh';

addRequired(   p, 'Mesh');
addParameter(  p, 'FaceColor','none',@(x)ischar(x)|isnumeric(x));
addParameter(  p, 'ZData',[],@(x)isnumeric(x));
addParameter(  p, 'CData',[],@(x)isnumeric(x));
addParameter(  p, 'FaceMapping','none',@(x)ischar(x));

parse(p,Mesh,varargin{:});

FaceColor   = p.Results.FaceColor;
FaceMapping = p.Results.FaceMapping;
ZData       = p.Results.ZData;
CData       = p.Results.CData;

%------------------------------------------------------------------------------

% if FaceColor was provided, use it. If FaceMapping was provided, then it
% equals 

facemapping = true;

if FaceColor ~= "none"
   
   % convert the char to an rgb triplet
   if ischar(FaceColor)
      if numel(FaceColor) == 1
         % this is a matlab color char
         FaceColor = matlabcolor2rgb(FaceColor);
      else
         FaceColor = rgb(FaceColor);
      end
   end
   
   % NOTE: FaceColor could be changed to CData and then it could be passed to
   % fill, or we can call if FaceColor and pass it to pathc
   FaceColor = repmat(FaceColor,numel(Mesh),1);
   
   facemapping = false;
   
elseif FaceMapping ~= "none"
   
   % if CData was also passed in, use FaceMapping and warn
   if ~isempty(CData)
      warning('using FaceMapping variable for CData')
   end
   
   CData = [Mesh.(FaceMapping)];
   
   % FaceColor = flipud(brewermap(numel(CData),'BrBG'));
   
elseif isempty(CData) && isempty(ZData)
   % this also means FaceColor == "none" and FaceMapping == "none"
   
   FaceColor = repmat("none",numel(Mesh),1);
   facemapping = false;
   
elseif ~isempty(ZData)
   
   % for now, use ZData as CData
   CData = ZData;
   
else % CData must have a value   
  
   % FaceColor = flipud(brewermap(numel(CData),'BrBG')); 
   
end

% if no face color was requested, plot the polygons using patch
if facemapping == false
   
   hold on;
   for n = 1:numel(Mesh)
      patch('XData',Mesh(n).Lon,'YData',Mesh(n).Lat,'FaceColor',FaceColor(n,:));
   end
   axis image

% otherwise, use fill   
else

   % sort the data by the FaceMapping variable / CData and just use the index 
   [CData,idx] = sort(CData);
   hold on;
   for n = 1:numel(Mesh)
      fill(Mesh(idx(n)).Lon,Mesh(idx(n)).Lat,CData(n));
   end
   axis image
   colorbar;
   
end
