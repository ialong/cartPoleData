%% Generate data for training

%clear 
rng(1)

addpath('../')
addpath('../../../base')

plant.delay = 1e-10;                 
plant.dt = 0.075;
plant.ctrltype = @(t,f,f0)zoh(t,f,f0);               
plant.ode = @dynamics;

% Noise s.d.'s: 3cm, 6 degrees
% Dimensions: x position, pendulum angle, cart velocity, angular velocity
obs_noise_std = [0.03 6*pi/180 0.03/plant.dt 6*pi/180/plant.dt]; % add noise to sin & cos independently
add_noise = true;

N = 30;
T = 20;
state_dim = length(obs_noise_std);
max_force = 5;
x0 = [0,0,0,0];

u = zeros(2*N, T-1);
y_noiseless = zeros(2*N, T, state_dim);
y = zeros(2*N, T, state_dim);

for n=1:2*N
    n
    u(n, :) = 2*max_force*(rand(T-1,1)-0.5);
    
    y_noiseless(n, 1, :) = x0;
    count = 2;
    clear odestep
    for f=u(n,:)
        y_noiseless(n, count, :) = odestep(y_noiseless(n, count-1,:), f, plant);
        count = count + 1;
    end
    
%     if plant.delay > 0
%         u{n} = [[0; u{n}(1:end-1)] u{n}]; % also stack u_{t-1} if delayed control
%     end

%     y_n(:,5) = cos(y_n(:,2));
%     y_n(:,2) = sin(y_n(:,2));
%     y_n = y_n(:,[1,2,5,3,4]); 

%     y_noiseless(n, :, 2) = wrapTo2Pi(y_noiseless(n, :, 2));

%     if any(abs(y_n(:,1))>1), t = min(find(abs(y_n(:,1))>1))-1; else t = T; end
%     y_n = y_n(discard_first_n_steps+1:t,:);
%     u{n} = u{n}(discard_first_n_steps+1:t-1,:);
    
    if add_noise
        for tt=1:T
            for dd=1:state_dim
                y(n, tt, dd) = y_noiseless(n, tt, dd) + randn() * obs_noise_std(dd);
            end
        end
    else
        y(n, :, :) = y_noiseless(n, :, :);
    end
end

train = struct('y', y(1:N, :, :),     'u', u(1:N, :, :),     'latent', y_noiseless(1:N, :, :));
test  = struct('y', y(N+1:2*N, :, :), 'u', u(N+1:2*N, :, :), 'latent', y_noiseless(N+1:2*N, :, :));

save('noisier_data', 'train', 'test')
