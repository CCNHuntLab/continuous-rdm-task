function session = crdm_create_session_tones(session, options)
%CRDM_CREATE_SESSION_TONES For each block in the session, this function
%determines the sequence of tones to be played as a background MMN
%paradigm. The sequence vector 'audSequence' simply lists the frequency
%(pitch) of every tone. Tone length, inter-trial interval etc. are defined
%as auditory parameters in aPar, which is created by the function
%crdm_set_auditory_parameters, which in turn uses the settings in the
%substruct 'aStim' or the general 'options' struct.

% Create a tone sequence for each block
for iBlock = 1: session.nBlocks
    % This is just a dummy that uses a pre-defined sequence created by
    % Layla as saved in the variable 'sequences'
    session.blocks(iBlock).audSequence = sequences.tone_frequency_train;
    
    % This is a function one could write to generate the sequence
    %session.blocks(iBlock).audSequence = crdm_create_block_tones(options, aPar);
    
    % This is what Layla used to generate the 'sequences' variable.
    %sequences(iBlock).tone_frequency_train = set_tone_train(transition_state, parameters);
    %sequences(iBlock).block_identity = transition_state;
    % It would then require us to save the result in the 'audSequence'
    % vector:
    %session.blocks(iBlock).audSequence = sequences(iBlock).tone_frequency_train;
end

