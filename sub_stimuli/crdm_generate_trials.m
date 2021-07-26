function [ itiList, trialPositions, trialCoherences ] = ...
    crdm_generate_trials( nFramesToFill, nFramesTotal, firstLastFrame, ...
    itiDef, trialDef )
%CRDM_GENERATE_TRIALS This function distributes periods of coherent motion
%(trials) and of incoherent motion (ITIs) across all frames of a block of
%the continuous random dot motion (crdm) task, and assigns mean coherences
%to the trials by randomly shuffling the list of possible coherences.
% Input: 
%          nFramesToFill = total number of frames available for trials and ITIs
%                       (i.e., number of frames without gaps of defined incoherent motion at
%                         beginning and end of block)
%          nFramesTotal = total frames per block 
%          firstLastFrame = vector indicating first and last frame of
%                         framesToFill in framesTotal 
%          itiDef = struct with definition for possible ITIs, has the
%                   fields:
%                   min = minimum frame number of incoherent motion between
%                        two coherent motion periods
%                   max = max frame number of incoherent motion between two
%                        coherent motion periods
%                   mean = mean number of frames of incoherent motion
%                             betweeen coherent motion periods 
%          trialDef = struct with definition for possible trials, has the
%                       fields:
%                       length  = length of trial in frames
%                       cohList = list of coherences used for trials
%
% Output:
%           itiList = vector with length in frames for each ITIs
%           trialPositions = vector of length nFramesTotal with zeros for 
%                     incoherent motion frames, and trialCount for
%                     coherent motion frames
%                     e.g. 0 0 0 0 1 1 1 1 1 0 0 0 0 0 2 2 2 2 ...
%           trialCoherences = vector with one mean coherence per trial
            
            
% Maria Ruesseler, University of Oxford 2018


framesLeft = nFramesToFill; % variable that tracks for how many more frames ITIs and stim periods can be definded 
iIti = 1; % counter for index in itiList 
startFrame = firstLastFrame(1); % first frame of interval in which we can define coherent and incoherent motion
trialPositions = zeros(nFramesTotal, 1); % see above - vector with 0s 

% for incoherent motion frames, trial number for coherent motion 
iTrial = 1; % count coherent motion periods 

% loop through intertrial periods while the first frame of a new period we 
% want to define is smaller than the last frame of trialDef.length - itiDef.mean 
% and duration of coherent motion
while startFrame < firstLastFrame(2) - itiDef.mean - trialDef.length && framesLeft > 0
    

    %% generate intertrial epoch
    %  interframe_frames_interval = abs(maxframenum - minframenum); % calculate the actual interval possible of intertrial frames 
    itiFramesInterval = itiDef.max - itiDef.min; % calculate the actual interval possible of intertrial frames 
    
    % draw a random number from uniform distribution from that interval - 
    % this is the number of incohrent motion frames between two consecutive trials
    itiList(iIti) = abs(randi(itiFramesInterval,1,1) + itiDef.min); 
    
    %% generate trial
    startFrame = startFrame + itiList(iIti)+1; % get first frame of next coherent motion period
    endFrame = startFrame-1 + trialDef.length; % and its last frame 
    
    % for this coherent motion period assign number of trial for each frame within that period 
    trialPositions(startFrame:endFrame) = ones(trialDef.length,1) .* iTrial; 
    
    startFrame = endFrame; % this is used to calculate first frame of next coherent motion period 
    iTrial = iTrial + 1; % increase number of coherent motion period 
    
    framesLeft = framesLeft - itiList(iIti)-trialDef.length; % reduce number of intertrial frames left by the number we just draw
    iIti = iIti + 1; % update index counter for epochs vec 
    
end % while frames left 

if framesLeft <= 0    
    onsetLastTrial = find(trialPositions == iTrial-1, 1, 'first'); 
    itiList(iIti-1) = itiList(iIti-1) + framesLeft; % (frames left is negative in that case so that number gets subtracted)
    trialPositions(onsetLastTrial : end) = 0;
    totalTrials = iTrial -2; % -1 because we added + 1 after last trial in while loop 

else
    % last intertrial epoch is the one between last trial and end of block
    itiList(iIti) =  nFramesTotal - endFrame; 
    totalTrials = iTrial -1; % -1 because we added + 1 after last trial in while loop 
end

%% Assign a mean coherence to each trial period

% number of repetitions per coherence 
numRepeatsCoh = ceil(totalTrials/numel(trialDef.cohList));

% duplicate coherences accordingly 
coherenceMatrix = repmat(trialDef.cohList, [numRepeatsCoh, 1]);

% shuffle indices of that matrix  
idxShuffled = randperm(numel(coherenceMatrix));

% shuffle coherences 
trialCoherences = reshape(coherenceMatrix(idxShuffled), [numel(coherenceMatrix), 1]);

end % calculate_intertrial_epoch