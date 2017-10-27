function outputDatabank = run(varargin)
% run  Evaluate reporting equations (rpteq) object.
%
%
% __Syntax__
%
% Input arguments marked with a `~` sign may be omitted.
%
%     Outp = run(Q, Inp, Range, ~Model, ...)
%
%
% __Input arguments__
%
% * `Q` [ char ] - Reporting equations (rpteq) object.
%
% * `Inp` [ struct ] - Input database that will be used to evaluate the
% reporting equations.
%
% * `Dates` [ numeric | char ] - Dates at which the reporting equations
% will be evaluated; `Dates` does not need to be a continuous date range.
%
% * `~Model` [ model ] - Model object from which values will be substituted
% for steady-state references; if there are no steady-state references in
% reporting equations, this input argument may be omitted.
%
%
% __Output arguments__
%
% * `Outp` [ struct ] - Output database with reporting variables.
%
%
% __Options__
%
% * `'DbOverlay='` [ `true` | *`false`* | struct ] - If `true`, the LHS
% output data will be combined with data from the input database (or a
% user-supplied database).
%
% * `'Fresh='` [ `true` | *`false`* ] - If `true`, only the LHS reporting
% variables will be included in the output database, `Outp`; if `false` the
% output database will also include all entries from the input database, 
% `Inp`.
%
%
% __Description__
%
% Reporting equations are always evaluated non-simultaneously, i.e.
% equation by equation, for each period.
%
%
% __Example__
%
% Note the differences in the three output databases, `d1`, `d2`, `d3`, 
% depending on the options `AppendPresample=` and `Fresh=`.
%
%     >> q = rpteq({ ...
%         'a = c * a{-1}^0.8 * b{-1}^0.2;', ...
%         'b = sqrt(b{-1});', ...
%         })
% 
%     q =
%         rpteq object
%         number of equations: [2]
%         comment: ''
%         user data: empty
%         export files: [0]
%
%     >> d = struct( );
%     >> d.a = Series( );
%     >> d.b = Series( );
%     >> d.a(qq(2009, 4)) = 0.76;
%     >> d.b(qq(2009, 4)) = 0.88;
%     >> d.c = 10;
%     >> d
%
%     d = 
%         a: [1x1 tseries]
%         b: [1x1 tseries]
%         c: 10
%
%     >> d1 = run(q, d, qq(2010, 1):qq(2011, 4))
%
%     d1 = 
%         a: [8x1 tseries]
%         b: [8x1 tseries]
%         c: 10
%
%     >> d2 = run(q, d, qq(2010, 1):qq(2011, 4), 'AppendPresample=', true)
%
%     d2 = 
%         a: [9x1 tseries]
%         b: [9x1 tseries]
%         c: 10
%
%     >> d3 = run(q, d, qq(2010, 1):qq(2011, 4), 'Fresh=', true)
% 
%     d3 = 
%         a: [8x1 tseries]
%         b: [8x1 tseries]
% 

% -IRIS Macroeconomic Modeling Toolbox.
% -Copyright (c) 2007-2017 IRIS Solutions Team.

TIME_SERIES_CONSTRUCTOR = getappdata(0, 'IRIS_TimeSeriesConstructor');
TEMPLATE_SERIES = TIME_SERIES_CONSTRUCTOR( );

persistent INPUT_PARSER
if isempty(INPUT_PARSER)
    INPUT_PARSER = extend.InputParser('rpteq.run');
    INPUT_PARSER.addRequired('ReportingEquations', @(x) isa(x, 'rpteq'));
    INPUT_PARSER.addRequired('InputDatabank', @(x) isempty(x) || isstruct(x));
    INPUT_PARSER.addRequired('SimulationDates', @(x) isa(x, 'DateWrapper') || isnumeric(x));
    INPUT_PARSER.addOptional('Model', [ ], @(x) isempty(x) || isa(x, 'model'));
    INPUT_PARSER.addParameter('AppendPresample', false, @(x) isequal(x, true) || isequal(x, false) || isstruct(x));
    INPUT_PARSER.addParameter('DbOverlay', false, @(x) isequal(x, true) || isequal(x, false) || isstruct(x));
    INPUT_PARSER.addParameter('Fresh', false, @(x) isequal(x, true) || isequal(x, false));
end
INPUT_PARSER.parse(varargin{:});
this = INPUT_PARSER.Results.ReportingEquations;
inputDatabank = INPUT_PARSER.Results.InputDatabank;
dates = INPUT_PARSER.Results.SimulationDates;
m = INPUT_PARSER.Results.Model;
opt = INPUT_PARSER.Options;

%--------------------------------------------------------------------------

