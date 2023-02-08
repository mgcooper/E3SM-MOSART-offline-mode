function plothillsloper(slopes,links,nodes)
%PLOTHILLSLOPER plots the slopes, links, and nodes in a hillsloper slopes struct
% 
%  Syntax
% 
%     plot_hillsloper(slopes,links) plots the slopes and links
%     plot_hillsloper(slopes,links,nodes) also plots the nodes
% 
%  See also

%_______________________________________________________________________________

nslopes  = length(slopes);
nlinks   = length(links);
if nargin == 3
   nnodes = length(nodes);
end
   
figure; hold on;

for n = 1:nslopes
   
   if isfield(slopes,'X_hs')
      lonn = [slopes(n).X_hs];
   elseif isfield(slopes,'Lon_hs')
      lonn = [slopes(n).Lon_hs];
   elseif isfield(slopes,'Lon')
      lonn = [slopes(n).Lon];
   elseif isfield(slopes,'lon')
      lonn = [slopes(n).lon];
   end
   
   if isfield(slopes,'Y_hs')
      latn = [slopes(n).Y_hs];
   elseif isfield(slopes,'Lat_hs')
      latn = [slopes(n).Lat_hs];
   elseif isfield(slopes,'Lat')
      latn = [slopes(n).Lat];
   elseif isfield(slopes,'lat')
      latn = [slopes(n).lat];
   end
   
   % if lat/lon are not vectors, they are probably the slope centroid
   if isscalar(latn) | isscalar(lonn)
      warning('no hillslope outlines found')
   end
   
   % if no X_hs,Y_hs were found, convert the lat-lon to utm
   if islatlon(latn,lonn)
      [x,y] = ll2utm(latn,lonn);
   else
      x = lonn;
      y = latn;
   end
   plot(x,y,'Color','g');
end

for n = 1:nlinks

   if isfield(links,'X')
      lonn = [links(n).X];
   elseif isfield(links,'Lon')
      lonn = [links(n).Lon];
   elseif isfield(links,'lon')
      lonn = [links(n).lon];
   end
   
   if isfield(links,'Y')
      latn = [links(n).Y];
   elseif isfield(links,'Lon')
      latn = [links(n).Lat];
   elseif isfield(links,'lon')
      latn = [links(n).lat];
   end
   
   % if no X_hs,Y_hs were found, convert the lat-lon to utm
   if islatlon(latn,lonn)
      [x,y] = ll2utm(latn,lonn);
   else
      x = lonn;
      y = latn;
   end
   plot(x,y,'Color','b');
end

if nargin == 3
   for n = 1:length(nodes)
      
      if isfield(nodes,'Lon')
         lonn = [nodes(n).Lon];
      elseif isfield(links,'lon')
         lonn = [nodes(n).lon];
      end
   
      if isfield(nodes,'Lat')
         latn = [nodes(n).Lat];
      elseif isfield(links,'lat')
         latn = [nodes(n).lat];
      end
      
      
      [x,y] = ll2utm(latn,lonn);
      scatter(x,y,125,'y','filled');
   end
end

axis image
xlabel('Easting (m)');
ylabel('Northing (m)');
hold off;

% ax = gca;
% ax.YAxis.TickLabels = compose('%g',ax.YAxis.TickValues);

