%% Data for plotting

%clear 
rng(10)

addpath('../')
addpath('../../../base')

plant.delay = 0.025;                 
plant.dt = 0.075;
plant.ctrltype = @(t,f,f0)zoh(t,f,f0);               
plant.ode = @dynamics;

% Noise s.d.'s: 1cm, 1 degree
% Dimensions: x position, sin(\theta), cos(\theta), cart velocity, angular velocity
obs_noise_std = 0*[0.01 pi/180 0.01/plant.dt pi/180/plant.dt];
add_noise = true;

T = 100;
x0 = [0,0,0,0];
controls = 10*(rand(1,T-1)-0.5);
data = zeros(4,T);
data(:,1) = x0;

count = 2;
clear odestep
for f=controls
    data(:,count) = odestep(data(:,count-1), f, plant);
    count = count + 1;
end
if add_noise
    data = data + bsxfun(@times, randn(size(data)), obs_noise_std');
end

%% Plot various dimensions

figure
plot(data', '-o')
hold on
plot([0,controls],'-o')
legend('position','angle','velocity','angular velocity','controls')
plot([0,T],[0,0],'k')

%% Plot movie

fig = figure;
M(size(data,2)) = struct('cdata',[],'colormap',[]);
count = 1;
data_corr = data;
data_corr(2,:) = data_corr(2,:) + pi/2; % correction to visualize 0 angle at (0,1)=(cos,sin) coordinate
for obs = data_corr
    plot([obs(1)-3,obs(1),obs(1)+3],[0,0,0],'-o')                % cart
    axis equal
    xlim([min(data_corr(1,:))-10,max(data_corr(1,:))+10])
    ylim([-12,12])
    hold on
    plot([obs(1),10*cos(obs(2))+obs(1)],[0,10*sin(obs(2))],'-o') % pendulum
    hold off
    M(count) = getframe;
%     pause(0.1)
    count = count+1;
end
% movie(M)

% v = VideoWriter('movie.mp4', 'MPEG-4');
% open(v)
% writeVideo(v,M)
% close(v)