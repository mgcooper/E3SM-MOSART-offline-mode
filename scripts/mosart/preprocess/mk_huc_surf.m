clean


%% set paths

path.data   = '/Users/coop558/mydata/e3sm/sag/unstructured/icom_template/';
path.sag    = setpath('interface/data/hillsloper/');
path.out    = '/Users/coop558/myprojects/e3sm/sag/e3sm_input/';
path.in     = path.data;


%% 1. Load the hillsloper data and modify it for MOSART 

load([path.sag 'sag_hillslopes']); slopes = newslopes; clear newslopes;
sagvarnames     = fieldnames(slopes);
i               = isnan([slopes.dnID]);
slopes(i).dnID  = -9999;                    % replace nan with -9999


%% read in icom files to use as a template

% see sftp://compy.pnl.gov/compyfs/inputdata/rof/mosart/
fland   = [path.data 'surfdata_u_icom_half_sparse_grid_c200615.nc'];
fout    = [path.out 'surfdata_sag_test_basin.nc'];


%% 1. mosart file (frivinp_rtm)

info    = ncparse(fland);
vars    = [info.Name];
nvars   = length(vars);
ncells  = length(slopes);

for i = 1:nvars
    vari            = vars(i);
    myschema.(vari) = ncinfo(fland,vari);
    irep            = myschema.(vari).Size == 72;
    if any(irep)
        myschema.(vari).Size(irep)  = ncells;
    end
    if ~isempty(myschema.(vari).Dimensions)
        irep = [myschema.(vari).Dimensions.Length] == 72;
        if any(irep)
            myschema.(vari).Dimensions(irep).Length = ncells;
        end
    end
end


for i = 1:nvars
    vari = vars(i);     
    dati = ncread(fland,vari);  % read the value from the land file
    
    if strcmp(vari,'LATIXY')
        dati = slopes.latixy;
    end
    
    if strcmp(vari,'LONGXY')
        dati = slopes.longxy;
    end

    % this only works because 1) I know that 72 is always in the 1st
    % dimension, and 2) I know that there are no vars with >3 dims  
    sizei = size(dati);
    if any(sizei==72)
        dati = dati(1:ncells,:,:);
    end
    ncwriteschema(fout,myschema.(vari));
    ncwrite(fout,vari,dati);
end

testinfo = ncinfo(fout);


surfarea = ncread(fin,'AREA');
domainarea = ncread(fdomain,'area');

figure;
plot(surfarea); hold on;
plot(domainarea,':');
legend('domain file area','surf file area')

surftime = ncread(fin,'time');


%%


mosart_info = ncinfo(fout);
mosart_parse = ncparse(fout);


%%


% fmosart and fparams are both frivinp files, but fmosart is the one that
% is used in the unstructured test runs. the fland file is not specified in
% the .sh script, whereas the other two are. Other than formatting fmosart,
% I think I just need to format the runoff input file (which isn't shown
% here) but that might not be necessary - it might just source Runoff from
% that file automatically.         

% these ones are from Tian's create_unstructured_mosart_parameters script:
% vars            = {'latixy','longxy','area','areaTotal','areaTotal2',   ...
%                     'dnID','frac','gxr','hslp','ID','nh','nr','nt',     ...
%                     'rdep','rlen','rslp','rwid','rwid0','tslp','twid'};

% these ones are listed on this Confluence page:
% https://icom.atlassian.net/wiki/spaces/ICOM/pages/171901024/Offline+MOSART+for+mesh+testing
% vars            = {'lat','lon','area','areaTotal','ID','dnID','gxr',    ...
%                     'hslp','nh','tslp','twid','nt','rslp','rlen','rwid',...
%                     'rdep','nr'};

% these ones are listed on the Confluence page:
% https://icom.atlassian.net/wiki/spaces/ICOM/pages/569442313/MOSART+parameters+preparation
% vars            = {'fdir','lat','lon','frac','rslp','rlen','rdep',      ...
%                     'rwid','rwid0','gxr','hslp','twid','tslp','area',   ...
%                     'areaTotal','areaTotal2','nr','nt','nh'};
% note that 'dnID' and 'ID' are not included


