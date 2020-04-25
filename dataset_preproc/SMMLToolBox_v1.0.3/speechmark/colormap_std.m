function colormap_std(M,BRT)
% "Standard" colormap, a variant of JET, with optional compensation for brightness.
%   colormap_std with no arg., or with [], has the same length as the 
%	current colormap; specify the length as an explicit argument to 
%	use a non-default value.
% Specify a 2nd arg. [dflt. = ""] as:
% a."Brt" (case-insensitive) to compensate partially 
%	for the greater intensity (lightness) of yellow, an intermediate hue, than of 
%	red, the final hue.  The result makes later colors somewhat lighter than earlier 
%	ones, but keeps the colors represented in the colormap nearly saturated and 
%	differing most strongly in hue. 
% b."LogBrt" (case-insensitive) to perform the same compensation and simultaneously
%	provide a map that differs most strongly in hue and approximately logarithmically
%	in intensity.  See Note.
%
% Note: More accurately, the intensity variation for "LogBrt" is approximately ASINH of
%	10*I, where I is the intensity of the "Brt" colormap.
%
%   See also JET, COLORMAP, colorbar1, ColorSpiral.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2003-2014, Speech Technology & Applied Research Corp, (unpublished)
%
%	03/12/14 JM "?" processing added.
%	JM	06/2/26	Comment (ONLY) changed.
%	JM	08/4/11	'BRT' arg. added.
%	JM	09/4/21	Comment added (ONLY).
%	JM	13/9/25	Support "LogBrt".
%	JM	14/7/13	Small change to "?" msg (ONLY).

if nargin==1 && all(size(M)==1) && M=='?',
    fprintf('%s\n','colormap_std(<M>,<""|"BRT"|"LOGBRT">)')
    return
end

if nargin < 1, M = []; end
if nargin < 2, BRT = ''; end	% 08/4/11: Added.
if isempty(M), M = size(get(gcf,'colormap'),1); end
colormap([0 0 0;index(jet(round(M*64/55)-1),1:M-1,[])])
	% >> SIZE(COLORMAP()) = [M,3]. <<
% 08/4/11: Block added for BRT.	++ 09/4/21: Rotate color space so yellow = brightest?
if ~isempty(BRT) && (strcmpi('brt',BRT) || strcmpi('logbrt',BRT))
	sum(colormap,2);	% >>  SIZE(ans) = [M,1]. <<
		ans(2:end);	% Skip 0's before dividing.
		cbrt((2:M)/M)' ./ ans;	% CBRT(2:M) ad hoc (but more than adequate, visually). 
		[0; ans];
		colormap .* repmat(ans,[1 3]); % >> SIZE(ans) = [M,3]. <<
		% 13/9/14: Was: colormap(ans/max(ans(:)))	% /MAX() to make it as bright (light) as possible at end.
		ans/max(ans(:));	% /MAX() to make it as bright (light) as possible at end.
		if strcmpi('logbrt',BRT)	% Logarithmic (roughly)?
			rgb2hsv(ans);	% Transform intensity ("value") logarithmically; so extract intensity.
			ndxb = find( ans(:,1)==ans(2,1),1,'last');	% Index of last pure-blue entry.
			[[ans(1,1), ...	% Also tweak hue: Shrink pure-blue, widen rest.
				interp1(ans(ndxb:end,1),1:(length(ans)-ndxb)/length(ans):(length(ans)-ndxb))]', ...
			 ans(:,2), ...	% No change of sat.
			 asinh(10*ans(:,3))/asinh(10)];	% ASINH maps 0 -> 0, but is ~ log for arg. >> 1.
			hsv2rgb(ans);	% Back to RGB. % >> SIZE(ans) = [M,3]. <<
		end
		% >> (Both paths:) SIZE(ans) = [M,3]. <<
		colormap(ans)
end