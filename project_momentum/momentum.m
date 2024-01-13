%% Q1
clear ;

% read data and stack

return_m=readtable('return_monthly.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');
stack_return = stack(return_m, return_m.Properties.VariableNames(3:end),'NewDataVariableName', 'month_return',...
'IndexVariableName', 'date');

market_cap_lm=readtable('me_lag.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');
stack_lme = stack(market_cap_lm, market_cap_lm.Properties.VariableNames(3:end),'NewDataVariableName', 'lme',...
'IndexVariableName', 'date');

% clear NaN
merge_table = innerjoin(stack_return,stack_lme);
merge_table = rmmissing(merge_table);


%% Q2
% create a new dataset with previous K=frequency months return
all_codes = merge_table.code;
code_set = unique(all_codes);
datasets = cell(1, numel(code_set));

for i = 1:numel(code_set)
    codes = code_set{i};
    data = merge_table(strcmp(merge_table.code, codes), :);
    
    for k = [1,3,6,12,24]
        column_name = strcat('k = ', num2str(k));
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
