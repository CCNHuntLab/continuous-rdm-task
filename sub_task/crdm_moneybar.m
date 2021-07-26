function [ centeredBarFrame, centeredRewardRect, centeredNewRewardRect, ...
    rewardText, currentBarPoints, totalCoinsWon, rewardCount ] ...
    = crdm_moneybar( newlyWonPoints, currentBarPoints, totalCoinsWon, ...
    totalBarSize, nPointsPerFill, nCoinsPerFill, rewardBarLocation )
    
%totalCoinsWon, rewardText, centeredRewardRect, centeredBarFrame, ...
%    centeredNewRewardRect, currentBarPoints, rewardCount] = crdm_moneybar(...
%    totalCoinsWon, totalBarSize, currentBarPoints, nPointsPerBarFill, ...
%    newlyWonPoints, rewardBarLocation, nCoinsPerBarFill )
%CRDM_MONEYBAR Calculates current reward bar size and overall cumulative
%monetary reward based on previous reward and newly won points. Outputs the
%dimensions needed to display the updated reward bar, and the updated
%overall reward of the participant.

% The bar is totalBarSize pixels long. We always start to fill it in the
% centre. Rightwards fill indicates that participants have earned points,
% a leftwards one means they have lost points. Therefore, participants have to 
% fill half a reward bar (corresponding to nPointsPerBarFill points) to earn 
% a predefined unit of money (corresponding to nCoinsPerBarFill). The
% relevant reward parameters are set in options.reward, and the bar size
% and position are set in options.reward.bar.

% Whenever the reward bar is filled, it is 'reset' to start again, but carries 
% over any "spillover" amount of points from filling the reward bar too much in 
% the previous trial. This is saved in the variable currentBarPoints (which
% is also carried across sessions).

% CurrentBarPoints gets updated each time the particpant makes a response 
% (outside of this function), and determines how far the bar is filled by 
% calculating to what fraction of nPointsPerFill the currentBarPoints
% correspond. For a predefined number of frames, the newly won or lost points
% after a response are signaled by a white frame around the portion of the
% reward that is new. After these frames have passed, the colour of this
% frame tuns to green/red so that it blends in with the overall reward bar.
% If the bar is full, currentBarPoints starts at 0 (plus any spillover) again.

% Steps performed by this function:
% 1. determine current fill level of the bar according to currentBarPoints
% 2. check whether bar needs to be reset, if yes, add the earned coins to
% totalCoinsWon and reset currentBarPoints to 0 plus spillover
% 3. calculate the rectangles that will make up the new bar

% Input: 
%   newlyWonPoints      = points gained/lost by most recent response
%   currentBarPoints    = current fill level of reward bar (in points)
%   totalCoinsWon       = overall cumulative reward of participant
%   totalBarSize        = size of the full reward bar in pixels
%   nPointsPerFill      = how many points correspond to 1/2 of bar size
%   nCoinsPerFill       = how much money participant earns per bar fill
%   rewardBarLocation   = coordinates of the bar on screen (centre x, y)

% Output:
%   centeredBarFrame    = coordinates for PTB to draw frame of bar on right
%                       location and in correct size
%   centeredRewardRect  = coordinates of coloured reward bar within the
%                       frame
%   centeredNewRewardRect = coordinates of that part of the rewardRect that
%                       corresponds to the most recently won points
%   rewardText          = string: amount of money won up until this point for
%   currentBarPoints    = current fill level of reward bar (only updated to
%                       input if reward bar was reset)
%   totalCoinsWon       = updated total cumulative reward of participant
%   rewardCount         = variable to save currentBarPoints and
%                       totalCoinsWon across sessions


% 1. Calculate new length of filled reward bar
barSize = abs( (currentBarPoints / nPointsPerFill) .* (totalBarSize(1) / 2) );

% 2. Check whether bar is filled and needs to be reset
if barSize >= (totalBarSize(1) / 2) % in case reward bar is full 
    % 2a) add reward amount of money
    if currentBarPoints < 0
    	totalCoinsWon = totalCoinsWon - nCoinsPerFill; 
    else
        totalCoinsWon = totalCoinsWon + nCoinsPerFill;
    end 
    % 2b) reset bar size to only spillover after filling...
    barSize = abs(barSize - (totalBarSize(1)/2));
    % ... and reset the bar fill in points accordingly 
    currentBarPoints = (barSize / (totalBarSize(1)/2) ) * nPointsPerFill;
    
    if isnan(currentBarPoints)
        currentBarPoints = 0; % set it to 0 if it becomes NaN (plaster)
        disp('currentBarPoints was NaN, set to 0');
    elseif isnan(totalCoinsWon)
        totalCoinsWon = 0; % set it to 0 if it becomes NaN (plaster)
        disp('totalCoinsWon was NaN, set to 0');
    end
end

% 3. Update dimensions of the rectangles and text to be presented

% 3a) display amount of coins already earned 
rewardText = ['+', num2str(totalCoinsWon), ' �'];

% 3b) Calculate sizes of rectangles
% Outer rectangle in black: frameRect
frameRect = [0 0 totalBarSize(1) totalBarSize(2)];

% Inner rectangle in green/red: rewardRect - signals current points
rewardRect = [0 0 barSize totalBarSize(2)]; % defines how much of bar is filled

% Frame around new part of rewardRect in white (if new) or green/red -
% signals how much the rewardRect grew by the newly earned points
newRewardSize = (newlyWonPoints / nPointsPerFill) .* (totalBarSize(1) / 2);
newRewardRect =  [0 0 abs(newRewardSize) totalBarSize(2)];

% 3c) Calculate the centered rectangles to present

% Outer black frame
centeredBarFrame = ...
    CenterRectOnPointd(frameRect, rewardBarLocation(1), rewardBarLocation(2));

% Inner rectangles: depends on win/loss
if currentBarPoints >= 0
    % Participant has > 0 points: grow to the right
    % Centre of reward rect must be on right side of centre of overall bar
    centeredRewardRect = CenterRectOnPointd(rewardRect, ...
        rewardBarLocation(1) + (1/2.*abs(barSize)), rewardBarLocation(2));
    % Centre of new reward rect must be half of its size away from right end of
    % overall reward rect (to be part of the overall reward rect)
    centeredNewRewardRect = CenterRectOnPointd(newRewardRect, ...
        rewardBarLocation(1) + (abs(barSize)) - ((1/2).* newRewardSize), ...
        rewardBarLocation(2));
else
    % Participant has < 0 points: grow to the left
    % Centre of reward rect must be on left side of centre of overall bar
    centeredRewardRect = CenterRectOnPointd(rewardRect, ...
        rewardBarLocation(1) - (1/2.*abs(barSize)), rewardBarLocation(2));
    % Centre of new reward rect must be half of its size away from left end
    % of overall reward rect (to be part of the overall reward rect)
    centeredNewRewardRect = CenterRectOnPointd(newRewardRect, ...
        rewardBarLocation(1) - abs(barSize) - (1/2.* newRewardSize), ...
        rewardBarLocation(2));
end

% 4. Save the currentBarPoints and overall monetary reward together in a
% variable so we can carry this information over to the next session if
% necessary
rewardCount = [currentBarPoints totalCoinsWon];

end