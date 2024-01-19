function link = getlink(links, id, idtype)
   
   if nargin < 3
      idtype = 'link_ID'; % fid starts at 1, node_ID starts at 0
   end
   
   link = links([links.(idtype)] == id);
end