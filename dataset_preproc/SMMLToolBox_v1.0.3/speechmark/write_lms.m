%  Write array of landmark times & types in text file, standard format, with optional comment.
%  The resulting file will be compatible with 'read_lms'; in particular, text labels in the
% 	file will be those from 'lm_labels'.
% 
%  FILENAME is the name of the path and base name to be used for the ".lm" file; typically,
% 	this is the name of a waveform file that was analyzed to produce the landmarks; this
% 	name will be written into the file; see the Example.  Note that it is NOT (quite) the
% 	name of the output file.
%  LMARR is the 2xN or 3xN landmark array to be written, as from 'lmadult': [times; types;
% 	<strength>]. 
%  COMMENT is any comment that may be meaningful later.  To create a multi-line comment,
% 	embed newlines (^j's, or numeric 10's).  The default is a single blank character.  DO
% 	NOT include a "#" on a line by itself (i.e., surrounded by newlines).
% 
%  Notes:
%  1.It is often helpful, especially after real-time or stream processing, to discard any
% 	landmarks within the first ~ 1 msec.  This operation is not performed by this
% 	function, however.
%  2.It is often helpful for the caller to provide its own name in COMMENT.  This may be
% 	specified by a literal or by using the MFILENAME function.
% 
%  Example:
% 	status = write_lms('abc\def.wav',lms, ['Comment Line 1' 10 'Comment Line 2'])
%  will write the array 'lms' into the text file "abc\def.lm".  That file will contain a 
%  header mentioning "abc\def.wav" as the (presumed) source file.
% 
%    def.lm :
%            #def 01-Jan-2000
%            #Comment Line 1
%            #Comment Line 2
%            #
%             0.100 -g
%             0.200 +g
%             0.300 -b
%            ...
%  
%  See also: lmadult, read_lms, lm_labels, MFILENAME.
%
