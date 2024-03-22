function node = getnode(nodes, id, idtype)

   if nargin < 3
      idtype = 'node_ID'; % fid starts at 1, node_ID starts at 0
   end

   node = nodes([nodes.(idtype)] == id);
end
