%% Q1
clear

tic

% assign variable type
repeatedElement = 'double'; 
numRepeats = 125;
repeatedCell = repmat({repeatedElement}, 1, numRepeats);
varTypes = {['string','string',repeatedCell]};
clear numRepeats repeatedElement repeatedCell;
% varTypes = {'string', 'string', 'double'};

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

% clear stack_lme return_m market_cap_lm stack_return
toc

%% Q2
tic
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

toc

% portfolio analysis




%% Q3 

% PCA factors
data = [return_m, lag3];
[coefMatrix, score, latent, tsquared, explainedVar] = pca(data);
factors = spotRates * coefMatrix;

% MOM factors




