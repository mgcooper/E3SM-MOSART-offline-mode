function makeMosartHexwatershed(fhex,ftem,fmos,varargin)
%MAKEMOSARTHEXWATERSHED make Mosart parameter file from hexwatershed json
%
% Syntax:
%
%  msg = MAKEMOSARTHEXWATERSHED(fhex,ftem,fmos)
%  msg = MAKEMOSARTHEXWATERSHED(fhex,ftem,fmos,'fdom',fdom) also writes the
%  domain file
% 
% 
% Inputs
%     fhex: HexWaterhsed output
%     ftem: Template MOSART input file to intepolate on
%     fmos: MOSART input filename (to create)
%     fdom: Domain file
%     plot_river: plot_river = true, plot the river network. Default = false
%     plot_mesh: plot_mesh = true, plot the mesh. Default = false
%
% Author: Matt Cooper, 26-Jan-2023, https://github.com/mgcooper
% Based on code provided by Donghui Xu.

% NOTE this is based on a file emailed from donghui. see his version here:
% Setup-E3SM-Mac/matlab-scripts-to-process-inputs/generate_mosart_from_hexwatershed.m 
% 
% TODO
% reconcile with mk_mosart_file / mos_makemosart. will require a pre-processing
% step that adds the necessary fields to Mesh like b_make_newslopes adds the
% info to the slopes struct.

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p = inputParser;
p.FunctionName = mfilename;

addRequired(p,    'fhex',                 @(x)ischarlike(x)    );
addRequired(p,    'ftem',                 @(x)ischarlike(x)    );
addRequired(p,    'fmos',                 @(x)ischarlike(x)    );
addParameter(p,   'fdom',        '',      @(x)ischarlike(x)    );
addParameter(p,   'add_ele',     false,   @(x)islogical(x)     );
addParameter(p,   'plot_river',  false,   @(x)islogical(x)     );
addParameter(p,   'plot_mesh',   false,   @(x)islogical(x)     );

parse(p,fhex,ftem,fmos,varargin{:});

fdom = p.Results.fdom;
add_ele = p.Results.add_ele;
plot_mesh = p.Results.plot_mesh;
plot_river = p.Results.plot_river;

%------------------------------------------------------------------------------


% Read the Mesh, get cell vertices, and convert global ID to domain ID
Mesh = jsondecode(fileread(fhex));
[ID,dnID] = hexmesh_dnID(Mesh);
[latv,lonv,numv] = hexmesh_vertices(Mesh);

% setup the data for the Mosart parameter file
lonc = transpose([Mesh(:).dLongitude_center_degree]);
latc = transpose([Mesh(:).dLatitude_center_degree]);
area = transpose([Mesh(:).Area]);
elev = transpose([Mesh(:).Elevation]);
rlen = transpose([Mesh(:).dLength_flowline]); 
frac = ones(numel(ID),1);
fdir = ones(numel(ID),1);
area2 = transpose([Mesh(:).DrainageArea]);
dSlope = transpose([Mesh(:).dSlope_between]);
% TODO: use actual river length for rlen (dLength_flowline is conceptual length)

% set fdir = 0 at outlets
fdir(dnID == -9999) = 0;

% % this is from generate_hexagon_mesh_mosart which reads in hexwatershed.nc
% which must have been preprocessed to have the Depth/Width variables
% rdep = ncread(hexfile,'Depth'); rdep = rdep ./ 10^2.4;
% rwid = ncread(hexfile,'Width'); rwid = rwid ./ 10^3.6;

% assign channel geometry
if exist('channel_geometry.mat','file')
   load('channel_geometry.mat','rwid','rdep');
else
   
   % for now assign constants
   rwid = 20.*ones(size(ID));
   rdep = 2.*ones(size(ID));
   
   % [rwid,rdep,flood_2yr] = get_geometry(lonc,latc,ID,dnID,area);
   % save('channel_geometry.mat','rwid','rdep','flood_2yr');
end

% NOTE below here, no variables are modified. Above could be ported to a
% prepmesh function similar to how hillsoper is prepped by changing variable
% names to match the ones in the mosart input file

% -------
%  PLOTS
% -------
if plot_river
   figure;
   for i = 1 : length(ID)
      if dnID(i) ~= -9999
         plot([lonc(ID(i)) lonc(dnID(i))],[latc(ID(i)) latc(dnID(i))], ...
            'b-','LineWidth',1.5); hold on;
      else
         plot(lonc(ID(i)),latc(ID(i)),'r*'); hold on;
      end
   end
end

