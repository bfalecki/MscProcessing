function [slow_time, fast_time_idx_start] = drGetSlowTime(RT,range, range_ax)
%DRGETSLOWTIME extract slow time signal on a specific range cell
    if(isscalar(range))
        [~, fast_time_idx_start] = min(abs(range_ax - range));
        slow_time  = RT(fast_time_idx_start,:);
    else
        start_range = range(1);
        stop_range = range(2);
        [~, fast_time_idx_start] = min(abs(range_ax - start_range));
        [~, fast_time_idx_stop] = min(abs(range_ax - stop_range));
        slow_time  = RT(fast_time_idx_start:fast_time_idx_stop,:);
    end

end

