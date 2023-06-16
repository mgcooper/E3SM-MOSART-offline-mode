function varargout = read_e3sm_domain_file(varargin)

if nargin == 0
   filename = getenv('USER_E3SM_DOMAIN_NCFILE_FULLPATH');
else
   filename = varargin{1};
end

data = ncreaddata(filename);

switch nargout
   case 1
      varargout{1} = data;
   case 2
      [varargout{1:nargout}] = deal(data.xc,data.yc);
   case 3
      [varargout{1:nargout}] = deal(data.xc,data.yc,data.info);
   case 4
      [varargout{1:nargout}] = deal(data.xc,data.yc,data.xv.',data.yv.');
   case 5
      [varargout{1:nargout}] = deal(data.xc,data.yc,data.xv.',data.yv.',data.info);
   case 6
      [varargout{1:nargout}] = deal(data.xc,data.yc,data.xv.',data.yv.',data.area,data.info);
end