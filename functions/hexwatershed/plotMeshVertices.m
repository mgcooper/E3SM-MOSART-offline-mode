function plotMeshVertices(XV, YV, opts, patchprops)
   %PLOTMESHVERTICES
   %
   %  PLOTMESHVERTICES(XV, YV, "numverts", NUMVERTS)
   %
   % Notes on patch:
   % Faces is a list of indices indicating the order in which Vertices are
   % connected, with one index per row in Vertices. Here we require the
   % vertices to be ordered from 1:numverts, thus faces is simply 1:numverts,
   % but the ~isnan check is used to handle nan-padded features. At least 3
   % points are required to form a patch.
   %
   % See also:
   arguments
      XV
      YV
      opts.numverts = size(XV, 1)
      patchprops.?matlab.graphics.primitive.Patch
      patchprops.FaceColor = 'none'
      patchprops.LineWidth = 0.5
   end
   patchprops = namedargs2cell(patchprops);

   % The convention used in matlab is each column defines a feature
   % Thus the number of verts per feature is the number of rows, size(1)
   numverts = opts.numverts;

   xv = prepVertsForPatchPlot(XV, numverts);
   yv = prepVertsForPatchPlot(YV, numverts);

   % Patch the verts. This is designed to handle nan-padded features.
   arrayfun( @(n) patch('Faces', 1:sum(~isnan(yv(:, n))), ...
      'Vertices', [xv(:,n), yv(:,n)], patchprops{:}), ...
      1:size(yv,2));

   % Debug
   debug = false;
   if debug == true

      figure; hold on
      for n = 1:size(yv, 2)
         xv_n = xv(:, n);
         yv_n = yv(:, n);

         % Ensure polygon closure - should not be necessary.
         % [xv_n, yv_n] = closepolygon(xv_n, yv_n);

         keep = find(~isnan(yv_n));
         if numel(keep) >= 3
            patch('Faces', 1:numel(keep), 'Vertices', [xv_n(keep), yv_n(keep)], ...
               'FaceColor', 'none', 'LineWidth', 0.5);
         end
      end
      % test this
      % cellfun(@patch, XV, YV)

      % For reference, this was the original method designed for hexwatershed, if
      % for some reason sum(~isnan...) fails.
      % arrayfun( @(n) patch('Faces', 1:find(isnan(yv(:,n)), 1, 'first')-1, ...
      %    'Vertices', [xv(:,n), yv(:,n)], 'FaceColor', 'none', 'LineWidth', 0.5), ...
      %    1:size(yv,2));
   end
end

function verts = prepVertsForPatchPlot(verts, numverts)

   % Transpose the data to be numverts x numfeatures
   if size(verts,1) ~= numverts && size(verts,2) == numverts
      verts = transpose(verts);
   end
end
