
posnetek = 'C:\Users\rozma\Downloads\MMD\files\S001\S001R03.edf';
EEG = pop_biosig(posnetek);


l = 50;
EEG = pop_reref(EEG, []);
EEG = pop_select(EEG, 'channel', {'C3..'});

data = EEG.data;

fs = EEG.srate;

EEG_delta = pop_eegfiltnew(EEG, 1, 4);
EEG_theta = pop_eegfiltnew(EEG, 4, 8);
EEG_alpha = pop_eegfiltnew(EEG, 8, 13);
EEG_beta = pop_eegfiltnew(EEG, 13, 20);
EEG_gamma = pop_eegfiltnew(EEG, 20, 45);


time_range = 0:1/fs:8; 
time_range = time_range(1:end-1); 

data = data(1:length(time_range));
EEG_delta.data = EEG_delta.data(1:length(time_range));
EEG_theta.data = EEG_theta.data(1:length(time_range));
EEG_alpha.data = EEG_alpha.data(1:length(time_range));
EEG_beta.data = EEG_beta.data(1:length(time_range));
EEG_gamma.data = EEG_gamma.data(1:length(time_range));


fig = figure;
t = tiledlayout("vertical");
t.TileSpacing = 'compact';
t.Padding = 'compact';
nexttile();
plot(time_range, data);
ylabel('Raw',"Rotation",0);
ylim([-l l]);
set(gca, 'XTick', []);

nexttile();
plot(time_range, EEG_delta.data);
ylabel('Delta',"Rotation",0);
ylim([-l l]);
set(gca, 'XTick', []);

nexttile();
plot(time_range, EEG_theta.data);
ylabel('Theta',"Rotation",0);
ylim([-l l]);
set(gca, 'XTick', []);

nexttile();
plot(time_range, EEG_alpha.data);
ylabel('Alpha',"Rotation",0);
ylim([-l l]);
set(gca, 'XTick', []);

nexttile();
plot(time_range, EEG_beta.data);
ylabel('Beta',"Rotation",0);
ylim([-l l]);
set(gca, 'XTick', []);

nexttile();
plot(time_range, EEG_gamma.data);
ylabel('Gamma',"Rotation",0);
xlabel('time (sec)');
ylim([-l l]);


set(gcf, 'Position', [100, 100, 800, 600]); 
fontsize(fig, 15, "points");
