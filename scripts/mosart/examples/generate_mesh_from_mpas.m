clear;close all;clc;
​
addpath('/Users/xudo627/donghui/CODE/Setup-E3SM-Mac/matlab-scripts-to-process-inputs/');
​
domain = 'Mid-Atlantic';
add_ele = 1;
check_consistency  = 0;
check_data         = 1;
insert_Susquehanna = 0;
insert_midatlantic = 0;
​
fname = [domain '/hexwatershed.json'];
str = fileread(fname);
data = jsondecode(str);
​
​
if strcmp(domain,'Global') 
    lon = [data(:).dLon_center]'; 
    lat = [data(:).dLat_center]';
    globalID = [data(:).lCellID]';
    globaldnID = [data(:).lCellID_downslope]';
    Elevation = [data(:).Elevation]';
    areaTotal2 = [data(:).DrainageArea]';
    dSlope_between = [data(:).dSlope_between]';
​
    if add_ele == 1
        load('Global_MPAS_elevation_profile.mat');
    end
    if insert_Susquehanna
        fname2 = ['Susquehanna' '/hexwatershed.json'];
    elseif insert_midatlantic
        fname2 = ['Mid-Atlantic' '/hexwatershed.json'];
    end
    str2 = fileread(fname2);
    data2 = jsondecode(str2);
    lon2 = [data2(:).dLongitude_center_degree]';
    lat2 = [data2(:).dLatitude_center_degree]';
    globalID2 = [data2(:).lCellID]';
    globaldnID2 = [data2(:).lCellID_downslope]';
    Elevation2 = [data2(:).Elevation]';
    areaTotal22 = [data2(:).DrainageArea]';
    dSlope_between2 = [data2(:).dSlope_profile]';
    for i = 1 : length(globalID2)
        ind = find(globalID == globalID2(i));
        if globalID(ind)~= globalID2(i)
            disp([num2str(globalID(ind)) ',' num2str(globalID2(i))]);
        end
        if isempty(ind)
            stop('ind should not be empty!!!');
        else
            lon(ind)            = lon2(i);
            lat(ind)            = lat2(i);
            globaldnID(ind)     = globaldnID2(i);
            Elevation(ind)      = Elevation2(i);
            areaTotal2(ind)     = areaTotal22(i);
            dSlope_between(ind) = dSlope_between2(i);
        end
    end
elseif strcmp(domain,'Susquehanna') 
    lon = [data(:).dLongitude_center_degree]'; 
    lat = [data(:).dLatitude_center_degree]';
    globalID = [data(:).lCellID]';
    globaldnID = [data(:).lCellID_downslope]';
    Elevation = [data(:).Elevation]';
    areaTotal2 = [data(:).DrainageArea]';
    dSlope_between = [data(:).dSlope_profile]';
    
    if add_ele == 1
        load('./Susquehanna/ele.mat');
    end
elseif strcmp(domain,'Mid-Atlantic') 
    lon = [data(:).dLongitude_center_degree]'; 
    lat = [data(:).dLatitude_center_degree]';
    globalID = [data(:).lCellID]';
    globaldnID = [data(:).lCellID_downslope]';
    Elevation = [data(:).Elevation]';
    areaTotal2 = [data(:).DrainageArea]';
    dSlope_between = [data(:).dSlope_profile]';
    
    if add_ele == 1
        load('./Mid-Atlantic/ele_Mid_Atlantic_c220124.mat');
    end    
end
​
lon(lon < 0) = lon(lon < 0) + 360;
​
if check_consistency
    lonCell = ncread('delaware_lnd_60_30_5_2_v2/lnd_cull_mesh.nc','lonCell');
    latCell = ncread('delaware_lnd_60_30_5_2_v2/lnd_cull_mesh.nc','latCell');
    lonCell = rad2deg(lonCell);
    latCell = rad2deg(latCell);
    %lonCell(lonCell >= 180) = lonCell(lonCell >= 180) - 360;
    figure;
    plot(lonCell,latCell,'bo'); hold on;
    plot(lon,lat,'r.'); hold off;
