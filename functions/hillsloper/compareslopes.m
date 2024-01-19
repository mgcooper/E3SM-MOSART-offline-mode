function compareslopes(slopes, testslopes)

   % This is a snippet from comparing the modified slopes returned by
   % makenewslopes with makenewlinks (now findDownstreamLinks)
   
   tf = isequal(fieldnames(testslopes), fieldnames(slopes));

   if tf
      disp('fieldnames are identical');
   else
      disp('fieldnames are not identical');
   end

   fields = fieldnames(testslopes);
   for n = 1:numel(fields)
      dat1 = [testslopes.(fields{n})];
      dat2 = [slopes.(fields{n})];
      if ~isequal(dat1,dat2)
         disp([fields{n} ' not equal'])
      end
   end

   % test ID needs subtract one
   % testID = [testslopes.ds_link_ID]-1;
   % newID = [slopes.ds_link_ID];
   % find(testID~=newID)

   % figure;
   % plot([testslopes.link_ID],[slopes.link_ID],'o');
   % addOnetoOne;

   %% This was another way I compared them
   % test = links;
   % test(1392) = [];
   % % isequal(test, newlinks) % nope, b/c newlinks has additional fields
   % f1 = fieldnames(newlinks);
   % f2 = fieldnames(test);
   % test2 = newlinks;
   % test2 = rmfield(test2, setdiff(f1, f2));
   % isequal(test, test2) % nope, b/c newlinks has additional fields

   % isequal(fieldnames(test), fieldnames(test2))

   % [common, d1, d2] = comp_struct(test, test2, 0, 0);
end
