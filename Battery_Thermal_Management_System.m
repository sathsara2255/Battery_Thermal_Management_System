
%% =================== PARAMETERS ==============================
% ----- Battery cell -----
m_cell = 0.045;          % kg
cp_cell = 900;           % J/(kg*K)
R_int = 0.02;            % Ohm (internal resistance)

% ----- Coolant -----
m_cool = 0.5;            % kg
cp_cool = 4180;          % J/(kg*K)
hA_max = 50;             % W/K  (max heat transfer conductance)
h_rad  = 2;              % W/K  (radiator to ambient conductance)

% ----- Environment & Controller -----
T_amb = 25 + 273.15;     % K (ambient)
T_set = 30 + 273.15;     % K (target cell temperature)
Kp = 0.03;               % proportional gain
Ki = 0.005;              % integral gain
u_min = 0;               % lower limit of cooling fraction
u_max = 1;               % upper limit (max cooling)

% ----- Initial conditions -----
T0_cell = 25 + 273.15;   % K
T0_cool = 25 + 273.15;   % K
x0 = [T0_cell; T0_cool; 0]; % [Tcell, Tcool, integral_error]

% ----- Simulation time -----
tspan = [0 900];         % seconds (15 minutes)

%% ================== DEFINE CURRENT PROFILE ====================
% current_profile() gives current vs. time
I_profile = @(t) current_profile(t);

%% ================== RUN SIMULATION (ODE45) ====================
opts = odeset('RelTol',1e-6,'AbsTol',1e-7);
[t, x] = ode45(@(tt,xx) btms_odes(tt,xx,I_profile,T_set,...
    m_cell,cp_cell,R_int,m_cool,cp_cool,hA_max,h_rad,...
    T_amb,Kp,Ki,u_min,u_max), tspan, x0, opts);

% Extract results
Tcell = x(:,1); 
Tcool = x(:,2);
Ivec  = arrayfun(I_profile,t);

% Compute controller output (for plotting)
u_hist = zeros(size(t));
for k = 1:length(t)
    err = Tcell(k) - T_set;
    int_err = x(k,3);
    u = Kp * err + Ki * int_err;
    u = max(u_min, min(u_max, u));
    u_hist(k) = u;
end

%% ===================== PLOT RESULTS ===========================
figure('Units','normalized','Position',[0.1 0.1 0.7 0.8]);

% ----------- (1) TEMPERATURES -----------
subplot(3,1,1);
plot(t, Tcell-273.15, 'LineWidth',1.6); hold on;
plot(t, Tcool-273.15, '--', 'LineWidth',1.4);
yline(T_set-273.15,'r--','Setpoint');
xlabel('Time (s)'); ylabel('Temperature (°C)');
legend('Cell Temperature','Coolant Temperature','Setpoint','Location','best');
title('(1) Temperature Response of Cell and Coolant');
grid on;

% ----------- (2) CURRENT PROFILE -----------
subplot(3,1,2);
plot(t, Ivec, 'LineWidth',1.6);
xlabel('Time (s)'); ylabel('Current (A)');
title('(2) Battery Current Profile (Positive = Discharge, Negative = Charge)');
grid on;

% ----------- (3) CONTROLLER OUTPUT -----------
subplot(3,1,3);
plot(t, u_hist*100, 'LineWidth',1.6);
xlabel('Time (s)'); ylabel('Cooling Effort (%)');
title('(3) PI Controller Output (Cooling Fraction u ×100%)');
grid on;

sgtitle('Battery Thermal Management System Simulation Results');

%% ===================== HELPER FUNCTIONS =======================
function dx = btms_odes(t,x,I_profile,T_set,...
    m_cell,cp_cell,R_int,m_cool,cp_cool,hA_max,h_rad,...
    T_amb,Kp,Ki,u_min,u_max)

    % States
    Tcell = x(1);
    Tcool = x(2);
    int_err = x(3);

    % Current at time t
    I = I_profile(t);

    % Heat generation inside the cell (I^2 * R)
    Q_gen = I^2 * R_int;

    % PI controller
    err = Tcell - T_set;
    u_unsat = Kp*err + Ki*int_err;
    u = max(u_min, min(u_max, u_unsat)); % saturate

    % Heat transfers
    Q_cell_to_cool = hA_max * u * (Tcell - Tcool);
    Q_cool_to_amb  = h_rad * (Tcool - T_amb);

    % Differential equations
    dTcell = (Q_gen - Q_cell_to_cool) / (m_cell * cp_cell);
    dTcool = (Q_cell_to_cool - Q_cool_to_amb) / (m_cool * cp_cool);
    dint   = err; % integrate error for PI control

    dx = [dTcell; dTcool; dint];
end

function I = current_profile(t)
    % Simple current schedule (A)
    % 0-200 s : discharge 40 A
    % 200-400 s: rest 0 A
    % 400-700 s: heavy discharge 80 A
    % 700-900 s: charge -20 A
    if t < 200
        I = 40;
    elseif t < 400
        I = 0;
    elseif t < 700
        I = 80;
    else
        I = -20;
    end
end
