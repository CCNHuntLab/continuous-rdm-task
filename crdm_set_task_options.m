function options = crdm_set_task_options
%CRDM_SET_TASK_OPTIONS This function sets all the options for the combined CRDM
%and MMN tasks that might differ across task versions. We only set one
%value per setting here. If any of these are to vary across conditions
%within a task version, this has to be defined in crdm_define_conditions.
%If other parameters are to be changed for a new task version, these can be
%added to the options here. In this case, the relevant functions using these 
%parameters need to be adjusted to take the values saved here instead of
%the ones that are hard-coded within these functions (this applies to the
%functions set_visual_stim_parameters, set_auditory_stim_parameters, etc.).

% Note that all durations (here to be given in seconds/minutes) will later be
% converted to frames, and similarly all stimulus sizes (in visual degrees) 
% will be converted to pixels, all by crdm_set_visual_task_parameters. The
% conversion factors depend on the local screen setup and therefore need to be
% determined on the computer where the task is run.

% Local options
options.scrWidth    = 330;
options.scrHeight   = 207; % might be unused
options.subDist     = 540;
options.audSampFrq  = 4800; % interacts with aStim duration settings, this setting (4800) works at OHBA EEG when NOT in debug mode. In debug mode, tone duration needs to be divided by 100 instead of 1000
options.audVolume   = 0.5;
options.keys.index  = 11; % 1 for OHBA EEG lab, 11 for lilian's laptop, 5 for with screen % this depends on your keyboard setup - test!
options.keys.left   = 'A';
options.keys.right  = 'L';

% Flags - 1 means yes, 0 means no
options.doTones         = 0; % tone sequences are played in the background (and triggered if EEG)
options.doTraining      = 0; % trial periods are signalled via fix dot turning white
options.doRewardbar     = 1; % a bar is shown below the dots with the current reward & feedback
options.doAnnulus       = 0; % an empty circle around the fix dot where no moving dots appear

% Which design to use (conditions) - see crdm_define_conditions for details
options.design.designLabel      = 'coherence variance'; % 'coherence variance', 'trial frequency', 'trial length'
options.design.nConditions      = 2;
options.design.conditionNames   = {'lowVar', 'highVar'}; % {'rare', 'frequent'}, {'short', 'long'};

% Sessions and Blocks
options.design.blocks.duration      = 5; % in min - usually 5, for debugging use 1-2
options.design.blocks.nPerSession   = 4; % usually 4, for debugging use 1-2
options.design.noStimPeriod.pre     = 0.5; % "empty" time in block before first stimulus
options.design.noStimPeriod.post    = 0.5; % "empty" time in block after last stimulus

% Task-version specific instructions (could depend on designLabel)
options.instruct = crdm_define_instructions_text(options);

% The following settings are defaults, and any condition/block-specific settings
% will be defined in crdm_define_conditions per block and overwrite these.

% Trials
options.design.trial.cohList    = [-0.6 -0.5 -0.4 0.4 0.5 0.6];
options.design.trial.sd         = 0.3; % variance of coherence in trials
options.design.trial.duration   = 5; % in s

% Intertrial intervals ("baseline")
options.design.iti.sd       = 0.5; % variance of coherence in baseline periods
options.design.iti.minSec   = 1; % in s
options.design.iti.maxSec   = 8; % in s
options.design.iti.meanSec  = 5; % in s

% Jumps of coherence
% Note: currently same for trials and baseline
options.design.jump.meanDuration = 0.3; % in s
options.design.jump.minDuration = 0.05; % in s - 50ms - should be at least 40ms
options.design.jump.maxDuration = 1; % in s

% Reward settings
options.reward.probability  = 1; % changes to this are not yet implemented
options.reward.points.hit   = 3;
options.reward.points.error = -3;
options.reward.points.miss  = -1;
options.reward.points.fa    = -1.5;
% Money earned is determined by how many correct responses the participant
% has to emit to fill the reward bar once, and by the amount of money they
% gain by filling the reward bar once:
options.reward.nHitsToFill      = 5; % how many correct responses to fill bar
options.reward.nCoinsPerFill    = 0.15; % amount of pounds won if reward fills once
options.reward.nPointsPerFill   = options.reward.nHitsToFill * options.reward.points.hit;

options.reward.bar.location = [0 1.4]; % centre x, y coordinates of rectangle
options.reward.bar.size     = [12 1.5]; % width, height
options.reward.bar.showTime = 0.5; % time in sec for which new points are shown

% Visual feedback after button presses
options.feedback.duration   = 0.7; % in s
options.feedback.tolerance  = 0.5; % in s - time after end of trial where participants can still detect it to gain points

% Stimulus settings: visual (dots)
options.vStim.dots.density  = 0.1;
options.vStim.dots.type     = 2;
options.vStim.dots.size     = 0.2;
options.vStim.dots.speed    = 7;
options.vStim.fixSize       = [0.3 0.6]; % can specify 2 entries for 2 different conditions
options.vStim.annulusSize   = 1.75;
options.vStim.apRadius      = 5; % size of the area with moving dots, in visual degrees

% Stimulus settings: auditory (tones)
options.aStim.toneLength = 80/1000; % in s
options.aStim.isi = 500/1000; % in s

% Triggers
options.trig = crdm_define_trigger_values;

end