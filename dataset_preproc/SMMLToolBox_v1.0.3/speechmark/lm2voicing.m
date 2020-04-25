function vcg = lm2voicing(LMARRAY,TMS)
% Time-indexed array of voicing (true|false) according to a landmark array.
% Syntax: 
%	vcg	= lm2voicing(LMARRAY,TMS),
% where:
%   LMARRAY	= 2xN (or taller) array of landmarks, for some N >= 0; each landmark is denoted by a 
%			time & type (code, as in 'landmarks');
%	TMS		= times at which to evaluate 'vcg';
%	vcg		= voicing state (according to voicing transitions) at each time in TMS.
%
% Notes: 
% 1.LMARRAY must be a valid sequence of LMs (avoiding, e.g., consecutive +g's).
% 2.LMARRAY must not be empty.
%
% See also: lmadult.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2007-2013, Speech Technology & Applied Research Corp. (unpublished)
%
%	JM	07/11/7	Small change to doc. (ONLY).
%	JM	08/9/17	Fix defect: shape (SIZE) of TMS.
%		08/10/2	Recurse for very long arrays (as from streaming).
%	JM	10/9/23	Fix defect for case that LMARRAY starts with voiced LM (but NOT +g).
%	JM	12/5/23	Small changes to doc. (ONLY).
%	JM	13/12/9	Small changes to doc. (ONLY).

% Codes for the simple landmark types:
persistent PLUS_G MINUS_G MLIM	% 08/10/2: Added MLIM.
if isempty(MINUS_G), 
    [MINUS_G PLUS_G] = ...
        lm_codes('MINUS_G','PLUS_G');
	% The criterion for recursion (assuming DOUBLE, the usual case):
	MLIM = memlimit / typebytes(pi);	% 08/10/2: Added.
end

if nargin==1 && isequal(LMARRAY,'?'),
    fprintf('%s\n', 'vcg_K = lm2voicing(LMARRAY2xN,TIMES_K)')
    return
end

% 10/9/23: Fix defect for case of voiced LM (but NOT +g) at start of LMARRAY:
if LMARRAY(2,1) ~= PLUS_G && ismember(LMARRAY(2,1),lm_features('voiced'))
	LMARRAY(:,1);	% [Time; type; maybe other components].
		ans(1) = -Inf;
		ans(2) = PLUS_G;	% Fake +g LM before rest of LMs.
		% >> SIZE(ans) = [SIZE(LMARRAY,1), 1]. <<
		vcg = lm2voicing([ans, LMARRAY],TMS);
	return
end

% Indices (into LMARRAY) of voicing transitions:
ndxv = find(LMARRAY(2,:)==PLUS_G | LMARRAY(2,:)==MINUS_G);	% [Row]

tvx = LMARRAY(1,ndxv);	% [Row] TIMES of the v. transitions.
% 08/9/17: Fix defect: Was: repmat(tvx(:),size(TMS)) <= repmat(TMS,size(tvx(:)));	% Each row ~ (times >= +-g).
% 08/10/2: Added IF and first block for recursion:
if numel(tvx)*numel(TMS) > MLIM && ...	% Need to split & recurse?
	numel(tvx) > 1 && numel(TMS) > 1	% (No hope if already scalars!)
	% Recurse, using only +-g's in LMARRAY and bisecting TMS.  
	%	Note that we do NOT bisect LMARRAY(:,ndxv), because of the possible complication
	%	of handling segments that START with -g.
	tims = TMS(:)';	% [Row]
	lm2voicing(LMARRAY(:,ndxv),tims(1:floor(end/2)));	% [Row] 1st half (or just < 1/2).
		% >> LENGTH(ans) = LENGTH(TMS(1:FLOOR(END/2))) = FLOOR(END/2). <<
		[ans, lm2voicing(LMARRAY(:,ndxv),tims(1+floor(end/2):end))];	% [Row] Rest of TMS.
		% >> SIZE(ans) = [1, LENGTH(TMS)]. <<
else
	repmat(tvx(:),size(TMS(:)')) <= repmat(TMS(:)',size(tvx(:)));	% Each row ~ (times >= +-g).
		% >> SIZE(ans) = [LENGTH(tvx), LENGTH(TMS)]. <<
		sum(ans,1);	% [Row] NUMBER of 'ans' rows with (times >= +-g): Even # iff completed pairs.
		% >> SIZE(ans) = [1, LENGTH(TMS)]. <<
end
	% >> (Both paths:) SIZE(ans) = [1, LENGTH(TMS)]. <<
	vcg = (rem(ans,2)~=0);	% [Row] 0 iff completed pairs (presumably unvoiced again).
if ~isempty(ndxv) && LMARRAY(2,ndxv(1))==MINUS_G, vcg = ~vcg; end	% Non-typical.
