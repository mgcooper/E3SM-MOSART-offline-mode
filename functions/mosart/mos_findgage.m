function outletID = mos_find_gage(slopes,xgage,ygage)

outletID = [];
for n = 1:numel(slopes)
    polyhs = polyshape(slopes(n).X_hs,slopes(n).Y_hs);
    if inpolygon(xgage,ygage,polyhs.Vertices(:,1),polyhs.Vertices(:,2))
        outletID = n;
    else
        continue;
    end
    if ~isempty(outletID)
        break
    end
end