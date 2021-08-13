function blocks = crdm_define_conditions( conditionSequence, options )
%CRDM_DEFINE_CONDITIONS This function defines each condition used in the
%continuous random dot motion paradigm in one session. It takes in a
%sequence of conditions (a vector of integers) and defines all the settings
%that define each of these numbers. You can implement different versions of
%this and indicate in the main options which one you want to use.

switch options.design.designLabel
    case 'coherence variance'
        % condition 1: variance is low, condition 2: variance is high
        for iBlock = 1: numel(conditionSequence)
            switch conditionSequence(iBlock)
                case 1
                    blocks(iBlock).condition        = 1;
                    blocks(iBlock).conditionLabel   = 'lowVar';
                    blocks(iBlock).instruct.text    = 'Variance is low.';
                    blocks(iBlock).iti.sd           = 0.2;
                    blocks(iBlock).trial.sd         = 0.2;
                    blocks(iBlock).trial.cohList    = [-0.2 -0.1 0.1 0.2];

                case 2
                    blocks(iBlock).condition        = 2;
                    blocks(iBlock).conditionLabel   = 'highVar';
                    blocks(iBlock).instruct.text    = 'Variance is high.';
                    blocks(iBlock).iti.sd           = 0.5;
                    blocks(iBlock).trial.sd         = 0.5;
                    blocks(iBlock).trial.cohList    = [-0.3 -0.2 0.2 0.3];
            end

            % condition-independent settings
            blocks(iBlock).iti.minSec       = options.design.iti.minSec; % use 1.5
            blocks(iBlock).iti.maxSec       = options.design.iti.maxSec; % use 15
            blocks(iBlock).iti.meanSec      = options.design.iti.meanSec; % use 5
            blocks(iBlock).trial.lengthSec  = options.design.trial.duration; % use 4
            % make these block-specific if you want to signal the current
            % condition by the size/shape of the fixation dot:
            blocks(iBlock).fixDot.sizeDeg   = options.vStim.fixSize(1);
            blocks(iBlock).fixDot.shape     = 'C'; % circle (C) vs. square (S)
        end
        
    case 'trial frequency'
        % condition 1: trials are rare, condition 2: trials are frequent
        for iBlock = 1: numel(conditionSequence)
            switch conditionSequence(iBlock)
                case 1
                    blocks(iBlock).condition        = 1;
                    blocks(iBlock).conditionLabel   = 'rare';
                    blocks(iBlock).iti.minSec       = 5; 
                    blocks(iBlock).iti.maxSec       = 25;
                    blocks(iBlock).iti.meanSec      = 15;
                    blocks(iBlock).instruct.text    = 'Trials are rare.';

                case 2
                    blocks(iBlock).condition        = 2;
                    blocks(iBlock).conditionLabel   = 'frequent';
                    blocks(iBlock).iti.minSec       = 1.5;
                    blocks(iBlock).iti.maxSec       = 10;
                    blocks(iBlock).iti.meanSec      = 5;
                    blocks(iBlock).instruct.text    = 'Trials are frequent.';

            end

            % condition-independent settings
            blocks(iBlock).iti.sd           = options.design.iti.sd; % use 0.5
            blocks(iBlock).trial.lengthSec  = options.design.trial.duration; % use 4
            blocks(iBlock).trial.cohList    = options.design.trial.cohList; % use [-0.5 -0.4 -0.3 0.3 0.4 0.5]
            blocks(iBlock).trial.sd         = options.design.trial.sd; % use 0.3
            % make these block-specific if you want to signal the current
            % condition by the size/shape of the fixation dot:
            blocks(iBlock).fixDot.sizeDeg   = options.vStim.fixSize(1);
            blocks(iBlock).fixDot.shape     = 'C'; % circle (C) vs. square (S)
        end
    case 'trial length'
        % condition 1: trials are short (and strong), condition 2: trials
        % are long (and weak)
        for iBlock = 1: numel(conditionSequence)
            switch conditionSequence(iBlock)
                case 1
                    blocks(iBlock).condition        = 1;
                    blocks(iBlock).conditionLabel   = 'short';
                    blocks(iBlock).instruct.text    = 'Trials are short.';
                    blocks(iBlock).trial.lengthSec  = 2.5;
                    blocks(iBlock).trial.cohList    = [-0.6 -0.5 -0.4 0.4 0.5 0.6];

                case 2
                    blocks(iBlock).condition        = 2;
                    blocks(iBlock).conditionLabel   = 'long';
                    blocks(iBlock).instruct.text    = 'Trials are long.';
                    blocks(iBlock).trial.lengthSec  = 6;
                    blocks(iBlock).trial.cohList    = [-0.4 -0.3 -0.2 0.2 0.3 0.4];
            end

            % condition-independent settings
            blocks(iBlock).iti.sd           = options.design.iti.sd; % use 0.5
            blocks(iBlock).iti.minSec       = options.design.iti.minSec; % use 1.5
            blocks(iBlock).iti.maxSec       = options.design.iti.maxSec; % use 15
            blocks(iBlock).iti.meanSec      = options.design.iti.meanSec; % use 5
            blocks(iBlock).trial.sd         = options.design.trial.sd; % use 0.3
            % make these block-specific if you want to signal the current
            % condition by the size/shape of the fixation dot:
            blocks(iBlock).fixDot.sizeDeg   = options.vStim.fixSize(1);
            blocks(iBlock).fixDot.shape     = 'C'; % circle (C) vs. square (S)
        end
end
