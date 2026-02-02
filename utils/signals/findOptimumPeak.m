function [selected_peaks,selected_locs, upper_locs, lower_locs] = findOptimumPeak(matrix,distance, distTolerance)
%FINDOPTIMUMPEAK This function finds a set of three peaks spaced a specified 
% distance apart with a certain tolerance distTolerance and selects the middle peak. 
% When there are no three peaks spaced this distance, 
% the function finds a pair of peaks (spaced this distance)
% and selects the first one.
% The condition for detection is that at least one peak from a pair or
% triplet must be at least the second maximum peak in the entire vector.
% If there is no such triplet or pair, the function chooses the highest peak.


% example
% matrix =   [0,0,0; 
%             1 2 3; 
%             0,0,0; 
%             100 200 300 ;
%             0.1 0.2 0.3;
%             0,0,0; 
%             0.01, 0.02, 0.03;
%             0 0 0];
% matrix = [1 1 6 1 1  2  1 1 1 1 3 1 1 1 1 1 4 1 1 1 1 5  1 1 1 1 1 1 1 1 4 1 1 1 1 1 1 1 ; % find triple
%           1 1 6 1 1  2  1 1 1 1 3 1 1 1 1 1 4 1 1 1 1 5  1 1 1 1 1 1 1 1 4 1 1 1 1 1 1 1].';
% matrix = [0 0 0 0 0 1 2 3 4].'; % not found peaks
% matrix = [0 0 0 1 0 0 0 0].'; % 1 peak found
% matrix = [0 0 0 1 0 0 1 0].'; % 2 peaks found
% matrix = [0 0 0 4 0 0 2 0 0 0 0 0 0 3 0].'; % 3 peaks found
% matrix =  [1 1 1 1 1  2  1 1 1 1 3 1 1 1 1 1 1 1 1 1 1 1  1 1 1 1 1 1 1 1 4 1 1 1 1 1 1 1].'; % find 1 pair
% matrix = [1 1 1 1 1  2  1 1 1 1 3 1 1 1 1 1 1 1 1 1 1 1  1 1 1 2 1 1 1 1 4 1 1 1 1 1 1 1].'; % find 2 indep pair
% matrix = [1 1 1 1 1  2  1 1 1 1 3 1 1 1 1 1 4 1 1 1 1 1  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1].'; % find 1 triple
% matrix = [1 1 1 1 1  2  1 1 1 1 3 1 1 1 1 1 4 1 1 1 1 1  1 1 1 1 1 1 1 1 1 1 3 1 1 1 1 3 1 1 1 1 1 4 1].'; % find 2 triples
% matrix = [1 1 1 1 1  2  1 1 1 1 3 1 1 1 1 1 4 1 1 1 1 1  1 1 1 1 1 1 1 1 1 1 5 1 5 1].'; % find 1 triple below thresh
% matrix = [1 1 1 1 1  2  1 1 1 1 3 1 1 1 1 1 1 1 1 4 1 1  1 1 2 1 1 1 1 1 1 1 5 1 5 1].'; % find 2 pairs below thresh
% matrix = [1 8 1 1 1 1 1 1  2  1 1  1 3 1 1 1 1 1 4 1 1 8 1 1  1 1 1 1 1 1 1 1 1 1 3 1 1 1 1 3 1 1 1 1 1 4 1].'; % find 2 triples below thresh
% matrix = [ 1 1 1  5 1 1 1 4 1 5 1 1 1 6 1].'; % 2 triples in one
% matrix = [ 1 1 1  4 1 5 1 1 1 5 1 1 1 1 1].'; % 2 pairs in one
% matrix = [1 0 1 0 1 01 01 010 10 0 10 0 010 0 0 100 0100 0 010 001 0 00 0101 01010 0 100 100 010 10 010 10 10 010 01 10010100 1010  010  01101010  01 01 01 10 101 01 01 10 10 01 01 01 0 0 0 101 01 01 101 0 01 ].';
%     % random dense values
% distance = 5;
% distTolerance = 1;


