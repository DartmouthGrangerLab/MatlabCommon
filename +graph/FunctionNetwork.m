% Eli Bowen 6/2022
% a directed graph of functions (and their parameters)
%   data flows through this graph, from function to function
%   a node or edge can conveniently and transparently take on any value (including matrices, cell arrays of strings, ...)
%   a contract that's language-agnostic (matlab, julia, python)
% requires that each function produce a single output variable (can be an array)
% USAGE
%   net = graph.FunctionNetwork();
%   net = InsertNode(net, '',        [], 'sense', 100); % construct the input node with a null function
%   net = InsertNode(net, 'sum',     [], 'a');
%   net = InsertNode(net, '@(x)x+1', [], 'plusone');
%   net = InsertEdges(net, 'sense', 'a',       1);
%   net = InsertEdges(net, 'a',     'plusone', 1);
%   sense = randi(10, 100, 1); % n_dims x n_datapts
%   net = SetNodeOutput(net, 'sense', sense);
%   net = Execute(net); % 1st timestep
%   disp(GetNodeOutput(net, 'a'));
%   net = Execute(net); % 2nd timestep
%   disp(GetNodeOutput(net, 'plusone'));
%   figure;plot(net)
classdef FunctionNetwork
    properties (SetAccess=private)
        g (1,1) digraph = digraph()
    end
    properties (Transient, SetAccess=private)
        cache     (1,1) struct = struct()
        cache_ver (1,1) double = 0 % every time we reset the cache, we increment this - provides a way for other objects to determine whether our data has changed (and reset their own cache if they want)
    end
    properties (Dependent) % computed, derivative properties
        n_nodes          % scalar (int-valued numeric)
        n_edges          % scalar (int-valued numeric)
        node_name        % n_nodes x 1 (cellstr)
        node_func        % n_nodes x 1 (categorical)
        node_data        % n_nodes x 1 (cell) data provided as the first arg to the func
        %   ^ can be a class, etc
        %   ^ if node_data is another Network object, and node_func is 'Execute', you can have a sub-network
        edge_endnode     % n_edges x 2 (cellstr)
        edge_endnode_idx % n_edges x 2 (int-valued numeric)
        edge_dst_var     % n_edges x 1 (uint8)
        n_iter           % scalar (int-valued numeric)
    end


    methods
        % run one epoch
        function obj = Execute(obj)
            assert(all(indegree(obj.g) + outdegree(obj.g)), 'found orphan nodes');
            
            if ~isfield(obj.cache, 'node_output')
                obj.cache.node_output = cell(obj.n_nodes, 1); % so we can store data across calls to Execute
            end
            
            for i = 1 : obj.n_nodes
                if isundefined(obj.node_func(i))
                    assert(numel(inedges(obj.g, i)) == 0, 'undefined functions cant have inputs');
                    if isempty(obj.cache.node_output{i})
                        obj.cache.node_output{i} = zeros(obj.g.Nodes.n_out(i), 1); % treating this blank function like it's @()zeros(x, 1)
                    end
                else
                    % route outputs to this node using graph edges, then compute the function
                    [eid,nid] = inedges(obj.g, i);
                    input = obj.cache.node_output(nid(obj.edge_dst_var(eid))); % sorting nid by dst var
                    input = cat(1, obj.node_data{i}, input);

                    % compute the function
                    func = str2func(char(obj.node_func(i)));
                    obj.cache.node_output{i} = func(input{:});
                    assert(isnan(obj.g.Nodes.n_out(i)) || size(obj.cache.node_output{i}, 1) == obj.g.Nodes.n_out(i), 'functions must produce the same output dimensionality at each evaluation');
                end
            end
            
            % TODO: how to handle dot product (paired, not just indexed, vars)
            % TODO: how to handle separate sense and label inputs
            %   ^ instead of sense and label, can have one input vec along with not just dst idx, but grouping idx
            % careful! must get this right
            % one dstVar per edge. for low-level networks, will need multiple edges per dstVar
            %   stored in the edge or in the node?
            % index and var name must come across the network - dst has no way of knowing
            %   in hardware, each cmp can be just one dst_var
            %       (as long as dst vars can be 0-255, so it can act as first param in one dst and second param in another dst)
            %   so dst needs to keep track of which var idx is var 1, and which is var 2
            %       (in dot product, order is arbitrary)
            % so final decision: one var ID per src node, dst node maps var id of the src node onto var number (1, 2, ...) of the output
            %   keeps each func producing 1 output, lets it use several input args
            %   simplest version is use src node name as src var ID
            %       more bit-compressed version is for node to store a low-num-bits id
            %   problem: input starts as one node
            %       so need to map edge names to var names, not src node names to var names
            %       or we can split input into multiple
            %   of course this also breaks the idea that EDGES are connections (storing connection info in the destination)
            %   and edges are like hardware messages, so they should contain what the msg must contain
            
            %TODO: map each edge to a var name
            %TODO: split input into several nodes
            
            %TODO: multiple nodes per function, each node scalar output?
            %   if so, every node gets a func ID (categorical), and an index, and a var num
            %   need input nodes and output nodes, since there isn't 1:1 correspondance
            %   no longer need dst var or dst idx on edges
            %   nodeOutput becomes n_func_output_nodes x 1, nodeInput becomes n_func_input_nodes x 1
            %   more flexible, simpler, easier to compile to hardware
            %   but annoying to have two classes of node (tho it's bipartite...)
            %   also annoying to have a many-to-many relationship amongst nodes
            %       many-to-one and one-to-many are fine, it's this many-to-many mess
            %   ok so keep the old way
            %   perhaps we can treat each edge like a single var, but give it a data type that can be array? ugh no annoying too
            
            % best plan is to just make it work for the high-level code, then tweak the functions used in low-level to deal with it
            %   e.g. 256D dot product is 512 inputs (implicitly split in half)
            
            % UGH DO I STILL NEED dstIdx? i guess, but then why is that system different from the dstVar system?
            % maybe I should really just have one edge per scalar? simplest, but low performance for loop to pass info
            %   (cached high-performance data structure best)
        end


        function [obj,newName] = InsertNodes(obj, func, data, name)
            validateattributes(func, {'char','function_handle'}, {});
            if ~exist('data', 'var') || isempty(data)
                data = cell(numel(name), 1);
            end
            if ~exist('name', 'var') || isempty(name)
                name = cell(numel(data), 1);
            end
            
            newName = cell(numel(data), 1);
            for i = 1 : numel(data)
                [obj,newName{i}] = InsertNode(obj, func, data{i}, name{i});
            end
        end


        function [obj,newName] = InsertNode(obj, func, data, name, n_out)
            validateattributes(func, {'char','function_handle'}, {});
            validateattributes(data, {'numeric','logical'}, {});
            validateattributes(name, {'char'}, {});
            if isa(func, 'function_handle')
                func = func2str(func);
            end
            
            assert(~any(strcmp(name, obj.node_name)), 'nodes must have unique names');
            
            s = struct();
            s.func = {func};
            s.data = {data};
            s.Name = {name}; % lower case - using matlab's graph structure without official names, since that causes performance issues
            s.n_out = NaN;
            if exist('n_out', 'var') && ~isempty(n_out)
                s.n_out = double(n_out);
            end
            obj.g = addnode(obj.g, struct2table(s));
            newName = obj.node_name{end};
            if size(obj.g.Nodes, 1) == 1
                obj.g.Nodes.func = categorical(obj.g.Nodes.func);
            end
            
            obj = ResetCache(obj);
        end


        function obj = InsertEdges(obj, src, dst, dstVar)
            validateattributes(src, {'char','cell'}, {'nonempty','vector'});
            validateattributes(dst, {'char','cell'}, {'nonempty','vector'});
            validateattributes(dstVar, {'numeric'}, {'nonempty','vector','nonnegative','integer','<=',255});
            assert((ischar(src) && ischar(dst) && isscalar(dstVar))...
                || (iscell(src) && iscell(dst) && numel(src) == numel(dst) && numel(src) == numel(dstVar)));
            if ischar(src)
                src = {src};
                dst = {dst};
            end
            dstVar = uint8(dstVar(:));
            
            s = struct();
            warning('off', 'MATLAB:table:RowsAddedExistingVars');
            for i = 1 : numel(src)
                s.dst_var = dstVar(i);
                obj.g = addedge(obj.g, src{i}, dst{i}, struct2table(s));
            end
            
            obj = ResetCache(obj);
        end


        function obj = RemoveNodes(obj, names)
            obj.g = rmnode(obj.g, names);
            
            obj = ResetCache(obj);
        end


        function obj = SetNodeOutput(obj, name, output)
            validateattributes(name, {'char'}, {'nonempty'});
            validateattributes(output, {'numeric'}, {});
            
            idx = findnode(obj.g, name);
            assert(idx ~= 0, 'node must contain an existing node name');
            
            assert(isnan(obj.g.Nodes.n_out(idx)) || obj.g.Nodes.n_out(idx) == size(output, 1));
            if ~isfield(obj.cache, 'node_output')
                obj.cache.node_output = cell(obj.n_nodes, 1); % so we can store data across calls to Execute
            end
            obj.cache.node_output{idx} = output;
        end
        function x = GetNodeOutput(obj, name)
            validateattributes(name, {'char'}, {'nonempty'});
            
            idx = findnode(obj.g, name);
            assert(idx ~= 0, 'node must contain an existing node name');
            
            x = {};
            if isfield(obj.cache, 'node_output')
                x = obj.cache.node_output{idx};
            end
        end
        function x = GetOutputD(obj)
            x = obj.g.Nodes.n_out;
            if isfield(obj.cache, 'node_output')
                for i = 1 : obj.n_nodes
                    if isnan(x(i))
                        x(i) = size(obj.cache.node_output{i}, 1);
                    end
                end
            end
        end


        function obj = ResetCache(obj)
            obj.cache = struct();
            obj.cache_ver = obj.cache_ver + 1;
        end


        function h = plot(obj)
            h = plot(obj.g);
            nodeLabel = obj.node_name;
            for i = 1 : obj.n_nodes
                if ~isundefined(obj.node_func(i))
                    nodeLabel{i} = [nodeLabel{i},'=',char(obj.node_func(i))];
                end
                if ~isempty(obj.node_data{i}) && isobject(obj.node_data{i})
                    nodeLabel{i} = [nodeLabel{i},'(',class(obj.node_data{i}),')'];
                end
            end
            set(h, 'NodeLabel', nodeLabel);
        end


        % gets
        function x = get.n_nodes(obj)
            x = obj.g.numnodes;
        end
        function x = get.n_edges(obj)
            x = obj.g.numedges;
        end
        function x = get.node_name(obj)
            x = {};
            if obj.g.numnodes > 0
                x = obj.g.Nodes.Name;
            end
        end
        function x = get.node_func(obj)
            x = {};
            if obj.g.numnodes > 0
                x = obj.g.Nodes.func;
            end
        end
        function x = get.node_data(obj)
            x = {};
            if obj.g.numnodes > 0
                x = obj.g.Nodes.data;
            end
        end
        function x = get.edge_endnode(obj)
            x = obj.g.Edges.EndNodes;
        end
        function x = get.edge_endnode_idx(obj)
            x = findnode(obj.g, obj.g.Edges.EndNodes);
        end
        function x = get.edge_dst_var(obj)
            x = {};
            if obj.g.numedges > 0
                x = obj.g.Edges.dst_var;
            end
        end
        function x = get.n_iter(obj)
            d = distances(obj.g);
            x = max(d(d~=Inf)); % determine max number of iterations needed (longest path in graph)
        end
    end
end