classdef transfomerApp_code < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        LoadRLabel                      matlab.ui.control.Label
        CalculatorResultsPanel          matlab.ui.container.Panel
        EfficiencynPanel                matlab.ui.container.Panel
        EfficiencyValueLabel            matlab.ui.control.Label
        CoreLossPanel                   matlab.ui.container.Panel
        CoreLossValueLabel              matlab.ui.control.Label
        CopperLossPanel                 matlab.ui.container.Panel
        CopperLossValueLabel            matlab.ui.control.Label
        OutputPowerPanel                matlab.ui.container.Panel
        OutputPowerValueLabel           matlab.ui.control.Label
        SecondaryCurrentPanel           matlab.ui.container.Panel
        SecondaryCurrentValueLabel      matlab.ui.control.Label
        SecondaryVoltagePanel           matlab.ui.container.Panel
        SecondaryVoltageValueLabel      matlab.ui.control.Label
        LoadSlider                      matlab.ui.control.Slider
        LoadSliderLabel                 matlab.ui.control.Label
        TransformerParametersPanel      matlab.ui.container.Panel
        WLabel_3                        matlab.ui.control.Label
        WLabel_2                        matlab.ui.control.Label
        VALabel                         matlab.ui.control.Label
        UnitlessLabel                   matlab.ui.control.Label
        VLabel                          matlab.ui.control.Label
        CopperlossatratedlossTextArea   matlab.ui.control.TextArea
        TextArea_5Label                 matlab.ui.control.Label
        CorelossconstantTextArea        matlab.ui.control.TextArea
        CorelossconstantTextAreaLabel   matlab.ui.control.Label
        RatedapparentpowerTextArea      matlab.ui.control.TextArea
        TextArea_3Label                 matlab.ui.control.Label
        TurnsratioN_pN_sTextArea        matlab.ui.control.TextArea
        TurnsratioN_pN_sLabel           matlab.ui.control.Label
        PrimaryvoltageRMSTextArea       matlab.ui.control.TextArea
        PrimaryvoltageRMSTextAreaLabel  matlab.ui.control.Label
        Image                           matlab.ui.control.Image
        TransformerSchemeticPanel       matlab.ui.container.Panel
        ratio_sche                      matlab.ui.control.Label
        secondary_value_sche            matlab.ui.control.Label
        SecondaryLabel                  matlab.ui.control.Label
        primary_value_sche              matlab.ui.control.Label
        PrimaryLabel                    matlab.ui.control.Label
        EfficiencyVsLoad                matlab.ui.control.UIAxes
        LossesVsLoad                    matlab.ui.control.UIAxes
        OpVsLoad                        matlab.ui.control.UIAxes
    end

    
    methods (Access = private)
        
        function updateTransformer(app, v1_rms, ratio, s_rated, x, core_loss, copper_rated)
            p_out = NaN;
            i2 = NaN;
            copper_loss = NaN;
            n = NaN;

            % Validate turns ratio
            parts = split(string(ratio), ":");
            ratio_valid = false;

            if numel(parts) == 2
                Np = str2double(parts(1));
                Ns = str2double(parts(2));
                ratio_valid = isfinite(Np) && isfinite(Ns) && Np > 0 && Ns > 0;
            end

            % Check and validate other parameters
            voltage_valid = isfinite(v1_rms) && v1_rms > 0;
            power_valid = isfinite(s_rated) && s_rated > 0;
            load_valid = isfinite(x) && x >= 0 && x <= 1;
            core_valid = isfinite(core_loss) && core_loss >= 0;
            copper_valid = isfinite(copper_rated) && copper_rated >= 0;

            % Primary voltage label
            if voltage_valid
                app.primary_value_sche.Text = sprintf("%.2f V (RMS)", v1_rms);
            else
                app.primary_value_sche.Text = "Invalid Voltage";
            end

            % Turns ratio label
            if ratio_valid
                app.ratio_sche.Text = string(ratio);
            else
                app.ratio_sche.Text = "Invalid Ratio";
            end

            % Secondary voltage
            voltage2_valid = voltage_valid && ratio_valid;

            if voltage2_valid
                a = Np / Ns;
                v2_rms = v1_rms / a;

                app.secondary_value_sche.Text = sprintf("%.2f V (RMS)", v2_rms);
                app.SecondaryVoltageValueLabel.Text = sprintf("%.2f V", v2_rms);
            else
                app.secondary_value_sche.Text = "Invalid";
                app.SecondaryVoltageValueLabel.Text = "Invalid";
            end

            % Secondary current and output power
            output_valid = voltage2_valid && power_valid && load_valid;

            if output_valid
                i2_rated = s_rated / v2_rms;
                i2 = i2_rated * x;
                p_out = v2_rms * i2;

                app.SecondaryCurrentValueLabel.Text = sprintf("%.2f A", i2);
                app.OutputPowerValueLabel.Text = sprintf("%.2f W", p_out);
            else
                app.SecondaryCurrentValueLabel.Text = "Invalid";
                app.OutputPowerValueLabel.Text = "Invalid";
            end

            % Core loss
            if core_valid
                app.CoreLossValueLabel.Text = sprintf("%.2f W", core_loss);
            else
                app.CoreLossValueLabel.Text = "Invalid";
            end

            % Copper loss
            copper_loss_valid = copper_valid && load_valid;

            if copper_loss_valid
                copper_loss = copper_rated * x^2;
                app.CopperLossValueLabel.Text = sprintf("%.2f W", copper_loss);
            else
                app.CopperLossValueLabel.Text = "Invalid";
            end

            % Efficiency
            efficiency_valid = output_valid && core_valid && copper_loss_valid;

            if efficiency_valid
                p_loss = core_loss + copper_loss;
                p_in = p_out + p_loss;

                if p_in > 0
                    n = (p_out / p_in) * 100;
                    app.EfficiencyValueLabel.Text = sprintf("%.1f%%", n);
                else
                    app.EfficiencyValueLabel.Text = "N/A";
                end
            else
                app.EfficiencyValueLabel.Text = "Invalid";
            end

            % Variables for plots
            x_vector = linspace(0, 1, 100);
            p_out_vector = s_rated .* x_vector;

            p_copper_vector = x_vector.^2 .* copper_rated;

            p_in_vector = p_out_vector + core_loss + p_copper_vector;
            n_vector = (p_out_vector./p_in_vector) * 100;

            %plotting output power vs. Load
            if all(isfinite(p_out_vector)) && all(p_out_vector >= 0) && isfinite(p_out)
                cla(app.OpVsLoad);
                hold(app.OpVsLoad, 'on');
                plot(app.OpVsLoad, x_vector, p_out_vector, '-');
                plot(app.OpVsLoad, x, p_out, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.95 0.25 0.25], 'MarkerEdgeColor', 'white', 'LineWidth', 1.5);
                plot(app.OpVsLoad, [x x], [0 p_out], '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2);
                xlabel(app.OpVsLoad, "Load Fraction (0-1)");
                ylabel(app.OpVsLoad, "Output Power (Watts)");
                title(app.OpVsLoad, "Transformer output power vs. Load");
                legend(app.OpVsLoad, "Power Output (W)", sprintf("Output Power: %.2f W at %.0f%% Load", p_out, x*100), 'Location', 'northwest');
                grid(app.OpVsLoad, 'on');
                hold(app.OpVsLoad, 'off');
            else
                cla(app.OpVsLoad);
            end

            %plotting Transformer Losses vs. Load Fraction
            if copper_loss_valid && core_valid
                cla(app.LossesVsLoad);
                hold(app.LossesVsLoad, 'on');
                plot(app.LossesVsLoad, x_vector, p_copper_vector, 'Color', [0.95 0.45 0.15]);
                yline(app.LossesVsLoad, core_loss, 'Color', [0.20 0.65 0.95]);
                plot(app.LossesVsLoad, x, copper_loss, "o", "MarkerSize", 10, 'MarkerFaceColor', [0.95 0.45 0.15]);
                plot(app.LossesVsLoad, x, core_loss, "o", "MarkerSize", 10, 'MarkerFaceColor', [0.20 0.65 0.95]);
                max_loss = max(copper_loss, core_loss);
                plot(app.LossesVsLoad, [x x], [0 max_loss], '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2);
                title(app.LossesVsLoad, "Transformer losses vs. Load Fraction");
                xlabel(app.LossesVsLoad, "Load Fraction (0-1)");
                ylabel(app.LossesVsLoad, "Power Loss (W)");
                grid(app.LossesVsLoad, 'on');
                legend(app.LossesVsLoad, "Copper Loss", "Core Loss", sprintf("Copper Loss: %.2f W at %.2f%% load", x^2 * copper_rated, x*100), sprintf("Core Loss: %.2f W at %.2f%% Load", core_loss, x*100));
                hold(app.LossesVsLoad, 'off');
            else
                cla(app.LossesVsLoad);
            end

            %plotting efficiency
            if efficiency_valid
                cla(app.EfficiencyVsLoad);
                hold(app.EfficiencyVsLoad, 'on');
                plot(app.EfficiencyVsLoad, x_vector, n_vector, '-', 'LineWidth', 2);
                plot(app.EfficiencyVsLoad, x, n, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.20 0.65 0.95]);
                plot(app.EfficiencyVsLoad, [x x], [0 n], '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2);
                xlabel(app.EfficiencyVsLoad, "Load Fraction (0-1)");
                ylabel(app.EfficiencyVsLoad, "Efficiency (%)");
                title(app.EfficiencyVsLoad, "Transformer Efficiency vs. Load Fraction");
                legend(app.EfficiencyVsLoad, "Transformer Efficiency", sprintf("Efficiency: %.2f%% at %.1f%% Load", n, x*100), 'Location', 'southeast');
                ylim(app.EfficiencyVsLoad, [0 100]);
                grid(app.EfficiencyVsLoad, 'on');
                hold(app.EfficiencyVsLoad, 'off');
            else
                cla(app.EfficiencyVsLoad);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)

            app.UIFigure.WindowState = 'maximized';
            voltage = str2double(app.PrimaryvoltageRMSTextArea.Value{1});
            ratio = string(app.TurnsratioN_pN_sTextArea.Value{1});
            s_rated = str2double(app.RatedapparentpowerTextArea.Value{1});
            copper_rated = str2double(app.CopperlossatratedlossTextArea.Value{1});
            core_loss = str2double(app.CorelossconstantTextArea.Value{1});
            x = app.LoadSlider.Value;
            updateTransformer(app, voltage, ratio, s_rated, x, core_loss, copper_rated);

        end

        % Callback function
        function LoadSliderValueChanged(app, event)
            value = app.LoadSlider.Value;
        end

        % Value changing function: LoadSlider
        function LoadSliderValueChanging(app, event)

            ratio = string(app.TurnsratioN_pN_sTextArea.Value{1});
            s_rated = str2double(app.RatedapparentpowerTextArea.Value{1});
            voltage = str2double(app.PrimaryvoltageRMSTextArea.Value{1});
            copper_rated = str2double(app.CopperlossatratedlossTextArea.Value{1});
            core_loss = str2double(app.CorelossconstantTextArea.Value{1})
            updateTransformer(app, voltage, ratio, s_rated, event.Value, core_loss, copper_rated);
        end

        % Value changing function: PrimaryvoltageRMSTextArea
        function PrimaryvoltageRMSTextAreaValueChanging(app, event)
            voltage = str2double(event.Value{1});
            ratio = string(app.TurnsratioN_pN_sTextArea.Value{1});
            s_rated = str2double(app.RatedapparentpowerTextArea.Value{1});
            copper_rated = str2double(app.CopperlossatratedlossTextArea.Value{1});
            core_loss = str2double(app.CorelossconstantTextArea.Value{1});
            updateTransformer(app, voltage, ratio, s_rated, app.LoadSlider.Value, core_loss, copper_rated);
        end

        % Value changing function: TurnsratioN_pN_sTextArea
        function TurnsratioN_pN_sTextAreaValueChanging(app, event)
            ratio = string(event.Value{1});
            voltage = str2double(app.PrimaryvoltageRMSTextArea.Value{1});
            s_rated = str2double(app.RatedapparentpowerTextArea.Value{1});
            copper_rated = str2double(app.CopperlossatratedlossTextArea.Value{1});
            core_loss = str2double(app.CorelossconstantTextArea.Value{1});
            updateTransformer(app, voltage, ratio, s_rated, app.LoadSlider.Value, core_loss, copper_rated);
        end

        % Value changing function: RatedapparentpowerTextArea
        function RatedapparentpowerTextAreaValueChanging(app, event)

            copper_rated = str2double(app.CopperlossatratedlossTextArea.Value{1});
            core_loss = str2double(app.CorelossconstantTextArea.Value{1});
            ratio = string(app.TurnsratioN_pN_sTextArea.Value{1});
            voltage = str2double(app.PrimaryvoltageRMSTextArea.Value{1});
            s_rated = str2double(event.Value{1});
            updateTransformer(app, voltage, ratio, s_rated, app.LoadSlider.Value, core_loss, copper_rated);
        end

        % Value changing function: CorelossconstantTextArea
        function CorelossconstantTextAreaValueChanging(app, event)
            core_loss = str2double(event.Value{1});
            copper_rated = str2double(app.CopperlossatratedlossTextArea.Value{1});
            ratio = string(app.TurnsratioN_pN_sTextArea.Value{1});
            voltage = str2double(app.PrimaryvoltageRMSTextArea.Value{1});
            s_rated = str2double(app.RatedapparentpowerTextArea.Value{1});
            updateTransformer(app, voltage, ratio, s_rated, app.LoadSlider.Value, core_loss, copper_rated);
        end

        % Value changing function: CopperlossatratedlossTextArea
        function CopperlossatratedlossTextAreaValueChanging(app, event)
            copper_rated = str2double(event.Value{1});
            core_loss = str2double(app.CorelossconstantTextArea.Value{1});
            ratio = string(app.TurnsratioN_pN_sTextArea.Value{1});
            voltage = str2double(app.PrimaryvoltageRMSTextArea.Value{1});
            s_rated = str2double(app.RatedapparentpowerTextArea.Value{1});
            updateTransformer(app, voltage, ratio, s_rated, app.LoadSlider.Value, core_loss, copper_rated);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 1400 867];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Theme = 'light';

            % Create OpVsLoad
            app.OpVsLoad = uiaxes(app.UIFigure);
            title(app.OpVsLoad, 'Title')
            xlabel(app.OpVsLoad, 'X')
            ylabel(app.OpVsLoad, 'Y')
            zlabel(app.OpVsLoad, 'Z')
            app.OpVsLoad.Position = [724 587 676 281];

            % Create LossesVsLoad
            app.LossesVsLoad = uiaxes(app.UIFigure);
            title(app.LossesVsLoad, 'Title')
            xlabel(app.LossesVsLoad, 'X')
            ylabel(app.LossesVsLoad, 'Y')
            zlabel(app.LossesVsLoad, 'Z')
            app.LossesVsLoad.Position = [723 293 676 281];

            % Create EfficiencyVsLoad
            app.EfficiencyVsLoad = uiaxes(app.UIFigure);
            title(app.EfficiencyVsLoad, 'Title')
            xlabel(app.EfficiencyVsLoad, 'X')
            ylabel(app.EfficiencyVsLoad, 'Y')
            zlabel(app.EfficiencyVsLoad, 'Z')
            app.EfficiencyVsLoad.Position = [723 1 676 281];

            % Create TransformerSchemeticPanel
            app.TransformerSchemeticPanel = uipanel(app.UIFigure);
            app.TransformerSchemeticPanel.AutoResizeChildren = 'off';
            app.TransformerSchemeticPanel.BorderWidth = 0;
            app.TransformerSchemeticPanel.Title = 'Transformer Schemetic';
            app.TransformerSchemeticPanel.FontName = 'Arial';
            app.TransformerSchemeticPanel.FontWeight = 'bold';
            app.TransformerSchemeticPanel.FontSize = 24;
            app.TransformerSchemeticPanel.Position = [24 561 681 292];

            % Create PrimaryLabel
            app.PrimaryLabel = uilabel(app.TransformerSchemeticPanel);
            app.PrimaryLabel.HorizontalAlignment = 'center';
            app.PrimaryLabel.FontName = 'Arial';
            app.PrimaryLabel.FontSize = 24;
            app.PrimaryLabel.Position = [126 230 88 31];
            app.PrimaryLabel.Text = 'Primary';

            % Create primary_value_sche
            app.primary_value_sche = uilabel(app.TransformerSchemeticPanel);
            app.primary_value_sche.HorizontalAlignment = 'center';
            app.primary_value_sche.FontName = 'Arial';
            app.primary_value_sche.FontSize = 24;
            app.primary_value_sche.Position = [68 195 205 31];
            app.primary_value_sche.Text = '120V (RMS)';

            % Create SecondaryLabel
            app.SecondaryLabel = uilabel(app.TransformerSchemeticPanel);
            app.SecondaryLabel.HorizontalAlignment = 'center';
            app.SecondaryLabel.FontName = 'Arial';
            app.SecondaryLabel.FontSize = 24;
            app.SecondaryLabel.Position = [462 230 120 31];
            app.SecondaryLabel.Text = 'Secondary';

            % Create secondary_value_sche
            app.secondary_value_sche = uilabel(app.TransformerSchemeticPanel);
            app.secondary_value_sche.HorizontalAlignment = 'center';
            app.secondary_value_sche.FontName = 'Arial';
            app.secondary_value_sche.FontSize = 24;
            app.secondary_value_sche.Position = [412 194 205 31];
            app.secondary_value_sche.Text = '12V (RMS)';

            % Create ratio_sche
            app.ratio_sche = uilabel(app.TransformerSchemeticPanel);
            app.ratio_sche.HorizontalAlignment = 'center';
            app.ratio_sche.VerticalAlignment = 'bottom';
            app.ratio_sche.WordWrap = 'on';
            app.ratio_sche.FontName = 'Arial';
            app.ratio_sche.FontSize = 24;
            app.ratio_sche.Position = [273 200 117 61];
            app.ratio_sche.Text = '10:1';

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.Position = [7 562 698 191];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'transformer-removebg-preview.png');

            % Create TransformerParametersPanel
            app.TransformerParametersPanel = uipanel(app.UIFigure);
            app.TransformerParametersPanel.AutoResizeChildren = 'off';
            app.TransformerParametersPanel.BorderWidth = 0;
            app.TransformerParametersPanel.Title = 'Transformer Parameters';
            app.TransformerParametersPanel.BackgroundColor = [1 1 1];
            app.TransformerParametersPanel.FontName = 'Arial';
            app.TransformerParametersPanel.FontWeight = 'bold';
            app.TransformerParametersPanel.FontSize = 24;
            app.TransformerParametersPanel.Position = [23 366 618 169];

            % Create PrimaryvoltageRMSTextAreaLabel
            app.PrimaryvoltageRMSTextAreaLabel = uilabel(app.TransformerParametersPanel);
            app.PrimaryvoltageRMSTextAreaLabel.FontName = 'Arial';
            app.PrimaryvoltageRMSTextAreaLabel.FontSize = 14;
            app.PrimaryvoltageRMSTextAreaLabel.Interpreter = 'tex';
            app.PrimaryvoltageRMSTextAreaLabel.Position = [16 105 159 22];
            app.PrimaryvoltageRMSTextAreaLabel.Text = 'Primary voltage (RMS)';

            % Create PrimaryvoltageRMSTextArea
            app.PrimaryvoltageRMSTextArea = uitextarea(app.TransformerParametersPanel);
            app.PrimaryvoltageRMSTextArea.ValueChangingFcn = createCallbackFcn(app, @PrimaryvoltageRMSTextAreaValueChanging, true);
            app.PrimaryvoltageRMSTextArea.HorizontalAlignment = 'center';
            app.PrimaryvoltageRMSTextArea.FontName = 'Arial';
            app.PrimaryvoltageRMSTextArea.FontSize = 14;
            app.PrimaryvoltageRMSTextArea.Placeholder = 'Voltage Here';
            app.PrimaryvoltageRMSTextArea.Position = [178 104 112 25];
            app.PrimaryvoltageRMSTextArea.Value = {'120'};

            % Create TurnsratioN_pN_sLabel
            app.TurnsratioN_pN_sLabel = uilabel(app.TransformerParametersPanel);
            app.TurnsratioN_pN_sLabel.FontName = 'Arial';
            app.TurnsratioN_pN_sLabel.FontSize = 14;
            app.TurnsratioN_pN_sLabel.Interpreter = 'tex';
            app.TurnsratioN_pN_sLabel.Position = [16 81 151 22];
            app.TurnsratioN_pN_sLabel.Text = 'Turns ratio (N_{p}:N_{s})     ';

            % Create TurnsratioN_pN_sTextArea
            app.TurnsratioN_pN_sTextArea = uitextarea(app.TransformerParametersPanel);
            app.TurnsratioN_pN_sTextArea.ValueChangingFcn = createCallbackFcn(app, @TurnsratioN_pN_sTextAreaValueChanging, true);
            app.TurnsratioN_pN_sTextArea.HorizontalAlignment = 'center';
            app.TurnsratioN_pN_sTextArea.FontName = 'Arial';
            app.TurnsratioN_pN_sTextArea.Placeholder = 'Ex: 10:1';
            app.TurnsratioN_pN_sTextArea.Position = [178 80 112 25];
            app.TurnsratioN_pN_sTextArea.Value = {'10:1'};

            % Create TextArea_3Label
            app.TextArea_3Label = uilabel(app.TransformerParametersPanel);
            app.TextArea_3Label.FontName = 'Arial';
            app.TextArea_3Label.FontSize = 14;
            app.TextArea_3Label.Interpreter = 'tex';
            app.TextArea_3Label.Position = [16 57 148 22];
            app.TextArea_3Label.Text = 'Rated apparent power';

            % Create RatedapparentpowerTextArea
            app.RatedapparentpowerTextArea = uitextarea(app.TransformerParametersPanel);
            app.RatedapparentpowerTextArea.ValueChangingFcn = createCallbackFcn(app, @RatedapparentpowerTextAreaValueChanging, true);
            app.RatedapparentpowerTextArea.HorizontalAlignment = 'center';
            app.RatedapparentpowerTextArea.FontName = 'Arial';
            app.RatedapparentpowerTextArea.Placeholder = 'Power Value';
            app.RatedapparentpowerTextArea.Position = [178 56 112 25];
            app.RatedapparentpowerTextArea.Value = {'70'};

            % Create CorelossconstantTextAreaLabel
            app.CorelossconstantTextAreaLabel = uilabel(app.TransformerParametersPanel);
            app.CorelossconstantTextAreaLabel.FontName = 'Arial';
            app.CorelossconstantTextAreaLabel.FontSize = 14;
            app.CorelossconstantTextAreaLabel.Interpreter = 'tex';
            app.CorelossconstantTextAreaLabel.Position = [16 33 147 22];
            app.CorelossconstantTextAreaLabel.Text = 'Core loss (constant)';

            % Create CorelossconstantTextArea
            app.CorelossconstantTextArea = uitextarea(app.TransformerParametersPanel);
            app.CorelossconstantTextArea.ValueChangingFcn = createCallbackFcn(app, @CorelossconstantTextAreaValueChanging, true);
            app.CorelossconstantTextArea.HorizontalAlignment = 'center';
            app.CorelossconstantTextArea.FontName = 'Arial';
            app.CorelossconstantTextArea.Position = [178 32 112 25];
            app.CorelossconstantTextArea.Value = {'2'};

            % Create TextArea_5Label
            app.TextArea_5Label = uilabel(app.TransformerParametersPanel);
            app.TextArea_5Label.FontName = 'Arial';
            app.TextArea_5Label.FontSize = 14;
            app.TextArea_5Label.Interpreter = 'tex';
            app.TextArea_5Label.Position = [16 8 157 22];
            app.TextArea_5Label.Text = 'Coper loss at rated loss';

            % Create CopperlossatratedlossTextArea
            app.CopperlossatratedlossTextArea = uitextarea(app.TransformerParametersPanel);
            app.CopperlossatratedlossTextArea.ValueChangingFcn = createCallbackFcn(app, @CopperlossatratedlossTextAreaValueChanging, true);
            app.CopperlossatratedlossTextArea.HorizontalAlignment = 'center';
            app.CopperlossatratedlossTextArea.FontName = 'Arial';
            app.CopperlossatratedlossTextArea.Position = [178 8 112 25];
            app.CopperlossatratedlossTextArea.Value = {'5'};

            % Create VLabel
            app.VLabel = uilabel(app.TransformerParametersPanel);
            app.VLabel.FontName = 'Arial';
            app.VLabel.FontSize = 14;
            app.VLabel.Position = [295 102 25 26];
            app.VLabel.Text = 'V';

            % Create UnitlessLabel
            app.UnitlessLabel = uilabel(app.TransformerParametersPanel);
            app.UnitlessLabel.FontName = 'Arial';
            app.UnitlessLabel.FontSize = 14;
            app.UnitlessLabel.Position = [295 79 55 26];
            app.UnitlessLabel.Text = 'Unitless';

            % Create VALabel
            app.VALabel = uilabel(app.TransformerParametersPanel);
            app.VALabel.FontName = 'Arial';
            app.VALabel.FontSize = 14;
            app.VALabel.Position = [295 54 25 26];
            app.VALabel.Text = 'VA';

            % Create WLabel_2
            app.WLabel_2 = uilabel(app.TransformerParametersPanel);
            app.WLabel_2.FontName = 'Arial';
            app.WLabel_2.FontSize = 14;
            app.WLabel_2.Position = [295 30 25 26];
            app.WLabel_2.Text = 'W';

            % Create WLabel_3
            app.WLabel_3 = uilabel(app.TransformerParametersPanel);
            app.WLabel_3.FontName = 'Arial';
            app.WLabel_3.FontSize = 14;
            app.WLabel_3.Position = [295 6 25 26];
            app.WLabel_3.Text = 'W';

            % Create LoadSliderLabel
            app.LoadSliderLabel = uilabel(app.UIFigure);
            app.LoadSliderLabel.FontName = 'Arial';
            app.LoadSliderLabel.FontSize = 24;
            app.LoadSliderLabel.FontWeight = 'bold';
            app.LoadSliderLabel.Position = [35 326 201 31];
            app.LoadSliderLabel.Text = 'Load Fraction (x)';

            % Create LoadSlider
            app.LoadSlider = uislider(app.UIFigure);
            app.LoadSlider.Limits = [0 1];
            app.LoadSlider.ValueChangingFcn = createCallbackFcn(app, @LoadSliderValueChanging, true);
            app.LoadSlider.StepMode = 'manual';
            app.LoadSlider.FontName = 'Arial';
            app.LoadSlider.Position = [35 311 649 3];
            app.LoadSlider.Value = 0.7;

            % Create CalculatorResultsPanel
            app.CalculatorResultsPanel = uipanel(app.UIFigure);
            app.CalculatorResultsPanel.AutoResizeChildren = 'off';
            app.CalculatorResultsPanel.BorderWidth = 0;
            app.CalculatorResultsPanel.Title = 'Calculator Results (at current load)';
            app.CalculatorResultsPanel.FontWeight = 'bold';
            app.CalculatorResultsPanel.FontSize = 24;
            app.CalculatorResultsPanel.Position = [28 1 660 264];

            % Create SecondaryVoltagePanel
            app.SecondaryVoltagePanel = uipanel(app.CalculatorResultsPanel);
            app.SecondaryVoltagePanel.AutoResizeChildren = 'off';
            app.SecondaryVoltagePanel.BorderWidth = 0;
            app.SecondaryVoltagePanel.TitlePosition = 'centertop';
            app.SecondaryVoltagePanel.Title = 'Secondary Voltage';
            app.SecondaryVoltagePanel.BackgroundColor = [1 1 1];
            app.SecondaryVoltagePanel.FontWeight = 'bold';
            app.SecondaryVoltagePanel.FontSize = 14;
            app.SecondaryVoltagePanel.Position = [4 129 154 85];

            % Create SecondaryVoltageValueLabel
            app.SecondaryVoltageValueLabel = uilabel(app.SecondaryVoltagePanel);
            app.SecondaryVoltageValueLabel.HorizontalAlignment = 'center';
            app.SecondaryVoltageValueLabel.FontSize = 18;
            app.SecondaryVoltageValueLabel.Position = [5 7 150 55];

            % Create SecondaryCurrentPanel
            app.SecondaryCurrentPanel = uipanel(app.CalculatorResultsPanel);
            app.SecondaryCurrentPanel.AutoResizeChildren = 'off';
            app.SecondaryCurrentPanel.BorderWidth = 0;
            app.SecondaryCurrentPanel.TitlePosition = 'centertop';
            app.SecondaryCurrentPanel.Title = 'Secondary Current';
            app.SecondaryCurrentPanel.BackgroundColor = [1 1 1];
            app.SecondaryCurrentPanel.FontWeight = 'bold';
            app.SecondaryCurrentPanel.FontSize = 14;
            app.SecondaryCurrentPanel.Position = [179 129 154 85];

            % Create SecondaryCurrentValueLabel
            app.SecondaryCurrentValueLabel = uilabel(app.SecondaryCurrentPanel);
            app.SecondaryCurrentValueLabel.HorizontalAlignment = 'center';
            app.SecondaryCurrentValueLabel.FontSize = 18;
            app.SecondaryCurrentValueLabel.Position = [1 7 155 55];

            % Create OutputPowerPanel
            app.OutputPowerPanel = uipanel(app.CalculatorResultsPanel);
            app.OutputPowerPanel.AutoResizeChildren = 'off';
            app.OutputPowerPanel.BorderWidth = 0;
            app.OutputPowerPanel.TitlePosition = 'centertop';
            app.OutputPowerPanel.Title = 'Output Power';
            app.OutputPowerPanel.BackgroundColor = [1 1 1];
            app.OutputPowerPanel.FontWeight = 'bold';
            app.OutputPowerPanel.FontSize = 14;
            app.OutputPowerPanel.Position = [357 129 154 85];

            % Create OutputPowerValueLabel
            app.OutputPowerValueLabel = uilabel(app.OutputPowerPanel);
            app.OutputPowerValueLabel.HorizontalAlignment = 'center';
            app.OutputPowerValueLabel.FontSize = 18;
            app.OutputPowerValueLabel.Position = [1 7 154 55];

            % Create CopperLossPanel
            app.CopperLossPanel = uipanel(app.CalculatorResultsPanel);
            app.CopperLossPanel.AutoResizeChildren = 'off';
            app.CopperLossPanel.BorderWidth = 0;
            app.CopperLossPanel.TitlePosition = 'centertop';
            app.CopperLossPanel.Title = 'Copper Loss';
            app.CopperLossPanel.BackgroundColor = [1 1 1];
            app.CopperLossPanel.FontWeight = 'bold';
            app.CopperLossPanel.FontSize = 14;
            app.CopperLossPanel.Position = [4 19 154 85];

            % Create CopperLossValueLabel
            app.CopperLossValueLabel = uilabel(app.CopperLossPanel);
            app.CopperLossValueLabel.HorizontalAlignment = 'center';
            app.CopperLossValueLabel.FontSize = 18;
            app.CopperLossValueLabel.Position = [1 8 154 54];

            % Create CoreLossPanel
            app.CoreLossPanel = uipanel(app.CalculatorResultsPanel);
            app.CoreLossPanel.AutoResizeChildren = 'off';
            app.CoreLossPanel.BorderWidth = 0;
            app.CoreLossPanel.TitlePosition = 'centertop';
            app.CoreLossPanel.Title = 'Core Loss';
            app.CoreLossPanel.BackgroundColor = [1 1 1];
            app.CoreLossPanel.FontWeight = 'bold';
            app.CoreLossPanel.FontSize = 14;
            app.CoreLossPanel.Position = [179 19 154 85];

            % Create CoreLossValueLabel
            app.CoreLossValueLabel = uilabel(app.CoreLossPanel);
            app.CoreLossValueLabel.HorizontalAlignment = 'center';
            app.CoreLossValueLabel.FontSize = 18;
            app.CoreLossValueLabel.Position = [1 7 155 55];

            % Create EfficiencynPanel
            app.EfficiencynPanel = uipanel(app.CalculatorResultsPanel);
            app.EfficiencynPanel.AutoResizeChildren = 'off';
            app.EfficiencynPanel.BorderWidth = 0;
            app.EfficiencynPanel.TitlePosition = 'centertop';
            app.EfficiencynPanel.Title = 'Efficiency (n)';
            app.EfficiencynPanel.BackgroundColor = [1 1 1];
            app.EfficiencynPanel.FontWeight = 'bold';
            app.EfficiencynPanel.FontSize = 14;
            app.EfficiencynPanel.Position = [357 19 154 85];

            % Create EfficiencyValueLabel
            app.EfficiencyValueLabel = uilabel(app.EfficiencynPanel);
            app.EfficiencyValueLabel.HorizontalAlignment = 'center';
            app.EfficiencyValueLabel.FontSize = 18;
            app.EfficiencyValueLabel.Position = [1 7 154 55];

            % Create LoadRLabel
            app.LoadRLabel = uilabel(app.UIFigure);
            app.LoadRLabel.HorizontalAlignment = 'center';
            app.LoadRLabel.FontSize = 24;
            app.LoadRLabel.Position = [661 628 55 59];
            app.LoadRLabel.Text = {'Load'; '(R)'};

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = transfomerApp_code

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

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