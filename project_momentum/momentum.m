%% Q1
clear ;

% read data and stack

return_m=readtable('return_monthly.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');

%%

%%
stack_return = stack(return_m, return_m.Properties.VariableNames(3:end),'NewDataVariableName', 'month_return',...
'IndexVariableName', 'date');

market_cap_lm=readtable('me_lag.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');
stack_lme = stack(market_cap_lm, market_cap_lm.Properties.VariableNames(3:end),'NewDataVariableName', 'lme',...
'IndexVariableName', 'date');

% clear NaN
merge_table = innerjoin(stack_return,stack_lme);
merge_table = rmmissing(merge_table);


%% Q2
% step 1: create a new dataset with previous K=frequency months return
all_codes = merge_table.code;
code_set = unique(all_codes);
datasets = cell(1, numel(code_set));

for i = 1:numel(code_set)
    codes = code_set{i};
    data = merge_table(strcmp(merge_table.code, codes), :);
    
    for k = [1,3,6,12,24]
        column_name = strcat('k', num2str(k));
        if height(data) <= k
            data.(column_name) = NaN(height(data));
        end
        if  height(data) > k
            previous_return = movmean(data.month_return,k,'omitnan', "Endpoints","discard");
            previous_return = cat(1, NaN(k, 1),previous_return(1:end-1));
            data.(column_name) = previous_return;
        end
    end
    datasets{i} = table2cell(data);
end
combinedDataset = vertcat(datasets{:});
header = data.Properties.VariableNames;
combinedDataset = array2table(combinedDataset, 'VariableNames', header);

% step 2: Portfolio Analysis
combinedDataset.date = cell2table(combinedDataset.date);
combinedDataset.lme = cell2table(combinedDataset.lme);
%%
store = zeros(200);
t = 0;
for i = 2:height(combinedDataset)
if iscell(table2array(cell2table(combinedDataset.k24(i-1:i))))
    t = t+1;
    store(t) = i;
end
store = store(1:t);
combinedDataset(store,:) = [];
end
%%
combinedDataset.K1 = table2array(cell2table(combinedDataset.k1));
combinedDataset.K3 = table2array(cell2table(combinedDataset.k3));
combinedDataset.K6 = table2array(cell2table(combinedDataset.k6));
combinedDataset.K12 = table2array(cell2table(combinedDataset.k12));
combinedDataset.K24 = table2array(cell2table(combinedDataset.k24));

combinedDataset = combinedDataset((combinedDataset.k1 > 0) ...
& (combinedDataset.k3 > 0)  & (combinedDataset.k6 > 0) ...
& (combinedDataset.k12 > 0) & (combinedDataset.k24 > 0), :);
%%

[G,jdate]=findgroups(combinedDataset.date);

prctile_20=@(input)prctile(input,20);
prctile_40=@(input)prctile(input,40);
prctile_60=@(input)prctile(input,60);
prctile_80=@(input)prctile(input,80);

for i = 1:5
return_m.rr20 = splitapply(prctile_20, combinedDataset(:,i+5), G);
return_m.rr40 = splitapply(prctile_40, combinedDataset(:,i+5), G);
return_m.rr60 = splitapply(prctile_60, combinedDataset(:,i+5), G);
return_m.rr80 = splitapply(prctile_80, combinedDataset(:,i+5), G);
cell2
lmeport=rowfun(@return_bucket,return_m(:,{i+5,'rr20','rr40','rr60','rr80'}),'OutputFormat','cell');
end

%Q3
pca_table = zeros(length(timePoints),5);

%填入k=3时group1-group5的平均收益

[coeff, score, latent, ~, explained] = pca(pca_table);

firstPC = score(:, 1);
secondPC = score(:, 2);

%第一个主成分代表市场整体收益主要有group()提供；第二个主成分代表除去第一个主成分外，group()
%最大程度解释了剩余方差
pca_table.MOM = pca_table.group5 - pca_table.group1;