% vars    = {'latixy','longxy','ID','dnID','fdir','lat','lon','frac',     ...
%             'rslp','rlen','rdep','rwid','rwid0','gxr','hslp','twid',    ...
%             'tslp','area','areaTotal','areaTotal2','nr','nt','nh',      ...
%             'ele0','ele1','ele2','ele3','ele4','ele5','ele6','ele7',    ...
%             'ele8','ele9','ele10','ele'};
% 
% sname = {   'local drainage area',                                      ...
%             'total upstream drainage area with multi flow direction',   ...
%             'total upstream drainage area with single flow direction',  ...
%             'dnID',                                                     ...
%             'fraction of unit drainage',                                ...
%             'drainage density',                                         ...
%             'topo slope',                                               ...
%             'ID',                                                       ...
%             'Manning coef for overland flow',                           ...
%             'Manning coef for main channel',                            ...
%             'Manning coef for tributary',                               ...
%             'bankfull depth',                                           ...
%             'main channel length',                                      ...
%             'main channel slope',                                       ...
%             'bankfull width',                                           ...
%             'floodplain width',                                         ...
%             'mean tributary slope',...
%             'bankfull width of tributaries'};
% vars = {    'area',                                                     ...
%             'areaTotal',                                                ...
%             'areaTotal2',                                               ...
%             'dnID',                                                     ...
%             'frac',                                                     ...
%             'gxr',                                                      ...
%             'hslp',                                                     ...
%             'ID',                                                       ...
%             'nh',                                                       ...
%             'nr',                                                       ...
%             'nt',                                                       ...
%             'rdep',                                                     ...
%             'rlen',                                                     ...
%             'rslp',                                                     ...
%             'rwid',                                                     ...
%             'rwid0',                                                    ...
%             'tslp',                                                     ...
%             'twid'};
%     
% 
%         
% unit = {    'm^2','m^2','m^2','na','na','m^-1','na','na','na','na',     ...
%             'na','m','m','na','m','m','na','m'};


%%


% for i = 3:nvars     % start on 3 because 1/2 are lat/lon
%     isag = find(ismember(sagvarnames,vars(i)));
%     sagvar = sagvarnames{isag};
%     if isnan(sname{i})
%         sname{i} = vars(i);
%     end
%     netcdf.reDef(ncid)
%     varid_temp = netcdf.defVar(ncid,char(vars(i)),'double', dimid);
%     netcdf.putAtt(ncid,varid_temp,'standard_name',sname{i});
%     netcdf.putAtt(ncid,varid_temp,'units',units{i});
%     netcdf.endDef(ncid);
%     netcdf.putVar(ncid,varid_temp,[newslopes.(sagvar)]);
% end
% 
% netcdf.close(ncid);
% 
% testinfo = ncinfo('MOSART_sag_test_basin.nc');
% testparse = ncparse('MOSART_sag_test_basin.nc');
% 
% % I think the way I want to do it is this:
% % ID = upstream node
% % dnID = downstream node
% % xc/yc = lon/lat for upstream node
% % xv/yv = dummy values
% % not sure about the rest
% 
% % for each node, I need to aggregate the basins that contribute to that
% % node into a single basin, collect the input, and sum it up as one value
% % in which case the 
%

% this was a more complicated method to deal with snipping the vars
%     if ~isempty(dim_n)
%         dimlengths  = [dim_n.Length];
%         igridcell   = find(dimlengths == 72);
%     else
%         dimlengths  = [];
%         igridcell   = [];
%     end



