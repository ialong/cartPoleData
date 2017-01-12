%% Generate data for training

clear all
rng(1)

addpath('../')
addpath('../../../base')

plant.delay = 0.05;                 
plant.dt = 0.15;
plant.ctrltype = @(t,f,f0)zoh(t,f,f0);               
plant.ode = @dynamics;

% Noise s.d.'s: 1cm, 1 degree
% Dimensions: x position, sin(\theta), cos(\theta), cart velocity, angular velocity
obs_noise_std = [0.01 pi/180 0.01/plant.dt pi/180/plant.dt];
add_noise = true;

N = 10;
burn_in = 100;
T = 100 + burn_in;
max_force = 5;
x0 = [0,0,0,0];

u = cell(1,N);
y = cell(1,N);

for n=1:N
    n
    u{n} = 2*max_force*(rand(T-1,1)-0.5);
    
    y_n = zeros(T,4);
    y_n(1,:) = x0;
    count = 2;
    for f=u{n}'
        y_n(count,:) = odestep(y_n(count-1,:), f, plant);
        count = count + 1;
    end
    if add_noise
        y_n = y_n + bsxfun(@times, randn(size(y_n)), obs_noise_std);
    end
    y_n(:,5) = cos(y_n(:,2));
    y_n(:,2) = sin(y_n(:,2));
    y_n = y_n(:,[1,2,5,3,4]); 
    y{n} = y_n(burn_in+1:end,:);
end

y_position_angle = cellfun(@(x)({x(:,1:3)}),y);

data = struct('y',y,'u',u);
data_position_angle = struct('y',y_position_angle,'u',u);

save('data_all','data')
save('data_position_angle','data_position_angle')