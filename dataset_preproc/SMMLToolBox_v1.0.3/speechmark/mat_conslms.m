%  Landmarks of a speech-acoustic signal, as from 'landmarks'; use LM or MAT file if present.
% 	[lmArray,tvals,pcont,env,envthr,voicg,vthr] = ...
% 			mat_conslms(FNAME|SIGNAL,<Fs>,<MAX_F0>,<MATFN>,<KEEP>)
% 	FNAME|SIGNAL  = speech acoustic signal to be processed;
% 			OR
% 			filename of same, to be read by 'wavread_freq' (at frequency Fs);
% 	<Fs>	= sampling rate of FNSIGNAL [dflt = 16kHz].  Rates < 12kHz are likely to 
% 			produce unreliable results, unless the syllables have no strong bursts; 
% 			rates > 16kHz are unlikely to be better than 16kHz;
% 	<MAX_F0> = highest F0 to be considered when determining voicing; the default is that of 
% 			'maxf0_std';
% 	<MATFN>	= path & filename (to be combined using 'mat_vs_fileid' with FNAME, if 
% 			specified) for ".lm" file that will be read if present, or MAT file (extension
% 			".lmmat") that will be created if absent, or read if present; if the first
% 			argument is SIGNAL, use no arg. or "" [default] to suppress all use of any MAT
% 			file, regardless of KEEP; see Notes;
% 	<KEEP>	= the (case-insens.) string;
% 			"keep" to use a LM or MAT file if possible but NOT to create a new one, and to use 
% 				the signal/wave file if needed instead;
% 			"new" to create a new MAT file if possible from the signal/wave file, whether or not
% 				one already exists;
% 			"none" to ignore LM and MAT files, simply using 'lmadult' with the signal/wave 
% 				file directly;
% 			"use" to use a LM or MAT file if possible and to make a new MAT file from the
% 				signal/wave file if not;
% 			"use0" to use a LM or MAT file if possible; otherwise, to return [] for all 
% 				output arg's. and NOT to make a new MAT (or LM) file;
% 			"load" to use a LM file if possible [see Note #1], or to 
% 				use a MAT file if not, but ONLY if the MAT file was made with the same
% 				Fs and MAXF0; otherwise, to return [] for all output arg's. and NOT to 
% 				make a new MAT (or LM) file;
% 			"same" or "" [the default] to use a LM file if possible [see Note #1], or to 
% 				use a MAT file if not, but ONLY if the MAT file was made with the 
% 				same values of Fs and MAXF0 as presently, and to make a new one if not;
%    lmArray	= 2xN or 3xN array of consonantal landmarks (corresp. to +g/-g, +b/-b, +s/-s, etc.),
%    		for some N >= 0; each landmark (LM) is denoted by a time [SECS] & type
%    		(index), at least; the indexes are as in 'lm_labels';
% 	tvals	= times at which pitch is evaluated.
% 	pcont	= pitch track of 'signal', as returned by 'pitch_utt';
%    env		= amplitude-envelope of DIFF(SIGNAL), smoothed over intervals 
%            characteristic of speech (~ 50-100 msec); values within this distance
% 			of the ends of the signal are suspect (and are not plotted); length =
% 			length(FNSIGNAL) - 1; this array is NOT saved unless NARGOUT > 3 (due to 
% 			its length);
% 	envthr	= threshold of 'env' to identify intervals that are too quiet to be
% 			evaluated for voicing;
% 	voicg	= degree (0-1) of voicing (at times in 'tvals'), as from 'lmstreamSig';
% 	vthr	= threshold on 'voicg' (and 'pcont') for detection of voicing.
% 
%  Notes: 
%  1.If an LM file exists, 
% 		and either FNAME or (non-empty) MATFN is specified,
% 		and KEEP = "keep" or "use" or "same" or "load", 
% 		and only 'lmArray' is to be returned, 
% 		and the LM file can be read successfully by 'read_lms', 
% 	then the LM file will be used, whether or not a MAT file also exists.  In all other 
% 	cases, MAT-file processing will proceed as usual.
%  2.This function uses 'landmarks', unless:
% 		the LM file exists and is to be used (per Note #1), OR
% 		(otherwise) the MAT file already exists AND contains all of the specified output 
% 		variables.  To suppress checking Fs, specify 0 or NaN; to suppress checking MAX_F0,
% 		specify NaN.
% 	If some of the output variables of 'landmarks' are not needed by the caller of this
% 	function, they need not be present in the MAT file.  If KEEP="load" or "use0", then
% 	SIGNAL may be specified as [], or the .wav file named FNAME need not exist.
%  3.It is NOT an error if an output MAT file cannot be created.  However, if KEEP specifies 
% 	that one should be created, a warning will be produced in this case, using 'warnmsg'.
%  4.The name of the MAT file that is produced or used is given by 
% 	'mat_vs_fileid(FNAME,MATFN)' (or 'mat_vs_fileid([],MATFN)' if SIGNAL is given).  The
% 	name of the LM file that is used is identical, except that ".lm" replaces the 
% 	extension of the MAT file.  This holds even if the file does not exist (if KEEP="load"
% 	or "use0").  Note that this file is NOT used unless FNAME is specified, or MATFN is
% 	non-empty, or both.
%  5.If different values of MAX_F0 and Fs are present in the MAT file than in the argument
% 	list (explicitly or by default), and KEEP = "use" or "same", 'warnmsg' will give a
% 	warning.
%  6.If using the FNAME form, you may specify Fs = 0.  In this case, Fs will be set to the
% 	rate that was used in the file.
%  7.An ".lm" file can be created using 'write_lms'.  To create one with the name that this
% 	function would expect to find on a later call, use:
% 		lmArray = mat_conslms(FNAME,Fs,MAX_F0,MATFN,'none');
% 		status = write_lms(FNAME,lmArray,cmt); 
% 	This assumes that the first argument is a file name (FNAME).  A typical comment might be:
% 		cmt = sprintf('Created with mat_conslms: rate = %g, Max F0 = %g',Fs,MAX_F0);
%  8.If FNAME is specified, and the file is stereo, only the FIRST channel will be processed.
% 	If SIGNAL is given instead, it must be a vector (either row or column).
%  9.When creating a MAT file, this function includes an indicator of the signal.  The
% 	indicator will almost always be different for different signals (as with a checksum),
% 	but this is not guaranteed.  The indicator is checked when using "SAME" or "LOAD".
% 	Determining this indicator requires reading the whole signal file.  This can be
% 	extremely slow if the file is large and available only over a slow link; it can also
% 	be memory-intensive if the file is large.  Reading the signal file is otherwise
% 	unnecessary if the MAT (or LM) file can be guaranteed to have been produced from the
% 	signal.  Thus, "USE" and "USE0" can be much faster than "SAME" and "LOAD"
% 	(respectively), IF this can be guaranteed.
% 
%  See also: landmarks, abrupt_lms, mat_vs_fileid, wavread_freq, read_lms, mat_streamlms, 
% 		write_lms.
%
