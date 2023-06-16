function [XC,YC,XV,YV,IN] = clipMeshToPoly(P,XC,YC,XV,YV)

% [~,~,IN] = exactremap(NV,XC,YC,P,'clip','GridOption','unstructured');

% try clipping a bit outside of P to see if that fixes the area gap
% [XminP,XmaxP] = bounds(P.Vertices(:,1));
% [YminP,YmaxP] = bounds(P.Vertices(:,2));

% this works but creates a rectangle around the watershed
% IN = ...
%    (XC >= XminP-median(abs(diff(XC)))/2) & ...
%    (XC <= XmaxP+median(abs(diff(XC)))/2) & ...
%    (YC >= YminP-median(abs(diff(YC)))/2) & ...
%    (YC <= YmaxP+median(abs(diff(YC)))/2) ;

% dB = max(median(abs(diff(XC))),median(abs(diff(YC))));
dB = 10000;
PB = polybuffer(P,dB);
IN = inpolygon(XC,YC,PB.Vertices(:,1),PB.Vertices(:,2)); 

% Check the number of cells found inside the polygon
% sum(IN);

% Clip the data
XC = XC(IN);
YC = YC(IN);
XV = XV(IN,:);
YV = YV(IN,:);