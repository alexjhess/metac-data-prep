function [d] = metac_import_labchart_data()


%% plot settings
% dock all figures
set(0,'DefaultFigureWindowStyle','docked')

%% load ppid table
id_tab = readtable('data\metac_ppids_exploration.txt', "NumHeaderLines", 0);

%% loop over subjetcs
for n = 1:size(id_tab.PPID,1)
    

    %% load current sub
    id = id_tab.PPID(n)

    basedir = 'T:\METAC\behavior\raw\Temporary';
    ppid = ['TNU_METAC_', num2str(id)];
    fpath = 'behavior\LabChart\';

    f = dir(fullfile(basedir, ppid, fpath, '*.mat'));

    tmp = load(fullfile(f.folder, f.name));

    
    %% store info in struct
    
    % range of values
    specs.rangemin = tmp.rangemin(:,end)';
    specs.rangemax = tmp.rangemax(:,end)';
    
    % units of measurement    
    specs.units = cell(1,7);
    for c = 1:7
        specs.units{1,c} = tmp.unittext(tmp.unittextmap(c,1),:);
    end
    
    % sampling rate
    specs.samplerate = tmp.samplerate(:,1)';

    % labchart comments
    specs.comment_t = tmp.com(:,3)';
    specs.comment_txt = cell(1,length(specs.comment_t));
    for k = 1:length(specs.comment_t)
        specs.comment_txt{1,k} = tmp.comtext(tmp.com(k,5),:);
    end
    
    if isempty(specs.comment_t)
        disp('No comments in LabChart file!')
    end
    
    
    
    %% reshape 
    % channel data
    dat = [];
    for i = 1:size(tmp.datastart,2)
        t(i).tmp_dat = reshape(tmp.data(tmp.datastart(1,i):tmp.dataend(7,i)), (length(tmp.datastart(1,i):tmp.dataend(7,i))/7), 7);
        dat = cat(1,dat,t(i).tmp_dat);
    end

    % time vector
    dt = [1:size(dat,1)]'/tmp.samplerate(1,1);
    time = dt-1/tmp.samplerate(1,1);
    
    % sub id vector
    id_vec = n*ones(size(dat,1),1);
    
    %% add vars to array
    dat = cat(2,dat, time, id_vec);
    
    %% cut off data not from experiment
    if ~strcmp(num2str(id), {'1004'})
        t1 = specs.comment_t(3);
        specs.comment_txt(3)
        t2 = specs.comment_t(4);
        specs.comment_txt(4)
    elseif id==1004
        t1 = specs.comment_t(4);
        specs.comment_txt(4)
        t2 = specs.comment_t(5);
        specs.comment_txt(5)
    end
    
    dat_exp = dat(t1:t2,:);

    %% create table
    tmp_str = cellstr(tmp.titles);
    title_str = [tmp_str; 'time'; 'id'];
    tab = array2table(dat_exp, 'VariableNames', title_str);
    
    
    %% plot mouth pressure (from comment "start experiment" until the end)
    figure;
    plot(tab.time(specs.comment_t(3):end,:), tab.("Mouth Pressure")(specs.comment_t(3):end,:))
    hold on
    plot(tab.time(specs.comment_t(3):end,:), tab.("Resistance Trigger")(specs.comment_t(3):end,:)./10)
    ylabel('Mouth Pressure [mmHg], Triggers')
    xlabel('time [ms]')

    %% all 7 channels
    figure;
    plot(tab.time(specs.comment_t(3):end,:), tab.("Mouth Pressure")(specs.comment_t(3):end,:))
    hold on
    plot(tab.time(specs.comment_t(3):end,:), tab.Pulse(specs.comment_t(3):end,:))
    plot(tab.time(specs.comment_t(3):end,:), tab.("Resistance Trigger")(specs.comment_t(3):end,:)./10)
    plot(tab.time(specs.comment_t(3):end,:), tab.O2(specs.comment_t(3):end,:))
    plot(tab.time(specs.comment_t(3):end,:), tab.CO2(specs.comment_t(3):end,:))
    plot(tab.time(specs.comment_t(3):end,:), tab.("Spirometer (Flow)")(specs.comment_t(3):end,:))
    legend(tab.Properties.VariableNames{1}, tab.Properties.VariableNames{2},...
        tab.Properties.VariableNames{3}, tab.Properties.VariableNames{4},...
        tab.Properties.VariableNames{5}, tab.Properties.VariableNames{6})

    %% plot & save time t1:t2
    t1 = find(tab.time==1800);
    t2 = find(tab.time==2000);
    figure;
    plot(tab.time(t1:t2,:), tab.("Mouth Pressure")(t1:t2,:))
    hold on
    plot(tab.time(t1:t2,:), tab.Pulse(t1:t2,:))
    plot(tab.time(t1:t2,:), tab.("Resistance Trigger")(t1:t2,:)./10)
    plot(tab.time(t1:t2,:), tab.O2(t1:t2,:))
    plot(tab.time(t1:t2,:), tab.CO2(t1:t2,:))
    plot(tab.time(t1:t2,:), tab.("Spirometer (Flow)")(t1:t2,:))
    legend(tab.Properties.VariableNames{1}, tab.Properties.VariableNames{2},...
        tab.Properties.VariableNames{3}, tab.Properties.VariableNames{4},...
        tab.Properties.VariableNames{5}, tab.Properties.VariableNames{6})
    
    figdir = fullfile('C:\Users\alhess\Documents\local_data\metac_data_local\data_check', ...
    ['physiology_data_', num2str(id), '_1800-2000']);
    print(figdir, '-dpng');

    
    %% if no labchart comments: plot all data from 7 channels
    if isempty(specs.comment_t)
        
        figure;
        plot(tab.time, tab.("Mouth Pressure"))
        hold on
        plot(tab.time, tab.Pulse)
        plot(tab.time, tab.("Resistance Trigger")./10)
        plot(tab.time, tab.O2)
        plot(tab.time, tab.CO2)
        plot(tab.time, tab.("Spirometer (Flow)"))
        legend(tab.Properties.VariableNames{1}, tab.Properties.VariableNames{2},...
            tab.Properties.VariableNames{3}, tab.Properties.VariableNames{4},...
            tab.Properties.VariableNames{5}, tab.Properties.VariableNames{6})
    end
    
    
    %% save formatted data table as txt file
    saveDir = fullfile(basedir, ppid, fpath,...
        ['TNU_METAC_', num2str(id), '_task_formatted.csv']);
    writetable(tab,saveDir)
    
    %% save full data table as txt file
    tab_full = array2table(dat, 'VariableNames', title_str);
    saveDir = fullfile(basedir, ppid, fpath,...
        ['TNU_METAC_', num2str(id), '_task_full.csv']);
    writetable(tab_full,saveDir)
    
    %% save specs as json file
    txt = jsonencode(specs);
    saveDir = fullfile(basedir, ppid, fpath,...
        ['TNU_METAC_', num2str(id), '_task_specs.json']);
    fid = fopen(saveDir,'w');
    fprintf(fid,'%s',txt);
    fclose(fid);

    
end

    
end