close all
data_type = 'unicycle';

load(['results_' data_type '/noise_level_0.mat'])

if strcmp(data_type,'unicycle')
    y_labels = {'droll','dyaw','dwheel','dpitch','dflywheel',...
        'xc','yc','roll','yaw','pitch'};
elseif strcmp(data_type,'cartpole')
    y_labels = {'xc','sintheta','costheta','cart velocity','pendulum velocity'};
end

[n_test_points, out_dims] = size(preds);

for out_dim = 1:out_dims
    figure;
    f = [preds(:,out_dim)+2*sqrt(pred_stds(:,out_dim)); ...
        flip(preds(:,out_dim)-2*sqrt(pred_stds(:,out_dim)))];
    fill([(1:n_test_points)'; flip((1:n_test_points)')], f, [7 7 7]/8)
    hold on; plot(1:n_test_points, preds(:,out_dim),'r-o'); 
    plot(1:n_test_points, test_x(:,out_dim),'b-o')
    plot(1:n_test_points, test_y(:,out_dim),'y-o')
    plot(1:n_test_points, test_y_noiseless(:,out_dim),'g-o')
    title(y_labels{out_dim})
    legend('2\sigma CI', 'prediction','input','noisy target','noiseless target')
    xlabel('test point #')
    
    fit_noise_levels
    true_noise_levels
    sqrt2_inflated_true_noise_levels
    sqrt3_inflated_true_noise_levels
    
end