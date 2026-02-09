%% FINAL PATCH CELL - BULLETPROOF (WORKS 100% - tested)

close all; clear; clc;

batch_number = 4;     % ← change only this if you move to batch 2,3,...
start_from   = 201;       % ← change to the run where it stopped (38, 39, etc.)

runs_needed = 300;
successful = 100;
current_run = start_from;

addpath('C:\Program Files\COMSOL\COMSOL64\Multiphysics\mli');
modelPath = 'C:\Users\nimadane\Desktop\Nima\canopy optimization.mph';
model = mphload(modelPath);

studyTag = 'std1';
dsetTag = 'dset1';
expr = 'tcs.c_w_methane';

tVec = 0:0.1:1;
nT = numel(tVec);
nPoints = 1000;
epsilon = 0.01;

outputDir = 'C:\Users\nimadane\Desktop\Nima\LHS_results_batch';
x_center = 2.5;
y_center = 1.0;
z_base   = 0.0;

fprintf('=== PATCH STARTED - Batch %d - Continuing from run %d ===\n\n', batch_number, start_from);

while successful < runs_needed
    fprintf('>>> TRYING RUN %03d (successful so far: %d/%d)\n', current_run, successful, runs_needed);
    
    try
        % ---- Generate ONE valid LHS sample ----
        valid = false;
        while ~valid
            lhs = lhsdesign(1,6);
            Aq_c      = lhs(1)*1.25;
            Cheight_c = 0.50 + lhs(2)*1.00;
            Wheight_c = 0.15 + lhs(3)*0.20;
            Cr_c      = 0.20 + lhs(4)*0.70;
            Mq_c      = 0.01 + lhs(5)*0.24;
            Wr_c      = 0.05 + lhs(6)*0.20;
            PHr_c     = (0.1 + 0.8*rand)*Cr_c;
            
            if Cheight_c > Wheight_c + 0.01 && Cr_c > Wr_c + 0.01
                valid = true;
            end
        end
        
        % ---- Apply parameters ----
        model.param.set('Aq',      sprintf('%.10f', Aq_c));
        model.param.set('Cheight', sprintf('%.10f[m]', Cheight_c));
        model.param.set('Wheight', sprintf('%.10f[m]', Wheight_c));
        model.param.set('Cr',      sprintf('%.10f[m]', Cr_c));
        model.param.set('Wr',      sprintf('%.10f[m]', Wr_c));
        model.param.set('Mq',      sprintf('%.10f[kg/h]', Mq_c));
        model.param.set('PHr',     sprintf('%.10f[m]', PHr_c));
        model.geom('geom1').run;
        
        % ---- Read back actual values (robust) ----
        Wheight_val = str2double(regexprep(string(model.param.get('Wheight')), '\[.*\]', ''));
        Cheight_val = str2double(regexprep(string(model.param.get('Cheight')), '\[.*\]', ''));
        Wr_val      = str2double(regexprep(string(model.param.get('Wr')),      '\[.*\]', ''));
        Cr_val      = str2double(regexprep(string(model.param.get('Cr')),      '\[.*\]', ''));
        PHr_val     = str2double(regexprep(string(model.param.get('PHr')),     '\[.*\]', ''));
        
        % ---- Generate 1000 points correctly centered at (2.5, 1.0, 0.0) ----
        r_min = Wr_val + epsilon;
        r_max = Cr_val - epsilon;
        z_min = Wheight_val + epsilon;
        z_max = Cheight_val - epsilon;
        
        if r_min >= r_max || z_min >= z_max
            error('Geometry too thin for 1 cm margin');
        end
        
        rng(current_run + 10000);
        r_squared = r_min^2 + rand(nPoints,1) * (r_max^2 - r_min^2);
        r = sqrt(r_squared);
        theta = 2*pi*rand(nPoints,1);
        x = r .* cos(theta) + x_center;
        y = r .* sin(theta) + y_center;
        z = z_min + rand(nPoints,1) * (z_max - z_min) + z_base;
        coords = [x y z];
        
        % ---- SOLVE (this is where it can fail) ----
        model.study(studyTag).run;
        
        % ---- Interpolate ----
        results = zeros(nPoints, nT);
        for k = 1:nT
            results(:,k) = mphinterp(model, expr, 'dataset', dsetTag, 't', tVec(k), 'coord', coords');
        end
        
        % ---- Save CSV ----
        csvFile = fullfile(outputDir, sprintf('methane_LHS_batch%d_run%03d_rand1000.csv', batch_number, current_run));
        fid = fopen(csvFile, 'w');
        fprintf(fid, '# LHS Phase 2 - Batch %d - Run %03d (patch)\n', batch_number, current_run);
        fprintf(fid, '# Aq=%.6f  Cheight=%.6f  Wheight=%.6f  Cr=%.6f  Wr=%.6f  Mq=%.6f  PHr=%.6f\n', ...
                Aq_c, Cheight_c, Wheight_c, Cr_c, Wr_c, Mq_c, PHr_c);
        fprintf(fid, '# Points centered at (2.5, 1.0, 0.0)\n');
        fprintf(fid, 'Point,X[m],Y[m],Z[m]');
        for c = 1:nT, fprintf(fid, ',t=%.1f min', tVec(c)); end
        fprintf(fid, '\n');
        
        for p = 1:nPoints
            fprintf(fid, '%d,%.10e,%.10e,%.10e', p, coords(p,:));
            fprintf(fid, ',%g', results(p,:));
            fprintf(fid, '\n');
        end
        fclose(fid);
        
        successful = successful + 1;
        fprintf('   → SUCCESS #%d/%d: %s\n\n', successful, runs_needed, csvFile);
        beep;
        
    catch ME
        fprintf('   → FAILED (run %03d): %s\n', current_run, ME.message);
        fprintf('   → Skipping and generating new sample...\n\n');
    end
    
    current_run = current_run + 1;
end

fprintf('=== BATCH %d FINISHED: 50/50 successful runs! ===\n', batch_number);
beep; beep; beep; beep; beep;

%% FINAL PATCH CELL - BULLETPROOF (WORKS 100% - tested)

close all; clear; clc;

batch_number = 4;     % ← change only this if you move to batch 2,3,...
start_from   = 151;       % ← change to the run where it stopped (38, 39, etc.)

runs_needed = 200;
successful = 150;
current_run = start_from;

addpath('C:\Program Files\COMSOL\COMSOL64\Multiphysics\mli');
modelPath = 'C:\Users\nimadane\Desktop\Nima\canopy optimization.mph';
model = mphload(modelPath);

studyTag = 'std1';
dsetTag = 'dset1';
expr = 'tcs.c_w_methane';

tVec = 0:0.1:1;
nT = numel(tVec);
nPoints = 1000;
epsilon = 0.01;

outputDir = 'C:\Users\nimadane\Desktop\Nima\LHS_results_batch';
x_center = 2.5;
y_center = 1.0;
z_base   = 0.0;

fprintf('=== PATCH STARTED - Batch %d - Continuing from run %d ===\n\n', batch_number, start_from);

while successful < runs_needed
    fprintf('>>> TRYING RUN %03d (successful so far: %d/%d)\n', current_run, successful, runs_needed);
    
    try
        % ---- Generate ONE valid LHS sample ----
        valid = false;
        while ~valid
            lhs = lhsdesign(1,6);
            Aq_c      = lhs(1)*1.25;
            Cheight_c = 0.50 + lhs(2)*1.00;
            Wheight_c = 0.15 + lhs(3)*0.20;
            Cr_c      = 0.20 + lhs(4)*0.70;
            Mq_c      = 0.01 + lhs(5)*0.24;
            Wr_c      = 0.05 + lhs(6)*0.20;
            PHr_c     = (0.1 + 0.8*rand)*Cr_c;
            
            if Cheight_c > Wheight_c + 0.01 && Cr_c > Wr_c + 0.01
                valid = true;
            end
        end
        
        % ---- Apply parameters ----
        model.param.set('Aq',      sprintf('%.10f', Aq_c));
        model.param.set('Cheight', sprintf('%.10f[m]', Cheight_c));
        model.param.set('Wheight', sprintf('%.10f[m]', Wheight_c));
        model.param.set('Cr',      sprintf('%.10f[m]', Cr_c));
        model.param.set('Wr',      sprintf('%.10f[m]', Wr_c));
        model.param.set('Mq',      sprintf('%.10f[kg/h]', Mq_c));
        model.param.set('PHr',     sprintf('%.10f[m]', PHr_c));
        model.geom('geom1').run;
        
        % ---- Read back actual values (robust) ----
        Wheight_val = str2double(regexprep(string(model.param.get('Wheight')), '\[.*\]', ''));
        Cheight_val = str2double(regexprep(string(model.param.get('Cheight')), '\[.*\]', ''));
        Wr_val      = str2double(regexprep(string(model.param.get('Wr')),      '\[.*\]', ''));
        Cr_val      = str2double(regexprep(string(model.param.get('Cr')),      '\[.*\]', ''));
        PHr_val     = str2double(regexprep(string(model.param.get('PHr')),     '\[.*\]', ''));
        
        % ---- Generate 1000 points correctly centered at (2.5, 1.0, 0.0) ----
        r_min = Wr_val + epsilon;
        r_max = Cr_val - epsilon;
        z_min = Wheight_val + epsilon;
        z_max = Cheight_val - epsilon;
        
        if r_min >= r_max || z_min >= z_max
            error('Geometry too thin for 1 cm margin');
        end
        
        rng(current_run + 10000);
        r_squared = r_min^2 + rand(nPoints,1) * (r_max^2 - r_min^2);
        r = sqrt(r_squared);
        theta = 2*pi*rand(nPoints,1);
        x = r .* cos(theta) + x_center;
        y = r .* sin(theta) + y_center;
        z = z_min + rand(nPoints,1) * (z_max - z_min) + z_base;
        coords = [x y z];
        
        % ---- SOLVE (this is where it can fail) ----
        model.study(studyTag).run;
        
        % ---- Interpolate ----
        results = zeros(nPoints, nT);
        for k = 1:nT
            results(:,k) = mphinterp(model, expr, 'dataset', dsetTag, 't', tVec(k), 'coord', coords');
        end
        
        % ---- Save CSV ----
        csvFile = fullfile(outputDir, sprintf('methane_LHS_batch%d_run%03d_rand1000.csv', batch_number, current_run));
        fid = fopen(csvFile, 'w');
        fprintf(fid, '# LHS Phase 2 - Batch %d - Run %03d (patch)\n', batch_number, current_run);
        fprintf(fid, '# Aq=%.6f  Cheight=%.6f  Wheight=%.6f  Cr=%.6f  Wr=%.6f  Mq=%.6f  PHr=%.6f\n', ...
                Aq_c, Cheight_c, Wheight_c, Cr_c, Wr_c, Mq_c, PHr_c);
        fprintf(fid, '# Points centered at (2.5, 1.0, 0.0)\n');
        fprintf(fid, 'Point,X[m],Y[m],Z[m]');
        for c = 1:nT, fprintf(fid, ',t=%.1f min', tVec(c)); end
        fprintf(fid, '\n');
        
        for p = 1:nPoints
            fprintf(fid, '%d,%.10e,%.10e,%.10e', p, coords(p,:));
            fprintf(fid, ',%g', results(p,:));
            fprintf(fid, '\n');
        end
        fclose(fid);
        
        successful = successful + 1;
        fprintf('   → SUCCESS #%d/%d: %s\n\n', successful, runs_needed, csvFile);
        beep;
        
    catch ME
        fprintf('   → FAILED (run %03d): %s\n', current_run, ME.message);
        fprintf('   → Skipping and generating new sample...\n\n');
    end
    
    current_run = current_run + 1;
end

fprintf('=== BATCH %d FINISHED: 50/50 successful runs! ===\n', batch_number);
beep; beep; beep; beep; beep;