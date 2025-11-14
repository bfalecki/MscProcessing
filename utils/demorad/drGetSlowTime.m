function [slow_time] = drGetSlowTime(RT,range, range_ax)
%DRGETSLOWTIME extract slow time signal on a specific range cell
    [~, fast_time_idx] = min(abs(range_ax - range));
    slow_time  = RT(fast_time_idx,:);

end

