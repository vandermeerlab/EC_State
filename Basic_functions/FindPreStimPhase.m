function stim_phase = FindPreStimPhase(cfg_in, stim_times, csc_in)

cfg_def = [];
cfg_def.skip_time = 0.5; % time (in s) to start next trial
cfg_def.isi = 3; % inter-stim interval
cfg_def.fpass = [7 9];
cfg_def.fstop = [6 10];
cfg_def.att = 30; % stopband minimum attenuation
cfg_def.ripple = 2; % passband ripple
cfg_def.filtfilt = 0;
cfg_def.debug = 0;

cfg = ProcessConfig(cfg_def, cfg_in);

% make ivs
tstart = cat(2, stim_times.t{1}(1) - cfg.isi + cfg.skip_time, stim_times.t{1}(1:end-1) + cfg.skip_time);
tend = stim_times.t{1};
trials = iv(tstart, tend);

% set up filter
fprintf('Creating filter...\n');

Fs = 1 ./ median(diff(csc_in.tvec));
%d = fdesign.bandpass(cfg.f(1)-0.5, cfg.f(1)+0.5, cfg.f(2)-0.5, cfg.f(2)+0.5, 30, 2, 30, Fs);
d = fdesign.bandpass(cfg.fstop(1), cfg.fpass(1), cfg.fpass(2), cfg.fstop(2), cfg.att, cfg.ripple, cfg.att, Fs);
flt = design(d, 'equiripple'); % equiripple method (FIR) gives linear phase delay

if cfg.debug
   fvtool(flt);
   pause;
end

% loop over ivs, filter & get final phase
for iT = length(tstart):-1:1
    
    this_trial = restrict(csc_in, tstart(iT), tend(iT));
    this_trial.tvec = this_trial.tvec(1:end-1);
    this_trial.data = this_trial.data(1:end-1);
    
    switch cfg.filtfilt
        case 0
            trial_f = filter(flt, this_trial.data); % note, this will generate a phase shift
        case 1
            trial_f = filtfilt(flt.sosMatrix, flt.ScaleValues, this_trial.data);
    end
    
    trial_f = angle(hilbert(trial_f));
    stim_phase(iT) = trial_f(end);
    
end