if plot_mesh
   figure;
   subplot(1,3,1);
   for i = 4 : 8
      patch(lonv(1:i,numv == i),latv(1:i,numv == i),rlen(numv == i),'LineStyle','none'); colorbar; hold on;
   end
   set(gca,'ColorScale','log');
   title('River length [m]','FontSize',15,'FontWeight','bold');
   subplot(1,3,2);
   for i = 4 : 8
      patch(lonv(1:i,numv == i),latv(1:i,numv == i),rwid(numv == i),'LineStyle','none'); colorbar; hold on;
   end
   title('River width [m]','FontSize',15,'FontWeight','bold');
   subplot(1,3,3);
   for i = 4 : 8
      patch(lonv(1:i,numv == i),latv(1:i,numv == i),rdep(numv == i),'LineStyle','none'); colorbar; hold on;
   end
   title('River depth [m]','FontSize',15,'FontWeight','bold');
end

% ---------------
%  Make the file
% ---------------

% Prepare MOSART inputfile by creating the netcdf file
disp(['  MOSART_dataset: ' fmos]);
ncid_inp = netcdf.open(ftem,'NC_NOWRITE');
ncid_out = netcdf.create(fmos,'NC_CLOBBER');

info_inp = ncinfo(ftem);
[ndims,nvars,ngatts,unlimdimid] = netcdf.inq(ncid_inp);

% mgc these are used to interpolate variables in the template file that are not
% explicitly defined in the loop below onto the mesh latc/lonc grid
latixy = ncread(ftem,'latixy');
longxy = ncread(ftem,'longxy');

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define dimensions
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
dimid(1) = netcdf.defDim(ncid_out,'gridcell',length(latc));
if add_ele == 1
   dimid(2) = netcdf.defDim(ncid_out,'nele',11);
end

% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
%                           Define variables
%
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
found_ele = 0;
for ivar = 1 : nvars % nvars = # of variables in the template file
   [varname,xtype,dimids,natts] = netcdf.inqVar(ncid_inp,ivar-1);
   if strcmp(varname,'ele')
      found_ele = 1;
      % mgc added this if-else
      if add_ele == true
         dimid(2) = netcdf.defDim(ncid_out,'nele',11);
         varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,[dimid(1) dimid(2)]);
      else
         varid(ivar) = netcdf.defVar(ncid_out,varname,xtype,dimid(1));
      end
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
for ivar = 1:nvars
   [varname,vartype,vardimids,varnatts]=netcdf.inqVar(ncid_inp,ivar-1);
   tmp = netcdf.getVar(ncid_inp,ivar-1);
   if strcmp(varname,'lat') || strcmp(varname,'latixy')
      netcdf.putVar(ncid_out,ivar-1,latc);
   elseif strcmp(varname,'lon') || strcmp(varname,'longxy')
      netcdf.putVar(ncid_out,ivar-1,lonc);
   elseif strcmp(varname,'rslp') || strcmp(varname,'tslp')
      netcdf.putVar(ncid_out,ivar-1,dSlope);
   elseif strcmp(varname,'ID')
      netcdf.putVar(ncid_out,ivar-1,ID);
   elseif strcmp(varname,'dnID')
      netcdf.putVar(ncid_out,ivar-1,dnID);
   elseif strcmp(varname,'frac')
      netcdf.putVar(ncid_out,ivar-1,frac);
   elseif strcmp(varname,'fdir')
      netcdf.putVar(ncid_out,ivar-1,fdir);
   elseif strcmp(varname,'rdep')
      netcdf.putVar(ncid_out,ivar-1,rdep);
   elseif strcmp(varname,'rwid')
      netcdf.putVar(ncid_out,ivar-1,rwid);
   elseif strcmp(varname,'rwid0')
      netcdf.putVar(ncid_out,ivar-1,rwid.*5);
   elseif strcmp(varname,'areaTotal') || strcmp(varname,'areaTotal2')
      netcdf.putVar(ncid_out,ivar-1,area2);
   elseif strcmp(varname,'area')
      netcdf.putVar(ncid_out,ivar-1,area);
   elseif strcmp(varname,'rlen')
      netcdf.putVar(ncid_out,ivar-1,rlen);
   elseif strcmp(varname,'ele')
      netcdf.putVar(ncid_out,ivar-1,elev);
   else
      % this interpolates the data in the template file onto the mesh latc/lonc
      tmpv = griddata(longxy,latixy,tmp,lonc,latc,'nearest');
      tmpv(tmpv < -9000) = NaN;
      tmpv = fillmissing(tmpv,'nearest');
      netcdf.putVar(ncid_out,ivar-1,tmpv);
   end
end
if add_ele == 1 && found_ele == 0
   ivar = nvars + 1;
   netcdf.putVar(ncid_out,ivar-1,elev);
end

% close files
netcdf.close(ncid_inp);
netcdf.close(ncid_out);

if plot_river
   figure;
   show_river_network(fmos,0.1);
end

if ~isempty(fdom)
   mask = zeros(numel(ID),1); mask(frac > 0) = 1;
   area2 = generate_lnd_domain(lonc,latc,lonv,latv,frac,mask,area,fdom);
end















