function specs = createSymbolSpecs
   
   specs.nodes = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
      6,'MarkerFaceColor','g','MarkerEdgeColor','none'});

   specs.outletnode = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
      12,'MarkerFaceColor','r','MarkerEdgeColor','none'});
   
   specs.interiornode = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
      6,'MarkerFaceColor','m','MarkerEdgeColor','none'});
      
   specs.links = makesymbolspec('Line',{'Default','Color','b','LineWidth',1});

   specs.outletlink = makesymbolspec('Line', ...
      {'Default', 'Color', 'r', 'LineWidth', 3});

   specs.slopes = makesymbolspec('Polygon',{'Default','FaceColor','none',   ...
      'EdgeColor','g','LineWidth',1});

   specs.newslopes = makesymbolspec('Polygon',{'Default','FaceColor','none',   ...
      'EdgeColor','r','LineWidth',1});
end
