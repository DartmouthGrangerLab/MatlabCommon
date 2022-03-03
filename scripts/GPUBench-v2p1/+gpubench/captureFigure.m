function captureFigure( figh, filename, trim )
%captureFigure: use print to capture a figure with over-sampling
%
%   gpubench.captureFigure(figh,filename,trim)

%   Copyright 2011-2014 The MathWorks, Inc.

if nargin<3
    trim = true;
end

% Copy the position to the paper position to get the size right
pos = get( figh, 'Position' );
set( figh, 'PaperUnits', 'Points', 'PaperPosition', pos );

% Print directly at screen resolution
dpi = get(0,'ScreenPixelsPerInch');
print( figh, sprintf('-r%d',dpi), '-dpng', filename );

% Load and trim the top whitespace
gpubench.trimImage( filename, trim );
