function done = upstreamPixels(Ifdr, start_idx, fdir_map, remove)

   % Ensure fdir_map and remove are provided with defaults if not specified
   if nargin < 3
      fdir_map = [64, 128, 1, 32, 2, 16, 8, 4]; % Default mapping of integer values to flow directions
   end
   if nargin < 4
      remove = []; % Default empty array if remove is not specified
   end

   % Initialize logical arrays for done and todo
   done = false(numel(Ifdr), 1);
   todo = false(numel(Ifdr), 1);
   todo(start_idx) = true;

   while any(todo)
      % Find the first true index in 'todo', process it, and then set it to false
      doidx = find(todo, 1, 'first');
      todo(doidx) = false;
      done(doidx) = true;

      % Find neighbors that flow into this index
      neighs_into = into(Ifdr, doidx, fdir_map);

      for i = 1:length(neighs_into)
         ni = neighs_into(i);
         if ~done(ni) && ~ismember(ni, remove)
            todo(ni) = true;
         end
      end
   end

   % Convert logical array 'done' to indices
   done = find(done);
end

function neighs_into = into(Ifdr, doidx, fdir_map)
   % This function should identify neighboring pixels that flow into the current pixel
   % based on the Ifdr array and the specified flow direction mapping (fdir_map).
   % You'll need to implement the logic specific to your application's flow direction conventions.

   % Example placeholder implementation
   neighs_into = [];
end
