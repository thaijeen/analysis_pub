function k = myAxis(ax)

if nargin < 1
    ax = gca;
end

set(ax, 'LineWidth',  1.2, 'TickDir', 'out', ...
    'FontSize', 27, 'FontName', 'Arial', 'Box', 'off');

end