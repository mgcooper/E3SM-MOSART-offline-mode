function mask = mos_maskbasin(slopes,xbasin,ybasin)

% this function finds the hillslopes in the mosart data saved by
% 'read_output_sag' that are contained within the gaged basin

   % load the projection
   load('proj_alaska_albers.mat','proj_alaska_albers');

   % init the mask
   N       = numel([slopes.lat]);    % number of hillslopes
   mask    = false(N,1);             % true if in basin

   % find the hillslopes in the basin
   for n = 1:N

      % lati    = slopes(n).lat;
      % loni    = slopes(n).lon;
      % [xh,yh] = projfwd(proj_alaska_albers,lati,loni);
      xh    = slopes(n).X;
      yh    = slopes(n).Y;

      if inpolygon(xh,yh,xbasin,ybasin)
         mask(n) = true;
      else
         mask(n) = false;
      end
   end

end


%     xbasin  = sag.poly_gage.Vertices(:,1);
%     ybasin  = sag.poly_gage.Vertices(:,2);
%     Abasin  = area(sag.poly_gage);

% note, these are identical to the xbasin,ybasin above
%xbasin  = sag.bounds_aka.X;
%ybasin  = sag.bounds_aka.Y;
