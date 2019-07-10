classdef InputOutputData < handle
    properties
        YXEPG
        Blazers
        BaseRange
        ExtendedRange
        BaseRangeColumns
        MaxShift
        TimeTrend
        NumOfDummyPeriods
        InxOfInitInPresample
        MixinUnanticipated
        TimeFrames
        TimeFrameDates
        Success
        ExitFlags = solver.ExitFlag.empty(1, 0)
        DiscrepancyTables = cell.empty(1, 0)
        Method = solver.Method.empty(1, 0) 
        Deviation = logical.empty(1, 0)
        NeedsEvalTrends = logical.empty(1, 0)
        PrepareOutputInfo = false
        Plan = Plan.empty(0)


        % __Options Copied over From Input Parser__


        % Solver  Solver options
        Solver = solver.Options.empty(0)

        % Window  Minimum lengths of time frame required
        Window = @auto

        % SuccessOnly  Stop simulation if a time frame fails
        SuccessOnly = false

        % Store shocks in sparse arrays
        SparseShocks = false

        % Initial  Choose input data or first-order simulation for starting values
        Initial = 'Data'
    end


    properties (Dependent)
        NumOfPages
    end


    methods
        function n = get.NumOfPages(this)
            n = size(this.YXEPG, 3);
        end%
    end
end