end
lonVertex      = ncread('delaware_lnd_60_30_5_2_v2/lnd_cull_mesh.nc','lonVertex');
latVertex      = ncread('delaware_lnd_60_30_5_2_v2/lnd_cull_mesh.nc','latVertex');
verticesOnCell = ncread('delaware_lnd_60_30_5_2_v2/lnd_cull_mesh.nc','verticesOnCell');
indexToCellID  = ncread('delaware_lnd_60_30_5_2_v2/lnd_cull_mesh.nc','indexToCellID');
areaCell       = ncread('delaware_lnd_60_30_5_2_v2/lnd_cull_mesh.nc','areaCell');
​
lonVertex = rad2deg(lonVertex);
latVertex = rad2deg(latVertex);
%lonVertex(lonVertex > 180) = lonVertex(lonVertex > 180) - 360;
​
lonv = NaN(8,length(globalID));
latv = NaN(8,length(globalID));
numv = NaN(length(globalID),1);
area = NaN(length(globalID),1);
for i = 1 : length(globalID)
    disp(i);
    if strcmp(domain,'Global')
        ind = i;
    else
        ind = find(indexToCellID == globalID(i));
    end
    numv(i) = length(find(verticesOnCell(:,ind) > 0));
    lonv(1:numv(i),i) = lonVertex(verticesOnCell(1:numv(i),ind));
    latv(1:numv(i),i) = latVertex(verticesOnCell(1:numv(i),ind));
    area(i)           = areaCell(ind);
end
​
% sTODO: consider what is the coefficient for global domain
rwid = 15.0418.*(areaTotal2.*3.86102e-7).^0.4038.*0.3048;
rdep = 0.9502.*(areaTotal2.*3.86102e-7).^0.2960.*0.3048;
% rwid(rwid < 30) = 30;
% rdep(rdep < 2 ) = 2;
nh   = ones(length(areaTotal2),1).*0.4;
​
ID = 1 : length(globalID);
ID = ID';
dnID = NaN(length(globalID),1);
​
for i = 1 : length(ID)
    if globaldnID(i) == -9999
        dnID(i) = -9999;
    else
        ind = find(globalID == globaldnID(i));
        if isempty(ind)
            dnID(i) = -9999;
        else
            dnID(i) = ID(ind);
        end
    end
end
​
fdir = ones(length(globalID),1);
fdir(dnID == -9999) = 0;
frac = ones(length(globalID),1);
rlen = sqrt(area);
​
if check_data
    figure;
    for i = 1 : length(ID)
        if dnID(i) ~= -9999
            plot([lon(ID(i)) lon(dnID(i))],[lat(ID(i)) lat(dnID(i))],'b-','LineWidth',1.5);hold on;
        else
            plot(lon(ID(i)),lat(ID(i)),'r*'); hold on;
        end
    end
    
    figure;
    for i = 4 : 8
        patch(lonv(1:i,numv == i),latv(1:i,numv == i),rwid(numv == i),'LineStyle','none'); colorbar; hold on;
    end
​
    figure;
    for i = 4 : 8
        patch(lonv(1:i,numv == i),latv(1:i,numv == i),rdep(numv == i),'LineStyle','none'); colorbar; hold on;
    end
​
    figure;
    for i = 4 : 8
        patch(lonv(1:i,numv == i),latv(1:i,numv == i),dSlope_between(numv == i),'LineStyle','none'); colorbar; hold on;
    end
end
​
% Prepare MOSART inputfile by creating the netcdf file
out_netcdf_dir = ['./' domain];
mosart_usrdat_name = [domain '_MPAS'];
if strcmp(domain,'Global') 
mosart_gridded_surfdata_filename = '/Users/xudo627/projects/cesm-inputdata/MOSART_global_8th_20180211b.nc';
elseif strcmp(domain,'Susquehanna') || strcmp(domain,'Mid-Atlantic')
mosart_gridded_surfdata_filename = '/Users/xudo627/projects/cesm-inputdata/MOSART_NLDAS_8th_c210129.nc';
end
​
fname_out = sprintf('%s/MOSART_%s_%s.nc',out_netcdf_dir,mosart_usrdat_name,datestr(now, 'cyymmdd'));
disp(['  MOSART_dataset: ' fname_out]);
ncid_inp = netcdf.open(mosart_gridded_surfdata_filename,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');
​
info_inp = ncinfo(mosart_gridded_surfdata_filename);
[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);
​
latixy = ncread(mosart_gridded_surfdata_filename,'latixy');
longxy = ncread(mosart_gridded_surfdata_filename,'longxy');
​
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dimid(1) = netcdf.defDim(ncid_out,'gridcell',length(lat));
if add_ele == 1
    dimid(2) = netcdf.defDim(ncid_out,'nele',11);
end
​
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
found_ele = 0;
for ivar = 1 : nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    if strcmp(varname,'ele')
        found_ele = 1;
        %dimid(2) = netcdf.defDim(ncid_out,'nele',11);
        varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,[dimid(1) dimid(2)]); 
    else
        varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1)); 
    end
   
    if strcmp(varname,'rdep')
        xtype2 = xtype;
    end
    varnames{ivar} = varname;
    for iatt = 1 : natts
        attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
        attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);
        
        netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
    end
