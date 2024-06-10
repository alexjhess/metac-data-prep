function [d] = metac_import_labchart_data()

ppid = 9014;

%% load 
tmp = load('T:\METAC\behavior\raw\Temporary\TNU_METAC_9014\behavior\LabChart\TNU_METAC_9014_task.mat');

%% reshape channel data
dat = [];
for i = 1:size(tmp.datastart,2)
    t(i).tmp_dat = reshape(tmp.data(tmp.datastart(1,i):tmp.dataend(7,i)), (length(tmp.datastart(1,i):tmp.dataend(7,i))/7), 7);
    dat = cat(1,dat,t(i).tmp_dat);
end

d.rangemin = tmp.rangemin(:,i)';
d.rangemax = tmp.rangemax(:,i)';

%% create table
d.tab = array2table(dat, 'VariableNames',cellstr(tmp.titles));

%% add time
dt = [1:size(d.tab,1)]'/tmp.samplerate(1,1);
time = dt-1/tmp.samplerate(1,1);
d.tab = addvars(d.tab, time, 'NewVariableNames', 'time');

%% store info
d.units = cell(1,7);
for c = 1:7
    d.units{1,c} = tmp.unittext(tmp.unittextmap(c,1),:);
end
d.samplerate = tmp.samplerate(:,1)';

%% comments
d.comment_t = tmp.com(:,3)';
d.comment_txt = cell(1,length(d.comment_t));
for k = 1:length(d.comment_t)
    d.comment_txt{1,k} = tmp.comtext(tmp.com(k,5),:);
end

%% plot settings
% dock all figures
set(0,'DefaultFigureWindowStyle','docked')

%% plot mouth pressure (from comment "start experiment" until the end)
figure;
plot(d.tab.time(d.comment_t(3):end,:), d.tab.("Mouth Pressure")(d.comment_t(3):end,:))
hold on
plot(d.tab.time(d.comment_t(3):end,:), d.tab.("Resistance Trigger")(d.comment_t(3):end,:)./10)
ylabel('Mouth Pressure [mmHg], Triggers')
xlabel('time [ms]')

%% all 7 channels
figure;
plot(d.tab.time(d.comment_t(3):end,:), d.tab.("Mouth Pressure")(d.comment_t(3):end,:))
hold on
plot(d.tab.time(d.comment_t(3):end,:), d.tab.Pulse(d.comment_t(3):end,:))
plot(d.tab.time(d.comment_t(3):end,:), d.tab.("Resistance Trigger")(d.comment_t(3):end,:)./10)
plot(d.tab.time(d.comment_t(3):end,:), d.tab.O2(d.comment_t(3):end,:))
plot(d.tab.time(d.comment_t(3):end,:), d.tab.CO2(d.comment_t(3):end,:))
plot(d.tab.time(d.comment_t(3):end,:), d.tab.("Spirometer (Flow)")(d.comment_t(3):end,:))
legend(d.tab.Properties.VariableNames{1}, d.tab.Properties.VariableNames{2},...
    d.tab.Properties.VariableNames{3}, d.tab.Properties.VariableNames{4},...
    d.tab.Properties.VariableNames{5}, d.tab.Properties.VariableNames{6},...
    d.tab.Properties.VariableNames{7})


%% create json files for saving
%...


    
end