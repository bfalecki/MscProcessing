function [startIdxes, endIdxes] = logical2segmentIdxes(logicalSegmentIdxes)
%LOGICAL2SEGMENTIDXES This function converts logical segment idxes to
%segment idxes in integer values

% % example
% logicalSegmentIdxes = [1     0     0     1     1     0     0     0     0     1     1     1    ];

startIdxes = find(diff([0 logicalSegmentIdxes]) == 1);
endIdxes = find(diff([logicalSegmentIdxes 0]) == -1);

end

