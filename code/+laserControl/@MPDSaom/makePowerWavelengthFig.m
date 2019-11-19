function varargout=makePowerWavelengthFig(obj)
    % Plot the power/wavelength data and current laser wavelength if possible


    % Make new figure window if needed
    figTag = 'plambda';

    f=findobj('Tag',figTag);
    
    if isempty(f)
        fprintf('Making new power/wavelength figure window\n');
        f=figure;
    else
        clf(f)
    end

    set(f,'Tag',figTag, ...
        'NumberTitle','off')

    ax=axes('Parent',f);

    % Plot current power table data and laser wavelength if possible
    plot(obj.powerTable(:,1),obj.powerTable(:,2),'-ob',...
        'MarkerSize',7, 'LineWidth', 1, 'Tag', 'powerTablePlotData',...
        'MarkerFaceColor',[0.33,0.33,1],'Parent',ax);

    if ~isempty(obj.laser)
        hold(ax,'on')
        plot(obj.laser.currentWavelength, obj.interpPowerValue,'or','MarkerSize', 12, ...
        'LineWidth', 2, 'Tag', 'currentLambda','Parent',ax)
        hold(ax,'off')
    end

    % Embelish plot
    xlabel('Laser wavelength (nm)')
    ylabel('AOM RF Power')
    ylim([0,40])
    xlim([700,1100])

    box on 
    grid on

