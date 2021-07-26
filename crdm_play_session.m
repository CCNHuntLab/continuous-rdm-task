function [ S, respMat ] = crdm_play_session( session, doDebug, doEEG, options, basePath )
%CRDM_PLAY_SESSION Presents all blocks of one session of the combined
%continuous random dot motion (crdm) and mismatch negativity (mmn)
%paradigm.
%   IN:     session     - struct containing all information needed to
%                       present the visual task and auditory stimuli for each 
%                       block, variable is created by crdm_create_session.m
%           doDebug     - are we using a fullscreen window (doDebug=0)?
%           doEEG       - are we recording EEG (and sending triggers, EEG=1)?
%           options     - general task options
%           blockFile   - optional, for saving results after every block
%   OUT:    results     - struct containing actual stimulus played to
%                       participant, and their responses and rewards

%% SETUP
if doDebug ~= session.debugMode
    warning(['Stimuli were generated in a different debugMode than is ' ...
        'being used to play the session.']);
end

% Set up S stuct which will hold all session info
S.subjectID     = session.subjectID;
S.sessionID     = session.sessionID;
S.startTaskTime = session.timeStamp;

S.debugMode = doDebug;
S.doEEG     = doEEG;
S.options   = options;

% Initialize triggers
if doEEG
    %handle = serial('COM9', 'BaudRate', 115200);
    %fopen(handle);
    %fwrite(handle, ['mh', 0, 0]); % turn trigger off
end 

% Initialize screen and get initial flip time
if doDebug == 2 || doDebug == 3
    % Exact synchronization not possible on Mac
    flipTime = Screen('Preference', 'SkipSyncTests', 1);
else
    % Exact synchronization for EEG experiment
    flipTime = Screen('Preference', 'SkipSyncTests', 0);
end

if doDebug == 0
    HideCursor;
end

% Boilerplate initialisations
PsychDefaultSetup(2);
screens = Screen('Screens');
% Get correct screen number for screen on which we want to show task
tconst = options.scr;
tconst.winptr = max(screens);

%% Initialise auditory presentation
if options.doTones
    audioStartTime = NaN(session.nBlocks); 
    InitializePsychSound(1);
    switch doDebug
        case 1
            pahandle = PsychPortAudio('Open');
        otherwise
            pahandle = PsychPortAudio('Open', 1, 1, 1, options.audSampFrq);
    end
end
                
%% OPEN WINDOW
if doDebug == 1 || doDebug == 3
    % Window size reduced to keep Matlab visible
    [tconst.win, tconst.rect] = PsychImaging('OpenWindow', tconst.winptr, ...
        session.vPar.col.grey, [0 0 1048 786]);
else
    % Full screen window
    [tconst.win, tconst.rect] = PsychImaging('OpenWindow', tconst.winptr, ...
        session.vPar.col.grey);
end
S.tconst = tconst;
disp('Screen is set up.');

%% KEYBOARD
% Response keys that participants should use
KbName('UnifyKeyNames');
leftKey     = KbName(options.keys.left);
rightKey    = KbName(options.keys.right);

% Index of the keyboard we are listening to
[keyboardIndices, ~, ~] = GetKeyboardIndices;
% Keyboard index is specific to every machine, test this on the machine
% that the experiment will be run on to get the right keyboard

if doDebug == 2 || doDebug == 3
    % Mac keyboard - test this on your machine
    deviceNumber = keyboardIndices;
else
    deviceNumber = keyboardIndices(options.keys.index);
end

% Create queue to wait for button press from keyboard (this is required for
% us to be able to listen to keyboard responses from the participant)
KbQueueCreate(deviceNumber);


%% FEEDBACK AND REWARD INITIALIZATION
% pre-allocate cells to respMat matrix to record responses later on
respMat = cell(session.nBlocks, 1);

if options.doRewardbar
    
    rewardCountdown = 0; % This will be set to a value > 0 whenever a reward needs
    % to be signalled, i.e., after a button was pressed or a a trial was
    % missed. It will be set to the number of frames for which we want to show
    % the reward update in the reward bar. Then, with every following frame, we
    % will count down this number until it's back to zero.

    %%%--- Load reward matrix if exists; if not, create one ---%%%
    % This is the matrix saved in reward_info.mat that contains information
    % about reward earned in this session which is starting point for next
    % session (so that reward is carried over between sessions)

    % check whether a rewardInfo file for this participant exists
    rewardInfoFile = [basePath 'reward_info.mat'];
    if exist(fullfile(rewardInfoFile), 'file')
        load(rewardInfoFile, 'rewardInfo');
        
        totalCoinsWon = rewardInfo(1, 2); % money already won
        currentRewardBarPoints = rewardInfo(1, 1); % how far reward bar has been
                                                   % filled up in last session
    else
        % This is the first session: create a reward info matrix
        rewardInfo = zeros(1, 2);
        totalCoinsWon = 0;
        currentRewardBarPoints = 0;
    end 

    updateRewardBar = 0; % flag: whether rewardbar needs update
    responseFlag = 0; % flag: whether response was recorded
    missedFlag = 0; % flag: whether trial was missed
    % if either one of responseFlag and missedFlag is true, reward bar
    % needs to be updated on the next frame and is thus true.
end

%% FUNCTION CALLS
%%%% to save time, call functions used in while loop through frames and call
%%%% all screen functions to draw different feedback shapes (MATLAB needs a
%%%% little bit of time to find all functions and to draw feedback shapes
%%%% for the first time for some reason, which leads to dropping frames)

