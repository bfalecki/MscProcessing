function slowTimePhase= sts2stp(slowTimeSignal,opts)
%STS2STP SlowTimeSignal to SlowTimePhase conversion

    arguments
        slowTimeSignal % SlowTimeSignal instance
        opts.method = "atan" % method
        opts.fixEdgesDepth = 0.1; % part of segment to fix last value on the segment edges
    end
    
    if(isa(slowTimeSignal,"SlowTimeSignalPhaser"))
        slowTimePhase = SlowTimePhasePhaser();
        slowTimePhase.initializePhaserRelated( ...
            "segmentEndIndices",slowTimeSignal.segmentEndIndices,...
            "segmentStartIndices",slowTimeSignal.segmentStartIndices, ...
            "segmentDuration",slowTimeSignal.segmentDuration);
    else
        slowTimePhase = SlowTimePhase();
    end

    slowTimePhase.initialize( ...
        "phaseDiscontinuitiesRemoved",slowTimeSignal.phaseDiscontinuitiesRemoved,...
        "desiredRangeCellMeters",slowTimeSignal.desiredRangeCellMeters,...
        "actualRangeCellsMeters",slowTimeSignal.actualRangeCellsMeters,...
        "rangeCellNumber",slowTimeSignal.rangeCellNumber,...
        "resamplingWasApplied",slowTimeSignal.resamplingWasApplied,...
        "signalInfo",slowTimeSignal.signalInfo);

    if(strcmp(slowTimeSignal.signalInfo.device, "phaser"))
        % a bit more complicated, we need to linearly interpolate to keep
        % phase offset
        phasesRaw = extractPhase(slowTimeSignal.signal, opts.method).';
        final_phases = zeros(size(phasesRaw));
        for k = 1:size(phasesRaw,1)
            % get rid of big first difference sample
            phaseRaw = phasesRaw(k, :);

            % after recent fix in fix_edges function, this function does
            % not change anything
            % phaseRaw = reset_accumulated_phase(phaseRaw, ...
            %     slowTimeSignal.segmentStartIndices, ...
            %     slowTimeSignal.segmentEndIndices);  % save this for further possible processing

            % differentiation
            phaseDiffRaw = compl_diff(diff(phaseRaw)); % save this for further possible processing
    
            phaseDiff = phaseDiffRaw;
            % fix segment edge noise (put mean values to every edge) - helpful for
            % further linear interpolation
            segmentDuration = mean(slowTimeSignal.segmentEndIndices - slowTimeSignal.segmentStartIndices) ...
                / slowTimeSignal.signalInfo.PRF;
            depth_samples = round(segmentDuration * opts.fixEdgesDepth * slowTimeSignal.signalInfo.PRF);
            depth_samples(depth_samples < 1) = 1;
            phaseDiff = fix_edges(phaseDiff, ...
                slowTimeSignal.segmentStartIndices, ...
                slowTimeSignal.segmentEndIndices, ...
                depth_samples);
            
            % place NaNs in breaks
            [phaseDiff, max_gap] = placeNans_RN(phaseDiff, ...
                slowTimeSignal.segmentStartIndices, ...
                slowTimeSignal.segmentEndIndices);
            
            % interpolate breaks
            phaseDiff = fillmissing(phaseDiff, 'linear', 'MaxGap',max_gap*2);
            
            % Restore zeroes in NaN samples
            phaseDiff(isnan(phaseDiff)) = 0;
            
            final_phase = cumsum(phaseDiff);
            final_phases(k,:) = final_phase;

        end
        % % in case of phaser signal, most often we have also some linear
        % % phase componenet which can be subtracted here
        % final_phases = subtractLinearComponent(final_phases.').';

        slowTimePhase.setPhase(final_phases);
        
    else
        slowTimePhase.setPhase( extractPhase(slowTimeSignal.signal, opts.method).' )
    end

end