% % create the file and put the lat/lon
% ncid    = netcdf.create(fout,'CLASSIC_MODEL');
% 
% % I think the dims must be created on the fly
% % for n = 1:length(dims)
% %     dimid   = netcdf.defDim(ncid,dims(n).Name,dims(1).Length);
% % end
% % 
% % netcdf.endDef(ncid)
% 
% newdimnames = {'n_mxsoil_color','n_mxsoil_order'};
% 
% % put the first 18 variables that come before lat/lon
% for n = 1:18
%     
%     % read the value from the land file
%     dat_n       = ncread(fin,vars(n));
%     num_dims    = ndims(dat_n);
%     if isscalar(dat_n) || isvector(dat_n); num_dims = num_dims-1; end
%     
%     for i = 1:num_dims
%         if ~isempty(info.land.Variables(n).Dimensions)
%             dim_name    = info.land.Variables(n).Dimensions(i).Name;
%             dim_size    = info.land.Variables(n).Dimensions(i).Length;
%         else
%             dim_name    = newdimnames{n};
%             dim_size    = length(dat_n);
%         end
%     
%         if dim_size == 72
%             dat_n       = dat_n(1:ncells,:,:);
%             dim_size    = ncells;
%         end
%         dimid       = netcdf.defDim(ncid,dim_name,dim_size);
%     end
%     
%     % this works because 1) I know that 72 is always in the 1st dimension,
%     % and 2) I know that there are no vars with >3 dims  
%     varid_temp = netcdf.defVar(ncid,char(vars(n)),'double', dimid);
%     netcdf.putAtt(ncid,varid_temp,'standard_name',sname{n});
%     netcdf.putAtt(ncid,varid_temp,'units',units{n});
%     netcdf.endDef(ncid);
%     netcdf.putVar(ncid,varid_temp,dat_n);
%     netcdf.reDef(ncid)
% end
% 
% % put the 'time'
% 
% % put the 'AREA'
% 
% % put the 'LONGXY'
% netcdf.reDef(ncid)
% varid_lon = netcdf.defVar(ncid,'longxy','double', dimid);
% netcdf.putAtt(ncid,varid_lon,'standard_name','longitude');
% netcdf.putAtt(ncid,varid_lon,'long_name','longitude');
% netcdf.putAtt(ncid,varid_lon,'units','degrees_east');
% netcdf.putAtt(ncid,varid_lon,'axis','X');
% netcdf.endDef(ncid);
% netcdf.putVar(ncid,varid_lon,[newslopes.longxy]);
% 
% % put the 'LATIXY'
% varid_lat   = netcdf.defVar(ncid,'latixy','double', dimid);
% netcdf.putAtt(ncid,varid_lat,'standard_name','latitude');
% netcdf.putAtt(ncid,varid_lat,'long_name','latitude');
% netcdf.putAtt(ncid,varid_lat,'units','degrees_north');
% netcdf.putAtt(ncid,varid_lat,'axis','Y');
% netcdf.endDef(ncid);
% netcdf.putVar(ncid,varid_lat,[newslopes.latixy]);
% 
% % put the rest of the variables 
% for n = 23:nvars
%     netcdf.reDef(ncid)
%     varid_temp = netcdf.defVar(ncid,char(vars(n)),'double', dimid);
%     netcdf.putAtt(ncid,varid_temp,'standard_name',sname{n});
%     netcdf.putAtt(ncid,varid_temp,'units',units{n});
%     netcdf.endDef(ncid);
%     
%     % read the value from the land file
%     dat_n = ncread(fin,vars(n));
%     
%     netcdf.putVar(ncid,varid_temp,[newslopes.(sagvar)]);
% end
% 
% netcdf.close(ncid);
% 
% % info = ncinfo('surfdata_sag_test_basin.nc')


% river file:
% latixy                latitude of the controid of the unit
% longxy                longitude of the controid of the unit
% ID	
% dnID	
% fdir                  flow direction based on D8 algorithm
% lat                   latitude
% lon                   longitude
% frac                  fraction of the unit draining to the outlet
% rslp                  main channel slope
% rlen                  main channel length
% rdep                  bankfull depth of main channel
% rwid                  bankfull width of main channel
% rwid0                 floodplain width linked to main channel
% gxr                   drainage density
% hslp                  topographic slope
% twid                  bankfull width of local tributaries
% tslp                  mean tributary channel slope averaged through the unit
% area                  local drainage area
% areaTotal             total upstream drainage area, local unit included; using concept of multi flow direction
% areaTotal2            total upstream drainage area, local unit included; using concept of single flow direction
% nr                    Manning's roughness coefficient for main channel flow
% nt                    Manning's roughness coefficient for tributary channel flow
% nh                    Manning's roughness coefficient for overland flow
% ele0	
% ele1	
% ele2	
% ele3	
% ele4	
% ele5	
% ele6	
% ele7	
% ele8	
% ele9	
% ele10	
% ele	

