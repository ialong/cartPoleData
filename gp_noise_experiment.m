addpath(genpath('/home/adi24/gpml-matlab-v4.0-2016-10-19'))

meanfunc = {@meanSum, {@meanLinear, @meanConst}};          
covfunc = @covSEard;             
likfunc = @likGauss;             

series = 20;
series_length = 100;
discard_first_n_steps = 0;

rng(1)
clear odestep
[data_noiseless, ~, ~, plant] = return_cartpole_data(series, series_length, discard_first_n_steps, 0);

% Noise s.d.'s: 1cm, 1 degree
% Dimensions: x position, sin(\theta), cos(\theta), cart velocity, angular velocity
obs_noise_stds = [0.01 pi/180 pi/180 0.01/plant.dt pi/180/plant.dt]; % add noise to sin & cos independently

noise_std_multipliers = [0 0.1 1 2 3 5 10 20];

for noise_std_multiplier = noise_std_multipliers
    noise_std_multiplier
    
    data = data_noiseless;
    
    % truncate series so cart lies in [-1, 1]meters:
    stacked_x = [];
    stacked_y = [];
    for n = 1:series
        data(n).y(:,1) = data(n).y(:,1) - data(n).y(1,1);
        pos_less_than_one = abs(data(n).y(:,1)) > 1;
        pos_less_than_one = find(pos_less_than_one, 1, 'first') - 1;
        if isempty(pos_less_than_one); pos_less_than_one = series_length; end
        data(n).y = data(n).y(1:pos_less_than_one,:);
        
        data(n).u = [0; data(n).u];
        data(n).u = data(n).u(1:pos_less_than_one,:);
        
        % add noise to data:
        additive_noise = bsxfun(@times, randn(size(data(n).y)), noise_std_multiplier*obs_noise_stds);
        data(n).y = data(n).y + additive_noise;
        
        % stack data all together:
        x_and_u = [data(n).y(1:end-1,:)   data(n).u(1:end-1)   data(n).u(2:end)];
        stacked_x = [stacked_x; x_and_u];
        stacked_y = [stacked_y; data(n).y(2:end,:)];
    end

    train_test_cutoff = ceil(size(stacked_x,1)/2);
    
    train_x = stacked_x(1:train_test_cutoff,:);
    train_y = stacked_y(1:train_test_cutoff,:);
    test_x = stacked_x(train_test_cutoff+1:end,:);
    test_y = stacked_y(train_test_cutoff+1:end,:);
    
    
    % GP fitting:
    
    out_dims = size(test_y,2);
    
    hyp_init = cell(out_dims,1);
    hyp_fit = cell(out_dims,1);
    marg_lik_values = cell(out_dims,1);
    preds = zeros(size(test_y));
    pred_stds = zeros(size(test_y));
    
    for out_dim = 1:out_dims
        hyp_init{out_dim} = struct('mean', [0.5; 0.5; 0.5; 0.5; 0.5; 0.5; 0.5; 0.5], ...
            'cov', [0.5; 0.5; 0.5; 0.5; 0.5; 0.5; 0.5; 0.5], 'lik', -1);
        [hyp_fit{out_dim}, marg_lik_values{out_dim}, ~] = minimize(hyp_init{out_dim}, @gp, -300, ...
            @infGaussLik, meanfunc, covfunc, likfunc, train_x, train_y(:,out_dim));
        [preds(:,out_dim), pred_stds(:,out_dim)] = gp(hyp_fit{out_dim}, @infGaussLik, meanfunc, covfunc, likfunc, ...
            train_x, train_y(:,out_dim), test_x);
    end

    save(strrep(sprintf('results/noise_level_%g', noise_std_multiplier),'.','_'))
end