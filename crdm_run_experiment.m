%%% All steps needed to run 1 session of the continuous random dot motion
%%% task with auditory paradigm in the background

%% Define local path and session info
% Set the path to where we want to save behavioural data and stimuli. This
% should ideally be separate from the code
dataRoot = fullfile(fileparts(mfilename('fullpath')), 'data');
if ~exist(dataRoot, 'dir')
    mkdir(dataRoot);
end

% Define the subject ID, session number, and datetime
promptID = 'Please enter subject ID (e.g., 66).\n\n    '; 
subjID = input(promptID);
subjRoot = fullfile(dataRoot, sprintf('sub%03.0f', subjID));
if ~exist(subjRoot, 'dir')
    mkdir(subjRoot)
end

promptSession = 'Please enter this session''s number (e.g., 2).\n\n    '; 
sessID = input(promptSession);
sessionFile = fullfile(subjRoot, ...
    sprintf('sub%03.0f_sess%03.0f_stimuli.mat', subjID, sessID));

timeStamp = datetime;

%% Create or load the stimulus for this session
promptCreateSess = ['Do you need to create stimuli for this session?\n' ...
    'Enter 1 to create new stimuli or 0 for loading an existing session.\n\n    '];
createSession = input(promptCreateSess);

promptDebug = ['Will you run the task in debug mode?\n' ... 
    ' (0 = no (fullscreen), 1 = yes (debug window), \n' ...
    '  2 = Mac fullscreen,  3 = Mac debug window)) \n\n    '];
debugMode = input(promptDebug);
    
if createSession    
    promptSequence = ['Enter the order of conditions to use.\n' ...
        '  For example: [1 2 1 2] (include the brackets)\n\n    '];
    condSeq = input(promptSequence);
    % Create a new session based on the settings in crdm_set_task_options.m
    [session, options] = crdm_create_session(debugMode, condSeq);
else
    % Load the session that you previously saved for this subject & session
    % number
    load(sessionFile, 'session', 'options');
end

% Add some pre-programmed tone sequences to this session
promptTones = 'Do you want to add a pre-existing tone sequence? (1=yes, 0=no)\n\n    ';
addTones = input(promptTones);
if addTones
    session = crdm_add_existing_tone_sequence(session);
end

% Save the session in the subject folder
save(sessionFile, 'session', 'options');


%% Run the task
promptRun = 'Do you want to run the task now? (1=yes, 0=no)?\n\n    ';
doTask = input(promptRun);

if doTask
    % Add subject/session info to existing experimental session
    session.subjectID = subjID;
    session.sessionID = sessID;
    session.timeStamp = datetime;

    % Reorder fields of session, so we have the new info on top
    nFields = numel(fieldnames(session));
    session = orderfields(session, [nFields-2 nFields-1 nFields 1:nFields-3]);
    
    % Save the session in the subject folder (including timeStamp to know when
    % it was played)
    save(sessionFile, 'session', 'options');

    % We specify the base path here for:
    % 1. saving this session's behavioural data after completion of session
    % 2. saving responses etc. after every block, in case the session does not 
    % run through all intended blocks, and 
    % 3. saving reward info that needs to be carried across sessions.
    basePath = fullfile(subjRoot, sprintf('sub%03.0f_', subjID));

    % If session runs through, we will save all results here
    resultsFile = [basePath sprintf('sess%03.0f_results.mat', sessID)];

    % Specify how we should run this session - with/out audio and EEG
    promptAudio = 'Do you want to play tones? (1=yes, 0=no)\n\n    ';
    options.doTones = input(promptAudio);
    
    promptEEG = 'Are you recording EEG? (1=yes, 0=no)\n\n    ';
    doEEG = input(promptEEG);
    
    % Actually run the task
    [S, respMat] = crdm_play_session(session, debugMode, doEEG, options, basePath);
    save(resultsFile, 'S', 'respMat');
end