eqtn = this.EqtnRhs;
nEqtn = numel(eqtn);
nNameRhs = numel(this.NameRhs);
dates = dates(:).';
minDate = min(dates);
maxDate = max(dates);
maxSh = this.MaxSh;
minSh = this.MinSh;
xRange = minDate+minSh : maxDate+maxSh;
nXPer = numel(xRange);
isSteadyRef = ~isempty(this.NameSteadyRef) && isa(m, 'model');

D = struct( );
S = struct( );

% Convert tseries to arrays, remove time subscript placeholders # from
% non-tseries names. Pre-allocate LHS time series not supplied in input
% database.
chkRhsNames( );
preallocLhsNames( );
if isSteadyRef
    S = createSteadyRefDbase( );
end

eqtn = strrep(eqtn, '&?', 'S.');
eqtn = strrep(eqtn, '?', 'D.');
eqtn = regexprep(eqtn, '\{@(.*?)\}#', '(t$1, :)');
eqtn = strrep(eqtn, '#', '(t, :)');

fn = cell(1, nEqtn);
for i = 1 : nEqtn
    fn{i} = mosw.str2func(['@(D, t, S)', eqtn{i}]);
end

% Evaluate equations sequentially period by period.
runTime = dates-minDate+1 - minSh;
for t = runTime
    for iEq = 1 : nEqtn
        name = this.NameLhs{iEq};
        lhs = D.(name);
        try
            x = fn{iEq}(D, t, S);
        catch %#ok<CTCH>
            x = NaN;
        end
        if size(x, 1)>1
            x = NaN;
        end
        x( isnan(x) ) = this.NaN(iEq);
        if length(x)>1 && ndims(lhs)==2 && size(lhs, 2)==1  %#ok<ISMAT>
            newSize = size(x);
            lhs = repmat(lhs, [1, newSize(2:end)]);
        end
        lhs(t, :) = x;
        D.(name) = lhs;
    end
end

outputDatabank = struct( );
if ~opt.Fresh
    outputDatabank = inputDatabank;
end

if isstruct(opt.DbOverlay)
    inputDatabank = opt.DbOverlay;
    opt.DbOverlay = true;
end

if ~opt.DbOverlay && opt.AppendPresample
    inputDatabank = dbclip(inputDatabank, [-Inf, minDate]);
end

appendPresample = opt.DbOverlay || opt.AppendPresample;

for i = 1 : nEqtn
    name = this.NameLhs{i};
    data = D.(name)(-minSh+1:end-maxSh, :);
    cmt = this.Label{i};
    outputDatabank.(name) = replace(TEMPLATE_SERIES, data, minDate, cmt);
    if appendPresample && isfield(inputDatabank, name)
        outputDatabank.(name) = [ inputDatabank.(name) ; outputDatabank.(name) ];
    end 
end

return


    function s = createSteadyRefDbase( )
        ttrend = dat2ttrend(xRange, m);
        lsName = this.NameSteadyRef;
        ell = lookup(m, this.NameSteadyRef);
        pos = ell.PosName;
        ixNan = isnan(pos);
        if any(ixNan)
            throw( exception.Base('RptEq:STEADY_REF_NOT_FOUND_IN_MODEL', 'error'), ...
                lsName{ixNan} );
        end
        
        pos = pos(:).';
        X = createTrendArray(m, @all, true, pos, ttrend);
        X = permute(X, [2, 3, 1]);
        
        s = struct( );
        for ii = 1 : numel(lsName)
            nname = lsName{ii};
            s.(nname) = X(:, :, ii);
        end
    end


    function chkRhsNames( )
        ixFound = true(1, nNameRhs);
        ixValid = true(1, nNameRhs);
        for ii = 1 : nNameRhs
            nname = this.NameRhs{ii};
            isField = isfield(inputDatabank, nname);
            ixFound(ii) = isField || any(strcmp(nname, this.NameLhs));
            if ~isField
                continue
            end
            if isa(inputDatabank.(nname), 'tseries')
                D.(nname) = rangedata(inputDatabank.(nname), xRange);
                continue
            end
            ixValid(ii) = isnumeric(inputDatabank.(nname)) && size(inputDatabank.(nname), 1)==1;
            if ixValid(ii)
                D.(nname) = inputDatabank.(nname);
                eqtn = regexprep(eqtn, ['\?', nname, '#'], ['?', nname]);
            end
        end
        if any(~ixFound)
            throw( exception.Base('RptEq:RHS_NAME_DATA_NOT_FOUND', 'error'), ...
                this.NameRhs{~ixFound} );
        end
        if any(~ixValid)
            throw( exception.Base('RptEq:RHS_NAME_DATA_INVALID', 'error'), ...
                this.NameRhs{~ixFound} );
        end        
    end


    function preallocLhsNames( )
        for ii = 1 : nEqtn
            nname = this.NameLhs{ii};
            if ~isfield(D, nname)
                D.(nname) = nan(nXPer, 1);
            end
        end
    end
end
