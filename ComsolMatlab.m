%% FULL SCRIPT WITH CORRECT CANOPY CENTER AT (2.5, 1, 0)

close all; clear; clc;

% --- Add LiveLink path ---
addpath('C:\Program Files\COMSOL\COMSOL64\Multiphysics\mli');

% --- Load model ---
modelPath = 'C:\Users\nimadane\Desktop\Nima\canopy optimization.mph';
model = mphload(modelPath);

% --- Common settings ---
studyTag = 'std1';
dsetTag = 'dset1';
expr = 'tcs.c_w_methane';

tVec = 0:0.1:1;
nT = numel(tVec);
nPoints = 1000;
epsilon = 0.01;  % 1 cm safety margin

outputDir = 'C:\Users\nimadane\Desktop\Nima\Sweep_results';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

% ==================== CANOPY CENTER OFFSET ====================
x_center = 2.5;   % m
y_center = 1.0;   % m
z_base   = 0.0;   % m  (your floor/wellhead level is at global z = 0)

fprintf('=== ALL SWEEPS WITH POINTS CENTERED AT (%.1f, %.1f, %.1f) ===\n\n', x_center, y_center, z_base);

%% CELL 1: Wheight sweep
sweep_values = [0.150 0.200 0.250 0.300 0.350];

for i = 1:numel(sweep_values)
    val = sweep_values(i);
    fprintf('>>> (%2d/%2d) Running Wheight = %.3f m ...\n', i, numel(sweep_values), val);
    
    model.param.set('Wheight', '0.15[m]');
    model.param.set('Cheight', '1[m]');
    model.param.set('Wr', '0.05[m]');
    model.param.set('Cr', '0.6[m]');
    model.param.set('PHr', '0.396[m]');
    model.param.set('Mq', '0.05[kg/h]');
    model.param.set('Aq', '0.95');
    
    model.param.set('Wheight', sprintf('%.10f[m]', val));
    model.geom('geom1').run;
    
    Wheight_val = str2double(regexprep(string(model.param.get('Wheight')), '\[.*\]', ''));
    Cheight_val = str2double(regexprep(string(model.param.get('Cheight')), '\[.*\]', ''));
    Wr_val      = str2double(regexprep(string(model.param.get('Wr')),      '\[.*\]', ''));
    Cr_val      = str2double(regexprep(string(model.param.get('Cr')),      '\[.*\]', ''));
    PHr_val     = str2double(regexprep(string(model.param.get('PHr')),     '\[.*\]', ''));
    Mq_val      = str2double(regexprep(string(model.param.get('Mq')),      '\[.*\]', ''));
    Aq_val      = str2double(regexprep(string(model.param.get('Aq')),      '\[.*\]', ''));
    
    r_min = Wr_val + epsilon;
    r_max = Cr_val - epsilon;
    z_min = Wheight_val + epsilon;
    z_max = Cheight_val - epsilon;
    
    if r_min >= r_max || z_min >= z_max
        error('Geometry too thin for 1 cm safety margin');
    end
    
    rng(i + 2025);
    r_squared = r_min^2 + rand(nPoints,1) * (r_max^2 - r_min^2);
    r = sqrt(r_squared);
    theta = 2*pi*rand(nPoints,1);
    x = r .* cos(theta) + x_center;
    y = r .* sin(theta) + y_center;
    z = z_min + rand(nPoints,1) * (z_max - z_min) + z_base;
    coords = [x y z];
    
    model.study(studyTag).run;
    
    results = zeros(nPoints, nT);
    for k = 1:nT
        results(:,k) = mphinterp(model, expr, 'dataset', dsetTag, 't', tVec(k), 'coord', coords');
    end
    
    val_str = sprintf('%.3f', val);
    csvFile = fullfile(outputDir, sprintf('methane_Wheight_%s_rand1000.csv', val_str));
    
    fid = fopen(csvFile, 'w');
    fprintf(fid, '# Wheight = %.3f m (swept)\n', val);
    fprintf(fid, '# Cheight = %.3f m\n', Cheight_val);
    fprintf(fid, '# Wr = %.3f m\n', Wr_val);
    fprintf(fid, '# Cr = %.3f m\n', Cr_val);
    fprintf(fid, '# PHr = %.4f m\n', PHr_val);
    fprintf(fid, '# Mq = %.5f kg/h\n', Mq_val);
    fprintf(fid, '# Aq = %.4f\n', Aq_val);
    fprintf(fid, '# Points centered at (x,y,z) = (%.1f, %.1f, %.1f)\n', x_center, y_center, z_base);
    fprintf(fid, '# 1000 uniform random points with 1 cm safety margin\n');
    fprintf(fid, 'Point,X[m],Y[m],Z[m]');
    for c = 1:nT, fprintf(fid, ',t=%.1f min', tVec(c)); end
    fprintf(fid, '\n');
    
    for p = 1:nPoints
        fprintf(fid, '%d,%.10e,%.10e,%.10e', p, coords(p,:));
        fprintf(fid, ',%g', results(p,:));
        fprintf(fid, '\n');
    end
    fclose(fid);
    
    fprintf(' ✓ SUCCESS → %s\n\n', csvFile);
    beep;
end

%% CELL 2: Cheight sweep - 1000 fresh random points centered at (2.5, 1.0, 0.0)

sweep_values = [0.500 0.750 1.000 1.250 1.500];

for i = 1:numel(sweep_values)
    val = sweep_values(i);
    fprintf('>>> (%2d/%2d) Running Cheight = %.3f m ...\n', i, numel(sweep_values), val);
    
    % Reset to base state
    model.param.set('Wheight', '0.15[m]');
    model.param.set('Cheight', '1[m]');
    model.param.set('Wr', '0.05[m]');
    model.param.set('Cr', '0.6[m]');
    model.param.set('PHr', '0.396[m]');
    model.param.set('Mq', '0.05[kg/h]');
    model.param.set('Aq', '0.95');
    
    % Apply swept value
    model.param.set('Cheight', sprintf('%.10f[m]', val));
    model.geom('geom1').run;
    
    % --- Robust parameter reading ---
    Wheight_val = str2double(regexprep(string(model.param.get('Wheight')), '\[.*\]', ''));
    Cheight_val = str2double(regexprep(string(model.param.get('Cheight')), '\[.*\]', ''));
    Wr_val      = str2double(regexprep(string(model.param.get('Wr')),      '\[.*\]', ''));
    Cr_val      = str2double(regexprep(string(model.param.get('Cr')),      '\[.*\]', ''));
    PHr_val     = str2double(regexprep(string(model.param.get('PHr')),     '\[.*\]', ''));
    Mq_val      = str2double(regexprep(string(model.param.get('Mq')),      '\[.*\]', ''));
    Aq_val      = str2double(regexprep(string(model.param.get('Aq')),      '\[.*\]', ''));
    
    % --- 1000 points correctly placed inside canopy ---
    r_min = Wr_val + epsilon;
    r_max = Cr_val - epsilon;
    z_min = Wheight_val + epsilon;
    z_max = Cheight_val - epsilon;
    
    if r_min >= r_max || z_min >= z_max
        error('Geometry too thin for 1 cm safety margin');
    end
    
    rng(i + 2025);
    r_squared = r_min^2 + rand(nPoints,1) * (r_max^2 - r_min^2);
    r = sqrt(r_squared);
    theta = 2*pi*rand(nPoints,1);
    x = r .* cos(theta) + x_center;   % 2.5
    y = r .* sin(theta) + y_center;   % 1.0
    z = z_min + rand(nPoints,1) * (z_max - z_min) + z_base;   % 0.0
    
    coords = [x y z];
    
    % Solve
    model.study(studyTag).run;
    
    % Interpolate
    results = zeros(nPoints, nT);
    for k = 1:nT
        results(:,k) = mphinterp(model, expr, 'dataset', dsetTag, 't', tVec(k), 'coord', coords');
    end
    
    % Save CSV
    val_str = sprintf('%.3f', val);
    csvFile = fullfile(outputDir, sprintf('methane_Cheight_%s_rand1000.csv', val_str));
    
    fid = fopen(csvFile, 'w');
    fprintf(fid, '# Cheight = %.3f m (swept)\n', val);
    fprintf(fid, '# Wheight = %.3f m\n', Wheight_val);
    fprintf(fid, '# Wr = %.3f m\n', Wr_val);
    fprintf(fid, '# Cr = %.3f m\n', Cr_val);
    fprintf(fid, '# PHr = %.4f m\n', PHr_val);
    fprintf(fid, '# Mq = %.5f kg/h\n', Mq_val);
    fprintf(fid, '# Aq = %.4f\n', Aq_val);
    fprintf(fid, '# Points centered at (x,y,z) = (%.1f, %.1f, %.1f)\n', x_center, y_center, z_base);
    fprintf(fid, '# 1000 uniform random points with 1 cm safety margin\n');
    fprintf(fid, 'Point,X[m],Y[m],Z[m]');
    for c = 1:nT, fprintf(fid, ',t=%.1f min', tVec(c)); end
    fprintf(fid, '\n');
    
    for p = 1:nPoints
        fprintf(fid, '%d,%.10e,%.10e,%.10e', p, coords(p,:));
        fprintf(fid, ',%g', results(p,:));
        fprintf(fid, '\n');
    end
    fclose(fid);
    
    fprintf(' ✓ SUCCESS → %s\n\n', csvFile);
    beep;
end

fprintf('*** Cheight sweep completed - all 5 runs 100%% successful ***\n');
beep; beep; beep;

%% CELL 3: Wr sweep - 1000 fresh random points centered at (2.5, 1.0, 0.0)

sweep_values = [0.05 0.10 0.15 0.20 0.25];

for i = 1:numel(sweep_values)
    val = sweep_values(i);
    fprintf('>>> (%2d/%d) Running Wr = %.3f m ...\n', i, numel(sweep_values), val);
    
    % Reset to base state
    model.param.set('Wheight', '0.15[m]');
    model.param.set('Cheight', '1[m]');
    model.param.set('Wr', '0.05[m]');
    model.param.set('Cr', '0.6[m]');
    model.param.set('PHr', '0.396[m]');
    model.param.set('Mq', '0.05[kg/h]');
    model.param.set('Aq', '0.95');
    
    % Apply swept value
    model.param.set('Wr', sprintf('%.10f[m]', val));
    model.geom('geom1').run;
    
    % --- Robust parameter reading ---
    Wheight_val = str2double(regexprep(string(model.param.get('Wheight')), '\[.*\]', ''));
    Cheight_val = str2double(regexprep(string(model.param.get('Cheight')), '\[.*\]', ''));
    Wr_val      = str2double(regexprep(string(model.param.get('Wr')),      '\[.*\]', ''));
    Cr_val      = str2double(regexprep(string(model.param.get('Cr')),      '\[.*\]', ''));
    PHr_val     = str2double(regexprep(string(model.param.get('PHr')),     '\[.*\]', ''));
    Mq_val      = str2double(regexprep(string(model.param.get('Mq')),      '\[.*\]', ''));
    Aq_val      = str2double(regexprep(string(model.param.get('Aq')),      '\[.*\]', ''));
    
    % --- 1000 points correctly placed inside canopy ---
    r_min = Wr_val + epsilon;
    r_max = Cr_val - epsilon;
    z_min = Wheight_val + epsilon;
    z_max = Cheight_val - epsilon;
    
    if r_min >= r_max || z_min >= z_max
        error('Geometry too thin for 1 cm safety margin');
    end
    
    rng(i + 2025);
    r_squared = r_min^2 + rand(nPoints,1) * (r_max^2 - r_min^2);
    r = sqrt(r_squared);
    theta = 2*pi*rand(nPoints,1);
    x = r .* cos(theta) + x_center;   % 2.5
    y = r .* sin(theta) + y_center;   % 1.0
    z = z_min + rand(nPoints,1) * (z_max - z_min) + z_base;   % 0.0
    
    coords = [x y z];
    
    % Solve
    model.study(studyTag).run;
    
    % Interpolate
    results = zeros(nPoints, nT);
    for k = 1:nT
        results(:,k) = mphinterp(model, expr, 'dataset', dsetTag, 't', tVec(k), 'coord', coords');
    end
    
    % Save CSV
    val_str = sprintf('%.3f', val);
    csvFile = fullfile(outputDir, sprintf('methane_Wr_%s_rand1000.csv', val_str));
    
    fid = fopen(csvFile, 'w');
    fprintf(fid, '# Wr = %.3f m (swept)\n', val);
    fprintf(fid, '# Wheight = %.3f m\n', Wheight_val);
    fprintf(fid, '# Cheight = %.3f m\n', Cheight_val);
    fprintf(fid, '# Cr = %.3f m\n', Cr_val);
    fprintf(fid, '# PHr = %.4f m\n', PHr_val);
    fprintf(fid, '# Mq = %.5f kg/h\n', Mq_val);
    fprintf(fid, '# Aq = %.4f\n', Aq_val);
    fprintf(fid, '# Points centered at (x,y,z) = (%.1f, %.1f, %.1f)\n', x_center, y_center, z_base);
    fprintf(fid, '# 1000 uniform random points with 1 cm safety margin\n');
    fprintf(fid, 'Point,X[m],Y[m],Z[m]');
    for c = 1:nT, fprintf(fid, ',t=%.1f min', tVec(c)); end
    fprintf(fid, '\n');
    
    for p = 1:nPoints
        fprintf(fid, '%d,%.10e,%.10e,%.10e', p, coords(p,:));
        fprintf(fid, ',%g', results(p,:));
        fprintf(fid, '\n');
    end
    fclose(fid);
    
    fprintf(' ✓ SUCCESS → %s\n\n', csvFile);
    beep;
end

fprintf('*** Wr sweep completed - all 5 runs 100%% successful ***\n');
beep; beep; beep;

%% CELL 4: Cr sweep - 1000 fresh random points centered at (2.5, 1.0, 0.0) + PHr = 0.66 × Cr

sweep_values = [0.20 0.40 0.60 0.75 0.90];  % your actual sweep range

for i = 1:numel(sweep_values)
    val = sweep_values(i);
    PHr_new = 0.66 * val;   % perfect proportional scaling
    
    fprintf('>>> (%2d/%2d) Running Cr = %.3f m  →  PHr = %.4f m ...\n', i, numel(sweep_values), val, PHr_new);
    
    % Reset to base state
    model.param.set('Wheight', '0.15[m]');
    model.param.set('Cheight', '1[m]');
    model.param.set('Wr', '0.05[m]');
    model.param.set('Cr', '0.6[m]');
    model.param.set('PHr', '0.396[m]');
    model.param.set('Mq', '0.05[kg/h]');
    model.param.set('Aq', '0.95');
    
    % Apply swept Cr and scaled PHr
    model.param.set('Cr', sprintf('%.10f[m]', val));
    model.param.set('PHr', sprintf('%.10f[m]', PHr_new));
    model.geom('geom1').run;
    
    % --- Robust parameter reading ---
    Wheight_val = str2double(regexprep(string(model.param.get('Wheight')), '\[.*\]', ''));
    Cheight_val = str2double(regexprep(string(model.param.get('Cheight')), '\[.*\]', ''));
    Wr_val      = str2double(regexprep(string(model.param.get('Wr')),      '\[.*\]', ''));
    Cr_val      = str2double(regexprep(string(model.param.get('Cr')),      '\[.*\]', ''));
    PHr_val     = str2double(regexprep(string(model.param.get('PHr')),     '\[.*\]', ''));
    Mq_val      = str2double(regexprep(string(model.param.get('Mq')),      '\[.*\]', ''));
    Aq_val      = str2double(regexprep(string(model.param.get('Aq')),      '\[.*\]', ''));
    
    % --- 1000 points correctly placed inside canopy ---
    r_min = Wr_val + epsilon;
    r_max = Cr_val - epsilon;
    z_min = Wheight_val + epsilon;
    z_max = Cheight_val - epsilon;
    
    if r_min >= r_max || z_min >= z_max
        error('Geometry too thin for 1 cm safety margin');
    end
    
    rng(i + 2025);
    r_squared = r_min^2 + rand(nPoints,1) * (r_max^2 - r_min^2);
    r = sqrt(r_squared);
    theta = 2*pi*rand(nPoints,1);
    x = r .* cos(theta) + x_center;   % 2.5
    y = r .* sin(theta) + y_center;   % 1.0
    z = z_min + rand(nPoints,1) * (z_max - z_min) + z_base;   % 0.0
    
    coords = [x y z];
    
    % Solve
    model.study(studyTag).run;
    
    % Interpolate
    results = zeros(nPoints, nT);
    for k = 1:nT
        results(:,k) = mphinterp(model, expr, 'dataset', dsetTag, 't', tVec(k), 'coord', coords');
    end
    
    % Save CSV
    val_str = sprintf('%.2f', val);   % Cr files were saved as 0.20, 0.40 etc.
    csvFile = fullfile(outputDir, sprintf('methane_Cr_%s_rand1000.csv', val_str));
    
    fid = fopen(csvFile, 'w');
    fprintf(fid, '# Cr = %.3f m (swept)\n', val);
    fprintf(fid, '# PHr = %.4f m (scaled = 0.66 × Cr)\n', PHr_val);
    fprintf(fid, '# Wheight = %.3f m\n', Wheight_val);
    fprintf(fid, '# Cheight = %.3f m\n', Cheight_val);
    fprintf(fid, '# Wr = %.3f m\n', Wr_val);
    fprintf(fid, '# Mq = %.5f kg/h\n', Mq_val);
    fprintf(fid, '# Aq = %.4f\n', Aq_val);
    fprintf(fid, '# Points centered at (x,y,z) = (%.1f, %.1f, %.1f)\n', x_center, y_center, z_base);
    fprintf(fid, '# 1000 uniform random points with 1 cm safety margin\n');
    fprintf(fid, 'Point,X[m],Y[m],Z[m]');
    for c = 1:nT, fprintf(fid, ',t=%.1f min', tVec(c)); end
    fprintf(fid, '\n');
    
    for p = 1:nPoints
        fprintf(fid, '%d,%.10e,%.10e,%.10e', p, coords(p,:));
        fprintf(fid, ',%g', results(p,:));
        fprintf(fid, '\n');
    end
    fclose(fid);
    
    fprintf(' ✓ SUCCESS → %s\n\n\n', csvFile);
    beep;
end

fprintf('*** Cr sweep (with perfect PHr = 0.66×Cr scaling) completed - all 5 runs 100%% successful ***\n');
beep; beep; beep;

%% CELL 5: PHr sweep - 1000 fresh random points centered at (2.5, 1.0, 0.0) (Cr fixed at 0.6 m)

sweep_values = [0.060 0.180 0.300 0.420 0.540];  % 0.1×Cr → 0.9×Cr with Cr = 0.6 m

for i = 1:numel(sweep_values)
    val = sweep_values(i);
    
    fprintf('>>> (%2d/%2d) Running PHr = %.4f m ...\n', i, numel(sweep_values), val);
    
    % Reset to base state
    model.param.set('Wheight', '0.15[m]');
    model.param.set('Cheight', '1[m]');
    model.param.set('Wr', '0.05[m]');
    model.param.set('Cr', '0.6[m]');
    model.param.set('PHr', '0.396[m]');
    model.param.set('Mq', '0.05[kg/h]');
    model.param.set('Aq', '0.95');
    
    % Apply swept PHr only (Cr stays fixed at 0.6 m)
    model.param.set('PHr', sprintf('%.10f[m]', val));
    model.geom('geom1').run;
    
    % --- Robust parameter reading ---
    Wheight_val = str2double(regexprep(string(model.param.get('Wheight')), '\[.*\]', ''));
    Cheight_val = str2double(regexprep(string(model.param.get('Cheight')), '\[.*\]', ''));
    Wr_val      = str2double(regexprep(string(model.param.get('Wr')),      '\[.*\]', ''));
    Cr_val      = str2double(regexprep(string(model.param.get('Cr')),      '\[.*\]', ''));
    PHr_val     = str2double(regexprep(string(model.param.get('PHr')),     '\[.*\]', ''));
    Mq_val      = str2double(regexprep(string(model.param.get('Mq')),      '\[.*\]', ''));
    Aq_val      = str2double(regexprep(string(model.param.get('Aq')),      '\[.*\]', ''));
    
    % --- 1000 points correctly placed inside canopy ---
    r_min = Wr_val + epsilon;
    r_max = Cr_val - epsilon;
    z_min = Wheight_val + epsilon;
    z_max = Cheight_val - epsilon;
    
    if r_min >= r_max || z_min >= z_max
        error('Geometry too thin for 1 cm safety margin');
    end
    
    rng(i + 2025);
    r_squared = r_min^2 + rand(nPoints,1) * (r_max^2 - r_min^2);
    r = sqrt(r_squared);
    theta = 2*pi*rand(nPoints,1);
    x = r .* cos(theta) + x_center;   % 2.5
    y = r .* sin(theta) + y_center;   % 1.0
    z = z_min + rand(nPoints,1) * (z_max - z_min) + z_base;   % 0.0
    
    coords = [x y z];
    
    % Solve
    model.study(studyTag).run;
    
    % Interpolate
    results = zeros(nPoints, nT);
    for k = 1:nT
        results(:,k) = mphinterp(model, expr, 'dataset', dsetTag, 't', tVec(k), 'coord', coords');
    end
    
    % Save CSV
    val_str = sprintf('%.4f', val);
    csvFile = fullfile(outputDir, sprintf('methane_PHr_%s_rand1000.csv', val_str));
    
    fid = fopen(csvFile, 'w');
    fprintf(fid, '# PHr = %.4f m (swept)\n', val);
    fprintf(fid, '# Cr = %.3f m (fixed)\n', Cr_val);
    fprintf(fid, '# Wheight = %.3f m\n', Wheight_val);
    fprintf(fid, '# Cheight = %.3f m\n', Cheight_val);
    fprintf(fid, '# Wr = %.3f m\n', Wr_val);
    fprintf(fid, '# Mq = %.5f kg/h\n', Mq_val);
    fprintf(fid, '# Aq = %.4f\n', Aq_val);
    fprintf(fid, '# Points centered at (x,y,z) = (%.1f, %.1f, %.1f)\n', x_center, y_center, z_base);
    fprintf(fid, '# 1000 uniform random points with 1 cm safety margin\n');
    fprintf(fid, 'Point,X[m],Y[m],Z[m]');
    for c = 1:nT, fprintf(fid, ',t=%.1f min', tVec(c)); end
    fprintf(fid, '\n');
    
    for p = 1:nPoints
        fprintf(fid, '%d,%.10e,%.10e,%.10e', p, coords(p,:));
        fprintf(fid, ',%g', results(p,:));
        fprintf(fid, '\n');
    end
    fclose(fid);
    
    fprintf(' ✓ SUCCESS → %s\n\n', csvFile);
    beep;
end

fprintf('*** PHr sweep completed - all 5 runs 100%% successful ***\n');
beep; beep; beep;
%% CELL 6: Mq sweep - 1000 fresh random points centered at (2.5, 1.0, 0.0) (geometry fixed)

sweep_values = [0.01000 0.07000 0.13000 0.19000 0.25000];

for i = 1:numel(sweep_values)
    val = sweep_values(i);
    
    fprintf('>>> (%2d/%2d) Running Mq = %.5f kg/h ...\n', i, numel(sweep_values), val);
    
    % Reset to base state
    model.param.set('Wheight', '0.15[m]');
    model.param.set('Cheight', '1[m]');
    model.param.set('Wr', '0.05[m]');
    model.param.set('Cr', '0.6[m]');
    model.param.set('PHr', '0.396[m]');
    model.param.set('Mq', '0.05[kg/h]');
    model.param.set('Aq', '0.95');
    
    % Apply swept Mq only
    model.param.set('Mq', sprintf('%.10f[kg/h]', val));
    model.geom('geom1').run;  % safe to keep
    
    % --- Robust parameter reading ---
    Wheight_val = str2double(regexprep(string(model.param.get('Wheight')), '\[.*\]', ''));
    Cheight_val = str2double(regexprep(string(model.param.get('Cheight')), '\[.*\]', ''));
    Wr_val      = str2double(regexprep(string(model.param.get('Wr')),      '\[.*\]', ''));
    Cr_val      = str2double(regexprep(string(model.param.get('Cr')),      '\[.*\]', ''));
    PHr_val     = str2double(regexprep(string(model.param.get('PHr')),     '\[.*\]', ''));
    Mq_val      = str2double(regexprep(string(model.param.get('Mq')),      '\[.*\]', ''));
    Aq_val      = str2double(regexprep(string(model.param.get('Aq')),      '\[.*\]', ''));
    
    % --- 1000 points correctly placed inside canopy (same geometry for all Mq) ---
    r_min = Wr_val + epsilon;
    r_max = Cr_val - epsilon;
    z_min = Wheight_val + epsilon;
    z_max = Cheight_val - epsilon;
    
    if r_min >= r_max || z_min >= z_max
        error('Geometry too thin for 1 cm safety margin');
    end
    
    rng(i + 2025);
    r_squared = r_min^2 + rand(nPoints,1) * (r_max^2 - r_min^2);
    r = sqrt(r_squared);
    theta = 2*pi*rand(nPoints,1);
    x = r .* cos(theta) + x_center;   % 2.5
    y = r .* sin(theta) + y_center;   % 1.0
    z = z_min + rand(nPoints,1) * (z_max - z_min) + z_base;   % 0.0
    
    coords = [x y z];
    
    % Solve
    model.study(studyTag).run;
    
    % Interpolate
    results = zeros(nPoints, nT);
    for k = 1:nT
        results(:,k) = mphinterp(model, expr, 'dataset', dsetTag, 't', tVec(k), 'coord', coords');
    end
    
    % Save CSV
    val_str = sprintf('%.5f', val);
    csvFile = fullfile(outputDir, sprintf('methane_Mq_%s_rand1000.csv', val_str));
    
    fid = fopen(csvFile, 'w');
    fprintf(fid, '# Mq = %.5f kg/h (swept)\n', val);
    fprintf(fid, '# Wheight = %.3f m\n', Wheight_val);
    fprintf(fid, '# Cheight = %.3f m\n', Cheight_val);
    fprintf(fid, '# Wr = %.3f m\n', Wr_val);
    fprintf(fid, '# Cr = %.3f m\n', Cr_val);
    fprintf(fid, '# PHr = %.4f m\n', PHr_val);
    fprintf(fid, '# Aq = %.4f\n', Aq_val);
    fprintf(fid, '# Points centered at (x,y,z) = (%.1f, %.1f, %.1f)\n', x_center, y_center, z_base);
    fprintf(fid, '# 1000 uniform random points with 1 cm safety margin\n');
    fprintf(fid, 'Point,X[m],Y[m],Z[m]');
    for c = 1:nT, fprintf(fid, ',t=%.1f min', tVec(c)); end
    fprintf(fid, '\n');
    
    for p = 1:nPoints
        fprintf(fid, '%d,%.10e,%.10e,%.10e', p, coords(p,:));
        fprintf(fid, ',%g', results(p,:));
        fprintf(fid, '\n');
    end
    fclose(fid);
    
    fprintf(' ✓ SUCCESS → %s\n\n', csvFile);
    beep;
end

fprintf('*** Mq sweep completed - all 5 runs 100%% successful ***\n');
beep; beep; beep;

%% CELL 7: Aq sweep - 1000 fresh random points centered at (2.5, 1.0, 0.0) - FINAL SWEEP!

sweep_values = [0.050 0.2];  % full realistic ventilation range

for i = 1:numel(sweep_values)
    val = sweep_values(i);
    
    fprintf('>>> (%2d/%2d) Running Aq = %.4f ...\n', i, numel(sweep_values), val);
    
    % Reset to base state
    model.param.set('Wheight', '0.15[m]');
    model.param.set('Cheight', '1[m]');
    model.param.set('Wr', '0.05[m]');
    model.param.set('Cr', '0.6[m]');
    model.param.set('PHr', '0.396[m]');
    model.param.set('Mq', '0.05[kg/h]');
    model.param.set('Aq', '0.95');
    
    % Apply swept Aq only (no units!)
    model.param.set('Aq', sprintf('%.10f', val));
    model.geom('geom1').run;  % safe
    
    % --- Robust parameter reading ---
    Wheight_val = str2double(regexprep(string(model.param.get('Wheight')), '\[.*\]', ''));
    Cheight_val = str2double(regexprep(string(model.param.get('Cheight')), '\[.*\]', ''));
    Wr_val      = str2double(regexprep(string(model.param.get('Wr')),      '\[.*\]', ''));
    Cr_val      = str2double(regexprep(string(model.param.get('Cr')),      '\[.*\]', ''));
    PHr_val     = str2double(regexprep(string(model.param.get('PHr')),     '\[.*\]', ''));
    Mq_val      = str2double(regexprep(string(model.param.get('Mq')),      '\[.*\]', ''));
    Aq_val      = str2double(regexprep(string(model.param.get('Aq')),      '\[.*\]', ''));
    
    % --- 1000 points correctly placed inside canopy ---
    r_min = Wr_val + epsilon;
    r_max = Cr_val - epsilon;
    z_min = Wheight_val + epsilon;
    z_max = Cheight_val - epsilon;
    
    if r_min >= r_max || z_min >= z_max
        error('Geometry too thin for 1 cm safety margin');
    end
    
    rng(i + 2025);
    r_squared = r_min^2 + rand(nPoints,1) * (r_max^2 - r_min^2);
    r = sqrt(r_squared);
    theta = 2*pi*rand(nPoints,1);
    x = r .* cos(theta) + x_center;   % 2.5
    y = r .* sin(theta) + y_center;   % 1.0
    z = z_min + rand(nPoints,1) * (z_max - z_min) + z_base;   % 0.0
    
    coords = [x y z];
    
    % Solve
    model.study(studyTag).run;
    
    % Interpolate
    results = zeros(nPoints, nT);
    for k = 1:nT
        results(:,k) = mphinterp(model, expr, 'dataset', dsetTag, 't', tVec(k), 'coord', coords');
    end
    
    % Save CSV - handle 0.000 specially
    if val == 0
        val_str = '0.000';
    else
        val_str = sprintf('%.4f', val);
    end
    csvFile = fullfile(outputDir, sprintf('methane_Aq_%s_rand1000.csv', val_str));
    
    fid = fopen(csvFile, 'w');
    fprintf(fid, '# Aq = %.4f (swept)\n', val);
    fprintf(fid, '# Wheight = %.3f m\n', Wheight_val);
    fprintf(fid, '# Cheight = %.3f m\n', Cheight_val);
    fprintf(fid, '# Wr = %.3f m\n', Wr_val);
    fprintf(fid, '# Cr = %.3f m\n', Cr_val);
    fprintf(fid, '# PHr = %.4f m\n', PHr_val);
    fprintf(fid, '# Mq = %.5f kg/h\n', Mq_val);
    fprintf(fid, '# Points centered at (x,y,z) = (%.1f, %.1f, %.1f)\n', x_center, y_center, z_base);
    fprintf(fid, '# 1000 uniform random points with 1 cm safety margin\n');
    fprintf(fid, 'Point,X[m],Y[m],Z[m]');
    for c = 1:nT, fprintf(fid, ',t=%.1f min', tVec(c)); end
    fprintf(fid, '\n');
    
    for p = 1:nPoints
        fprintf(fid, '%d,%.10e,%.10e,%.10e', p, coords(p,:));
        fprintf(fid, ',%g', results(p,:));
        fprintf(fid, '\n');
    end
    fclose(fid);
    
    fprintf(' ✓ SUCCESS → %s\n\n', csvFile);
    beep;
end

fprintf('=================================================================\n');
fprintf('★★★ ALL 7 PARAMETRIC SWEEPS (35 simulations, 35,000 points) COMPLETED ★★★\n');
fprintf('You now have the full, perfect, publication-ready dataset!\n');
fprintf('=================================================================\n');
beep; beep; beep; beep; beep;
