%  Determine times of all detected syllable onsets and ends in a speech-acoustic signal in silence.
% 	[vsegs,vlms,lms,tvals,pcont,env,envv,vf,tvv] = ...
% 					= vowel_segs_full(SIGNAL,<Fs>,<MAX_F0>,<FIGNO>,<AGESZ>)
% 			-or-	= vowel_segs_full(SIGNAL,<Fs>,<MAX_F0>,<FIGNO>,<AGESZ>,LMS,TVALS, ...
% 										PCONT,ENV,ENVTHR)
% 	SIGNAL 	= speech signal to be processed;
% 	<Fs>	= sampling rate of SIGNAL [dflt = 16kHz].  Rates < 11kHz are likely to 
% 			produce unreliable results, unless the syllables have no strong bursts; 
% 			rates > 16kHz are unlikely to be better than 16kHz;
% 	<MAX_F0> = highest F0 [Hz] or [max.,min.] to be considered when determining voicing; 
% 			the default value is the default of 'landmarks' and of 'vowel_lms' 
% 			independently; note that these two defaults may not be equal;
% 	<FIGNO>	= figure number for plotting, or:
% 				0 for new figure;
% 				[] for no plotting;
% 			[dflt. = 0];
% 	<AGESZ>	= age or size code [case-insens.; dflt. = "adult"] to set spectral bands and to
% 			effect high-pass filtering with 'hpfilt_std'; see Note 9;
% 	LMS		= abrupt-consonantal landmark array, if known, as from 'landmarks'; see 'lms';
%    ENV		= amplitude-envelope of DIFF(SIGNAL), smoothed over intervals characteristic
% 			of speech (~ 50-100 msec), as from 'landmarks'; values within this distance
% 			of the ends of the signal are suspect (and are not plotted); length =
% 			length(FNSIGNAL) - 1; 
% 	ENVTHR	= threshold of ENV (if ENV is supplied), as from 'landmarks', to identify intervals 
% 			that are too quiet to be evaluated for voicing;
% 	TVALS	= times [seconds; COLUMN] at which PCONT is evaluated, as from 'landmarks';
% 	PCONT	= pitch track of SIGNAL, as from 'landmarks';
% 	vsegs	= 3xM array denoting vowel (syllabic) segments, for some M >= 0, consisting of:
% 				onset time [sec] -- the time of one of the landmarks in 'lms';
% 				cutoff time [sec] -- the time of another of the landmarks in 'lms';
% 				max( degree of "vowel-ness"), i.e., of approx. voiced fraction of energy
% 					(in 0-1) times low-freq. amplitude 'envv') over the segment; this
% 					will be negated if the interval not voiced long enough (~ 20-40 ms);
% 			see Notes;
% 	vlms	= 3xK array of vowel landmarks, for some K >= M, consisting of:
% 				time
% 				degree
% 				"strength" = +-degree*'envv'
% 			of the "most vocalic" instant(s) in SIGNAL; the "degree" is based on 
% 			the local strength of voicing only, and approx. represents the voiced 
% 			fraction of (local) energy; the TIME of the landmark represents a local
% 			max. of (the degree multiplied by 'envv'); the degree is negated if the vowel LM
% 			(VLM) is not voiced for long enough (typically 20-30 ms) or if it is not the 
% 			maximal-"strength" VLM of its vowel segment;
%    lms	=	3xN array of consonantal landmarks (LMs) (corresp. to +g/-g, +b/-b, +s/-s, 
%    		etc.), for some N >= 0; each LM is denoted by a time & type (index);
% 			the indices are as in 'lm_labels' and 'lm_codes'; see Notes;
% 	tvals	= times [seconds; COLUMN] at which pitch is evaluated (may exclude end, if
% 			SIGNAL is quiet at end); identical to TVALS, if TVALS is supplied;
% 	pcont	= pitch track of SIGNAL, as returned by 'pitch_utt' (may exclude end, if
% 			SIGNAL is quiet at end); identical to PCONT, if PCONT is supplied;
%    env     = amplitude-envelope of DIFF(SIGNAL), smoothed over intervals 
%            characteristic of speech (~ 50-100 msec); values within this distance
% 			of the ends of the signal are suspect; shape = same as SIGNAL, length =
% 			LENGTH(SIGNAL) - 1; identical to ENV, if ENV is supplied;
% 	envv	= ampl.-envelope of DIFF(low-pass version of SIGNAL), for low-pass ~ 2kHz
% 			to suppress frication noise (which can have high ampl. in 'env');
% 			size = SIZE(env);
% 	vf		= voiced fraction of signal's power at certain times (in the range [0-1]);
% 	tvv		= times [seconds; COLUMN] at which 'vf' is evaluated.
% 
%  Notes: 
%  1.If LMS is not specified (or []), this function constructs the abrupt or "consonant" 
% 	landmarks (LMs) as in 'landmarks'. It then constructs the vowel LMs as in 'vowel_lms' 
% 	(with multiplication by 'envv'), after suppressing low-amplitude parts of the signal, as 
% 	by 'deg_speech'.  The abrupt LMs will be identical to those of 'landmarks(SIGNAL, ...)',
% 	after possible filtering by 'lm_sylfilter' to remove the very least speech-like intervals.  
% 	Therefore, stored values of these LMs may be used whether produced by 'mat_vowel_segs' or 
% 	'mat_conslms'.  If the LMS arg. is not specified on input, then LMs in regions of very low 
% 	amplitude (envelope-based degree of speech) will not be used, per 'lm_sylfilter', although
% 	they will still be included in 'lms'.  However, if LMS is specified, no such filtering
% 	will be performed; also, 'lms' will just be a copy of LMS in this case.
%  2.If a vowel LM (VLM) precedes the first consonant LM, the VLM will be deleted.  If a VLM
% 	follows the last cons. LM, indicating that the utterance continues past
% 	the end of SIGNAL, then its ending time ('vsegs(2,end)') will be +Inf.
%  3.A "vocalic segment" (or syllabic segment) MUST follow a mouth-opening LM (per 
% 	'lm_features') or voicing onset ("+g") as its most recent prior LM.  It need NOT be
% 	voiced (by the criteria of 'landmarks' -- i.e., positive pitch period or voiced 
% 	fraction, etc.), although this is rare.  E.g., it might be whispered.  However, each
% 	segment is either voiced throughout or unvoiced throughout (possibly with very
% 	brief intervals of aggressively detected voicing).  The 'vsegs(3,:)' component
% 	is negated unless the segment is determined to be voiced throughout, regardless of 
% 	the sign of the corresponding 'vlms(3,:)'.
% 	Vowel segments only begin and end at LMs that are NOT periodicity events ("+-p"); they 
% 	will only have the same time as some periodicity LM if that LM occurs at the same 
% 	time as a non-periodicity LM (normally a corresponding +-g).
%  4.'vsegs(3,:)' will also be negated if a "vocalic segment" is too brief for normal 
% 	adult speech.  The duration threshold is implementation-dependent (~20-30 msec).
% 	Many of these and other problematic VLMs and segments are deleted as "non-standard"
% 	by 'vowel_segs_std'.
%  5.Apart from such negation, for any "m", the strength 'vsegs(3,"m")' is always the
% 	strength of some element "k" of 'vlms(3,:)'.  That is,
% 		vsegs(3,m) = vlms(3,k) (or -vlms(3,k) if negated).
% 	'vsegs(1:2,"m")' are times bracketing 'vlms(1,"k")', the instant of the VLM.
% 	In general, there are more VLMs than segments.  The 'vlms' entries may 
% 	be considered as candidates for marking the vocalic segments.  Notice that this
% 	means that multiple segments can share beginning and/or ending points (but not
% 	both).  This is especially common if diphthongs and schwa releases are not marked by 
% 	abrupt LMs (+s or -v, typically): They may be found as additional VLMs that share
% 	initial or final abrupt LMs (and thus segments) with the primary vowel.
%  6.If SIGNAL is entirely quiet (according to 'deg_speechenv' or similar function), then 
% 	'vsegs' will be NaN and all other output arguments will be [].
%  7.The function 'mat_vowel_segs' can preserve the results of this function, saving 
% 	substantial time in recomputation.
%  8.SIGNAL is assumed to be a segment of a longer signal from the same source, which 
% 	is assumed to be SILENT in immediately adjacent short segments.  
% 	In speech, this would be typical of a complete utterance with some silence included
% 	near the ends of SIGNAL.  (Such presumed silence, wherever it occurs, is used to 
% 	estimate the noise level of SIGNAL.) 
% 	If SIGNAL is NOT expected to be such a segment, it may be more appropriate to 
% 	use 'vowel_segs_nsil', which assumes that the source continues in adjacent segments, 
% 	or at least that it almost completely occupies the SIGNAL interval.  In speech, this 
% 	would be typical of words or smaller segments within an utterance, or a sustained 
% 	vowel with no significant intervals of silence at the ends.
%  9.If MAX_F0 is empty, it will be determined by 'maxf0_std' from AGESZ according to 
% 	the rules:
% 		a. If AGESZ = "adult", then MAX_F0 = 'maxf0_std("n")'	-- i.e., adult, unspecified sex.
% 		b. Else if AGESZ = "child", MAX_F0 = 'maxf0_std("i")'	-- i.e., infant.
% 		c. Else MAX_F0 = 'maxf0_std("")'.
% 	However, the converse does NOT hold: If AGESZ is absent or "", it will be interpreted as
% 	"adult", regardless of any value of MAX_F0.  If MAX_F0 and AGESZ are incompatible, NO
% 	message will be provided.  (Thus, e.g., males singing falsetto can be processed with no
% 	warning by a suitable, though atypical, combination of MAX_F0 and AGESZ.)
% 	The value of AGESZ must be recognized by 'hpfilt_std' in all cases.
%  10.After calling this function, it may be helpful to remove "non-standard" vowel segments 
% 	as by 'vseg_ndxs_std'.
%  11.It can be useful to provide LMS if known, both because this avoids recomputing them and
% 	because the caller may wish to filter them in some non-standard way (for example, no 
% 	filtering by 'lm_sylfilter' at all).
%  12.The function 'vowel_segs_std' provides similar functionality to this one, but 'lms'
% 	as returned by that function excludes any LMs that are removed by 'lm_sylfilter', and 
% 	'vsegs' as returned by that function excludes "non-standard" segments.
%  13.Providing LMS as input can save a large part of the computation time; however, this 
% 	is only allowed if TVALS, PCONT, ENV and ENVTHR are also supplied.
% 
%  See also: landmarks, vowel_lms, lm_labels, deg_speechenv, mat_vowel_segs, vowel_segs_nsil, 
% 		deg_voiced, vseg_ndxs_std, lm_sylfilter, vowel_segs_std, hpfilt_std.
%
