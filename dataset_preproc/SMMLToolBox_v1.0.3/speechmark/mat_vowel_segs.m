%  Use 'vowel_segs_full' on a speech-acoustic signal; use MAT file if specified.
% 	[vsegs,vlms,lmArray,tvals,pcont,env,envv,vf,tvv] = ...
% 			mat_vowel_segs(FNAME|SIGNAL,<Fs>,<MAX_F0>,<FIGNO>,<MATFN>,<KEEP>)
% 	FNAME|SIGNAL  = speech acoustic signal to be processed;
% 			OR
% 			filename of same, to be read by 'wavread_freq' (at frequency Fs);
% 	<Fs>	= sampling rate [Hz] of FNSIGNAL [dflt = 16kHz].  Rates < 12kHz are likely to 
% 			produce unreliable results, unless the syllables have no strong bursts; 
% 			rates > 16kHz are unlikely to be better than 16kHz;
% 	<MAX_F0> = highest F0 [Hz] to be considered when determining voicing; the default is 
% 			that of 'vowel_segs_full';
% 	<FIGNO>	= figure number for plotting, or:
% 				0 for new figure;
% 				[] for no plotting (the default);
% 	<MATFN>	= path & filename (to be combined using 'mat_vs_fileid' with FNAME, if 
% 			specified) for ".mat" file that will be created if absent, or read if present; 
% 			if the first argument is SIGNAL, use no arg. or "" [default] to suppress all 
% 			use of any MAT file, regardless of KEEP; see Notes;
% 	<KEEP>	= the (case-insens.) string;
% 			"keep" to use a MAT file if possible but NOT to create a new one;
% 			"new" to create a new MAT file if possible, whether or not one already exists;
% 			"none" to ignore MAT files, simply using 'vowel_segs_full' directly;
% 			"use" to use one if present and to make a new one if not;
% 			"load" to use one if present, but ONLY if it was made with the same values of 
% 				Fs and MAXF0 and (probably) the signal; but if not, to return [] for 
% 				all output arg's. and NOT to make a new one;
% 			"same" or "" [the default] to use one if present ONLY if it was made with the 
% 				same values of Fs and MAXF0, and (probably) the signal; and to make 
% 				a new one if not;
% 		++	the "use0" keyword is not supported ++
% 	vsegs	= 3xM array denoting vowel segments, for some M >= 0, consisting of:
% 				onset time [sec];
% 				cutoff time [sec];
% 				+-max( degree of "vowel-ness"), i.e., of approx. voiced fraction of 
% 				energy (in 0-1) times low-freq. amplitude 'envv') over the segment; 
% 			see Notes.
% 	vlms	= 3xK array of vowel landmarks, for some K >= M, consisting of:
% 				time
% 				degree
% 				degree*'envv'
% 			of the "most vocalic" instant(s) in SIGNAL; the "degree" is based on 
% 			the local strength of voicing only, and approx. represents the voiced 
% 			fraction of (local) energy; the TIME of the landmark represents a local
% 			max. of (the degree multiplied by 'envv').
%    lmArray	= 2xN or 3xN array of consonantal landmarks (corresp. to +g/-g, +b/-b, +s/-s, etc.),
%    		for some N >= 0; each landmark is denoted by a time & type (index);
% 			the indices are as in 'lm_labels';
% 	tvals	= times [seconds; COLUMN] at which pitch is evaluated (may exclude end, if
% 			SIGNAL is quiet at end).
% 	pcont	= pitch track of SIGNAL, as returned by 'pitch_utt' (may exclude end, if
% 			SIGNAL is quiet at end);
%    env     = amplitude-envelope of DIFF(SIGNAL), smoothed over intervals 
%            characteristic of speech (~ 50-100 msec); values within this distance
% 			of the ends of the signal are suspect; shape = same as SIGNAL, length =
% 			length(SIGNAL) - 1; this array is NOT saved unless NARGOUT > 6 (due to its length);
% 	envv	= ampl.-envelope of DIFF(low-pass version of SIGNAL), for low-pass ~ 2kHz
% 			to suppress frication noise (which can have high ampl. in 'env');
% 			size = SIZE(env); this array is NOT saved unless NARGOUT > 6 (due to its length);
% 	vf		= voiced fraction of signal's power at certain times (in the range [0-1]);
% 	tvv		= times [seconds; COLUMN] at which 'vf' is evaluated.
% 
%  Notes: 
%  1.This function uses 'vowel_segs_full', unless the MAT file (with extension ".lmmat")
% 	already exists AND contains all of the specified output variables, and either FNAME is
% 	specified or MATFN is non-empty (or both).  If some of the output variables are not
% 	needed by the caller, they need not be present in the MAT file.
%  2.It is NOT an error if an output MAT file cannot be created.  However, a warning will be
% 	produced in this case, using 'warnmsg'.
%  3.The name of the MAT file that is produced or used is given by 
% 	'mat_vs_fileid(FNAME,MATFN)' (or 'mat_vs_fileid([],MATFN)' if SIGNAL is given).
% 	Notice that this is the same name that would be constructed for 'mat_vowel_segs_nsil',
% 	although the results will generally NOT be the same.  Ordinarily, only one OR the
% 	other of these two functions will be appropriate for any signal, so this will cause no
% 	problem.  However, you should NOT specify KEEP as "keep" or "use", unless you are sure
% 	that THIS function created the MAT file. (If you specify "same" or "load", information
% 	in the MAT file will show whether the other function produced it, so there is no
% 	danger of loading the wrong values.)
%  4.The plotting default is not necessarily the same as that of 'vowel_segs_full'.
%  5.If all specified output arg's. can be read from a MAT file, the figure may not have 
% 	the same details as that created by 'vowel_segs_full' (unless KEEP = "new" or "none").
%  6.If different values of MAX_F0 and Fs (and usually the signal) are present in the 
% 	MAT file than in the argument list, and KEEP = "use" or "same", 'warnmsg' will give a
% 	warning.
%  7.When creating a MAT file, this function includes an indicator of the signal.  The
% 	indicator will almost always be different for different signals (as with a checksum),
% 	but this is not guaranteed.
%  8.If FNAME is specified, and the file is stereo, only the FIRST channel will be processed.
% 	If SIGNAL is given instead, it must be a vector (either row or column).
% 
%  See also: vowel_segs_full, mat_vs_fileid, wavread_freq, lmadult, lm_labels, pitch_utt,
% 	warnmsg.
%
