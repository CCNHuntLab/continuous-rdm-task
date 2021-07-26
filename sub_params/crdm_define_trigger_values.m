function trig = crdm_define_trigger_values
%CRDM_DEFINE_TRIGGER_VALUES Sets all trigger values that are being sent in
%the combined auditory MMN and continuous random dot motion (crdm)
%paradigm. Note that the auditory trigger values will be added onto the
%current visual task trigger, resulting in a combined trigger value that
%appears on every frame in the EEG.
% For book keeping, all relevant trigger values (auditory, visual, and
% combined) are additionally saved in a Matlab struct per frame. This
% allows 1) comparison with what was recorded in the EEG - sometimes
% triggers get lost, and 2) to work out, in case of ambigious combined trigger 
% values, which auditory and visual events were being marked in this frame.

% In the absence of a noteworthy event
trig.holdValue = 0;

% Frames, blocks, and seconds/minutes
trig.blockStart = 10;
trig.blockEnd   = 200; %59;

% Visual task triggers
trig.vis.cohJump    = 20; %24;
trig.vis.startIti   = 30; %23;

trig.vis.trialStart.leftHighCoh = 40; %35;
trig.vis.trialStart.leftMedCoh = 50; %34;
trig.vis.trialStart.leftLowCoh = 60; %33;
trig.vis.trialStart.rightLowCoh = 70; %30;
trig.vis.trialStart.rightMedCoh = 80; %40;
trig.vis.trialStart.rightHighCoh = 90; %50;

trig.vis.miss           = 100; %53;
trig.vis.hitLeft        = 110; %55;
trig.vis.hitRight       = 120; %51;
trig.vis.errorLeft      = 130; %55;
trig.vis.errorRight     = 140; %51;
trig.vis.falseAlarmLeft = 150; %56;
trig.vis.falseAlarmRight= 160; %52;


% Auditory triggers - these will be added to the visual ones
trig.aud.silence    = 1;
trig.aud.deviant    = 2;
trig.aud.standard   = 3;

% Auditory trigger values - I think this is outdated, from Layla's code
%parameters.tone_A_trigger = 52;
%parameters.tone_B_trigger = 53;
%parameters.silence = 54; 
%parameters.start_trigger = 180;
%parameters.end_trigger = 230; 

   
% Trigger values as used by Maria
% S.trig.coherent_motion_fb_right = 201; % trigger that gets send everytime person hits right button during coherent motion
% S.trig.coherent_motion_fb_left = 205; % same, but for left
% S.trig.coherent_motion_missed = 203; % every time person missed response to coherent motion
% S.trig.resp_incoherent_motion_right = 202;% every time person pressed right button during incoherent motion
% S.trig.resp_incoherent_motion_left = 206; % Neb: same as above, but for left?
% S.trig.trigger_per_10_secs = 11;% trigger for counting minutes and 10seconds of time passed
% S.trig.last_frame = 210; % trigger send on last frame
% S.trig.trigger_min = 12;% for updating trigger code every time minute is
% S.trig.incoh_motion = 23; % trigger for onset of incoherent motion
% % full, full minute is a value between 11 and 19 that gets updated every
% % time a minute is hit, for 10seconds it is a 3 digit code starting at 102
% S.trig.jump = 24;
% % initialise counter for sending a trigger every S.trig_thresh jump
% trig_num = 0; 
    
% Trigger values as used by Layla (in combo with MMN)
%trig.coherent_motion_fb_right = 51; % trigger that gets send everytime person hits right button during coherent motion
%trig.coherent_motion_fb_left = 55; % same, but for left
%trig.coherent_motion_missed = 53; % every time person missed response to coherent motion
%trig.resp_incoherent_motion_right = 52;% every time person pressed right button during incoherent motion
%trig.resp_incoherent_motion_left = 56; % Neb: same as above, but for left?
%trig.trigger_per_10_secs = 11;% trigger for counting minutes and 10seconds of time passed
%trig.last_frame = 59; % trigger send on last frame
%trig.trigger_min = 12;% for updating trigger code every time minute is
%trig.incoh_motion = 23; % trigger for onset of incoherent motion
% full, full minute is a value between 11 and 19 that gets updated every
% time a minute is hit, for 10seconds it is a 3 digit code starting at 102
%trig.jump = 24;
end