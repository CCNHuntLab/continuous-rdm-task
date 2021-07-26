function [ session ] = crdm_create_session_stimulus( condSequence, blocks, ...
    vPar, options )

% Creating the stimulus for one session: steps
% ============================================
% 1) design a session (number of blocks, conditions) - done in options
% 2) for each block: create trials (number of trials, ITIs, mean coherences)
% 3) for each block: fill block with sequence of actual coherences
% 4) for each block: generate xy locations for every frame of block + noise
% input to all of these: general stimulus settings, e.g. size of aperture,
% dot size and density

% 1) Design a session 
%    ----------------
session.nBlocks = options.design.blocks.nPerSession;
session.conditionSequence = condSequence; % the meaning of these numbers depends on
% the task version/ experimental design (see options and
% crdm_define_conditions)
session.vPar = vPar;

% Now create the stimulus for each block
for iBlock = 1: numel(blocks)
    
    % 2) Create trials
    %    -------------
    %blocks(iBlock).trials = crdm_create_trials(blocks(iBlock));
    [trl.itiList, trl.trialPositionVector, trl.meanCoherenceTrialList] = ...
        crdm_generate_trials(vPar.nFramesForTrials, vPar.nFramesPerBlock, ...
        vPar.onsets_occur, blocks(iBlock).iti, blocks(iBlock).trial);
    
    % 3) Generate a sequence of coherences
    %    ---------------------------------
    %blocks(iBlock).coherences = crdm_generate_coherences(trials);
    [coh.trialCohPerFrame, coh.meanCohPerFrame, coh.trialPositionVector] = ...
        crdm_generate_coherence_frames('trials', vPar.nFramesPerBlock, ...
        [blocks(iBlock).iti.sd blocks(iBlock).trial.sd], ...
        trl.meanCoherenceTrialList, trl.itiList, blocks(iBlock).trial.length, ...
        vPar.jump_meanDur, vPar.jump_minDur, vPar.jump_maxDur);
    
    coh.noiseCohPerFrame = crdm_generate_coherence_frames('noise', ...
        vPar.nFramesPerBlock, [blocks(iBlock).iti.sd []], [], [], [], ...
        vPar.jump_meanDur, vPar.jump_minDur, vPar.jump_maxDur);
    
    % 4) Generate a sequence of xy locations
    %    -----------------------------------
    %blocks(iBlock).stimulus = crdm_generate_dot_locations(coherences);
    stim.xy = crdm_move_dots(vPar.nFramesPerBlock, vPar.Nd, ...
        vPar.step, vPar.ap_radius, coh.trialCohPerFrame);
    stim.xy_noise = crdm_move_dots(vPar.nFramesPerBlock, vPar.Nd, ...
        vPar.step, vPar.ap_radius, coh.noiseCohPerFrame);
    
    blocks(iBlock).epochs = trl;
    blocks(iBlock).coherences = coh;
    blocks(iBlock).stimulus = stim;
    
    % create a copy of the framewise coherences, as these will change as
    % the experiment runs and participants press buttons
    blocks(iBlock).origCoherences = blocks(iBlock).coherences;
    
    % calculate how many trials we have in each block
    blocks(iBlock).nTrials = numel(trl.meanCoherenceTrialList);
end

session.blocks = blocks;

end