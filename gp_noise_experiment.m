addpath(genpath('/home/adi24/gpml-matlab-v4.0-2016-10-19'))

meanfunc = {@meanSum, {@meanLinear, @meanConst}};                    % empty: don't use a mean function
covfunc = @covSEard;              % Squared Exponental covariance function
likfunc = @likGauss;              % Gaussian likelihood

series = 20;
series_length = 100;
discard_first_n_steps = 0;
noise_levels = [0 0.5 1 2 3 5 10 20];

for noise_multiplier = noise_levels
    noise_multiplier
    
    rng(1)
    [data, data_position_angle, noiseless_data] = return_cartpole_data(series, series_length, discard_first_n_steps, noise_multiplier);
    
    % truncate series so cart lies in [-1, 1]meters:
    stacked_x = [];
    stacked_y = [];
    for n = 1:series
        data(n).y(:,1) = data(n).y(:,1) - data(n).y(1,1);
        pos_less_than_one = abs(data(n).y(:,1)) > 1;
        pos_less_than_one = find(pos_less_than_one, 1, 'first') - 1;
        if isempty(pos_less_than_one); pos_less_than_one = series_length; end
        data(n).y = data(n).y(1:pos_less_than_one,:);
        stacked_x = [stacked_x; data(n).y(1:end-1,:)];
        stacked_y = [stacked_y; data(n).y(2:end,  :)];
    end
    
    assert(length(stacked_x) == length(stacked_x))

    train_test_cutoff = ceil(length(stacked_x)/2);
    
    train_x = stacked_x(1:train_test_cutoff,:);
    train_y = stacked_y(1:train_test_cutoff,:);
    test_x = stacked_x(train_test_cutoff+1:end,:);
    test_y = stacked_y(train_test_cutoff+1:end,:);
    
    out_dims = size(test_y,2);
    
    hyp_init = cell(out_dims,1);
    hyp_fit = cell(out_dims,1);
    marg_lik_values = cell(out_dims,1);
    preds = zeros(size(test_y));
    pred_stds = zeros(size(test_y));
    
    for out_dim = 1:out_dims
        hyp_init{out_dim} = struct('mean', [0.5; 0.5; 0.5; 0.5; 0.5; 0.5], 'cov', [0.5; 0.5; 0.5; 0.5; 0.5; 0.5], 'lik', -1);
        [hyp_fit{out_dim}, marg_lik_values{out_dim}, ~] = minimize(hyp_init{out_dim}, @gp, -300, @infGaussLik, meanfunc, covfunc, likfunc, train_x, train_y(:,out_dim));
        [preds(:,out_dim), pred_stds(:,out_dim)] = gp(hyp_fit{out_dim}, @infGaussLik, meanfunc, covfunc, likfunc, ...
            train_x, train_y(:,out_dim), test_x);
    end

    save(replace(sprintf('results/noise_level_%g', noise_multiplier),'.','_'))
end