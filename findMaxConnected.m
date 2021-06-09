function max_conn= findMaxConnected(ad_mat)
%myFun - Finding max connect component for a graph using adjacent matrix
%
% Syntax: max_conn = findMaxConnected(ad_mat)
%
% Long description
% Input: ad_mat: adjacent matrix
% max_conn: max connection component
    
G = graph(ad_mat);
bins = conncomp(G, 'OutputForm', 'cell');

conn_size = cellfun(@length, bins);
max_idx = find(max(conn_size));
max_conn = bins{max_idx(1)};
plot(G);
    