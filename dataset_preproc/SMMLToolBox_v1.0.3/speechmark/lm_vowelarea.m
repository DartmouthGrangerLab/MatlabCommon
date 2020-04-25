%  Area in vowel (F1-F2) space in all vowels in given vowel-segment array, ".mat" file, or list of same.
%  Syntax:	[arC,fts,vsegndxs]	= lm_vowelarea(VSEGSSIG|SIG_FNAME|MAT_FNAME,<MAX_F0>,<FIGNO>,<"lin"|LOGLIN|"log">)
% 			[arC_K,fts_K,vsegndxs] = lm_vowelarea({VSEGSSIG|SIG_FNAME|MAT_FNAME}_K,<{MAX_F0_K}>,<FIGNO>, ...
% 													<"lin"|LOGLIN|"log">)
% 			[arC_K,fts_K,vsegndxs] = lm_vowelarea({{VSEGSSIG|SIG_FNAME|MAT_FNAME}_Nj}_K,<{MAX_F0_K}>,<FIGNO>, ...
% 													<"lin"|LOGLIN|"log">)
%  where:
% 	VSEGSSIG = structure of:
% 				.vsegs	= vowel-segments (i.e., [starts; ends; ...]) array, 
% 				.signal	= underlying waveform;
% 				.rate	= sampling rate;
% 			or cell array (of "K" elements) of same;
% 			or a cell array (of "K" elements) OF cell arrays (of any lengths) of the same: see Notes;
% 	*_FNAME = filename from which to read the vowel-segments array (with 'mat_vowel_segs'); 
% 				specify any other extension (such as ".wav") to use EITHER ".mat" file or the 
% 				original signal file, according to 'mat_vowel_segs'; 
% 			or cell array (of "K" elements) of such names; 
% 			or a cell array (of "K" elements) OF inner cell arrays (of any lengths) of the 
% 				same: see Notes;
% 	<MAX_F0> = highest F0 to be considered when determining voicing in each vowel segment
% 				[dflt. = value used in MAT file, if any; else 'maxf0_std("n")'] in each file or 
%                outer cell array;
% 			or a cell array (NOT a numeric array) of same for each input separately (i.e., of "K"
% 				elements);
% 	<FIGNO>	= figure number for plotting, or:
% 				0 for new figure (for every cell in the first arg., if a cell array);
% 				[] for no plotting;
% 			[dflt. = []];
% 	<LOGLIN> = "lin" [default] to use linear formant-space units [Hz^2] or "log" for Log2 units
% 			[octave^2]; case-insensitive; see Notes;
% 	arC		= area in vowel space covered by all vowels in signal [Hz^2 or octave^2]; if the 
% 			input is a cell array, then 'arC' will be a numeric array of the same size; COMPLEX:
% 				Real part = area of convex hull ("rubber-band" area);
% 				Imag part = area of std.-dev. ellipse (which is always <= hull area);
% 	fts		= "vowel space" of the whole signal or list of signals: 3xK numeric array of 
% 			[F1;F2;F3] for the first 3 formants of all vowels in the signal [Hz]; negated if 
% 			frequencies of a segment are acceptable but bandwidths are not;
% 			if the first arg. is a cell array, then this will be a cell array of each file's 
% 				list of formants;
% 			if the input is a cell array (of "K" elements) OF inner cell arrays (of any size), 
% 				then this will be a cell array of the collective vowels of each inner array 
% 				(concatenation of formant arrays for each signal of the inner array): see Notes.
% 	vsegndxs = indexes into vowel segments array for corresponding formants.  Useful when 
% 			formants are undefined for some vowel-segments, but correspondence needed 
% 			between vsegs and formants.
% 
%  Notes:
%  1.Linear vowel-space units [Hz^2] are conventional.  However, Sapir, et al. [2010]
% 	demonstrate that hypokinetic dysarthria (articulatory undershoot in Parkinson's Disease) is
% 	better measured in log units, in the sense that inter-speaker and inter-gender variation is
% 	substantially lower (dysarthria-related effect size is larger) than with linear units.  Note
% 	that this is essentially equivalent to measuring the formant ranges in octaves (frequency 
% 	ratios) instead of freq. differences.  [Sapir, Ramig, Spielman, and Fox, 2010: JSLHR 
% 	vol. 53, 114-125.]
%  2.If Any of the inputs is a cell array, then the first input must also be a cell array.  In
% 	this case, the shape of the output arrays will be the same as that of the first input:
% 		SIZE(arC) = SIZE(fts) = SIZE(*_FNAME), or SIZE(arC) = SIZE(fts) = SIZE(VSEGSTRUCT).
% 	(Note that this identity does not hold if the first input arg. is NOT a cell array.)
%  3.For cell arrays, this function processes each array element independently, returning the
% 	results for each array element separately.  See Example 2.  However, for cell arrays OF inner 
% 	cell arrays, the inner cell arrays are handled as 'lm_vowelspace' does: as the UNION of the 
% 	vowels' formants across all the signals specified by the inner arrays.  See Example 3.
%  4.If the first arg. is a cell array of "K" elements and MAX_F0 is a NON-cell array with "K" 
% 	elements, and K > 2, this function will issue an error/warning (through 'warnerr').
%  
%  Examples:
%  1.>> lm_vowelarea('abc.mat', 350,0,'log')
% 	plots the vowel space (in octave units) in a new figure, and returns the vowel area 'arC' (also
% 	in octave units) corresponding to the vowels in the file 'abc.mat', for both the convex hull
% 	(Real part) and std.dev. ellipse (Imag part).
%  2.>> lm_vowelarea({'abc.mat', 'def.mat'}, 350)
% 	returns 'arC(1:2)', a 2-element Complex row-vector for the areas of 'abc.mat' and 'def.mat',
% 	respectively.  It is a row-vector because the first input arg. is a row-vector: SIZE(arC) =
% 	SIZE({'abc.mat', 'def.mat'}).  Since the 2nd arg. is a scalar, it will be used for both files.
% 	No data will be plotted, and the areas will be in linear units: Hz^2.
%  3.>> lm_vowelarea({{'abc.mat','def.mat'}}, 350)
% 	returns 'arC', a Complex scalar (the hull & SD areas) for the UNION of the vowels in 'abc.mat'
% 	and 'def.mat'.  Note that MAX_F0 (350) must be the same for both files.
%  4.>> lm_vowelarea({{'abc1.mat', 'abc2.mat'}, {'def1.mat', 'def2.mat', 'def3.mat'}}, {350,220})
% 	returns 'arC(1:2)', a TWO-element Complex vector of areas:
% 	'arC(1)' contains the hull & SD areas for the union of the vowels in 'abc1.mat' and 'abc2.mat',
% 		using MAX_F0 = 350;
% 	'arC(2)' contains the hull and SD areas for the union of the vowels in 'def1/def2/def3.mat'.
% 		using MAX_F0 = 220. 
% 
%  See also: mat_vowel_segs, maxf0_std, lm_vowelspace, warnerr.
%
