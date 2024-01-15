%% Q1
clear

tic

% assign vardoc iabnanmeanle type
% repeatedElement = 'double'; 
% numRepeats = 125;
% repeatedCell = repmat({repeatedElement}, 1, numRepeats);
% varTypes = {['string','string',repeatedCell]};
% clear numRepeats repeatedElement repeatedCell;
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


[G,jdate]=findgroups(combinedDataset.date);

prctile_20=@(input)prctile(input,20);
prctile_40=@(input)prctile(input,40);
prctile_60=@(input)prctile(input,60);
prctile_80=@(input)prctile(input,80);

return_m_port=table();
spread = zeros(1,5);
for i = 1:5
return_m_port.rr20 = splitapply(prctile_20, combinedDataset(:,i+5), G);
return_m_port.rr40 = splitapply(prctile_40, combinedDataset(:,i+5), G);
return_m_port.rr60 = splitapply(prctile_60, combinedDataset(:,i+5), G);
return_m_port.rr80 = splitapply(prctile_80, combinedDataset(:,i+5), G);

%rr is the abbreviation of return rate
rrport=rowfun(@return_bucket,return_m_port(:,:),'OutputFormat','cell');
return_m_port.rrport = cell2mat(rrport);
High = return_m_port((return_m_port.rrport == "VH"),:);
Low = return_m_port((return_m_port.rrport == "VL"),:);
High_rr = mean(High(:,i+5));
Low_rr = mean(Low(:,i+5));

spread(i) = High_rr - Low_rr;
end

%% Q3
timePoints = unique(combinedDataset.date);
pca_table = zeros(length(timePoints),5);

%填入k=3时group1-group5的平均收益

[coeff, score, latent, ~, explained] = pca(pca_table);

firstPC = score(:, 1);
secondPC = score(:, 2);

%第一个主成分代表市场整体收益主要有group()提供；第二个主成分代表除去第一个主成分外，group()
%最大程度解释了剩余方差
pca_table.MOM = pca_table.group5 - pca_table.group1;
