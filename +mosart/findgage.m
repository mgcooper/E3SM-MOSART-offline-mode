function outletID = findgage(slopes,xgage,ygage)

   outletID = [];
   for n = 1:numel(slopes)
      if ~isa(slopes(n), 'polyshape')
         polyhs = polyshape(slopes(n).X_hs,slopes(n).Y_hs);
      else
         polyhs = slopes(n);
      end
      if inpolygon(xgage,ygage,polyhs.Vertices(:,1),polyhs.Vertices(:,2))
         outletID = n;
      else
         continue
      end
      if ~isempty(outletID)
         break
      end
   end
end
