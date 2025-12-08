classdef InteractivePhotosApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        CropButton                matlab.ui.control.Button
        MirrorSwitch              matlab.ui.control.Switch
        EdgeValueLabel            matlab.ui.control.Label
        BrightnessValueLabel      matlab.ui.control.Label
        ContrastValueLabel        matlab.ui.control.Label
        EdgedetectionSlider       matlab.ui.control.Slider
        EdgedetectionSliderLabel  matlab.ui.control.Label
        BWSwitch                  matlab.ui.control.Switch
        BrightnessSlider          matlab.ui.control.Slider
        BrightnessSliderLabel     matlab.ui.control.Label
        ContrastSlider            matlab.ui.control.Slider
        ContrastLabel             matlab.ui.control.Label
        ResetButton               matlab.ui.control.Button
        SaveimageButton           matlab.ui.control.Button
        LoadimageButton           matlab.ui.control.Button
        GreenHistogram            matlab.ui.control.UIAxes
        RedHistogram              matlab.ui.control.UIAxes
        BlueHistogram             matlab.ui.control.UIAxes
        ProcessedPhoto            matlab.ui.control.UIAxes
        OriginalPhoto             matlab.ui.control.UIAxes
    end


    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation simulink.Simulation
    end

    
    properties (Access = private)
        imgOrig   double
        imgProc   double
        cropRect double =[];
        brightVal double = 0
        contrVal  double = 1
        isGray    logical = false 
       isMirrored logical = false

    end

    
    methods (Access = private)
        

    % Sliders & switch to defaults
        function resetParams(app)
    if isempty(app.imgOrig)
        app.isGray = false;
    else
        if size(app.imgOrig,3) == 1
            app.isGray = true;
        else
            tol = 0.02;
            R = app.imgOrig(:,:,1);
            G = app.imgOrig(:,:,2);
            B = app.imgOrig(:,:,3);
            app.isGray = max(abs(R-G),[],'all')<=tol && max(abs(R-B),[],'all')<=tol;
        end
    end

    app.brightVal   = 0;
    app.contrVal    = 1;
    app.cropRect    = [];
    app.isMirrored  = false;

    app.BrightnessSlider.Value    = 0;
    app.ContrastSlider.Value      = 0;
    app.EdgedetectionSlider.Value = 0;
    app.MirrorSwitch.Value        = 'Off';

    app.BrightnessValueLabel.Text = "0";
    app.ContrastValueLabel.Text   = "0";
    app.EdgeValueLabel.Text       = "0";

    if app.isGray
        app.BWSwitch.Visible = 'off';
    else
        app.BWSwitch.Visible = 'on';
        app.BWSwitch.Value   = 'Color';
    end

    app.imgProc = app.imgOrig;
end


        function enableControls(app, on)
    if on
        state = 'on';
    else
        state = 'off';
    end
    app.MirrorSwitch.Enable = state;
    app.SaveimageButton.Enable = state;
    app.ResetButton.Enable = state;
    app.BrightnessSlider.Enable = state;
    app.ContrastSlider.Enable = state;
    app.EdgedetectionSlider.Enable = state;
    app.CropButton.Enable = state;
        end
        

        function g = toGray(~,img)
            if size(img,3)==3
                g = rgb2gray(img);
            else
                g = img;
            end
        end

% Calculations and setters for image processing,
%  to be perfect as i want it to be. 
        function processImage(app)
    if isempty(app.imgOrig)
        return; 
    end
    I = app.imgOrig;
    if app.isGray && size(I,3)==3
        I = repmat(app.toGray(I),[1 1 3]);
    end
    if app.isMirrored
    I = fliplr(I);
    end
    I = (I-0.5)*app.contrVal + 0.5 + app.brightVal;
    I = min(max(I,0),1);

    raw = max(app.EdgedetectionSlider.Value,0);
    if raw > 0
    normVal = raw / 100;
    amount = 0.8 + 2.2 * normVal;
    radius = 1.5 + 2.5 * normVal;
    threshold = 0.02*normVal;
    I = imsharpen(I, 'Radius', radius, 'Amount', amount, 'Threshold', threshold);
    end
    if ~isempty(app.cropRect)
        I = imcrop(I,app.cropRect);
    end
    app.imgProc = I;
    app.updateDisplays();
        end

