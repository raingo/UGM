clear all
close all
load rain.mat

n = 100

proportion_visible = 0.95

X = X(1:100, :);
months = months(1:100, :);

% Make rain labels y, and binary month features X
y = int32(X+1);
invisible_nodes = rand(size(y)) > proportion_visible;
y(invisible_nodes, :) = 0;
[nInstances,nNodes] = size(y);

%% Make edgeStruct
nStates = max(y);
adj = zeros(nNodes);
for i = 1:nNodes-1
    adj(i,i+1) = 1;
end
adj = adj+adj';
edgeStruct = UGM_makeEdgeStruct(adj,nStates);
nEdges = edgeStruct.nEdges;
maxState = max(nStates);

%% Training (no features)

% Make simple bias features
Xnode = ones(nInstances,1,nNodes);
Xedge = ones(nInstances,1,nEdges);

% Make nodeMap
nodeMap = zeros(nNodes,maxState,'int32');
nodeMap(:,1) = 1;

edgeMap = zeros(maxState,maxState,nEdges,'int32');
edgeMap(1,1,:) = 2;
edgeMap(2,1,:) = 3;
edgeMap(1,2,:) = 4;

% Initialize weights
nParams = max([nodeMap(:);edgeMap(:)]);
w = zeros(nParams,1);

disp("Optimize (mex)")
edgeStruct.useMex = 1;
w_mex = minFunc(@UGM_CRF_NLL_Hidden,w,[],Xnode,Xedge,y,nodeMap,edgeMap,edgeStruct,@UGM_Infer_Chain)


disp("Optimize (no mex)")
edgeStruct.useMex = 0;
w_nomex = minFunc(@UGM_CRF_NLL_Hidden,w,[],Xnode,Xedge,y,nodeMap,edgeMap,edgeStruct,@UGM_Infer_Chain)
