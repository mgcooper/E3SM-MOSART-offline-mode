function show_river_network(fname,thresh,col)

if nargin < 3
   col = 'b-';
end

dnID   = ncread(fname,'dnID');
ID     = ncread(fname,'ID');
latixy = ncread(fname,'latixy');
longxy = ncread(fname,'longxy');
area   = ncread(fname,'area');
areaTotal2 = ncread(fname,'areaTotal2');
ratio  = areaTotal2 ./ sum(area,'omitnan');
rwid   = ncread(fname,'rwid');

[m,n] = size(dnID);

if m> 1 && n == 1
   show_river_1d(dnID,ID,longxy,latixy,rwid,col)
elseif m > 1 && n > 1
   show_river_2d(dnID,ID,longxy,latixy,ratio,thresh,col)
end


function show_river_2d(dnID,ID,longxy,latixy,ratio,thresh,col)

[m,n] = size(dnID);
for i = 1 : m
   for j = 1 : n
      if dnID(i,j) == -9999
         continue;
      else
         [i2,j2] = find(ID == dnID(i,j));
         if ratio(i,j) > thresh
            plot([longxy(i,j) longxy(i2,j2)], [latixy(i,j) latixy(i2,j2)], ...
               col,'LineWidth',2); hold on;
         end
         i2 = []; j2 = [];
      end
   end
end

function show_river_1d(dnID,ID,longxy,latixy,rwid,thresh,col)
m = length(dnID);
lw = rwid./(max(rwid) - min(rwid)) .* 3;
for i = 1 : m
   if dnID(i) == -9999
      plot(longxy(i),latixy(i),'rx'); hold on;
   else
      i2 = find(ID == dnID(i));
      if lw(i) > thresh
         plot([longxy(i) longxy(i2)], [latixy(i) latixy(i2)], ...
            col,'LineWidth',lw(i)); hold on;
      end
      i2 = [];
   end
end