% In real time and for the app design

function updateDisplays(app)
    imshow(app.imgOrig, 'Parent', app.OriginalPhoto);
    imshow(app.imgProc, 'Parent', app.ProcessedPhoto);

    cla(app.RedHistogram); 
    cla(app.GreenHistogram); 
    cla(app.BlueHistogram);

    if app.isGray || size(app.imgProc,3)==1
        grayImg = im2uint8(app.toGray(app.imgProc));
        [countGray, binsGray] = imhist(grayImg,255);
        bar(app.BlueHistogram, binsGray, countGray, 'FaceColor',[0.5 0.5 0.5],'EdgeColor','none');

        app.GreenHistogram.Visible = 'off';
        app.RedHistogram.Visible = 'off';

        title(app.BlueHistogram,'Grayscale Histogram');
        xlim(app.BlueHistogram,[0 255]);
        ylim(app.BlueHistogram,[0 max(countGray)*1.1]);
    else
        app.RedHistogram.Visible   = 'on';
        app.GreenHistogram.Visible = 'on';

        R = im2uint8(app.imgProc(:,:,1));
        G = im2uint8(app.imgProc(:,:,2));
        B = im2uint8(app.imgProc(:,:,3));

        [countR, binsR] = imhist(R,255);
        [countG, binsG] = imhist(G,255);
        [countB, binsB] = imhist(B,255);

        bar(app.RedHistogram,binsR,countR,'FaceColor','r','EdgeColor','none');
        bar(app.GreenHistogram,binsG,countG,'FaceColor','g','EdgeColor','none');
        bar(app.BlueHistogram,binsB,countB,'FaceColor','b','EdgeColor','none');
        
        xlim(app.RedHistogram,[0 255]); ylim(app.RedHistogram,[0 max(countR)*1.1]);
        xlim(app.GreenHistogram,[0 255]); ylim(app.GreenHistogram,[0 max(countG)*1.1]);
        xlim(app.BlueHistogram,[0 255]); ylim(app.BlueHistogram,[0 max(countB)*1.1]);
    end
