function session = crdm_add_existing_tone_sequence( session )
%CRDM_ADD_EXISTING_TONE_SEQUENCE For each block in the session, this function
%adds a pre-defined sequence of tones (one that was used by Layla previsouly)
%to be played as a background MMN paradigm. The sequence vector 'audSequence' 
%simply lists the frequency (pitch) of every tone. Tone length, inter-trial 
%interval etc. are defined as auditory parameters in aPar, which is created by 
%the functionccrdm_set_auditory_parameters, which in turn uses the settings in 
%the substruct 'aStim' or the general 'options' struct.

% Load the pre-defined tone sequence
load('sub001_sess001_auditory_stim.mat', 'sequences');

% Create a tone sequence for each block
for iBlock = 1: session.nBlocks
    session.blocks(iBlock).audSequence = sequences(iBlock).tone_frequency_train;
end

