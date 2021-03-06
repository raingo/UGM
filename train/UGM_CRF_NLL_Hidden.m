function [global_NLL,global_g] = UGM_CRF_NLL_Hidden(w,Xnode,Xedge,Y,nodeMap,edgeMap,edgeStruct,inferFunc,varargin)
  % UGM_CRF_NLL(w,Xnode,Xedge,Y,nodeMap,edgeMap,edgeStruct,inferFunc,varargin)

  [nNodes,maxState] = size(nodeMap);
  nNodeFeatures = size(Xnode,2);
  nEdgeFeatures = size(Xedge,2);
  nEdges = edgeStruct.nEdges;
  edgeEnds = edgeStruct.edgeEnds;
  nStates = edgeStruct.nStates;

  nInstances = size(Y,1);
  global_NLL = 0;
  global_g = zeros(size(w));

  my_varargin = varargin;
  my_nargout = nargout;

  parfor i = 1:nInstances
    NLL = 0;
    g = zeros(size(w));

    % Make potentials
    if edgeStruct.useMex
      [nodePot,edgePot] = UGM_CRF_makePotentialsC(w,Xnode,Xedge,nodeMap,edgeMap,nStates,edgeEnds,int32(i));
    else
      [nodePot,edgePot] = UGM_CRF_makePotentials(w,Xnode,Xedge,nodeMap,edgeMap,edgeStruct,i);
    end

    % Compute marginals and logZ
    [nodeBel,edgeBel,logZ] = inferFunc(nodePot,edgePot,edgeStruct,my_varargin{:});

    if any(Y(i,:)==0)
      % This is an update where we sum over all possible values of missing variables

      % Compute conditional marginals and logZ
      [nodeBelC,edgeBelC,logZC] = UGM_Infer_Conditional(nodePot,edgePot,edgeStruct,Y(i,:),inferFunc,my_varargin{:});

      % Now add back the terms that disappeared when we formed the
      % conditional UGM
      for n = 1:nNodes
        if Y(i,n)~=0
          logZC = logZC + log(nodePot(n,Y(i,n)));
        end
      end
      for e = 1:nEdges
        n1 = edgeEnds(e,1);
        n2 = edgeEnds(e,2);
        if Y(i,n1)~=0 && Y(i,n2)~=0
          logZC = logZC + log(edgePot(Y(i,n1),Y(i,n2),e));
        end
      end

      % Update NLL
      NLL = NLL - logZC + logZ;

      % Update gradient
      if edgeStruct.useMex
        % updates in place
        UGM_CRF_NLL_HiddenC(g,int32(i),nodeBel,edgeBel,edgeEnds,nStates,nodeMap,edgeMap,Xnode,Xedge,Y,nodeBelC,edgeBelC);
      else
        if my_nargout > 1
          for n = 1:nNodes
            for s = 1:nStates(n)
              for f = 1:nNodeFeatures
                if nodeMap(n,s,f) > 0
                  if Y(i,n) == 0
                    obs = nodeBelC(n,s);
                  elseif s == Y(i,n)
                    obs = 1;
                  else
                    obs = 0;
                  end
                  g(nodeMap(n,s,f)) = g(nodeMap(n,s,f)) + Xnode(i,f,n)*(nodeBel(n,s) - obs);
                end
              end
            end
          end
          for e = 1:nEdges
            n1 = edgeEnds(e,1);
            n2 = edgeEnds(e,2);
            for s1 = 1:nStates(n1)
              for s2 = 1:nStates(n2)
                for f = 1:nEdgeFeatures
                  if edgeMap(s1,s2,e,f) > 0
                    if Y(i,n1) == 0 && Y(i,n2) == 0
                      obs = edgeBelC(s1,s2,e);
                    elseif Y(i,n1) == 0 && Y(i,n2) == s2
                      obs = edgeBelC(s1,Y(i,n2),e);
                    elseif Y(i,n1) == s1 && Y(i,n2) == 0
                      obs = edgeBelC(Y(i,n1),s2,e);
                    elseif s1 == Y(i,n1) && s2 == Y(i,n2)
                      obs = 1;
                    else
                      obs = 0;
                    end
                    g(edgeMap(s1,s2,e,f)) = g(edgeMap(s1,s2,e,f)) + Xedge(i,f,e)*(edgeBel(s1,s2,e) - obs);
                  end
                end
              end
            end
          end
        end
      end

    else
      % This is just the usual update, copied and pasted from UGM_CRF_NLL

      % Update NLL
      if edgeStruct.useMex
        NLL = NLL - UGM_LogConfigurationPotentialC(Y(i,:),nodePot,edgePot,edgeEnds) + logZ;

        % Updates in-place
        UGM_CRF_NLLC(g,int32(i),nodeBel,edgeBel,edgeEnds,nStates,nodeMap,edgeMap,Xnode,Xedge,Y);
      else
        NLL = NLL - UGM_LogConfigurationPotential(Y(i,:),nodePot,edgePot,edgeEnds) + logZ;

        if my_nargout > 1
          for n = 1:nNodes
            for s = 1:nStates(n)
              for f = 1:nNodeFeatures
                if nodeMap(n,s,f) > 0
                  if s == Y(i,n)
                    obs = 1;
                  else
                    obs = 0;
                  end
                  g(nodeMap(n,s,f)) = g(nodeMap(n,s,f)) + Xnode(i,f,n)*(nodeBel(n,s) - obs);
                end
              end
            end
          end
          for e = 1:nEdges
            n1 = edgeEnds(e,1);
            n2 = edgeEnds(e,2);
            for s1 = 1:nStates(n1)
              for s2 = 1:nStates(n2)
                for f = 1:nEdgeFeatures
                  if edgeMap(s1,s2,e,f) > 0
                    if s1 == Y(i,n1) && s2 == Y(i,n2)
                      obs = 1;
                    else
                      obs = 0;
                    end
                    g(edgeMap(s1,s2,e,f)) = g(edgeMap(s1,s2,e,f)) + Xedge(i,f,e)*(edgeBel(s1,s2,e) - obs);
                  end
                end
              end
            end
          end
        end
      end
    end
    global_NLL = global_NLL + NLL;
    global_g = global_g + g;
  end
  global_NLL = global_NLL / nInstances;
  global_g = global_g / nInstances;
