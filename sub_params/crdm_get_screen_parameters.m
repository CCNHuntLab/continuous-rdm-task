function tconst = crdm_get_screen_parameters( screenWidth, distance2screen, debug )
%CRDM_GET_SCREEN_PARAMETERS This function calls PTB to determine the screen
%number, its flip interval, and the pixels per degree for a given screen
%setup. 
%   IN:     screenWidth     - scalar, in mm
%           distance2screen - scalar, in cm, how far does the participant
%                           sit from the screen
%           debug           - flag for screen setup, 0 is full screen, rest
%                           is debug setups (1: Windows small window, 2: MAC 
%                           full screen, 3: MAC small window)
%   OUT:    tconst          - struct with pointer to window (.winptr),
%                           window number (.win), coordinates (.rect),
%                           frame rate (.framerate), flip interval
%                           (.flipint), and constant to turn visual degrees
%                           into pixels (.pixperdeg)

%=== PTB SyncTests and Default Setup ========================================%

% 0 is preferred, but does not work on MAC. 
if debug == 2 || debug == 3
    Screen('Preference', 'SkipSyncTests', 1);
elseif debug == 0 || debug == 1
    Screen('Preference', 'SkipSyncTests', 0);
end 
PsychDefaultSetup(2);


%=== Identify the correct screen ===========================================%
screens = Screen('Screens');
tconst.winptr = max(screens);

%=== Open full screen window once ==========================================%
% Choose any colour here
grey = [0.5 0.5 0.5];
if debug == 1 % Windows debug window
    [tconst.win, tconst.rect] = ...
        PsychImaging('OpenWindow', tconst.winptr, grey, [0 0 1048 786]);
    tconst.framerate = ...
        Screen('FrameRate', tconst.win);
    
elseif debug == 2 % MAC full screen
    [tconst.win, tconst.rect] = ...
        PsychImaging('OpenWindow', tconst.winptr, grey);
    tconst.framerate = 60;
    % On MAC framerate sometimes cannot be determined but 60 Hz 
    % is a good approximation.

elseif debug == 3 % MAC debug window
    [tconst.win, tconst.rect] = ...
        PsychImaging('OpenWindow', tconst.winptr, grey, [0 0 1048 786]);
    tconst.framerate = 59;

else % Windows full screen
    [tconst.win, tconst.rect] = ...
        PsychImaging('OpenWindow', tconst.winptr, grey);
    tconst.framerate = Screen('FrameRate', tconst.win);
end

%=== Constants =============================================================%
tconst.flipint = Screen ('GetFlipInterval', tconst.win);
% calculate constant to transform visual degrees into pixels 
tconst.pixperdeg = metpixperdeg(screenWidth, tconst.rect(3), distance2screen);

%=== Close PTB =============================================================%
sca;

end


function ppd = metpixperdeg(mm, px, sub)
%
% ppd = metpixperdeg ( mm , px , sub )
%
% MATLAB electrophysiology toolbox. Convenience function to calculate the
% pixels per degree of visual angle. mm is the length of the screen along a
% given dimension in millimetres, while px is the length along the same
% dimension in pixels. sub is the distance in millimetres from the
% subject's eyes to the nearest point on the screen i.e. the distance along
% a line that is perpendicular to the screen and passes through the eye.
%
% mm and px must be numeric matrices that have the same number of elements,
% such that mm( i ) and px( i ) refer to the ith dimension of the screen.
% sub must always be a scalar numeric value. All numbers must be rational
% and greater than zero.
%
% Returns column vector ppd that has the same number of elements as mm and
% px, where ppd( i ) is the number of pixels per degree along the ith
% dimension.
%
% Written by Jackson Smith - Dec 2016 - DPAG , University of Oxford
%

% NB. Maria: we use ppd(1) = xdimension as coefficient to transform visual
% deg ree in pixel, see Jacksons remark:

% To calculate the degree-to-pixel coefficient, you need to use some dimension
% of the screen. But the way that metpixperdeg estimates this coefficient gives
% you the same answer whether you use the width or height, assuming that pixels
% are an equal width in both dimensions. This is because it estimates the distance
% from the centre of the screen in mm for one degree of visual angle, and then
% divides that by pixels per millimetre. Width happens to be the most convenient
% dimension to use because it is the first value returned by PsychToolbox.
% It is also the most relevant dimension when you are studying stereoscopic vision.


%%% Error checking %%%

% Check millimetre dimension measurements
if  isempty ( mm )  ||  ~ isnumeric ( mm )  ||  ~ isreal ( mm )  ||  ...
        any (  ~ isfinite ( mm )  |  mm <= 0  )
    
    error ( 'MET:metpixperdeg:input' , ...
        [ 'metpixperdeg: Input arg mm must have finite real values ' , ...
        'greater than 0' ] )
    
    % Check pixel dimension measurements
elseif  isempty ( px )  ||  ~ isnumeric ( px )  ||  ...
        ~ isreal ( px )  ||  any (  ~ isfinite ( px )  |  px <= 0  )
    
    error ( 'MET:metpixperdeg:input' , ...
        [ 'metpixperdeg: Input arg px must have finite real values ' , ...
        'greater than 0' ] )
    
    % Check subject distance
elseif  numel ( sub ) ~= 1  ||  ~ isnumeric ( sub )  ||  ...
        ~ isreal ( sub )  ||  ~ isfinite ( sub )  ||  sub <= 0
    
    error ( 'MET:metpixperdeg:input' , ...
        [ 'metpixperdeg: Input arg sub must be a scalar, finite ' , ...
        'real value greater than 0' ] )
    
    % Check that mm and px have the same number of values
elseif  numel ( mm )  ~=  numel ( px )
    
    error ( 'MET:metpixperdeg:input' , ...
        'metpixperdeg: mm and px must have the same number of elements' )
    
end


%%% Compute pixels per degree %%%

% Compute millimetres of screen per degree of visual angle
mm_deg = sub  *  tand ( 1 ) ;

% Then compute pixels per millimetre of screen
pix_mm = px( : )  ./  mm( : ) ;

% And finally, pixels per degree
ppd = mm_deg  *  pix_mm ;


end % metpixperdeg