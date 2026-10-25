v1_rms = 120;
a = 10;
s_rated = 100;

v2_rms = v1_rms / a;
i2_rated = s_rated/v2_rms;

fprintf("Primary voltage: %.2fV RMS\n", v1_rms)
fprintf("Turns ratio: %i \n", a)
fprintf("Rated VA: %.2f VA\n", s_rated)
fprintf("Secondary voltage: %.2fV RMS\n", v2_rms)
fprintf("Secondary rated current: %.2f A \n", i2_rated)

x = 0.70;
i2 = x * i2_rated;
fprintf("Secondary current: %.2f A\n", i2)
fprintf("Secondary current is running at %i%% of the rated current\n", x*100)

p_out = v2_rms * i2;
fprintf("Power output: %.2f Watts\n", p_out)

r_load = v2_rms / i2;
fprintf("Equivalent Resistive load: %.2f Ohms\n", r_load)

x_vector = linspace(0, 1, 50);
i2_vector = x_vector .* i2_rated
p_out_vector = i2_vector .* v2_rms

p_copper_rated = 5;
p_copper = x_vector.^2 .* p_copper_rated

for k = 1:length(p_copper)
    fprintf("heat_loss: %.2f Watts | Load: %.2f%%\n", p_copper(k), x_vector(k).*100);
end

p_core = 2
p_loss = p_core + p_copper;

%Conservation of energy
p_in = p_out_vector + p_loss;

%efficiency n
n = (p_out_vector./p_in) * 100;

%plotting output power vs. Load
figure(1)
hold on
plot(x_vector, p_out_vector, '-')
plot(x, p_out, 'ro', 'MarkerSize', 10)
xlabel("Load Fraction (0-1)")
ylabel("Output Power (Watts)")
title("Transformer output power vs. Load")
legend("Power Output (W)", sprintf("Output Power: %.2f W at %i%% Load", p_out, x*100), 'Location', 'northwest')
grid on
hold off

%plotting Transformer Losses vs. Load Fraction
figure(2)
hold on
plot(x_vector, p_copper, 'Color', [0.95 0.45 0.15])
yline(p_core, 'Color', [0.20 0.65 0.95])
plot(x, x^2 * p_copper_rated, "o", "MarkerSize", 10, 'MarkerFaceColor', [0.95 0.45 0.15])
plot(x, p_core, "o", "MarkerSize", 10, 'MarkerFaceColor', [0.20 0.65 0.95])
title("Transformer losses, vs. Load Fraction")
xlabel("Load Fraction (0-1)")
ylabel("Power Loss (W)")
grid on
legend("Copper Loss", "Core Loss", sprintf("Copper Loss: %.2f W at %i%% load", x^2 * p_copper_rated, x*100), sprintf("Core Loss: %.2f W at %i%% Load", p_core, x*100))
hold off

%Plotting Efficiency
figure(3)
hold on
plot(x_vector, n)
plot(x, p_out/(p_out+(p_core + x^2*p_copper_rated))*100, "o", "MarkerSize", 10, 'MarkerFaceColor', [0.20 0.65 0.95])
xlabel("Load Fraction (0-1)")
ylabel("Efficiency (%)")
title("Transformer Efficiency vs. Load Fraction")
legend("Transformer Efficiency", sprintf("Efficiency: %.2f%% at %i%% Load", p_out/(p_out + p_core + x^2*p_copper_rated)*100, x*100), 'Location', 'southeast')
grid on
hold off