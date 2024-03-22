function plotlinks(links, start_ID, highlight)
   %PLOTLINKS Plot links using an upstream walk
   %
   % Key logic this relies on:
   %  us_hs_ID is nan for headwater links
   %  us_conn_ID contains all immediate upstream links of each link

   if nargin < 2
      % Start at the outlet index
      start_ID = links([links.isOutlet]); % hillsloper.outlet_link_ID;
      start_ID = 2661;
   end
   if nargin < 3
      highlight = start_ID;
   end

   figontop
   ids = [links.link_ID];
   idx = find(ids == start_ID);

   % Initialize variables to keep track of what has been done
   id_done = [];     % Links that have been traversed
   stack = [];       % Stack to hold upstream links at confluences

   while ~isempty(idx)  % While there are still links to visit

      % Plot the current link
      lati = [links(idx).Lat];
      long = [links(idx).Lon];

      if ismember(links(idx).link_ID, highlight)
         geoshow(lati(1:end-1), long(1:end-1), 'Color', 'g'); hold on;
      else
         geoshow(lati(1:end-1), long(1:end-1)); hold on;
      end

      scatter(long(end-1), lati(end-1), 'r', 'filled');

      % Get upstream links
      us_conn_ids = links(idx).us_conn_ID;

      % Here's the problem, us_conn_ID should have 185 and 1390, which should be
      % the us_conn_ID of the removed link
      % 2665

      % Add the traversed link to id_done
      id_done = [id_done; links(idx).link_ID];

      % If it's a headwater link
      if isnan(links(idx).us_hs_ID)
         next_id = [];
      else
         % Remove self
         us_conn_ids = us_conn_ids(us_conn_ids ~= links(idx).link_ID);

         if length(us_conn_ids) > 1  % We're at a confluence
            % Push extra upstream links to stack
            stack = [stack us_conn_ids(2:end)];
         end

         % Choose the next upstream link to go to
         next_id = us_conn_ids(1);
      end

      if isempty(next_id) || ismember(next_id, id_done)  % If we've reached a headwater or loop
         if isempty(stack)  % If no more upstream links in stack, we're done
            break;
         else  % Pop the next link from the stack
            next_id = stack(end);
            stack(end) = [];
         end
      end

      % Update idx for the next iteration
      idx = find(ids == next_id);

      if isempty(idx)
         warning('Next index is empty. Check your link connectivity.');
         break
      end

      pause;  % For visualization
   end
end
