function [slowTimeSignal] = rtm2sts(rangeTimeMap, rangeCell)
% range time map to slow time signal (extraction)
% input: rangeTimeMap: instance of RangeTimeMap
        % rangeCell: scalar, range cell [m]

% % example
% rangeTimeMap = RangeTimeMap([],[],[],SignalInfo("carrierFrequency",[],"device","phaser","PRF",133));

% if the recording is from phaser, then create SlowTimeSignalPhaser
% instance, else create normal SlowTimeSignal instance
if(strcmp(rangeTimeMap.signalInfo.device, "phaser"))
    slowTimeSignal = SlowTimeSignalPhaser();
else
    slowTimeSignal = SlowTimeSignal();
end

% extract slow time signal
[slow_time, range_cell_no, rangeCellsMeters] = drGetSlowTime(rangeTimeMap.data, rangeCell, rangeTimeMap.rangeAxis);

if(strcmp(rangeTimeMap.signalInfo.device,"phaser"))
    [slow_time, timeLags, segmentDuration, start_samples, end_samples] = ...
    fill_signal_gaps(slow_time, rangeTimeMap.signalInfo.frameStartTimes, rangeTimeMap.signalInfo.PRF);
    slowTimeSignal.initializePhaserRelated( ...
        "segmentEndIndices",end_samples, ...
        "segmentStartIndices",start_samples, ...
        "segmentDuration", segmentDuration);
end

% initialize variable
slowTimeSignal.initialize( ...
    "signalInfo",rangeTimeMap.signalInfo, ...
    "desiredRangeCellMeters",rangeCell, ...
    "rangeCellNumber",range_cell_no, ...
    "actualRangeCellsMeters", rangeCellsMeters);

slowTimeSignal.setSignal(slow_time);

end

