clear ;

return_m=readtable('return_monthly.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');
stack_return = stack(return_m, return_m.Properties.VariableNames(3:end),'NewDataVariableName', 'month_return',...
'IndexVariableName', 'date');

market_cap_lm=readtable('me_lag.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');
stack_lme = stack(market_cap_lm, market_cap_lm.Properties.VariableNames(3:end),'NewDataVariableName', 'lme',...
'IndexVariableName', 'date');

merge_table = innerjoin(stack_return,stack_lme);
