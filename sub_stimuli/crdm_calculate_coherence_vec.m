function cohVec = crdm_calculate_coherence_vec( nFrames, meanDur, minDur, ...
    maxDur, meanCoh, sdCoh )
%CRDM_CALCULATE_COHERENCE_VEC This function generates a vector of coherences by
%drawing coherence values from a normal distribution and drawing the
%durations of each coherence value from a truncated exponential function.
%   IN:     nFrames     - total number of frames (length of vector) to fill
%           meanDur     - mean duration for exponential function
%           minDur      - minimum duration for truncating exp function
%           maxDur      - maximum duration for truncating exp function
%           meanCoh     - mean coherence for normal distribution
%           sdCoh       - standard deviation for normal distribution

%=== Draw durations from exponential distribution
iFrame = 0; 
durCount = 0;
while  iFrame < nFrames
    durCount = durCount + 1;
    % draw a new duration
    durations(durCount) = round(exprnd(meanDur));
    % truncate: only allow durations between minDur and maxDur
    while durations(durCount) < minDur || durations(durCount) > maxDur
        durations(durCount) = round(exprnd(meanDur));
    end
    % update t
    iFrame = iFrame + durations(durCount);
end

%=== Draw coherence values from normal distribution
cohVec = zeros(sum(durations), 1);
periodStart = 1;
for iFrame = 1 : length(durations)
    % draw a new coherence value
    cohValue =  sdCoh .* randn(1,1) + meanCoh;
    % fill all frames belonging to this period with this coherence
    % value
    cohVec(periodStart : periodStart + (durations(iFrame)-1)) ...
        = cohValue .* ones(durations(iFrame), 1);
    % start time of next period
    periodStart = periodStart + durations(iFrame);
end

% discard all coherences after last frame
cohVec = cohVec(1: nFrames);
end

