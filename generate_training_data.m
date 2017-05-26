%% Generate data for training

%clear 
rng(1)

addpath('../')
addpath('../../../base')

plant.delay = 0.025;                 
plant.dt = 0.075;
plant.ctrltype = @(t,f,f0)zoh(t,f,f0);               
plant.ode = @dynamics;

% Noise s.d.'s: 1cm, 4 degree
% Dimensions: x position, sin(\theta), cos(\theta), cart velocity, angular velocity
obs_noise_std = [0.01 4*pi/180 4*pi/180 0.01/plant.dt 4*pi/180/plant.dt]; % add noise to sin & cos independently
add_noise = true;

N = 10;
discard_first_n_steps = 1;
T = 100 + discard_first_n_steps;
max_force = 5;
x0 = [0,0,0,0];

u = cell(1,N);
y_noiseless = cell(1,N);
y = cell(1,N);

for n=1:2*N
    n
    u{n} = 2*max_force*(rand(T-1,1)-0.5);
    
    y_n = zeros(T,4);
    y_n(1,:) = x0;
    count = 2;
    clear odestep
    for f=u{n}'
        y_n(count,:) = odestep(y_n(count-1,:), f, plant);
        count = count + 1;
    end
    
    if plant.delay > 0
        u{n} = [[0; u{n}(1:end-1)] u{n}]; % also stack u_{t-1} if delayed control
    end

    y_n(:,5) = cos(y_n(:,2));
    y_n(:,2) = sin(y_n(:,2));
    y_n = y_n(:,[1,2,5,3,4]); 

    if any(abs(y_n(:,1))>1), t = min(find(abs(y_n(:,1))>1))-1; else t = T; end
    y_n = y_n(discard_first_n_steps+1:t,:);
    u{n} = u{n}(discard_first_n_steps+1:t-1,:);
    
    y_noiseless{n} = y_n;
    if add_noise
        y{n} = y_n + bsxfun(@times, randn(size(y_n)), obs_noise_std);
    else
        y{n} = y_noiseless{n};
    end
end

y_position_angle = cellfun(@(x)({x(:,1:3)}),y);

train = struct('y', y(1:N),     'u', u(1:N),     'latent', y_noiseless(1:N));
test  = struct('y', y(N+1:2*N), 'u', u(N+1:2*N), 'latent', y_noiseless(1+N:2*N));
train_position_angle = struct('y', y_position_angle(1:N),     'u', u(1:N),     'latent', y_noiseless(1:N));
test_position_angle  = struct('y', y_position_angle(N+1:2*N), 'u', u(N+1:2*N), 'latent', y_noiseless(N+1:2*N));

save('data_all', 'train', 'test')
save('data_position_angle', 'train_position_angle', 'test_position_angle')