end
if add_ele == 1 && found_ele == 0
    ivar = nvars + 1;
    fdrainid = netcdf.defVar(ncid_out,'ele',xtype2,[dimid(1) dimid(2)]);
    netcdf.putAtt(ncid_out,ivar-1,'long_name','elevation profile');
    netcdf.putAtt(ncid_out,ivar-1,'unites','m-1');
end
​
varid = netcdf.getConstant('GLOBAL');
[~,user_name]=system('echo $USER');
netcdf.putAtt(ncid_out,varid,'Created_by' ,user_name(1:end-1));
netcdf.putAtt(ncid_out,varid,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
netcdf.endDef(ncid_out);
​
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Copy variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
for ivar = 1:nvars
    [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
    tmp = netcdf.getVar(ncid_inp,ivar-1);
    if strcmp(varname,'lat') || strcmp(varname,'latixy')
        netcdf.putVar(ncid_out,ivar-1,lat);
    elseif strcmp(varname,'lon') || strcmp(varname,'longxy')
        netcdf.putVar(ncid_out,ivar-1,lon);
    elseif strcmp(varname,'rslp') || strcmp(varname,'tslp')
        netcdf.putVar(ncid_out,ivar-1,dSlope_between);
    elseif strcmp(varname,'ID')
        netcdf.putVar(ncid_out,ivar-1,ID);
    elseif strcmp(varname,'dnID')
        netcdf.putVar(ncid_out,ivar-1,dnID);
    elseif strcmp(varname,'frac')
        netcdf.putVar(ncid_out,ivar-1,frac);
    elseif strcmp(varname,'fdir')
        netcdf.putVar(ncid_out,ivar-1,frac);
    elseif strcmp(varname,'rdep')
        netcdf.putVar(ncid_out,ivar-1,rdep);
    elseif strcmp(varname,'rwid')
        netcdf.putVar(ncid_out,ivar-1,rwid);
    elseif strcmp(varname,'rwid0')
        netcdf.putVar(ncid_out,ivar-1,rwid.*5);
    elseif strcmp(varname,'areaTotal') || strcmp(varname,'areaTotal2')
        netcdf.putVar(ncid_out,ivar-1,areaTotal2);
    elseif strcmp(varname,'area')
        netcdf.putVar(ncid_out,ivar-1,area);
    elseif strcmp(varname,'rlen')
        netcdf.putVar(ncid_out,ivar-1,rlen);
    elseif strcmp(varname,'nh')
        netcdf.putVar(ncid_out,ivar-1,nh);
    elseif strcmp(varname,'ele')
        netcdf.putVar(ncid_out,ivar-1,ele);
    else
        tmpv = griddata(longxy,latixy,tmp,lon,lat,'nearest');
        tmpv(tmpv < -9000) = NaN;
        tmpv = fillmissing(tmpv,'nearest');
        %[varname2,vartype2,vardimids2,varnatts2]=netcdf.inqVar(ncid_out,ivar-1);
        netcdf.putVar(ncid_out,ivar-1,tmpv);
    end
end
if add_ele == 1 && found_ele == 0
    ivar = nvars + 1;
    netcdf.putVar(ncid_out,ivar-1,ele);
end
% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);
​
mask = zeros(length(frac),1);
mask(frac > 0) = 1;
​
fname_out2 =  sprintf('%s/domain_lnd_%s_%s.nc',out_netcdf_dir, ...
                      mosart_usrdat_name,datestr(now, 'cyymmdd'));
                  
area2 = generate_lnd_domain(lon,lat,lonv,latv,frac,mask,area,fname_out2);