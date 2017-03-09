load('results/noise_level_0_1.mat')

n_test_points = size(preds(:,1),1);

for out_dim = 1:5
    figure;
    f = [preds(:,out_dim)+2*sqrt(pred_stds(:,out_dim)); ...
        flipdim(preds(:,out_dim)-2*sqrt(pred_stds(:,out_dim)),1)];
    fill([[1:n_test_points]'; flipdim([1:n_test_points]',1)], f, [7 7 7]/8)
    hold on; plot(1:n_test_points, preds(:,out_dim),'r-o'); 
    plot(1:n_test_points, test_x(:,out_dim),'b-o')
    plot(1:n_test_points, test_y(:,out_dim),'y-o')
    plot(1:n_test_points, test_y_noiseless(:,out_dim),'g-o')
    
    fit_noise_levels
    true_noise_levels
    sqrt2_inflated_true_noise_levels
    sqrt3_inflated_true_noise_levels
    
end