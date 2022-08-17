function h = mos_plotslopes(slopes,links,nodes)

skipnodes = false;
if nargin == 2
   skipnodes = true;
end

nodespec    = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
                6,'MarkerFaceColor','g','MarkerEdgeColor','none'});
linkspec    = makesymbolspec('Line',{'Default','Color','b','LineWidth',1});
slopespec   = makesymbolspec('Polygon',{'Default',                      ...
                                        'FaceColor',rgb('forest green'),...
                                        'FaceAlpha',0.5,                ...
                                        'EdgeColor','k'} );
                    
figure;
mapshow(slopes,'SymbolSpec',slopespec); hold on;
mapshow(links,'SymbolSpec',linkspec);

if skipnodes == false
   mapshow(nodes,'SymbolSpec',nodespec);

   if isfield(links,'ds_link_ID')
       newspec = makesymbolspec('Point',{'Default','Marker','o','MarkerSize', ...
                   10,'MarkerFaceColor','r','MarkerEdgeColor','none'});
       outlet  = links(isnan([links.ds_link_ID])).ds_node_ID;
       mapshow(nodes([nodes.id]==outlet),'SymbolSpec',newspec);
   end

end

% for n = 1:length(nodes)
%     nx  = 1.0001*nodes(n).X;
%     ny  = 1.0001*nodes(n).Y;
%     nid = num2str(nodes(n).id);
%     text(nx,ny,nid,'Color','r','FontSize',12)
% end

for n = 1:length(links)
    nx  = median(links(n).X,'omitnan');
    ny  = median(links(n).Y,'omitnan');
    nid = num2str(links(n).ds_link_ID);
    text(nx,ny,nid,'Color','r','FontSize',12)
end

h.f     = gcf;
h.ax    = gca;



