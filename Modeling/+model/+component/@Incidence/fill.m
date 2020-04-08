function [this, epsCurrent, epsShifted] = fill(this, qty, equationStrings, inxEquations, varargin)
% fill  Populate incidence matrices
%
% Backend [IrisToolbox] method
% No help provided

% -[IrisToolbox] for Macroeconomic Modeling
% -Copyright (c) 2007-2020 [IrisToolbox] Solutions Team

PTR = @int32;

%--------------------------------------------------------------------------

t0 = PTR(find(this.Shift==0)); %#ok<FNDSB>
numShifts = numel(this.Shift);
numEquations = numel(equationStrings);
numQuantities = numel(qty.Name);


%
% Reset incidence in indexEquations
%
this.Matrix(inxEquations, :) = false;


%
% Get equation, position of name, shift
%
[epsCurrent, epsShifted] = ...
    model.component.Incidence.getIncidenceEps(equationStrings, inxEquations, varargin{:});


%
% Place current dated incidence in the incidence matrix
%
epsCurrent = locallyRemovePosBeyondNumQuantities(epsCurrent, numQuantities); % [^1]
ind = sub2ind( ...
    [numEquations, numQuantities, numShifts] ...
    , epsCurrent(1, :), epsCurrent(2, :), t0+epsCurrent(3, :) ...
);
this.Matrix(ind) = true;


%
% Place time shifted incidence in the incidence matrix
%
epsShifted = locallyRemovePosBeyondNumQuantities(epsShifted, numQuantities); % [^1]
ind = sub2ind( ...
    [numEquations, numQuantities, numShifts] ...
    , epsShifted(1, :), epsShifted(2, :), t0+epsShifted(3, :) ...
);
this.Matrix(ind) = true;

end%

% [^1]: Incidence is sometimes also calculated for !links in which case
% there might be references to std or corr; these are excluded here.

%
% Local Functions
%

function eps = locallyRemovePosBeyondNumQuantities(eps, numQuantities) % [^1]
    inxToRemove = eps(2, :)>numQuantities;
    if any(inxToRemove)
        eps(:, inxToRemove) = [ ];
    end
end%