selected_peaks = zeros(1, size(matrix, 2));
selected_locs = zeros(1, size(matrix, 2));
upper_locs = zeros(1, size(matrix, 2));
lower_locs = zeros(1, size(matrix, 2));
for k = 1:size(matrix, 2)
    column = matrix(:,k);
    [peaks, locs] = findpeaks(column); % find all peaks

    if(isempty(locs))
        selected_peaks(k) = nan;
        selected_locs(k) = nan;
        upper_locs(k) = nan;
        lower_locs(k) = nan;
        continue
    elseif(isscalar(locs))
        selected_locs(k) = locs;
        upper_locs(k) = nan;
        lower_locs(k) = nan;
        selected_peaks(k) = column(selected_locs(k)); % assign peak value
        continue
    elseif(length(locs) >= 2)
        distance_matrix = locs - locs.';
        pairs = locs(getPairsIdxes(distance_matrix, distance, distTolerance)); % Nx2 matrix
        if(isvector(pairs))
            pairs = pairs.'; % transpose, case of only one pair
        end
        if(isempty(pairs)) % then get maximum peak - this block repeats once
            [~,greaterPeakPosition] = max(peaks);
            selected_locs(k) = locs(greaterPeakPosition);
            % since the exact distance pair is not found, we do not save
            % the second value
            upper_locs(k) = nan;
            lower_locs(k) = nan;
            selected_peaks(k) = column(selected_locs(k)); % assign peak value
            continue
        end
        pairsDoubleDistance = locs(getPairsIdxes(distance_matrix, 2*distance, distTolerance)); % THE SAME TOLERANCE, Nx2 matrix
        if(isvector(pairsDoubleDistance))
            pairsDoubleDistance = pairsDoubleDistance.'; % transpose if only one pair
        end


        % now we need to find triples
        triples = nan(size(pairsDoubleDistance,1),3);
        for l = 1:size(pairsDoubleDistance,1)
            pairs1xval1idxes = any(pairsDoubleDistance(l,1) == pairs,2);
            pairs1xval2idxes = any(pairsDoubleDistance(l,2) == pairs,2);
            potentialRelatedIdxes = pairs1xval1idxes | pairs1xval2idxes;
            if(sum(potentialRelatedIdxes) < 2) % we want at least 2 pairs
                continue
            end
            potentialRelatedPairs = pairs(potentialRelatedIdxes, :);
            % min - max constraint
            relatedPairsIdxes = all(potentialRelatedPairs >= min(pairsDoubleDistance(l,:)) & ...
                potentialRelatedPairs <= max(pairsDoubleDistance(l,:)), 2);
            if(sum(relatedPairsIdxes) < 2) % no 2 related pairs found
                continue
            end
            relatedPairs = potentialRelatedPairs(relatedPairsIdxes, :);
            relatedUniqueVals = unique(relatedPairs);
            if(length(relatedUniqueVals) > 2) % we need to consider separate triples
                % we have ambiguiti in triples, we need to find middle
                % values first, and add separate triples based on them

                min_val= min([pairsDoubleDistance(l,1), pairsDoubleDistance(l,2)]);
                max_val = max([pairsDoubleDistance(l,1), pairsDoubleDistance(l,2)]);
                possibleMidValues = relatedUniqueVals(relatedUniqueVals ~= min_val & relatedUniqueVals ~= max_val);
                triples(l, :) = [min_val possibleMidValues(1) max_val]; % add first triple
                for m = 2:length(possibleMidValues) % now we need to add these remaining triples to the end
                    triples(end+1, :) = [min_val possibleMidValues(m) max_val]; % add first triple
                end
            else
                relatedPairs = potentialRelatedPairs(relatedPairsIdxes, :);
                unique_vals =  unique(relatedPairs);
                triples(l, :) = unique_vals;
            end
        end
        triples = triples(~any(isnan(triples),2),:);

        

        twoHighestPeaks = maxk(peaks,2); % threshold after fusion of pairs
        threshold = twoHighestPeaks(end);
        columnValInTriples = column(triples);
        if(isvector(columnValInTriples))
            columnValInTriples = columnValInTriples.';
        end
        acceptedTriplesIdxes = any(columnValInTriples >= threshold,2);% accept only if pair or triple contains higher or equal val than second peak
        acceptedTriples = triples(acceptedTriplesIdxes, :);

        if(isempty(acceptedTriples)) % then select pairs
            pairs_values = column(pairs);
            if(isvector(pairs_values))
                pairs_values = pairs_values.';
            end
            acceptedPairsIdxes = any(pairs_values >= threshold,2); 
            if(length(acceptedPairsIdxes) ~= size(pairs,1))
                disp("error")
            end
            acceptedPairs = pairs(acceptedPairsIdxes, :);
            if(isempty(acceptedPairs)) % then select maximum value and continue
                [~,greaterPeakPosition] = max(peaks);
                selected_locs(k) = locs(greaterPeakPosition);
                % since the exact distance pair is not found, we do not save
                % the second value
                upper_locs(k) = nan;
                lower_locs(k) = nan;
                selected_peaks(k) = column(selected_locs(k)); % assign peak value
                continue
            end
            % select max pair, get lower peak and continue
            peaksOfPairs = column(acceptedPairs); % fix transposition (only if size(acceptedTriples,1) == 1)
            if(isvector(peaksOfPairs))
                peaksOfPairs = peaksOfPairs.';
            end
            pairComparisonFunction = sum(peaksOfPairs,2); % sum or max
            [~, maxPairIdx] = max(pairComparisonFunction); % max of vector
            maxPair = acceptedPairs(maxPairIdx, :);
            selected_locs(k) = min(maxPair);
            upper_locs(k) = max(maxPair);
            lower_locs(k) = nan;
            selected_peaks(k) = column(selected_locs(k)); % assign peak value
            continue
        end

        % select middle
        peaksOfTriples = column(acceptedTriples); % fix transposition (only if size(acceptedTriples,1) == 1)
        if(isvector(peaksOfTriples))
            peaksOfTriples = peaksOfTriples.';
        end
        tripleComparisonFunction = sum(peaksOfTriples,2); % sum or max
        % tripleComparisonFunction = -sum(acceptedTriples,2); % lowest triple (to elliminate harmonics ?)
        [~, maxTripleIdx] = max(tripleComparisonFunction); % max of vector
        maxTriple = acceptedTriples(maxTripleIdx, :);
        selected_locs(k) = median(maxTriple); % middle value
        upper_locs(k) = max(maxTriple); % higher value
        lower_locs(k) = min(maxTriple); % lower value
        selected_peaks(k) = column(selected_locs(k)); % assign peak value
    end
end

end

function pairsIdxes = getPairsIdxes(distance_matrix, distance, tolerance)
    exactDistancesFound = abs(distance_matrix - distance) <= tolerance;
    [locIdxs1,locIdxs2] = find(exactDistancesFound); % find i-j locs idxes
    pairsIdxes = [locIdxs1,locIdxs2];
end

