clear;close all;clc;

addpath('/qfs/people/xudo627/mylib/m/');
addpath('/qfs/people/xudo627/Setup-E3SM-Mac/matlab-scripts-to-process-inputs');
addpath('/qfs/people/xudo627/Setup-E3SM-Mac/matlab-scripts-for-mosart/');

domain = 'Mid-Atlantic';

lon = ncread('../Susquehanna_test/surfdata_delaware_60_30_5_2_v2_simyr2010_c211007.nc','LONGXY');
lat = ncread('../Susquehanna_test/surfdata_delaware_60_30_5_2_v2_simyr2010_c211007.nc','LATIXY');
lonv= ncread('../Susquehanna_test/domain_lnd_Global_MPAS_c211208.nc','xv');
latv= ncread('../Susquehanna_test/domain_lnd_Global_MPAS_c211208.nc','yv');
mask= ncread('../Susquehanna_test/domain_lnd_Global_MPAS_c211208.nc','mask');
frac= ncread('../Susquehanna_test/domain_lnd_Global_MPAS_c211208.nc','frac');
area= ncread('../Susquehanna_test/domain_lnd_Global_MPAS_c211208.nc','area');
if strcmp(domain,'Susquehanna')
    longxy = ncread('../Susquehanna_test/MOSART_Susquehanna_MPAS_c211026.nc','longxy')+360;
    latixy = ncread('../Susquehanna_test/MOSART_Susquehanna_MPAS_c211026.nc','latixy');
    in = NaN(length(longxy),1);
    for i = 1 : length(longxy)
    dist = pdist2([lon lat], [longxy(i) latixy(i)]);
    ind = find(dist == min(dist));
    
    disp([num2str(lon(ind)) ', ' num2str(lat(ind)) ' === ' num2str(longxy(i)) ', ' num2str(latixy(i))]);
    in(i) = ind;
    end

elseif strcmp(domain,'Delaware')
    S = shaperead('WBD_02_Shape/WBDHU4.shp');
    in = inpolygon(lon,lat,S(6).X+360,S(6).Y);
    in = find(in == 1);
    
elseif strcmp(domain,'Mid-Atlantic')
    S = shaperead('WBD_02_Shape/WBDHU2.shp');
    in = inpolygon(lon,lat,S.X+360,S.Y);
    in = find(in == 1);
    
end

fname_out = CreateCLMUgridSurfdatForE3SM2(  ...
                    in,                             ...
                    '../Susquehanna_test/surfdata_delaware_60_30_5_2_v2_simyr2010_c211007.nc',  ...
                    '.', [domain '_MPAS'],...
                    [],[],[],[],[], ...
                    [],[],[],[],[],[],[],[],[]);

if strcmp(domain,'Delaware') || strcmp(domain, 'Mid-Atlantic')
    
% Prepare MOSART inputfile by creating the netcdf file
out_netcdf_dir = ['.'];
mosart_usrdat_name = [domain '_MPAS'];
mosart_gridded_surfdata_filename = '../Susquehanna_test/MOSART_Global_MPAS_c211208.nc';

fname_out = sprintf('%s/MOSART_%s_%s.nc',out_netcdf_dir,mosart_usrdat_name,datestr(now, 'cyymmdd'));
disp(['  MOSART_dataset: ' fname_out]);
ncid_inp = netcdf.open(mosart_gridded_surf  data_filename,'NC_NOWRITE');
ncid_out = netcdf.create(fname_out,'NC_CLOBBER');

info_inp = ncinfo(mosart_gridded_surfdata_filename);
[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);


% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dimid(1) = netcdf.defDim(ncid_out,'gridcell',length(in));
dimid(2) = netcdf.defDim(ncid_out,'nele',11);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
for ivar = 1 : nvars
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
    if strcmp(varname,'ele')
        varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,[dimid(1) dimid(2)]); 
    else
        varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1)); 
    end
   
    varnames{ivar} = varname;
    for iatt = 1 : natts
        attname = netcdf.inqAttName(ncid_inp,ivar-1,iatt-1);
        attvalue = netcdf.getAtt(ncid_inp,ivar-1,attname);
        
        netcdf.putAtt(ncid_out,ivar-1,attname,attvalue);
    end
end

varid = netcdf.getConstant('GLOBAL');
[~,user_name]=system('echo $USER');
netcdf.putAtt(ncid_out,varid,'Created_by' ,user_name(1:end-1));
netcdf.putAtt(ncid_out,varid,'Created_on' ,datestr(now,'ddd mmm dd HH:MM:SS yyyy '));
netcdf.endDef(ncid_out);

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Copy variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
ID_region = 1 : length(in);
ID = ncread(mosart_gridded_surfdata_filename,'ID');
dnID = ncread(mosart_gridded_surfdata_filename,'dnID');

for ivar = 1:nvars
    [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
    tmp = netcdf.getVar(ncid_inp,ivar-1);
    if strcmp(varname,'ID')
        netcdf.putVar(ncid_out,ivar-1,ID_region);
    elseif strcmp(varname,'dnID')
        dnID_temp = dnID(in);
        ID_temp   = ID(in);
        dnID_region = NaN(length(dnID_temp),1);
        for i = 1 : length(dnID_temp)
            if dnID_temp(i) == -9999
                dnID_region(i) = -9999;
            else
                ind = find(ID_temp == dnID_temp(i));
                if isempty(ind)
                    dnID_region(i) = -9999;
                else
                    dnID_region(i) = ID_region(ind);
                end
            end
        end
        netcdf.putVar(ncid_out,ivar-1,dnID_region);
    elseif strcmp(varname,'ele')
        netcdf.putVar(ncid_out,ivar-1,tmp(in,:));
    else
        netcdf.putVar(ncid_out,ivar-1,tmp(in));
    end
end
% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);


fname_out2 =  sprintf('%s/domain_lnd_%s_%s.nc',out_netcdf_dir, ...
                      mosart_usrdat_name,datestr(now, 'cyymmdd'));
                  
area2 = generate_lnd_domain(lon(in),lat(in),lonv(:,in),latv(:,in),frac(in),mask(in),area(in),fname_out2);
end