end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: LoadimageButton
        function LoadimageButtonPushed(app, event)
    [f, p] = uigetfile({'*.jpg;*.png;*.bmp;*.tif;*.jpeg','Image Files'});
    if isequal(f,0)
        return;
    end
    rawImg = imread(fullfile(p,f));
    app.imgOrig = im2double(rawImg);
    app.imgProc = app.imgOrig;

    if size(rawImg,3) == 1
        app.isGray = true;
    else
        R = rawImg(:,:,1);
        G = rawImg(:,:,2);
        B = rawImg(:,:,3);
        tol = 5; 
        app.isGray = max(abs(R-G),[],'all')<=tol && max(abs(R-B),[],'all')<=tol;
    end
    if app.isGray
        app.BWSwitch.Visible = 'off';
        app.BWSwitch.Enable  = 'off';
    else
        app.BWSwitch.Visible = 'on';
        app.BWSwitch.Enable  = 'on';
        app.BWSwitch.Value   = 'Color';
    end
    app.resetParams();
    app.enableControls(true);
    app.processImage();
        end

        % Button pushed function: SaveimageButton
        function SaveimageButtonPushed(app, event)
            if isempty(app.imgProc); return; end
            [f,p] = uiputfile({'*.png'},'Save image');
            if isequal(f,0); return; end
            imwrite(app.imgProc, fullfile(p,f));
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
   if isempty(app.imgOrig)
       return; 
   end
   app.resetParams();
   app.processImage();
        end

        % Value changed function: BWSwitch
        function BWSwitchValueChanged(app, event)
            value = app.BWSwitch.Value;
             if isempty(app.imgOrig)
                 return; 
             end
            app.isGray = strcmp(event.Value,'Black&White');
            app.processImage();
        end

        % Value changing function: ContrastSlider
        function ContrastSliderValueChanging(app, event)
            raw = event.Value; 
            app.contrVal = 1 + raw/100;
            app.ContrastValueLabel.Text = sprintf('%.0f', raw);
            app.processImage();
        end

        % Value changing function: BrightnessSlider
        function BrightnessSliderValueChanging(app, event)
            raw = event.Value;
            app.brightVal = raw/100;
            app.BrightnessValueLabel.Text = sprintf('%.0f', raw);
            app.processImage();
        end

        % Value changing function: EdgedetectionSlider
        function EdgedetectionSliderValueChanging(app, event)
            app.EdgeValueLabel.Text = sprintf('%.0f', event.Value);
            app.EdgedetectionSlider.Value = event.Value;
            app.processImage();
            drawnow limitrate;
        end

        % Value changed function: MirrorSwitch
        function MirrorSwitchValueChanged(app, event)
            value = app.MirrorSwitch.Value;
            if isempty(app.imgOrig)
                return;  
            end
            app.isMirrored = strcmp(app.MirrorSwitch.Value,'Mirror');
            app.processImage();      
        end

        % Button pushed function: CropButton
        function CropButtonPushed(app, event)
            if isempty(app.imgOrig)
        return;
            end
            imshow(app.imgProc, 'Parent', app.ProcessedPhoto, 'InitialMagnification', 'fit');
            roi = drawrectangle(app.ProcessedPhoto);
            wait(roi);
            app.cropRect = round(roi.Position);
            app.processImage();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1052 757];
            app.UIFigure.Name = 'MATLAB App';

            % Create OriginalPhoto
            app.OriginalPhoto = uiaxes(app.UIFigure);
            title(app.OriginalPhoto, 'Original image')
            app.OriginalPhoto.LabelFontSizeMultiplier = 1.2;
            app.OriginalPhoto.FontName = 'Heiti TC';
            app.OriginalPhoto.XColor = [0 0 0];
            app.OriginalPhoto.XTick = [];
            app.OriginalPhoto.YColor = [0 0 0];
            app.OriginalPhoto.YTick = [];
            app.OriginalPhoto.ZColor = [0 0 0];
            app.OriginalPhoto.ZTick = [];
            app.OriginalPhoto.GridColor = [0 0 0];
            app.OriginalPhoto.FontSize = 14;
            app.OriginalPhoto.TitleFontSizeMultiplier = 1.5;
            app.OriginalPhoto.Position = [51 467 420 269];

            % Create ProcessedPhoto
            app.ProcessedPhoto = uiaxes(app.UIFigure);
            title(app.ProcessedPhoto, 'Processed image')
            app.ProcessedPhoto.LabelFontSizeMultiplier = 1.2;
            app.ProcessedPhoto.FontName = 'Heiti TC';
            app.ProcessedPhoto.XColor = [0 0 0];
            app.ProcessedPhoto.XTick = [];
            app.ProcessedPhoto.YColor = [0 0 0];
            app.ProcessedPhoto.YTick = [];
            app.ProcessedPhoto.ZColor = [0 0 0];
            app.ProcessedPhoto.ZTick = [];
            app.ProcessedPhoto.GridColor = [1 1 1];
            app.ProcessedPhoto.MinorGridColor = [1 1 1];
            app.ProcessedPhoto.FontSize = 14;
            app.ProcessedPhoto.TitleFontSizeMultiplier = 1.5;
            app.ProcessedPhoto.Position = [533 468 440 265];

            % Create BlueHistogram
            app.BlueHistogram = uiaxes(app.UIFigure);
            title(app.BlueHistogram, 'Blue Histogram')
            xlabel(app.BlueHistogram, 'Intensity')
            ylabel(app.BlueHistogram, 'Pixel Count')
            zlabel(app.BlueHistogram, 'Z')
            app.BlueHistogram.FontName = 'Heiti TC';
            app.BlueHistogram.XLim = [0 256];
            app.BlueHistogram.XColor = [0 0 0];
            app.BlueHistogram.XTick = [64 128 192 255];
            app.BlueHistogram.YColor = [0 0 0];
            app.BlueHistogram.ZColor = [0 0 0];
            app.BlueHistogram.FontSize = 14;
            app.BlueHistogram.TitleFontSizeMultiplier = 1.3;
            app.BlueHistogram.Position = [364 233 324 212];

            % Create RedHistogram
            app.RedHistogram = uiaxes(app.UIFigure);
            title(app.RedHistogram, 'Red Histogram')
            xlabel(app.RedHistogram, 'Intensity')
            ylabel(app.RedHistogram, 'Pixel Count')
            zlabel(app.RedHistogram, 'Z')
            app.RedHistogram.FontName = 'Heiti TC';
            app.RedHistogram.XLim = [0 256];
            app.RedHistogram.XColor = [0 0 0];
            app.RedHistogram.XTick = [64 128 192 255];
            app.RedHistogram.YColor = [0 0 0];
            app.RedHistogram.ZColor = [0 0 0];
            app.RedHistogram.FontSize = 14;
            app.RedHistogram.TitleFontSizeMultiplier = 1.3;
            app.RedHistogram.Position = [703 231 327 217];

            % Create GreenHistogram
            app.GreenHistogram = uiaxes(app.UIFigure);
            title(app.GreenHistogram, 'Green Histogram')
            xlabel(app.GreenHistogram, 'Intensity')
            ylabel(app.GreenHistogram, 'Pixel Count')
            zlabel(app.GreenHistogram, 'Z')
            app.GreenHistogram.FontName = 'Heiti TC';
            app.GreenHistogram.XLim = [0 256];
            app.GreenHistogram.XColor = [0 0 0];
            app.GreenHistogram.XTick = [64 128 192 255];
            app.GreenHistogram.YColor = [0 0 0];
            app.GreenHistogram.ZColor = [0 0 0];
            app.GreenHistogram.FontSize = 14;
            app.GreenHistogram.TitleFontSizeMultiplier = 1.3;
            app.GreenHistogram.Position = [17 234 326 209];

            % Create LoadimageButton
            app.LoadimageButton = uibutton(app.UIFigure, 'push');
            app.LoadimageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadimageButtonPushed, true);
            app.LoadimageButton.BackgroundColor = [1 0.9216 1];
            app.LoadimageButton.FontName = 'Heiti TC';
            app.LoadimageButton.FontSize = 18;
            app.LoadimageButton.FontWeight = 'bold';
            app.LoadimageButton.FontColor = [1 0.5882 0.9294];
            app.LoadimageButton.Position = [147 148 121 30];
            app.LoadimageButton.Text = 'Load image';

            % Create SaveimageButton
            app.SaveimageButton = uibutton(app.UIFigure, 'push');
            app.SaveimageButton.ButtonPushedFcn = createCallbackFcn(app, @SaveimageButtonPushed, true);
            app.SaveimageButton.BackgroundColor = [1 0.9216 1];
            app.SaveimageButton.FontName = 'Heiti TC';
            app.SaveimageButton.FontSize = 18;
            app.SaveimageButton.FontWeight = 'bold';
            app.SaveimageButton.FontColor = [1 0.5882 0.9294];
            app.SaveimageButton.Position = [147 104 119 30];
            app.SaveimageButton.Text = 'Save image';

            % Create ResetButton
            app.ResetButton = uibutton(app.UIFigure, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.BackgroundColor = [1 0.9216 1];
            app.ResetButton.FontName = 'Heiti TC';
            app.ResetButton.FontSize = 18;
            app.ResetButton.FontWeight = 'bold';
            app.ResetButton.FontColor = [1 0.5882 0.9294];
            app.ResetButton.Position = [157 39 100 30];
            app.ResetButton.Text = 'Reset';

            % Create ContrastLabel
            app.ContrastLabel = uilabel(app.UIFigure);
            app.ContrastLabel.HorizontalAlignment = 'right';
            app.ContrastLabel.FontName = 'Heiti TC';
            app.ContrastLabel.FontSize = 18;
            app.ContrastLabel.FontWeight = 'bold';
            app.ContrastLabel.FontColor = [1 0.5882 0.9294];
            app.ContrastLabel.Position = [323 191 84 23];
            app.ContrastLabel.Text = 'Contrast ';

            % Create ContrastSlider
            app.ContrastSlider = uislider(app.UIFigure);
            app.ContrastSlider.Limits = [-100 100];
            app.ContrastSlider.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.ContrastSlider.MajorTickLabels = {'-100', '-80', '-60', '-40', '-20', '0', '20', '40', '60', '80', '100'};
            app.ContrastSlider.ValueChangingFcn = createCallbackFcn(app, @ContrastSliderValueChanging, true);
            app.ContrastSlider.FontName = 'Heiti TC';
            app.ContrastSlider.FontSize = 18;
            app.ContrastSlider.FontWeight = 'bold';
            app.ContrastSlider.FontColor = [1 0.5882 0.9294];
            app.ContrastSlider.Position = [485 201 385 3];

            % Create BrightnessSliderLabel
            app.BrightnessSliderLabel = uilabel(app.UIFigure);
            app.BrightnessSliderLabel.HorizontalAlignment = 'right';
            app.BrightnessSliderLabel.FontName = 'Heiti TC';
            app.BrightnessSliderLabel.FontSize = 18;
            app.BrightnessSliderLabel.FontWeight = 'bold';
            app.BrightnessSliderLabel.FontColor = [1 0.5882 0.9294];
            app.BrightnessSliderLabel.Position = [323 138 90 23];
            app.BrightnessSliderLabel.Text = 'Brightness';

            % Create BrightnessSlider
            app.BrightnessSlider = uislider(app.UIFigure);
            app.BrightnessSlider.Limits = [-100 100];
            app.BrightnessSlider.MajorTicks = [-100 -80 -60 -40 -20 0 20 40 60 80 100];
            app.BrightnessSlider.MajorTickLabels = {'-100', '-80', '-60', '-40', '-20', '0', '20', '40', '60', '80', '100'};
            app.BrightnessSlider.ValueChangingFcn = createCallbackFcn(app, @BrightnessSliderValueChanging, true);
            app.BrightnessSlider.FontName = 'Heiti TC';
            app.BrightnessSlider.FontSize = 18;
            app.BrightnessSlider.FontWeight = 'bold';
            app.BrightnessSlider.FontColor = [1 0.5882 0.9294];
            app.BrightnessSlider.Interruptible = 'off';
            app.BrightnessSlider.Position = [485 148 384 3];

            % Create BWSwitch
            app.BWSwitch = uiswitch(app.UIFigure, 'slider');
            app.BWSwitch.Items = {'Color', 'Black&White'};
            app.BWSwitch.ValueChangedFcn = createCallbackFcn(app, @BWSwitchValueChanged, true);
            app.BWSwitch.FontName = 'Heiti TC';
            app.BWSwitch.FontSize = 18;
            app.BWSwitch.FontWeight = 'bold';
            app.BWSwitch.FontColor = [1 0.5882 0.9294];
            app.BWSwitch.Position = [550 19 45 20];
            app.BWSwitch.Value = 'Color';

            % Create EdgedetectionSliderLabel
            app.EdgedetectionSliderLabel = uilabel(app.UIFigure);
            app.EdgedetectionSliderLabel.HorizontalAlignment = 'right';
            app.EdgedetectionSliderLabel.FontName = 'Heiti TC';
            app.EdgedetectionSliderLabel.FontSize = 18;
            app.EdgedetectionSliderLabel.FontWeight = 'bold';
            app.EdgedetectionSliderLabel.FontColor = [1 0.5882 0.9294];
            app.EdgedetectionSliderLabel.Position = [323 84 141 23];
            app.EdgedetectionSliderLabel.Text = 'Edge detection';

            % Create EdgedetectionSlider
            app.EdgedetectionSlider = uislider(app.UIFigure);
            app.EdgedetectionSlider.ValueChangingFcn = createCallbackFcn(app, @EdgedetectionSliderValueChanging, true);
            app.EdgedetectionSlider.FontName = 'Heiti TC';
            app.EdgedetectionSlider.FontSize = 18;
            app.EdgedetectionSlider.FontWeight = 'bold';
            app.EdgedetectionSlider.FontColor = [1 0.5882 0.9294];
            app.EdgedetectionSlider.Position = [492 93 378 3];

            % Create ContrastValueLabel
            app.ContrastValueLabel = uilabel(app.UIFigure);
            app.ContrastValueLabel.FontName = 'Heiti TC';
            app.ContrastValueLabel.FontSize = 18;
            app.ContrastValueLabel.FontWeight = 'bold';
            app.ContrastValueLabel.FontColor = [1 0.5882 0.9294];
            app.ContrastValueLabel.Position = [946 179 39 23];
            app.ContrastValueLabel.Text = '0';

            % Create BrightnessValueLabel
            app.BrightnessValueLabel = uilabel(app.UIFigure);
            app.BrightnessValueLabel.FontName = 'Heiti TC';
            app.BrightnessValueLabel.FontSize = 18;
            app.BrightnessValueLabel.FontWeight = 'bold';
            app.BrightnessValueLabel.FontColor = [1 0.5882 0.9294];
            app.BrightnessValueLabel.Position = [946 128 39 23];
            app.BrightnessValueLabel.Text = '0';

            % Create EdgeValueLabel
            app.EdgeValueLabel = uilabel(app.UIFigure);
            app.EdgeValueLabel.FontName = 'Heiti TC';
            app.EdgeValueLabel.FontSize = 18;
            app.EdgeValueLabel.FontWeight = 'bold';
            app.EdgeValueLabel.FontColor = [1 0.5882 0.9294];
            app.EdgeValueLabel.Position = [946 74 39 23];
            app.EdgeValueLabel.Text = '0';

            % Create MirrorSwitch
            app.MirrorSwitch = uiswitch(app.UIFigure, 'slider');
            app.MirrorSwitch.Items = {'Off', 'Mirror'};
            app.MirrorSwitch.ValueChangedFcn = createCallbackFcn(app, @MirrorSwitchValueChanged, true);
            app.MirrorSwitch.FontName = 'Heiti TC';
            app.MirrorSwitch.FontSize = 18;
            app.MirrorSwitch.FontWeight = 'bold';
            app.MirrorSwitch.FontColor = [1 0.5882 0.9294];
            app.MirrorSwitch.Position = [786 20 45 20];

            % Create CropButton
            app.CropButton = uibutton(app.UIFigure, 'push');
            app.CropButton.ButtonPushedFcn = createCallbackFcn(app, @CropButtonPushed, true);
            app.CropButton.BackgroundColor = [1 0.9216 1];
            app.CropButton.FontSize = 14;
            app.CropButton.FontColor = [1 0.5882 0.9294];
            app.CropButton.Position = [343 23 100 25];
            app.CropButton.Text = 'Crop';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = InteractivePhotosApp_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end