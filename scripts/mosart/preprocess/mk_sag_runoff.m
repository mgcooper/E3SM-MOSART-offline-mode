clean

% i did not update this for sag_basin. the GPCC.daily.nc does not have
% dimensions 'gridcell' x 'nele', those dimensions came from the
% MOSART_icom_half_c200624.nc file in mydata/e3sm/input/icom, and I must
% have just copied the idea over to the runoff file to see if it would work

%% set paths
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
p.data  = setpath('interface/data/hillsloper/');
p.temp  = '/Users/coop558/mydata/e3sm/input/icom/';
p.forc  = '/Users/coop558/mydata/e3sm/forcing/lnd/dlnd7/hcru_hcru/';
p.save  = '/Users/coop558/myprojects/e3sm/sag/input/';

cd(p.save);

fmosart     = [p.temp 'MOSART_icom_half_c200624.nc'];
frunoff     = [p.forc 'GPCC.daily.nc'];
fsave       = [p.save 'runoff_sag_test.nc'];

if exist(fsave,'file'); delete(fsave); end


%% load the hillsloper data that has ID and dnID
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
load([p.data 'sag_hillslopes']); slopes = newslopes; clear newslopes;

sagvars     = fieldnames(slopes);
ID          = [slopes.ID];
dnID        = [slopes.dnID];
i           = isnan(dnID);
dnID(i)     = -9999;                    % replace nan with -9999
lat         = [slopes.lat];
lon         = [slopes.lon];
lon         = wrapTo360(lon);
ncells      = length(lon);

%% read in GPCC runoff
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
info_mos    = ncinfo(fmosart);
info        = ncinfo(frunoff);
vars        = {info.Variables.Name};
data        = ncreaddata(frunoff,vars);

%% interpolate the GPCC runoff to the sag basins
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
R           = permute(data.QRUNOFF,[2,1,3]);
[LON,LAT]   = meshgrid(data.lon,data.lat);
LAT         = flipud(LAT);
R           = flipud(R);
Ravg        = nanmean(R,3);
[nr,nc]     = size(LON);

% reshape to columns for griddedInterpolant
LONrs       = reshape(LON,nr*nc,1);
LATrs       = reshape(LAT,nr*nc,1);
Ravgrs      = reshape(Ravg,nr*nc,1);

% interpolate across all days
for i = 1:size(R,3)
    Ri      = reshape(R(:,:,i),nr*nc,1);
    Rq      = scatteredInterpolant(LONrs,LATrs,Ri);
    Rs(:,i) = Rq(lon,lat);
end

QRUNOFF     = Rs;
QDRAI       = zeros(size(Rs));
QOVER       = zeros(size(Rs));
ndays       = size(QRUNOFF,2);
lon         = wrapTo180(lon);

%% 4. write the file in the format of GPCC.daily
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% QDRAI
var                         = 'QDRAI';
sch                         = ncinfo(frunoff,var);
sch.Dimensions(1)           = [];
sch.Dimensions(1).Name      = 'gridcell';
sch.Dimensions(1).Length    = ncells;
sch.ChunkSize               = [];
sch.Size                    = [ncells,ndays];
ncwriteschema(fsave,sch);
ncwrite(fsave,var,QDRAI);

% QOVER
var                         = 'QOVER';
sch                         = ncinfo(frunoff,var);
sch.Dimensions(1)           = [];
sch.Dimensions(1).Name      = 'gridcell';
sch.Dimensions(1).Length    = ncells;
sch.ChunkSize               = [];
sch.Size                    = [ncells,ndays];
ncwriteschema(fsave,sch);
ncwrite(fsave,var,QOVER);

% QRUNOFF
var                         = 'QRUNOFF';
sch                         = ncinfo(frunoff,var);
sch.Dimensions(1)           = [];
sch.Dimensions(1).Name      = 'gridcell';
sch.Dimensions(1).Length    = ncells;
sch.ChunkSize               = [];
sch.Size                    = [ncells,ndays];
sch.Attributes.Name
ncwriteschema(fsave,sch);
ncwrite(fsave,var,QRUNOFF);

% ID (use 'lat' as a template)
var                         = 'lat';
nvar                        = 'ID';
sch                         = ncinfo(frunoff,var);
sch.Name                    = 'ID';
sch.Dimensions(1).Name      = 'gridcell';
sch.Dimensions(1).Length    = ncells;
sch.Size                    = ncells;
sch.ChunkSize               = [];
sch.Attributes              = [];
ncwriteschema(fsave,sch);
ncwrite(fsave,nvar,ID);

% lat
var                         = 'lat';
sch                         = ncinfo(frunoff,var);
sch.Dimensions(1).Name      = 'gridcell';
sch.Dimensions(1).Length    = ncells;
sch.Size                    = ncells;
sch.ChunkSize               = [];
ncwriteschema(fsave,sch);
ncwrite(fsave,var,lat);

% lon
var                         = 'lon';
sch                         = ncinfo(frunoff,var);
sch.Dimensions(1).Name      = 'gridcell';
sch.Dimensions(1).Length    = ncells;
sch.Size                    = ncells;
sch.ChunkSize               = [];
ncwriteschema(fsave,sch);
ncwrite(fsave,var,lon);

newinfo = ncinfo(fsave);

