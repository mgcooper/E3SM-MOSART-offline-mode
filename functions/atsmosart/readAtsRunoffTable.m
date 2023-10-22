function Data = readAtsRunoffTable(fname,varargin)

   % the data in the spreadsheet is ats runoff for each hillslope in units m3/d
   % the data is converted to mm/s for input to MOSART elsewhere

   % probably makes sense to have this read the spreadhseet and the area file
   % and require hs_id and use it as a preprocessor for mk_runoff

   opts = optionParser({'plotdata','mergeslopes'},varargin(:));

   if opts.mergeslopes
      hs_id = varargin{1};
   end

   % these data are just columns of runoff
   Data = readtable(fname);
   Data = settableunits(Data,'m3/d');

   % the first three columns are year, doy, day since first day. remove them,
   % build a calendar, and convert to timetable: Time =
   % datetime(T(:,1)+T(:,2)./365)
   Time = datetime(1998,1,1):caldays(1):datetime(2002,12,31);
   Time = rmleapinds(Time);
   Data = Data(:,4:end);
   Data = table2timetable(Data,'RowTimes',Time);

   % merge the slopes / combine the runoff
   if opts.mergeslopes == true

      timeATS = Data.Time;
      numdays = numel(timeATS);
      nslopes = size(Data,2)/2;
      roffATS = nan(numdays,nslopes);

      % combine the ats runoff for each hillslope
      for n = 1:nslopes
         str1 = ['hillslope_' num2str(n) ];
         str2 = ['hillslope' num2str(n)  ];
         roffATS(:,n) = Data.(str1) + Data.(str2);
         % hsarea(n) = A.area_m2_(A.ID==-n) + A.area_m2_(A.ID==n);
      end

      % the data in runoff goes from 1->nslopes or 1->18 for the trib basin
      % re-order the data to go from 1->nlinks using the hs_id field
      roffATS = roffATS(:,hs_id);

      Data = array2timetable(roffATS,'RowTimes',timeATS);

      % could use 'link' to avoid further confusion about the ID field but use
      % hillslope for now for consistency with other functions
      Data = settablevarnames(Data,'hillslope','consecutive');
   end

   % plot the basin-sum runoff
   if opts.plotdata == true
      figure; plot(Data.Time,sum(table2array(Data),2));
   end

   % % for reference, an earlier version had slopes numbered from 1:36: for n =
   % 1:nslopes
   %     str1 = ['slope_' num2str(2*n-1) ]; str2 = ['slope_' num2str(2*n)];
   %     roffATS(:,n) = Data.(str1) + Data.(str2);
   % end
end
