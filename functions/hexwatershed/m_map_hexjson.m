function h = m_map_hexjson(json,Dams)


ncells = numel(json);

% init the colormap
a = cptcmap('GMT_red2green'); % cptcmap('SP08');
a = [(1:size(a,1))' a];
range = [0 1e10];

% prep the dam capacity 
damltln = table2array(Dams(:,1:2)); 
cap = table2array(Dams(:,3));
c  = table2cell(Dams(:,5));

% displacement so the text does not overlay the data points
dx = 0.01; 
dy = 0.01; 

% make the figure
f = macfig;

% set the projection
m_proj('Equid','lon',[-79.2 -74],'lat',[39.4 43]); hold on
%m_proj('oblique','lon',[-150 -146],'lat',[68 70.6],'aspect',.8);

for n = 1:ncells
    
    vertex = json{1,n}.vVertex;
    nverts = numel(vertex);
    latlon = nan(nverts,2);

    for m = 1:nverts
        latlon(m,1) = vertex{1,m}.dLongitude_degree;
        latlon(m,2) = vertex{1,m}.dLatitude_degree;
    end
    
    %%%%%%%%
    x = json{1,n}.DrainageArea;
    if x>= range(2)
        rgb = a(end,2:4);
    elseif x<= range(1)
        rgb = a(1,2:4);
    else
        id = interp1(range,[a(1,1) a(end,1)],x);
        idfloor = floor(id);
        
        rgb = a(idfloor,2:4)+(a(idfloor+1,2:4) - a(idfloor,2:4))*(id-idfloor);
    end
    %%%%%%%%
    
    m_patch(latlon(:,1),latlon(:,2),rgb);
end

m_coast;
m_scatter(damltln(:,2),damltln(:,1),cap*100,'c','filled');
m_text(damltln(:,2)+dx, damltln(:,1)+dy, c,'fontsize',5);
set(gca,'fontname','Segoe UI Semilight')
m_grid('linewi',1,'tickdir','in')


h.figure = f;
h.ax = gca;

