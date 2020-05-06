function output = xlist(glue, varargin)
% textual.xlist  Create list of all combinations of components
%{
% ## Syntax ##
%
%     output = textual.xlist(glue, component, component, etc...)
%
%
% ## Input Arguments ##
% 
% __`glue`__ [ char | string ] -
% String that will be used as a glue placed between individual components.
%
% __`component`__ [ char | cellstr | string | numeric ] -
% Individual components from which the output string will be composed. Each
% `component` can be either a scalar (a char vector, a string scalar, or a
% numeric scalar) or a non-scalar (a cell array of chars, a string array,
% or a numeric array); see Description for how non-scalar inputs are
% combined into the final `output`.
%
%
% ## Output Arguments ##
%
% __`output`__ [ string ] -
% Horizontal string vector composed from the input components.
%
%
% ## Description ##
%
% If each of the inputs is a scalar (a char vector, a string scalar, or a
% numeric scalar), the final `output` is either a char vector or a string
% scalar consisting of the individual components separated by the `glue`.
%
% Any numeric input is converted to a char or string using the standard
% `sprintf(~)` function with a `%g` format.
% 
% The default type (class) of the `output` is string. The `output` is a
% char vector if neither any input nor the glue is a string, and at least
% one input is a char. The output is a cell array of chars if neither any
% input nor the glue is a string, and at least one input is a cell array of
% chars.
%
%
% ## Example ##
%
% Examples of scalar components
% 
%     >> textual.xlist('_', "my', "cross", 'list')
%     ans =
%         "my_cross_list"
%
%     >> textual.crosslist('_', 1, 2, 3) 
%     ans =
%         "1_2_3"
%}

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2020 IRIS Solutions Team

%--------------------------------------------------------------------------

output = hereEnsureType(varargin{end});
for component = varargin(end-1:-1:1)
    add = hereEnsureType(component{1});
    temp = cellfun(@(x) strcat(x, glue, output), add, 'UniformOutput', false);
    output = [temp{:}];
end
output = reshape(string(output), 1, [ ]);

return

    function c = hereEnsureType(c)
        if isnumeric(c)
            c = arrayfun(@(x) sprintf('%g', x), c, 'UniformOutput', false);
            c = string(c);
        else
            try
                c = string(c);
            catch exc
                error('Inputs to textual.crosslist(~) must be char, cellstr, string or numeric');
            end
        end
        c = reshape(c, 1, [ ]);
    end%
end%