% domain file:
% xc                    longitude of grid cell center
% yc                    latitude of grid cell center
% xv                    longitude of grid cell verticies
% yv                    latitude of grid cell verticies
% mask                  domain mask
% area                  area of grid cell in radians squared
% frac                  fraction of grid cell that is active

% surf file:
% mxsoil_color          maximum numbers of soil colors
% mxsoil_order          maximum numbers of soil order
% SOIL_COLOR            soil color
% SOIL_ORDER            soil order
% PCT_SAND              percent sand
% PCT_CLAY              percent clay
% ORGANIC               organic matter density at soil levels
% FMAX                  maximum fractional saturated area
% natpft                indices of natural PFTs
% LANDFRAC_PFT          land fraction from pft dataset
% PFTDATA_MASK          land mask from pft dataset, indicative of real/fake points
% PCT_NATVEG            total percent natural vegetation landunit
% PCT_CROP              total percent crop landunit
% PCT_NAT_PFT           percent plant functional type on the natural veg landunit (% of landunit)
% MONTHLY_LAI           monthly leaf area index
% MONTHLY_SAI           monthly stem area index
% MONTHLY_HEIGHT_TOP	monthly height top
% MONTHLY_HEIGHT_BOT	monthly height bottom
% time                  Calendar month
% AREA                  area
% LONGXY                longitude
% LATIXY                latitude
% EF1_BTR               EF btr (isoprene)
% EF1_FET               EF fet (isoprene)
% EF1_FDT               EF fdt (isoprene)
% EF1_SHR               EF shr (isoprene)
% EF1_GRS               EF grs (isoprene)
% EF1_CRP               EF crp (isoprene)
% CANYON_HWR            canyon height to width ratio
% EM_IMPROAD            emissivity of impervious road
% EM_PERROAD            emissivity of pervious road
% EM_ROOF               emissivity of roof
% EM_WALL               emissivity of wall
% HT_ROOF               height of roof
% THICK_ROOF            thickness of roof
% THICK_WALL            thickness of wall
% T_BUILDING_MAX        maximum interior building temperature
% T_BUILDING_MIN        minimum interior building temperature
% WIND_HGT_CANYON       height of wind in canyon
% WTLUNIT_ROOF          fraction of roof
% WTROAD_PERV           fraction of pervious road
% ALB_IMPROAD_DIR       direct albedo of impervious road
% ALB_IMPROAD_DIF       diffuse albedo of impervious road
% ALB_PERROAD_DIR       direct albedo of pervious road
% ALB_PERROAD_DIF       diffuse albedo of pervious road
% ALB_ROOF_DIR          direct albedo of roof
% ALB_ROOF_DIF          diffuse albedo of roof
% ALB_WALL_DIR          direct albedo of wall
% ALB_WALL_DIF          diffuse albedo of wall
% TK_ROOF               thermal conductivity of roof
% TK_WALL               thermal conductivity of wall
% TK_IMPROAD            thermal conductivity of impervious road
% CV_ROOF               volumetric heat capacity of roof
% CV_WALL               volumetric heat capacity of wall
% CV_IMPROAD            volumetric heat capacity of impervious road
% NLEV_IMPROAD          number of impervious road layers
% peatf                 peatland fraction
% abm                   agricultural fire peak month
% gdp                   gdp
% SLOPE                 mean topographic slope
% STD_ELEV              standard deviation of elevation
% binfl                 VIC b parameter for the Variable Infiltration Capacity Curve
% Ws                    VIC Ws parameter for the ARNO Curve
% Dsmax                 VIC Dsmax parameter for the ARNO curve
% Ds                    VIC Ds parameter for the ARNO curve
% LAKEDEPTH             lake depth
% F0                    maximum gridcell fractional inundated area
% P3                    coefficient for qflx_surf_lag for finundated
% ZWT0                  decay factor for finundated
% PCT_WETLAND           percent wetland
% PCT_LAKE              percent lake
% PCT_GLACIER           percent glacier
% TOPO                  mean elevation on land
% PCT_URBAN             percent urban for each density type
% URBAN_REGION_ID       urban region ID
% APATITE_P             Apatite Phosphorus
% LABILE_P              Labile Inorganic Phosphorus
% OCCLUDED_P            Occluded Phosphorus
% SECONDARY_P           Secondary Mineral Phosphorus
