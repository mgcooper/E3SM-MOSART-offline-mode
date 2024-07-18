function [Z,R] = makeDomainFile_Hexwatershed(x,varargin)
   %MAKEDOMAINFILE_HEXWATERSHED general description of function
   %
   % Syntax:
   %
   %  [Z,R] = MAKEDOMAINFILE_HEXWATERSHED(x);
   %  [Z,R] = MAKEDOMAINFILE_HEXWATERSHED(x,'name1',value1);
   %  [Z,R] = MAKEDOMAINFILE_HEXWATERSHED(x,'name1',value1,'name2',value2);
   %  [Z,R] = MAKEDOMAINFILE_HEXWATERSHED(___,method). Options: 'flag1','flag2','flag3'.
   %        The default method is 'flag1'.
   %
   % Author: Matt Cooper, MMM-DD-YYYY, https://github.com/mgcooper

   parser = inputParser;
   parser.FunctionName = mfilename;

   addRequired(parser, 'x', @(x)isnumeric(x));
   addParameter(parser, 'namevalue', false, @(x)islogical(x));
   addOptional(parser, 'option', nan, @(x)ischar(x));

   parse(parser,x,varargin{:});

   namevalue = parser.Results.namevalue;
   option = parser.Results.option;


   % this was at the bottom of donghui's generate_mosart_from_hexwatershed
   mask = zeros(length(frac),1);
   mask(frac > 0) = 1;
   area2 = generate_lnd_domain(lon,lat,lonv,latv,frac,mask,area,fdom);
end
