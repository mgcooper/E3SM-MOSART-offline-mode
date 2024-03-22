function [slope, slope_n] = getslope(slopes, id, idtype)

   if nargin < 3
      idtype = 'hs_ID'; % fid starts at 1, hs_ID starts at 0
   end

   slope = slopes([slopes.(idtype)] == id);

   if nargout > 1
      try
         slope_n = slopes([slopes.(idtype)] == -id);
      catch
         slope_n = [];
      end
   end
end
