function [ xy ] = crdm_move_dots( nFrames, nDots, speed, apRadius, coherencePerFrame )
%CRDM_MOVE_DOTS This function generates x and y locations for every frame of a
%block of RDM, based on the vector of framewise motion coherence. The stimulus
%is coded in a way that there are 3 sets of dots and every dot is displayed 
%only every third frame.
%   IN: 
% nFrames           - number of frames random dots are displayed - this is
%                     for pre-allocation of space
% nDots             - number of dots displayed per frame
% speed             - speed with which the signal dots move - pixels/frame
% apRadius          - radius of the circular aperture in which the dots are
%                     displayed
% coherencePerFrame - pre-allocated vector that gets assigned coherence
%                     values during incoherent and coherent motion periods
%                     for each frame
%   OUT:
% xy                - 2xNdxf matrix, where first row is x position and,
%                     second row is y position for number of (Nd) dots for
%                     each frame (f)

xy = zeros(2, nDots, nFrames);

%% Generate xy positions for dots according to sequence of coherences
for f = 1: nFrames % loop through all frames
    
    coherence = coherencePerFrame(f);
    
    % if coherence negative change motion direction and turn coherence in
    % positive number
    direction = sign(coherence);
    
    %move dots - but first determine whether dots move in coherence
    %direction or randomly
    
    coh_prob = rand(1, nDots);
    
    %index vectors to noise and signal dots
    index_signal = find (coh_prob <= abs(coherence));
    index_noise = coh_prob > abs(coherence);
    
    %move noise dots
    
    xy(:,index_noise,f) = xypos(sum(index_noise), apRadius);
    
    %move signal dots - but only if we are above 3 frames because every
    %set of dots is shown only on every 3rd frame, otherwise all dots move randomly
    if f > 3
        xy(1,index_signal,f) = xy(1,index_signal,f-3) + speed * direction * 3;
        xy(2,index_signal,f) = xy(2,index_signal,f-3);
    else
        
        xy(:,index_signal,f) = xypos(numel(index_signal), apRadius);
    end % if f > 3
    
    
    % check whether dot crossed apperture, if dot crossed aperture -
    % re-plot at random location on opposite side of moving direction
    %outside the aperture then move dot with a random distance back into
    %the aperture
    
    % calculate distance to aperture centre
    distance_x_centre = sqrt(xy(1,index_signal,f).^2 + xy(2,index_signal,f).^2 );
    
    % get signal dots that have a distance greater than the radius
    % meaning that they are outside the aperture
    idx_dist = index_signal(distance_x_centre >= apRadius);
    
    if ~isempty(idx_dist) % if dots moved outside apperture
        %replex y and x coordinates of the dots to a place on the opposite
        %site of the aperture
        
        xy(2,idx_dist,f) = 2 .* apRadius .* rand(size(idx_dist)) - apRadius;
        xy(1,idx_dist,f) = sqrt((apRadius^2) - (xy(2,idx_dist,f).^2));
        
        %move signal dots back into aperture
        xy(1,idx_dist,f) = xy(1,idx_dist,f) - rand(size(idx_dist)) .* speed;
        
        % needs to be mirrored if coherence is positive
        if direction > 0
            xy(1,idx_dist,f) = - xy(1,idx_dist,f);
        end
    end
end

end

function XY = xypos(n, r)
%XYPOS Find randomised x and y coordinates for dots, needs number of dots (n) 
%and radius of aperture in pixels (r)

% find random angles
theta = 2*pi*rand(1,n);

% find random radius
radius = r * sqrt(rand(1,n));

% back to cartesian coordinate system
XY = [radius.*cos(theta); radius.*sin(theta)];

end
