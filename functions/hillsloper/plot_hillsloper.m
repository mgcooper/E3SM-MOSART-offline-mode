function plot_hillsloper(slopes,links,nodes)

for i = 1:length(slopes)
   
   if isfield(slopes,'Lon')
      loni    = [slopes(i).Lon];
   elseif isfield(slopes,'lon')
      loni    = [slopes(i).lon];
   end
   
   if isfield(slopes,'Lat')
      lati    = [slopes(i).Lat];
   else
      lati    = [slopes(i).lat];
   end
   
   [x,y]   = ll2utm(lati,loni);
   plot(x,y,'Color','g');
end

for i = 1:length(links)

   if isfield(links,'Lon')
      loni    = [links(i).Lon];
   elseif isfield(links,'lon')
      loni    = [links(i).lon];
   end
   
   if isfield(links,'Lon')
      lati    = [links(i).Lat];
   elseif isfield(links,'lon')
      lati    = [links(i).lat];
   end
   
   [x,y]   = ll2utm(lati,loni);
   plot(x,y,'Color','b');
end

if nargin == 3
   for i = 1:length(nodes)
      
      if isfield(nodes,'Lon')
         loni    = [nodes(i).Lon];
      elseif isfield(links,'lon')
         loni    = [nodes(i).lon];
      end
   
      if isfield(nodes,'Lat')
         lati    = [nodes(i).Lat];
      elseif isfield(links,'lat')
         lati    = [nodes(i).lat];
      end
      
      
      [x,y]   = ll2utm(lati,loni);
      scatter(x,y,125,'y','filled');
   end
end

