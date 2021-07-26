function [ vPar, blocks ] = crdm_set_visual_task_parameters( options, blocks )
%CRDM_SET_VISUAL_TASK_PARAMETERS This function sets all visual task
%parameters for the continuous random dot motion (crdm) task and transforms
%all durations and visual degrees in the general options and in the
%block-specific settings into frames and pixels, using the local screen
%parameters. 

% Before you run this function, you need to: 
%   a) get the local screen setup by running 
%       options.scr = crdm_get_screen_parameters(options), and
%   b) define all of your conditions by running
%       blocks = crdm_define_conditions(conditionSequence, options).


%% Visual stimulus parameters, general (fixed across blocks)

% get window centre
[vPar.centre_x, vPar.centre_y] = RectCenter(options.scr.rect);
vPar.centre = [vPar.centre_x, vPar.centre_y];
vPar.fixdotlocation = vPar.centre;

% dots per frame = dots/deg^2, round up so that we always get at least
% one dot if density is non-zero
vPar.Nd = ceil(pi * (options.vStim.apRadius^2) * options.vStim.dots.density);

% dotdiameter in pixels
vPar.dotdiameter = options.scr.pixperdeg * options.vStim.dots.size;
vPar.fixdiameter = options.scr.pixperdeg .* options.vStim.fixSize; % fix dot 
if vPar.fixdiameter(1) > 20
    vPar.fixdiameter(1) = 20; % max value is 20, screen too small (in mm) if >20
    disp('Fix dot 1 (smaller circle) diameter too high! Check crdm_set_task_options.');
end
if vPar.fixdiameter(2) > 20
    vPar.fixdiameter(2) = 20; % max value is 20, screen too small (in mm) if >20
    disp('Fix dot 2 (larger circle) diameter too high! Check crdm_set_task_options.');
end

% all parameters for Screen FillOval to draw annulus around fix dot. 
vPar.annulus = options.scr.pixperdeg * options.vStim.annulusSize; 

vPar.annulus_rect = [vPar.centre(1)-vPar.annulus, vPar.centre(2)-vPar.annulus, ...
    vPar.centre(1)+vPar.annulus, vPar.centre(2)+vPar.annulus];
vPar.annulus_diameter = 2.*vPar.annulus; % defining diameter to help with speed 

% aperture radius in pixels in which dots are displayed
vPar.ap_radius = options.scr.pixperdeg * options.vStim.apRadius;

% set all colours we will use later
vPar.col = crdm_set_colours;


%% Visual timing parameters, general (fixed across blocks)

% Pixels travelled by a signal dot between each 3rd frame (because I have 3
% sets of dots)
vPar.step = options.scr.pixperdeg * options.vStim.dots.speed * options.scr.flipint;

% Mean duration of constant coherence level during incoherent and coherent motion
vPar.jump_meanDur = round(options.design.jump.meanDuration / options.scr.flipint);
vPar.jump_minDur = round(options.design.jump.minDuration / options.scr.flipint);
vPar.jump_maxDur = round(options.design.jump.maxDuration / options.scr.flipint);

% get total number of frames
vPar.totalframes_per_block = round((options.design.blocks.duration * 60) / ...
    options.scr.flipint);
vPar.nFramesPerBlock = vPar.totalframes_per_block;

% min number of frames before first stimulus can occur and min number of frames of
% incoherent motion after last stimulus
vPar.gap_after_last_onset = round(options.design.noStimPeriod.post / options.scr.flipint);
vPar.gap_before_first_onset = round(options.design.noStimPeriod.pre / options.scr.flipint);

% vector with frame interval in which coherent stimuli can occur
vPar.onsets_occur = [vPar.gap_before_first_onset  vPar.totalframes_per_block - vPar.gap_after_last_onset];
vPar.total_stim_epoch = diff(vPar.onsets_occur); % total num of frames in which stim of coherent motion and incoherent motion can be shown
vPar.nFramesForTrials = vPar.total_stim_epoch;

%% Reward stimulus parameters, general (fixed across blocks)

% rewardbar size and location 
vPar.rewbarlocation = [vPar.centre(1) + ...
    (options.reward.bar.location(1).*options.scr.pixperdeg), ...
    vPar.centre(2) + (vPar.ap_radius + ...
    (options.reward.bar.location(2).*options.scr.pixperdeg))];
vPar.rewbarsize = options.reward.bar.size .* options.scr.pixperdeg; 

% amount of time in frames participants have to respond after the stimulus has
% disappeared 
vPar.flex_feedback = round(options.feedback.tolerance / options.scr.flipint);

% calculate the duration for which feedback is shown
vPar.feedback_frames = round(options.feedback.duration / options.scr.flipint);


%% Reward timing parameters, general (fixed across blocks)
vPar.rewardbartime = round(options.reward.bar.showTime / options.scr.flipint); 


%% Visual stimulus parameters, block-specific
for iBlock = 1: numel(blocks)
    blocks(iBlock).fixDot.size = options.scr.pixperdeg .* blocks(iBlock).fixDot.sizeDeg;
end

%% Visual timing parameters, block-specific
for iBlock = 1: numel(blocks)
    blocks(iBlock).iti.min = round(blocks(iBlock).iti.minSec / options.scr.flipint); %crdm_time2frames(blocks(iBlock).iti.minSec, options.scr);
    blocks(iBlock).iti.max = round(blocks(iBlock).iti.maxSec / options.scr.flipint); %crdm_time2frames(blocks(iBlock).iti.maxSec, options.scr);
    blocks(iBlock).iti.mean= round(blocks(iBlock).iti.meanSec / options.scr.flipint); %crdm_time2frames(blocks(iBlock).iti.meanSec, options.scr);
    blocks(iBlock).trial.length = round(blocks(iBlock).trial.lengthSec / options.scr.flipint); %crdm_time2frames(blocks(iBlock).trial.lengthSec, options.scr);
end

%% Reward stimulus parameters, block-specific
for iBlock = 1: numel(blocks)
    % no such settings currently
end

%% Reward timing parameters, block-specific
for iBlock = 1: numel(blocks)
    % no such settings currently
end


end













%============ only for training??? ========================%
%{
% location of the fixdot 
vPar.fixdotlocation = vPar.centre;

% size parameters of fixdot for training 
vPar.linewidth = vPar.vp.linewidth .* options.scr.pixperdeg; 
vPar.linesize = vPar.vp.linesize .* options.scr.pixperdeg; 

% square for feedback for replies during incoherent motion 
vPar.square_size = vPar.vp.square_size .* options.scr.pixperdeg; 

% vector with coordinates of square indicating long intertrial periods,
% left, upper corner, right, lower corner

% big square for long integration periods 
vPar.square_vector_big = [0 0 vPar.square_size(2) vPar.square_size(2)];
vPar.square_centred_big = CenterRectOnPointd(vPar.square_vector_big,vPar.fixdotlocation(1), vPar.fixdotlocation(2)); 

% small square for short integration periods 
vPar.square_vector_sm = [0 0 vPar.square_size(1) vPar.square_size(1)];
vPar.square_centred_sm = CenterRectOnPointd(vPar.square_vector_sm, vPar.fixdotlocation(1), vPar.fixdotlocation(2)); 

% square for photo-diode in upperleft corner of screen 
vPar.square_diode_length = 20; % in pix 
vPar.square_diode_vector = [0 0 vPar.square_diode_length vPar.square_diode_length]; 
vPar.square_diode_centred = CenterRectOnPointd(vPar.square_diode_vector,vPar.square_diode_length/2, vPar.square_diode_length/2); 
vPar.square_diode_colour = [0 0 0];
%}
%==========================================================%