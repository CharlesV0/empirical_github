%% Q1
clear

tic


% read data
return_m=readtable('return_monthly.xlsx', 'ReadVariableNames', true, 'PreserveVariableNames', true, 'Format', 'auto');

% 'VariableTypes', varTypes

market_cap_lm=readtable('me_lag.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');

% stack into long table
stack_return = stack(return_m, return_m.Properties.VariableNames(3:end),'NewDataVariableName', 'month_return',...
'IndexVariableName', 'date');

stack_lme = stack(market_cap_lm, market_cap_lm.Properties.VariableNames(3:end),'NewDataVariableName', 'lme',...
'IndexVariableName', 'date');

% merge
merge_table = innerjoin(stack_return,stack_lme);

% clear NaN
merge_table = rmmissing(merge_table);

clear return_m stack_lme market_cap_lm stack_return varTypes

toc

%% Q2
tic
% create a new dataset with previous K=frequency months return
% 假设 merge_table 是一个存在的表格，包含至少 'code' 和 'month_return' 两列
all_codes = merge_table.code;
code_set = unique(all_codes);

% 初始化一个空表格，列名与 merge_table 相同
resultTable = table();

for i = 1:numel(code_set)
    codes = code_set(i);
    data = merge_table(strcmp(merge_table.code, codes), :);
    
    for k = [1, 3, 6, 12, 24]
        column_name = strcat('k', num2str(k));
        if height(data) <= k
            data.(column_name) = NaN(height(data), 1);
        else
            previous_return = movmean(data.month_return, k, 'omitnan', "Endpoints", "discard");
            previous_return = cat(1, NaN(k-1, 1), previous_return);
            data.(column_name) = previous_return;
        end
    end
    
    % 将处理后的数据添加到结果表格
    resultTable = [resultTable; data];
end

% 最终的合并数据集
combinedDataset = resultTable;

toc

combinedDataset = rmmissing(combinedDataset);
combinedDataset.code = cell2mat(combinedDataset.code);

% finding out the problematic ones
% store = zeros(1,500);
% t = 0;
% for i = 2:height(combinedDataset)
%     if ~isnumeric(table2array(cell2table(combinedDataset.k24(i))))
%         t = t+1;
%         store(t) = i;
%         disp(i);
%     end
% end
% store = store(1,1:t);
% combinedDataset(store,:) = [];



%% step 2: Portfolio Analysis
tic
[G,~]=findgroups(combinedDataset.date);

prctile_20=@(input)prctile(input,20);
prctile_40=@(input)prctile(input,40);
prctile_60=@(input)prctile(input,60);
prctile_80=@(input)prctile(input,80);

spread = zeros(1,5);
%spread = zeros(length(unique(combinedDataset.date)),5);
dateseries = unique(combinedDataset.date);
for i = 1:5
    Separatepoint = [splitapply(prctile_20, combinedDataset(:,i+5), G) splitapply(prctile_40, combinedDataset(:,i+5), G) ...
       splitapply(prctile_60, combinedDataset(:,i+5), G) splitapply(prctile_80, combinedDataset(:,i+5), G) ];
    Tset = table(Separatepoint(:,1),Separatepoint(:,2),Separatepoint(:,3),Separatepoint(:,4));
    Tset.Properties.VariableNames = ["rr20","rr40","rr60","rr80"];
    Tset.date = unique(combinedDataset.date);
    new_combinedDataset = outerjoin(combinedDataset,Tset);
    %rr is the abbreviation of return rate
    rrport=rowfun(@return_bucket,new_combinedDataset(:,[i+5 11 12 13 14]),'OutputFormat','cell');
    new_combinedDataset.rrport = rrport;
    High = new_combinedDataset((new_combinedDataset.rrport == "VH"),:);
    Low = new_combinedDataset((new_combinedDataset.rrport == "VL"),:);
    High_rr = mean(High(:,i+5));
    Low_rr = mean(Low(:,i+5));
    spread(i) = table2array(High_rr) - table2array(Low_rr);
end

clear prctile_80 prctile_60 prctile_40 prctile_20;
toc
%% Q3
tic
pca_data = (zeros(length(dateseries),5));

%求k=3时group1-group5的平均收益
i=2;
new_G = findgroups(new_combinedDataset.date_combinedDataset, new_combinedDataset.rrport);
rr_distribution = splitapply(@mean, new_combinedDataset(:,i+5), new_G);

for j = 1: length(unique(new_combinedDataset.date_combinedDataset))
    date = dateseries(j);
    group1 = new_combinedDataset((new_combinedDataset.rrport == "VH" & new_combinedDataset.date_combinedDataset == date),:);
    group2 = new_combinedDataset((new_combinedDataset.rrport == "H" & new_combinedDataset.date_combinedDataset == date),:);
    group3 = new_combinedDataset((new_combinedDataset.rrport == "M" & new_combinedDataset.date_combinedDataset == date),:);
    group4 = new_combinedDataset((new_combinedDataset.rrport == "L" & new_combinedDataset.date_combinedDataset == date),:);
    group5 = new_combinedDataset((new_combinedDataset.rrport == "VL" & new_combinedDataset.date_combinedDataset == date),:);
    
    gVH = table2array(mean(group1(:,i+5)));
    gH = table2array(mean(group2(:,i+5)));
    gM = table2array(mean(group3(:,i+5)));
    gL = table2array(mean(group4(:,i+5)));
    gVL = table2array(mean(group5(:,i+5)));

    
    pca_data(j,:) = [gVL,gL,gM,gH,gVH];
end

% pca_table = array2table(pca_table,"VariableNames",["gVL","gL","gM",'gH','gVH']);

[coeff, score, latent, ~, explained] = pca(pca_data);

firstPC = score(:, 1);
secondPC = score(:, 2);

%第一个主成分代表市场整体收益主要有group()提供；第二个主成分代表除去第一个主成分外，group()
%最大程度解释了剩余方差

MOM_factor = pca_data(:,5) - pca_data(:,1);


clear group1 group2 group3 group4 group5;

toc
