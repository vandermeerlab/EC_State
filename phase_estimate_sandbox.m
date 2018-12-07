%% hilbert phase is accurate up to last sample of perfect sine wave
dt = 0.001;
tvec = 0:dt:2;

y = sin(2*pi*4*tvec);

plot(tvec, y); hold on;

phi = angle(hilbert(y));
plot(tvec, phi ./ pi, 'r');

%% what about some actual data? (note requires statedep_sandbox to have been run)
offs = 300; % plot some example stim events starting at this event number
for iE = 1:9

temp = restrict(this_csc, laser_on.t{1}(iE+offs)-2.5, laser_on.t{1}(iE+offs)+0.5);
this_idx = nearest_idx3(laser_on.t{1}(iE+offs), temp.tvec);

subplot(3, 3, iE);
plot(temp); hold on;
plot(temp.tvec(this_idx), temp.data(this_idx), '.k', 'MarkerSize', 10);
axis tight; box off;

end

%% idea: run forward filter up to time of stim to obtain phase estimate