if options.doRewardbar
    % find moneybar function
    [centeredBarFrame, centeredRewardRect, centeredNewRewardRect, rewardText, ...
        currentRewardBarPoints, totalCoinsWon, currentRewardInfo] ...
        = crdm_moneybar(0, 0, totalCoinsWon, session.vPar.rewbarsize, ...
        options.reward.nPointsPerFill, options.reward.nCoinsPerFill, ...
        session.vPar.rewbarlocation);

    Screen('FrameRect', tconst.win, session.vPar.col.black, centeredBarFrame, 4);
    DrawFormattedText(tconst.win, rewardText, ...
        session.vPar.centre(1) + round(session.vPar.rewbarsize(1)/2) + 30,...
        session.vPar.rewbarlocation(2), 0);
    Screen('Flip', tconst.win);

    DrawFormattedText(tconst.win, '', 'center', 'center', 0);
    Screen('Flip',tconst.win);
end

if options.doAnnulus
    % calling annulus for first time for speed
    Screen('FillOval', tconst.win, session.vPar.col.grey, ...
        session.vPar.annulus_rect, session.vPar.annulus_diameter);
end

% calling reallocation first time for speed
crdm_fill_trial_part_with_noise([], [], 0);


%% INSTRUCTIONS
Screen('TextFont', tconst.win, 'Arial');
% Next block of instructions always starts after participant presses
% button.
DrawFormattedText(tconst.win, options.instruct.taskDescription, 'center', 'center', 0);
Screen('Flip', tconst.win);
KbStrokeWait(deviceNumber) 

DrawFormattedText(tconst.win, options.instruct.pleaseFixate, 'center', 'center', 0);
Screen('Flip', tconst.win);
KbStrokeWait(deviceNumber)

DrawFormattedText(tconst.win, options.instruct.blockInfo, 'center', 'center', 0);
Screen('Flip', tconst.win);
KbStrokeWait(deviceNumber)

DrawFormattedText(tconst.win, options.instruct.feedbackInfo, 'center', 'center', 0);
Screen('Flip', tconst.win);
KbStrokeWait(deviceNumber)

% training instructions
if options.doTraining
    DrawFormattedText(tconst.win, options.instruct.trainingInfo, 'center', 'center', 0);
    Screen('Flip', tconst.win);
    KbStrokeWait(deviceNumber)
end


%% START TASK
statusSound = struct(); 
blockTime = tic; % time how long it takes to run a block - together with 
% toc furter down at end of loop, loop through the different blocks of 
% different conditions of integration (i.e. trial length) and intertrial
% interval (ITI) periods (i.e. trial frequency)


