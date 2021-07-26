function [ session, options ] = crdm_create_session( debugMode, conditionSequence )
%CRDM_CREATE_SESSION Creates all stimuli and settings needed to run one
%session of the combined continuous random dot motion (crdm) task and the
%background mismatch negativity paradigm.
%   IN:     debugMode   - flag for whether we want fullscreen (0) or a
%                       smaller window for debugging (1-3)
%           conditionSequence - vector with nBlocks entries specifying the
%                       order of conditions to use (e.g. [1 2 1 2])

options = crdm_set_task_options;
if length(conditionSequence) ~= options.design.blocks.nPerSession
    error('Condition sequence needs to have as many entries as blocks in a session.');
end

% Determine local screen parameters
options.scr = crdm_get_screen_parameters(options.scrWidth, options.subDist, debugMode);

% Define block-specific settings for each block in the session
blocks = crdm_define_conditions(conditionSequence, options);

% Convert visual degrees to pixels and durations to frames
[vPar, blocks] = crdm_set_visual_task_parameters(options, blocks);

%% Create a stimulus for one session
% visual stimuli
session = crdm_create_session_stimulus(conditionSequence, blocks, vPar, options);
session.debugMode = debugMode;

% auditory stimuli
%session = crdm_create_session_tones(session, options);
end

