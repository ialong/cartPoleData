%% Data for plotting

clear all
rng(1)

addpath('../')
addpath('../../../base')

plant.delay = 0.05;                 
plant.dt = 0.15;
plant.ctrltype = @(t,f,f0)zoh(t,f,f0);               
plant.ode = @dynamics;

T = 100;
x0 = [0,0,0,0];
controls = 10*(rand(1,T-1)-0.5);
data = zeros(4,T);
data(:,1) = x0;

count = 2;
for f=controls
    data(:,count) = odestep(data(:,count-1), f, plant);
    count = count + 1;
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
data_corr(2,:) = data_corr(2,:) + pi/2;
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