%% CYCLE THROUGH ALL BLOCKS
for iBlock = 1: numel(session.blocks)
    
    %% AUDIO: SCHEDULE BLOCK-SPECIFIC TONE SEQUENCE
    if options.doTones
        currentAudIdx = 1; % This runs over both tones and ISIs
        blockSequence = session.blocks(iBlock).audSequence;
        
        % Create an ISI, to be used after every tone
        mySilence = MakeBeep(0, options.aStim.isi, options.audSampFrq); 
        
        % Prepare PsychPortAudio for our schedule of tones
        PsychPortAudio('Volume', pahandle, options.audVolume); 
        PsychPortAudio('UseSchedule', pahandle, 2, 11000);
        
        audTriggerList = []; 
        for iTone = 1: length(blockSequence)
            % Create the next tone in the sequence
            myBeep = MakeBeep(blockSequence(iTone), options.aStim.toneLength, options.audSampFrq); 

            % We create a list of trigger values here, which we will use
            % later in the loop over frames to determine which trigger to
            % send for each new tone
            if iTone == 1
               audTriggerList(currentAudIdx) = options.trig.aud.deviant; 
            elseif blockSequence(iTone) == blockSequence(iTone-1)
                audTriggerList(currentAudIdx) = options.trig.aud.standard;
            else 
                audTriggerList(currentAudIdx) = options.trig.aud.deviant; 
            end
            
            % Now we add our tone to the schedule
            buffer(currentAudIdx) = PsychPortAudio('CreateBuffer', pahandle, [myBeep; myBeep]);
            PsychPortAudio('AddToSchedule', pahandle, buffer(currentAudIdx));
            currentAudIdx = currentAudIdx + 1; 

            % We also add the next ISI to the schedule
            buffer(currentAudIdx) = PsychPortAudio('CreateBuffer', pahandle, [mySilence; mySilence]);
            PsychPortAudio('AddToSchedule', pahandle, buffer(currentAudIdx));
            audTriggerList(currentAudIdx) = options.trig.aud.silence; 
            currentAudIdx = currentAudIdx + 1; 
        end 

        InitializePsychSound(1);
    end

    %% CONDITION-SPECIFIC INSTRUCTIONS
    infoText = ['Block: ', num2str(iBlock), ...
        ' \n\n ', session.blocks(iBlock).instruct.text];
    fixSize = session.blocks(iBlock).fixDot.size;
    
    % Actually draw the infoText
    Screen('Drawdots', tconst.win, [0 0], fixSize, session.vPar.col.black, ...
        session.vPar.fixdotlocation, options.vStim.dots.type);
    DrawFormattedText(tconst.win, infoText, 'center', ...
        session.vPar.centre(2)-200, 0);
    Screen('Flip', tconst.win);
    
    % Wait for (any) button press
    KbStrokeWait(deviceNumber);
    KbEventFlush(deviceNumber);
    KbQueueStop(deviceNumber);
    
    %% RESET BLOCK PARAMETERS
    % Set the coherence vectors to their original form (in case this
    % session has been played before)
    session.blocks(iBlock).coherences = session.blocks(iBlock).origCoherences;
    % We will use this one a lot, so make the name shorter
    meanCohPerFrame = session.blocks(iBlock).coherences.meanCohPerFrame;
    
    respCounter = 2; % index (idx) for counting rows in response Matrix
    tTrialStart = 0; % used to get time on first coherent motion frame of a 
                % trial and to calculate rt later
    
    % create a feedback structure (Fb) which contains some important
    % variables for the running of the task (see documentation)
    Fb.feedback_countdown = 0; % set to a certain number of frames for 
                               % which fb will be displayed
    iTrial = 0; % trial counter - needed to idx into epochs (trials) of 
               % coherent motion periods
    
    
    %% SETUP: matrix for behavioural responses
    respMat{iBlock} = NaN(session.blocks(iBlock).nTrials +50, 8);
    
    KbQueueStart(deviceNumber); % start recording button presses

    f = 1; % looping through frames idx
    currentTrialStartFrame = 0; % variable to save the frame on which a trial 
    % (coherent motion period) started. If this is zero, it serves as flag
    % indicating that there's currently no trial to respond to or miss, if
    % it's above zero, it indicates the frame on which the current trial
    % started.
    S.trialStarts{iBlock} = zeros(40, 2);
    trialCounter = 1; % counter for this vector
    
    % set max priority level to PTB (all other processes on computer now
    % secondary)
    topPriorityLevel = MaxPriority(tconst.win);
    Priority(topPriorityLevel);
    
    % set keycounter for keypress matrix that saves which button has been
    % pressed when to 1
    keyCounter = 1;
    
    % initialise keypress matrix to save all keypresses
    keyPress = cell(100, 3);
    
    % Set this to some value so it will be different to the first actual
    % position in the sound schedule and we get a trigger for the first tone
    lastPositionInSoundSchedule = -50; 
        
    %% SOME BOOK KEEPING
    % save how often we loop through the WHILE loop, and how long each 
    % loop takes    
    allWhileCalls   = nan(session.vPar.nFramesPerBlock +100, 1);
    allFrames       = nan(session.vPar.nFramesPerBlock +100, 1);
    stimOnsetTimes  = nan(session.vPar.nFramesPerBlock +100, 1);
    missBeam        = nan(session.vPar.nFramesPerBlock +100, 1);
    vblTimeStamps   = nan(session.vPar.nFramesPerBlock +100, 1);
    flipTimes       = nan(session.vPar.nFramesPerBlock +100, 1);
    
    whileCalls        = 0;
    whileLoopTime     = tic;
    
    S.blockstartsecs{iBlock}    = GetSecs;
    S.visualTriggers{iBlock}    = nan(session.vPar.nFramesPerBlock, 1);
    S.auditoryTriggers{iBlock}  = nan(session.vPar.nFramesPerBlock, 1);
    S.combinedTriggers{iBlock}  = nan(session.vPar.nFramesPerBlock, 1);

    %% CYCLE THOUGH FRAMES OF ONE BLOCK
    while f <= session.vPar.nFramesPerBlock % loop through all frames of block
        %% TRIGGERS
        if doEEG
            % set trigger back to 0 so that we can record next trigger
            visualTrigger = options.trig.holdValue;
            
            if f == 1 && doEEG
                visualTrigger = options.trig.blockStart;
            end
            
            if f > 1
                % send a trigger on *every* jump of coherence (in
                % intertrial and trial periods) This is later used for matching the
                % eeg and behavioural recordings
                if  session.blocks(iBlock).coherences.trialCohPerFrame(f) ~= session.blocks(iBlock).coherences.trialCohPerFrame(f-1) %S.coherence_frame{iBlock}(f) ~= S.coherence_frame{iBlock}(f-1)
                    visualTrigger = options.trig.vis.cohJump;
                end
                
                % send trigger at start of **incoherent** motion period
                % (this is the END of a trial)
                if  abs(meanCohPerFrame(f-1)) ~= 0 && abs(meanCohPerFrame(f)) == 0
                    %abs(S.mean_coherence_org{iBlock}(f-1)) ~= 0 && abs(S.mean_coherence_org{iBlock}(f)) == 0
                    visualTrigger = options.trig.vis.startIti;
                end                
            end
        end

        if f == session.vPar.nFramesPerBlock && doEEG
            visualTrigger = options.trig.blockEnd;
        end

        %% FRAMES AND TRIALS
        S.f{iBlock}(f) = f;
        
        % Is a trial starting with this frame?
        % trial start counter needed for feedback to know in which coherent
        % motion period (i.e. trial) we are in; also sends EEG triggers
        % corresponding to current trial coherence
        if abs(meanCohPerFrame(f)) > 0 && abs(meanCohPerFrame(f-1)) == 0
            % trial counter only updates if current frame is > 0 coherence
            % (i.e. trial) and last frame was exactly 0 (i.e. ITI)
            iTrial = iTrial+1;
            % set starting frame of trial to be current frame
            currentTrialStartFrame = f;
            % send EEG trigger that next coherent motion period is starting
            if doEEG
                % For setting the right trigger, we need the list of
                % possible trial coherences
                allTrialCoh = session.blocks(iBlock).trial.cohList;
                % Define the trigger relative to how many different
                % coherences we have, start with the highest coherence to
                % the left, add 10 to trigger value for every additional
                % coherence
                idxCohForTrigger = find(meanCohPerFrame(f) == allTrialCoh);
                visualTrigger = ...
                    options.trig.vis.trialStart.leftHighCoh ...
                    + 10 * idxCohForTrigger -10;               
