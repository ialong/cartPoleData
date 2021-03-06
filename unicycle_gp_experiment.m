addpath(genpath('~/gpml-matlab-v4.0-2016-10-19'))           

random_seed = 1;
noise_std_multipliers = [0 0.1 sqrt(0.1) 0.5 1 2 3 5 10 20];
in_dim = 10;
u_dim = 2;

dt = 0.05;
unicycle.l = 0.222/(2*pi) + 0.08 + 0.007;

%% Generate (noiseless) data:

all_data = load('unicycle_rollouts.mat', 'trajectories');
all_data = all_data.trajectories;

series = length(all_data);

% stack series:
stacked_x = [];
stacked_y = [];
boundaries = zeros(series,1);
for n = 1:series    
    boundaries(n) = size(all_data(n).latent,1)-1;

    stacked_x = [stacked_x; all_data(n).latent(1:end-1,1:in_dim)   all_data(n).action];
    stacked_y = [stacked_y; all_data(n).latent(2:end,1:in_dim)];
end
boundaries = cumsum(boundaries);

% split beteern train and test:
train_test_cutoff = 800;%ceil(size(stacked_x,1)/2);

train_x_noiseless = stacked_x(1:train_test_cutoff,:);
train_y_noiseless = stacked_y(1:train_test_cutoff,:);
test_x_noiseless = stacked_x(train_test_cutoff+1:end,:);
test_y_noiseless = stacked_y(train_test_cutoff+1:end,:);



%% Fit (noisy) data:

% Noise s.d.'s: 1cm, 1 degree
% Dimensions: x position, sin(\theta), cos(\theta), cart velocity, angular velocity
obs_noise_stds = [(deg2rad(1)/dt) * ones(1,5)...
                    (0.01*unicycle.l) * ones(1,2)...
                    deg2rad(1) * ones(1,3)];

for noise_std_multiplier = noise_std_multipliers
    noise_std_multiplier
    
    % add noise to data:
    stacked_x_noisy = stacked_x;
    stacked_y_noisy = stacked_y;
    
    rng(random_seed)
    x_additive_noise = bsxfun(@times, randn(size(stacked_y)), noise_std_multiplier*obs_noise_stds);
    y_additive_noise = bsxfun(@times, randn(size(stacked_y)), noise_std_multiplier*obs_noise_stds);
    stacked_x_noisy(:,1:end-u_dim) = stacked_x_noisy(:,1:end-u_dim) + x_additive_noise;
    stacked_y_noisy = stacked_y_noisy + y_additive_noise;
    
    train_x = stacked_x_noisy(1:train_test_cutoff,:);
    train_y = stacked_y_noisy(1:train_test_cutoff,:);
    test_x = stacked_x_noisy(train_test_cutoff+1:end,:);
    test_y = stacked_y_noisy(train_test_cutoff+1:end,:);
    
    
    % GP fitting:
    
    meanfunc = {@meanSum, {@meanLinear, @meanConst}};          
    covfunc = @covSEard;             
    likfunc = @likGauss;  
    
    out_dims = size(test_y,2);
    
    hyp_init = cell(out_dims,1);
    hyp_fit = cell(out_dims,1);
    marg_lik_values = cell(out_dims,1);
    preds = zeros(size(test_y));
    pred_stds = zeros(size(test_y));
    
    for out_dim = 1:out_dims
        hyp_init{out_dim} = struct('mean', 0.5*ones(in_dim + u_dim + 1,1), ...
            'cov', 0.5*ones(in_dim + u_dim + 1,1), 'lik', -1);
        [hyp_fit{out_dim}, marg_lik_values{out_dim}, ~] = minimize(hyp_init{out_dim}, @gp, -300, ...
            @infGaussLik, meanfunc, covfunc, likfunc, train_x, train_y(:,out_dim));
        [preds(:,out_dim), pred_stds(:,out_dim)] = gp(hyp_fit{out_dim}, @infGaussLik, meanfunc, covfunc, likfunc, ...
            train_x, train_y(:,out_dim), test_x);
    end
    
    fit_noise_levels = [hyp_fit{:}];
    fit_noise_levels = exp([fit_noise_levels(:).lik])
    true_noise_levels = noise_std_multiplier*obs_noise_stds
    sqrt2_inflated_true_noise_levels = true_noise_levels*sqrt(2)
    sqrt3_inflated_true_noise_levels = true_noise_levels*sqrt(3)

    save(strrep(sprintf('results_unicycle/noise_level_%g', noise_std_multiplier),'.','_'))
end