%========================================================================
%% this shows the discrepancy between scatteredInterpolant and interp2
% interpolate the GPCC runoff to the sag basin lat/lon
% Rq          = scatteredInterpolant(LONrs,LATrs,Ravgrs,'linear');
% Rsag        = Rq(lon,lat);
% Rsag2       = interp2(LON,LAT,Ravg,lon,lat);
% 
% figure; 
% plotLinReg(Rsag,Rsag2); ax = gca;
% ax.XLim = ax.YLim;
% axis square
% 
% figure; 
% myscatter(Rsag,Rsag2); 
% addOnetoOne

% for reference:
% R           = permute(data.QRUNOFF,[2,1,3]);
% 
% % this suggests the data is oriented correctly
% figure;
% surf(data.lon,data.lat,mean(R,3));
% view(2); shading flat
% 
% % but when LON/LAT are gridded, R has to be flipped upside down
% [LON,LAT]   = meshgrid(data.lon,data.lat);
% LAT         = flipud(LAT);
% R           = flipud(R);
% Ravg        = nanmean(R,3);

% figure;
% surf(LON,LAT,mean(R,3));
% view(2); shading flat

% % Below here is how it was when I started
% %==========================================================================
% %% 1. read in icom files to use as a template for the new file
% %==========================================================================
% frunoff     = [path.data 'GPCC.daily.nc'];
% fsave       = [path.save 'runoff_sag_test.nc'];
% 
% info        = ncinfo(frunoff);
% vars        = {info.Variables.Name};
% data        = ncreaddata(frunoff,vars);
% data.QDRAI  = permute(data.QDRAI,[2,1,3]);
% data.QOVER	= permute(data.QOVER,[2,1,3]);
% data.QRUNOFF= permute(data.QRUNOFF,[2,1,3]);
% 
% figure;
% worldmap
% surfm(data.lat,data.lon,mean(data.QRUNOFF,3));
% 
% 
% %==========================================================================
% %% 1. Load the hillsloper data and modify it for MOSART 
% %==========================================================================
% load([path.sag 'sag_hillslopes']);
% 
% % assign values to each variable
% xc      = [newslopes.longxy]';
% yc      = [newslopes.latixy]';
% mask    = (int32(ones(size([newslopes.longxy]))))';
% frac    = (ones(size([newslopes.longxy])))';
% ncells  = size(mask,1);
% 
% % compute the surface area of each sub-basin in units of steradians
% for i = 1:length(newslopes)
%     ilat        = newslopes(i).Y_hs;
%     ilon        = newslopes(i).X_hs;
%     area(i,1)   = llpoly2steradians(ilat,ilon);
% end
% 
% % compute the bounding box of each sub-basin
% for i = 1:length(newslopes)
%     ilat        = newslopes(i).Y_hs;
%     ilon        = newslopes(i).X_hs;
%     [x,y,f]     = ll2utm([ilat,ilon]);
%     poly        = polyshape(x,y);
%     [xb,yb]     = boundingbox(poly);
%     [latb,lonb] = utm2ll(xb,yb,f);  
%     xv(:,i)     = [lonb(1) lonb(2) lonb(2) lonb(1)];
%     yv(:,i)     = [latb(1) latb(1) latb(2) latb(2)];
% end
% 
% myschema.xc     = ncinfo(frunoff,'xc');
% myschema.yc     = ncinfo(frunoff,'yc');
% myschema.xv     = ncinfo(frunoff,'xv');
% myschema.yv     = ncinfo(frunoff,'yv');
% myschema.mask   = ncinfo(frunoff,'mask');
% myschema.area   = ncinfo(frunoff,'area');
% myschema.frac   = ncinfo(frunoff,'frac');
% 
% % modify the size to match the sag domain
% myschema.xc.Size    = [ncells,1];
% myschema.yc.Size    = [ncells,1];
% myschema.xv.Size    = [4,ncells,1];
% myschema.yv.Size    = [4,ncells,1];
% myschema.mask.Size  = [ncells,1];
% myschema.area.Size  = [ncells,1];
% myschema.frac.Size  = [ncells,1];
% 
% myschema.xc.Dimensions(1).Length    = ncells;
% myschema.yc.Dimensions(1).Length    = ncells;
% myschema.xv.Dimensions(2).Length    = ncells;
% myschema.yv.Dimensions(2).Length    = ncells;
% myschema.mask.Dimensions(1).Length  = ncells;
% myschema.area.Dimensions(1).Length  = ncells;
% myschema.frac.Dimensions(1).Length  = ncells;
% 
% ncwriteschema(fsave,myschema.xc);
% ncwriteschema(fsave,myschema.yc);
% ncwriteschema(fsave,myschema.xv);
% ncwriteschema(fsave,myschema.yv);
% ncwriteschema(fsave,myschema.mask);
% ncwriteschema(fsave,myschema.area);
% ncwriteschema(fsave,myschema.frac);
% 
% %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% % write the variable values
% %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% ncwrite(fsave,'xc',xc);
% ncwrite(fsave,'yc',yc);
% ncwrite(fsave,'xv',xv);
% ncwrite(fsave,'yv',yv);
% ncwrite(fsave,'mask',mask);
% ncwrite(fsave,'area',area);
% ncwrite(fsave,'frac',frac);
% 
% % read in the new file to compare with the old file                        
% %==========================================================================
% newinfo.domain  = ncinfo(fsave);