%                switch meanCohPerFrame(f)
%                    case allTrialCoh(1)
%                        visualTrigger = options.trig.vis.trialStart.leftHighCoh;
%                    case allTrialCoh(2)
%                        visualTrigger = options.trig.vis.trialStart.leftMedCoh;
%                    case allTrialCoh(3)
%                        visualTrigger = options.trig.vis.trialStart.leftLowCoh;
%                    case allTrialCoh(4)
%                        visualTrigger = options.trig.vis.trialStart.rightLowCoh;
%                    case allTrialCoh(5)
%                        visualTrigger = options.trig.vis.trialStart.rightMedCoh;
%                    case allTrialCoh(6)
%                        visualTrigger = options.trig.vis.trialStart.rightHighCoh;
%                end
            end
        end

        %% REWARDBAR
        if options.doRewardbar
            % if updateReward = 1 update reward bar, because on last
            % frame a response occured or coherent motion period has been missed
            if updateRewardBar
                % update current points as we made a response or missed trial
                currentRewardBarPoints = currentRewardBarPoints + ...
                    respMat{iBlock}(respCounter-1, 1);

                % calculate (update) how far rewardbar is filled and how much
                % money participant has won up to here
                [centeredBarFrame, centeredRewardRect, centeredNewRewardRect, ...
                rewardText, currentRewardBarPoints, totalCoinsWon, ...
                currentRewardInfo] = crdm_moneybar(...
                respMat{iBlock}(respCounter-1,1), currentRewardBarPoints, ...
                totalCoinsWon, session.vPar.rewbarsize, ...
                options.reward.nPointsPerFill, options.reward.nCoinsPerFill, ...
                session.vPar.rewbarlocation);
            end
            
            % Draw inner reward bar (in red/green) which grows with points
            if currentRewardBarPoints > 0
                % currently more than 0 points in bar => green reward bar
                % grows to the right of the centre
                Screen('FillRect', tconst.win, session.vPar.col.green, centeredRewardRect);
            else
                % currently less than 0 points in bar => red reward bar
                % grows to the left of the centre
                Screen('FillRect', tconst.win, session.vPar.col.red, centeredRewardRect);
            end
            
            % Draw outer reward bar frame in black, this is constant
            Screen('FrameRect', tconst.win, session.vPar.col.black, centeredBarFrame, 4);
            % Display in word the overall amount of money won up until here
            DrawFormattedText(tconst.win, rewardText, session.vPar.centre(1) + ...
                round(session.vPar.rewbarsize(1)/2) + 30, session.vPar.rewbarlocation(2), 0);
            
            % if response occured recently, draw a white frame around the part 
            % of the reward bar that was recently gained
            if rewardCountdown >= session.vPar.rewardbartime
                rewardCountdown = rewardCountdown - 1;
                Screen('FillRect', tconst.win, session.vPar.col.white, centeredNewRewardRect);
                % if feedback is half way through, turn points won in trial
                % bar at end of reward par in respective colour
            elseif rewardCountdown < session.vPar.rewardbartime && rewardCountdown > 0
                rewardCountdown = rewardCountdown - 1;
                if respMat{iBlock}(respCounter-1, 1) >= 0 %
                    % Participant has recently gained points => green frame
                    Screen('FillRect', tconst.win, session.vPar.col.green, centeredNewRewardRect);
                else
                    % Participant has recently lost points => red frame
                    Screen('FillRect', tconst.win, session.vPar.col.red, centeredNewRewardRect);
                end
            end
        end

        %% SUBMIT DOT DRAWING INSTRUCTIONS TO PTB
        % This is where the drawing of the dots occurs (in these following
        % lines of code).
        
        % Draw rdk dots
        % Parsing the 'Screen()' function and its parameters:
        % NB. All the dots' positions (and on which frame) were already set
        % up earlier by init_stimulus, and saved in the S.xy matrix
        Screen('DrawDots', tconst.win, session.blocks(iBlock).stimulus.xy(:,:,f), ...
            session.vPar.dotdiameter, session.vPar.col.black, session.vPar.centre, ...
            options.vStim.dots.type);
        
        % draw annulus, if it's turned on
        if options.doAnnulus
            Screen('FillOval', tconst.win, session.vPar.col.grey, ...
                session.vPar.annulus_rect, session.vPar.annulus_diameter);
        end
        
        %% DETERMINE FIXATION DOT (COLOUR = FEEDBACK/TRIALS, SHAPE = CONDITION)
        % We use the colour of the fixation dot to: 
        % a) give participants feedback about their response
        % b) signal the coherent motion periods during training
        
        % Default colour is black
        fixColour = session.vPar.col.black;
        
        % Check whether we're currently in a feedback period
        if Fb.feedback_countdown > 0
            % Count down time in which feedback has been presented
            Fb.feedback_countdown = Fb.feedback_countdown -1; 
            % Choose the current feedback colour
            fixColour = Fb.colour;
        else 
            if options.doTraining && meanCohPerFrame(f) ~= 0
                % During training, we signal the trial periods (coherent
                % motion) to participants by colouring the fixation dot
                % white.
                fixColour = [0.8 0.8 0.8];
            end
        end

        % We (can) use the shape (and size) of the fixation dot to signal the 
        % current condition
        switch session.blocks(iBlock).fixDot.shape
            case 'S'
                % Square fix dot
                Screen('FillRect', tconst.win, fixColour, fixSize);
            case 'C'
                % Circle fix dot
                Screen('Drawdots', tconst.win, [0 0], fixSize, fixColour, ...
                    session.vPar.fixdotlocation, options.vStim.dots.type);
        end
        
        % Set appropriate alpha blending for correct anti-aliasing of dots
        Screen('BlendFunction', tconst.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        
        %% COUNT TRIALS
        if f > 1
            % Check whether a trial starts on this frame and save the start time
            if meanCohPerFrame(f-1) == 0 && abs(meanCohPerFrame(f)) ~= 0
                % this is defined by the previous trial heaving a mean 
                % coherence of 0 in contrast to the current
                tTrialStart = GetSecs; % the start time
                S.trialStarts{iBlock}(trialCounter, :) = [f, tTrialStart];
                trialCounter = trialCounter + 1;
            end
        end
        
        %% SOUND: START PLAYBACK AND/OR CHECK WHETHER WE'VE MOVED TO A NEW TONE
        if options.doTones
            if f == 1
                % Start playback of the tone sequence on first frame of
                % block
                audioStartTime(iBlock) = PsychPortAudio('Start', pahandle, [], 0, 0);
            end 
            % On later frames, check whether we have moved from silence to
            % tone or from tone to silence, and set the trigger accordingly
            auditoryStatus = PsychPortAudio('GetStatus', pahandle);
            statusSound(f).stats = auditoryStatus; 
            positionInSoundSchedule = auditoryStatus.SchedulePosition;
            if positionInSoundSchedule == lastPositionInSoundSchedule
                % If nothing has changed in the auditory domain, trigger is
                % zero
                auditoryTrigger = 0; 
            else
                if positionInSoundSchedule == (length(blockSequence)*2)
                    % If we're at the last position in our sequence,
                    % trigger is zero as well.
                    auditoryTrigger = 0; 
                    lastPositionInSoundSchedule = positionInSoundSchedule;
                else
                    % Trigger is non-zero if on this frame, the auditory
                    % input has changed.
                    auditoryTrigger = audTriggerList(positionInSoundSchedule + 1); 
                    lastPositionInSoundSchedule = positionInSoundSchedule;
                end 
            end 
        end        
        
        %% FLIP THE SCREEN: ACTUALLY SHOW EVERYTHING THAT WE'VE JUST DEFINED
        [vblTimeStamps(f), stimOnsetTimes(f), flipTime, missBeam(f)] = ...
            Screen('Flip', tconst.win, flipTime+(1-0.5) * tconst.flipint);
        flipTimes(f) = flipTime;


        %% RESPONSES: 1. Missed trial?
        % Check whether coherent motion stimulus has been missed only from the
        % frame on where frame number is greater than 1 trial length + flexible
        % feedback allowance (plus one because we haven't checked for
        % responses on the current frame yet)
        if f > session.vPar.flex_feedback+1
            if respCounter == 2
                % We're still at row 2 of this block's response matrix, which 
                % will hold the first response, meaning participants have not
                % emitted any response yet - so we don't need to take into
                % account the time between now and the last response.
                if f == currentTrialStartFrame + ...
                        session.blocks(iBlock).trial.length + ...
                        session.vPar.flex_feedback + 1 ...
                        && currentTrialStartFrame ~= 0 
                    % Current frame is the first frame after a recent
                    % trial start + a trial's length + the feedback
                    % allowance (+1 because we haven't checked for
                    % responses on this frame yet)
                    
                    % Fill response matrix with a miss
                    respMat{iBlock}(respCounter,1) = options.reward.points.miss;
                    respMat{iBlock}(respCounter,2) = NaN; % no reaction time
                    respMat{iBlock}(respCounter,3) = 2; % choice missed
                    respMat{iBlock}(respCounter,4) = meanCohPerFrame(currentTrialStartFrame); % coherence of missed coherent motion
                    respMat{iBlock}(respCounter,5) = 0; % choice incorrect
                    respMat{iBlock}(respCounter,6) = f; % frame it occured
                    respMat{iBlock}(respCounter,7) = 3; % missed coherent motion
                    
                    % Switch feedback on: set no of frames for which to show
                    % feedback & set the colour to signal a miss
                    Fb.feedback_countdown  = session.vPar.feedback_frames;
                    Fb.colour = session.vPar.col.blue;
                    
                    % Increase counter for row index into respMat
                    respCounter = respCounter + 1;
                    
                    if options.doRewardbar
                        rewardCountdown = 2 .* session.vPar.rewardbartime; % this is the
                        % time the "points won" bar at the edge of reward bar 
                        % is shown first in white and then in green and red for
                        % won and lost respectively (thus, we must double the
                        % variable, as both white and green/red should be shown
                        % for the same length of time)

                        missedFlag = 1;
                    end
                    
                    % Reset the trial start flag as we've accounted for
                    % this miss already.
                    currentTrialStartFrame = 0;
                    
                    if doEEG
                        % Send missed trial trigger
                        visualTrigger = options.trig.vis.miss;
                    end
                else
                    % On every other frame, we don't need to do anything,
                    % except resetting the missed trial flag
                    if options.doRewardbar
                        missedFlag = 0;
                    end
                end
            else
                % respCounter is above 2: we need to take into account the 
                % amount of time since last time response has been made
                if f == currentTrialStartFrame + ...
                        session.blocks(iBlock).trial.length + ...
                        session.vPar.flex_feedback + 1 ...
                        && currentTrialStartFrame ~= 0 ...
                        && (f - respMat{iBlock}(respCounter - 1, 6)) >= ...
                        session.blocks(iBlock).trial.length + ...
                        session.vPar.flex_feedback
                    % Current frame is the first frame after a recent
                    % trial start + a trial's length + the feedback
                    % allowance (+1 because we haven't checked for
                    % responses on this frame yet)
                    % AND the time between the current frame f and the last
                    % of the last response is greater than a trial's length
                    % and the feedback allowance - i.e., the previous
                    % response was not related to the current trial
                    
                    respMat{iBlock}(respCounter, 1) = options.reward.points.miss;
                    respMat{iBlock}(respCounter, 2) = NaN;
                    respMat{iBlock}(respCounter, 3) = 2;
                    respMat{iBlock}(respCounter, 4) = meanCohPerFrame(currentTrialStartFrame);
                    respMat{iBlock}(respCounter, 5) = 0;
                    respMat{iBlock}(respCounter, 6) = f;
                    respMat{iBlock}(respCounter, 7) = 3;
                    
                    % Switch on feedback
                    Fb.feedback_countdown = session.vPar.feedback_frames;
                    Fb.colour = session.vPar.col.blue;
                    
                    % Reset trial start flag - we've accounted for this one
                    currentTrialStartFrame = 0;
                    
                    % Increase counter for row index into respMat
                    respCounter = respCounter + 1;
                    
                    if options.doRewardbar
                        rewardCountdown = 2 .* session.vPar.rewardbartime; % this is the
                        % time the "points won" bar at the edge of reward bar 
                        % is shown first in white and then in green and red for
                        % won and lost respectively (thus, we must double the
                        % variable, as both white and green/red should be shown
                        % for the same length of time)

                        missedFlag = 1;
                    end
                    
                    if doEEG
                        visualTrigger = options.trig.vis.miss;
                    end
                else
                    % On every other frame (and if last reponse took care
                    % of this trial) we don't need to do anything, except
                    % resetting the missed trial flag
                    if options.doRewardbar
                        missedFlag = 0;
                    end
                end
            end
        end

        %% EVALUATE RESPONSES
        % Check for responses
        [keyIsDown, firstpress] = KbQueueCheck(deviceNumber);
        
        % If a key has been pressed, we need to add an entry to the response 
        % matrix and prepare display of feedback
        
        %%% PARTICIPANT PRESSED KEY -> CHECK FOR CORRECT/INCORRECT RESPONSE %%%
        if keyIsDown
            rts = GetSecs;
            % Check whether this button is a response key: left or right
            % key. If yes, check for coherence and determine what sort of
            % response (correct or incorrect) during incoherent motion it 
            % is; if another key has been pressed, save which key it was, 
            % on which frame it was pressed, and coherence level
            if Fb.feedback_countdown <= 0
                %%% IF PARTICIPANT PRESSED LEFT %%%
                if firstpress(leftKey) > 0
                    if options.doRewardbar
                        responseFlag = 1;
                        rewardCountdown = 2 .* session.vPar.rewardbartime;
                        % this is the time the "points won" bar at
                        % end of reward bar is shown first in white and then in green and red for won and lost
                        % respectively, this is why we have to double this variable, because we want bar in white
                        % and green/red to be displayed same amount of time
                    end
                    
                    Fb.feedback_countdown = session.vPar.feedback_frames; % amount feedback in form of changing fixdot is shown
                    
                    respMat{iBlock}(respCounter,2) = rts - tTrialStart; % rt 
                    % (Neb: response time? This is the difference between
                    % the time of pressing some key, and the time of the 
                    % first frame of the first coherent block)
                    respMat{iBlock}(respCounter,3) = 0; % choice - 0 left, 1 right
                    respMat{iBlock}(respCounter,4) = meanCohPerFrame(f); % coherence on trial
                    respMat{iBlock}(respCounter,6) = f; % frame on which button press occured
                    
                    if meanCohPerFrame(f) > 0 % INCORRECT (i.e. if mean coherence is > 0, then dots moving to RIGHT, so incorrect button has been pressed...)
                        respMat{iBlock}(respCounter,1) = options.reward.points.error; % points lost
                        respMat{iBlock}(respCounter,5) = 0; % choice correct = 1/incorrect = 0
                        respMat{iBlock}(respCounter,7) = 0; % error = 0, hit = 1, miss = 2, fa = 3 (or miss/fa other way round?)
                        
                        Fb.colour = session.vPar.col.red; % colour of FB (red, b/c incorrect choice)
                        
                        % FILL REMAINING TRIAL WITH NOISE
                        session.blocks(iBlock) = crdm_fill_trial_part_with_noise(f, session.blocks(iBlock), iTrial);
                        % Always keep this variable up-to-date
                        meanCohPerFrame = session.blocks(iBlock).coherences.meanCohPerFrame;
                        
                        respCounter = respCounter + 1; % increase counter for row in response matrix
                        
                        currentTrialStartFrame = 0;
                        
                        if  doEEG % send trigger if responded to coherent motion
                            visualTrigger = options.trig.vis.errorLeft; %S.trig.coherent_motion_fb_left;
                        end
                    elseif meanCohPerFrame(f) < 0 % CORRECT (mean coh < 0 so dots moving LEFT, so CORRECT key was pressed)
                        respMat{iBlock}(respCounter,1) = options.reward.points.hit; % points lost (Neb: Gained?)
                        respMat{iBlock}(respCounter,5) = 1; % choice correct = 1/incorrect = 0
                        respMat{iBlock}(respCounter,7) = 1;
                        
                        Fb.colour = session.vPar.col.green; % colour of FB (green, b/c correct choice)
                        
                        % FILL REMAINING TRIAL WITH NOISE
                        session.blocks(iBlock) = crdm_fill_trial_part_with_noise(f, session.blocks(iBlock), iTrial);
                        % Always keep this variable up-to-date
                        meanCohPerFrame = session.blocks(iBlock).coherences.meanCohPerFrame;
                        
                        respCounter = respCounter + 1; % increase counter for row in response matrix
                        
                        currentTrialStartFrame = 0;
                        
                        
                        if  doEEG % send trigger if responded to coherent motion
                            visualTrigger = options.trig.vis.hitLeft;
                        end
                    else %%% INCORRECT because WASN'T IN TRIAL (i.e. participant thought there was coherence, but there wasn't)
                        respMat{iBlock}(respCounter,1) = options.reward.points.fa; % points lost
                        respMat{iBlock}(respCounter,5) = 0; % choice correct = 1/incorrect = 0
                        respMat{iBlock}(respCounter,7) = 2;
                        
                        Fb.colour = session.vPar.col.yellow; % colour of FB (yellow, since participant wasn't in a trial)
                        respCounter = respCounter + 1; % increase counter for row in response matrix
                        
                        
                        if  doEEG % send trigger if responded to incoherent motion
                            visualTrigger =  options.trig.vis.falseAlarmLeft;
                        end
                    end % mean coherence > 0 for left key
                %%% OTHERWISE, IF PARTICIPANT PRESS RIGHT %%%
                elseif firstpress(rightKey) > 0
                    if options.doRewardbar
                        responseFlag = 1;
                        rewardCountdown = 2 .* session.vPar.rewardbartime; 
                        % this is the time the points won bar at
                        % end of reward bar is shown first in white and then in green and red for won and lost
                        % respectively, this is why we have to doulbe this variable, because we want bar in white
                        % and green/red to be displayed same amount of time                    
                    end
                    
                    Fb.feedback_countdown  = session.vPar.feedback_frames;% amount feedback in form of changing fixdot is shown
                    
                    respMat{iBlock}(respCounter,2) = rts - tTrialStart; % rt
                    respMat{iBlock}(respCounter,3) = 1; % choice - 0 left, 1 right
                    respMat{iBlock}(respCounter,4) = meanCohPerFrame(f); % coherence on trial
                    respMat{iBlock}(respCounter,6) = f; % frame on which button press occured

                    if meanCohPerFrame(f) > 0 % CORRECT response (mean coh > 0, so dots moving right)
                        respMat{iBlock}(respCounter,1) = options.reward.points.hit; % points lost
                        respMat{iBlock}(respCounter,5) = 1; % choice correct = 1/incorrect = 0
                        respMat{iBlock}(respCounter,7) = 1;
                        
                        Fb.colour = session.vPar.col.green; % colour of FB (green b/c correct)
                        
                        % FILL REMAINING TRIAL WITH NOISE
                        session.blocks(iBlock) = crdm_fill_trial_part_with_noise(f, session.blocks(iBlock), iTrial);
                        % Always keep this variable up-to-date
                        meanCohPerFrame = session.blocks(iBlock).coherences.meanCohPerFrame;
                        
                        respCounter = respCounter + 1; % increase counter for row in response matrix
                          currentTrialStartFrame = 0;
                        if  doEEG % send trigger if responded to coherent motion
                            visualTrigger =  options.trig.vis.hitRight;
                        end
                    elseif meanCohPerFrame(f) < 0 % INCORRECT response (mean coh < 0, so dots moving left)
                        respMat{iBlock}(respCounter,1) = options.reward.points.error; % points lost
                        respMat{iBlock}(respCounter,5) = 0; % choice correct = 1/incorrect = 0
                        respMat{iBlock}(respCounter,7) = 0;
                        
                        Fb.colour = session.vPar.col.red; % colour of FB (red b/c incorrect)
                        
                        % FILL REMAINING TRIAL WITH NOISE
                        session.blocks(iBlock) = crdm_fill_trial_part_with_noise(f, session.blocks(iBlock), iTrial);
                        % Always keep this variable up-to-date
                        meanCohPerFrame = session.blocks(iBlock).coherences.meanCohPerFrame;
                        
                        respCounter = respCounter + 1; % increase counter for row in response matrix
                        
                        currentTrialStartFrame = 0;

                        if  doEEG % send trigger if responded to coherent motion
                            visualTrigger = options.trig.vis.errorRight;
                        end
                    else % INCORRECT b/c WASN'T IN TRIAL 
                        respMat{iBlock}(respCounter,1) = options.reward.points.fa; % points lost
                        respMat{iBlock}(respCounter,5) = 0; % choice correct = 1/incorrect = 0
                        respMat{iBlock}(respCounter,7) = 2;
                        
                        Fb.colour = session.vPar.col.yellow; % colour of FB (yellow)
                        respCounter = respCounter + 1; % increase counter for row in response matrix
                        if  doEEG % send trigger if responded to incoherent motion
                            visualTrigger =  options.trig.vis.falseAlarmRight;
                        end
                    end
                else
                    %%% OTHERWISE, PARTICIPANT PRESSED ANOTHER KEY (other than
                    %%% designated left or right key)
                    if options.doRewardbar
                        responseFlag = 0;
                    end

                    % save which key has been pressed and in what frame
                    keyPress{keyCounter,1} = KbName(firstpress);
                    keyPress{keyCounter,2} = f;
                    keyPress{keyCounter,3} = meanCohPerFrame(f);
                    
                    keyCounter = keyCounter + 1;
                end
            else
                % Feedback countdown is not 0 => other button has been pressed 
                % before - only save which button has been pressed now
                if options.doRewardbar
                    responseFlag = 0;
                end
                
                % save which key has been pressed and in what frame
                keyPress{keyCounter,1} = KbName(firstpress);
                keyPress{keyCounter,2} = f;
                keyPress{keyCounter,3} = meanCohPerFrame(f);
                
                keyCounter = keyCounter + 1;
            end
        else
            % No key has been pressed on current frame
            if options.doRewardbar
                responseFlag = 0;
            end
        end
        
        % We need to update the reward bar in the next frame if we either
        % missed a trial or recorded a response
        if options.doRewardbar
            updateRewardBar = responseFlag || missedFlag;
        end
        
        %% ACTUALLY SEND THE TRIGGER FOR THIS FRAME
        if doEEG
            % If we're playing the MMN, combine triggers
            if options.doTones
                S.auditoryTriggers{iBlock}(f) = auditoryTrigger;
        
                combinedTrigger = visualTrigger + auditoryTrigger;
            else
                auditoryTrigger = 0;
                combinedTrigger = visualTrigger;
            end

            if doDebug
                % Paste trigger values into command window for debugging
                if combinedTrigger ~= 0
                    visualTrigger
                    auditoryTrigger
                    combinedTrigger
                end
            end
            
            % Send trigger
            %fwrite(handle, ['mh', combinedTrigger, 0]);
            %WaitSecs(0.002);
            %fwrite(handle, ['mh', 0, 0]);
    
            S.visualTriggers{iBlock}(f) = visualTrigger;
            S.combinedTriggers{iBlock}(f) = combinedTrigger;
        end

        %% COUNTING FRAMES
        f = f+1; % increase to next frame
        whileCalls = whileCalls + 1; % counter for while calls for displaying frames
        allWhileCalls(whileCalls) = toc(whileLoopTime); % timing time between while calls
        allFrames(whileCalls) = f; % saving frame from current while call
    end
    
    %% BLOCK ENDED, TELL PARTICIPANT TO TAKE A BREAK
    DrawFormattedText(tconst.win, options.instruct.afterBlockInfo, 'center', 'center', 0);
    Screen('Flip', tconst.win);
        
    %% BLOCK INFO TO SAVE
    % We will save some relevant session info here, and the respMat which
    % contains participants' behaviour.
    
    % block-wise info to save
    S.endBlockTime{iBlock}      = datetime;
    S.stimonsettimes{iBlock}    = stimOnsetTimes;
    S.missbeam{iBlock}          = missBeam;
    S.vblstamp{iBlock}          = vblTimeStamps;
    S.flipts{iBlock}            = flipTimes;
    S.while_calls{iBlock}       = whileCalls;
    S.all_while_calls{iBlock}   = allWhileCalls;
    S.all_frames{iBlock}        = allFrames;
    S.length_block{iBlock}      = toc(blockTime);
    S.keypress{iBlock}          = keyPress;
    if options.doTones
        S.audioStartTime{iBlock}= audioStartTime;
    end
    
    S.mean_coherence{iBlock}        = ...
        session.blocks(iBlock).coherences.meanCohPerFrame;
    S.coherence_frame{iBlock}       = ...
        session.blocks(iBlock).coherences.trialCohPerFrame;
    S.mean_coherence_orig{iBlock}   = ...
        session.blocks(iBlock).origCoherences.meanCohPerFrame;
    S.coherence_frame_orig{iBlock}  = ...
        session.blocks(iBlock).origCoherences.trialCohPerFrame;
    

    S.reward(iBlock).nTrials = iTrial;
    % total points possible to earn during last block
    S.reward(iBlock).total_possible_points = S.reward(iBlock).nTrials .* options.reward.points.hit;
    
    % indices to all correct button responses during coherent motion
    S.reward(iBlock).idx_correct = respMat{iBlock}(:,7) == 1;
    
    % index to incorrect button presses during coherent motion
    S.reward(iBlock).idx_incorrect = respMat{iBlock}(:,7) == 0;
    
    % index to button presses during incoherent motion
    S.reward(iBlock).idx_false = respMat{iBlock}(:,7) == 2;
    
    % index to missed coherent motion epochs
    S.reward(iBlock).idx_miss = respMat{iBlock}(:,7) == 3;
    
    % total points won during last block
    S.reward(iBlock).points_won_correct_incorrect = ...
        sum(respMat{iBlock}(~isnan(respMat{iBlock}(:,1)), 1));
    
    % total coins earned in block including misses and false resp
    S.reward(iBlock).total_coins_earned = totalCoinsWon;
    
    disp('Total coins earned up to here:')
    disp(num2str(totalCoinsWon));
    
    %% SAVE ALL BLOCK INFO    
    if options.doRewardbar
        % Save info about reward for next session
        rewardInfo(1,:) = currentRewardInfo;
        save(rewardInfoFile, 'rewardInfo');
    end
    resultsFile = [basePath sprintf('sess%03.0f_block%03.0f_results.mat', ...
        session.sessionID, iBlock)];
    save(resultsFile, 'respMat', 'S');

    % Only after we've saved this block's data, we let the participant
    % decide when they want to continue with the next block (or that the
    % session is complete).
    pause(20);
    if iBlock < session.nBlocks
        text = 'Press any key to continue to the next block.';
    else
        text = 'You are done with this session!\n\nPress any key to exit.';
    end

    DrawFormattedText(tconst.win, text, 'center', 'center', 0);
    Screen('Flip', tconst.win);
    
    KbStrokeWait(deviceNumber);
    
    % Display reward bar for next block
    if options.doRewardbar
        Screen('FrameRect',tconst.win,session.vPar.col.black, centeredBarFrame, 4);
        DrawFormattedText(tconst.win, rewardText, ...
           session.vPar.centre(1) + round(session.vPar.rewbarsize(1)/2) +30, ...
           session.vPar.rewbarlocation(2), 0);

        if currentRewardBarPoints > 0 
            Screen('FillRect', tconst.win, session.vPar.col.green, centeredRewardRect);
        else 
            Screen('FillRect', tconst.win, session.vPar.col.red, centeredRewardRect);
        end 
    end
    
    ListenChar(0);
    
end 

%% END OF SESSION: CLEAN UP
if doEEG
    %fclose(handle);
end
    
% delete all keyboard presses
KbQueueStop(deviceNumber);
% close PTB window
sca;

if options.doTones
    %% STOP AUDIO
    PsychPortAudio('Stop', pahandle, 1, 1);
    PsychPortAudio('Close', pahandle);
end
end