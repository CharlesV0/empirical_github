%% Examine the momentum effect

clear
close all


return_m_hor=readtable('return_monthly.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');


return_m.date=char(return_m.date);
return_m.datestr=datestr(return_m.date);
return_m.date=datetime(return_m.datestr,'InputFormat','dd-MMM-yyyy','Locale','en_US');
return_m.return_m=return_m.return_m/100;


% Read the file with previous month market capitalizaiton 


market_cap_lm_hor=readtable('me_lag.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');

market_cap_lm.date=char(market_cap_lm.date);
market_cap_lm.datestr=datestr(market_cap_lm.date);
market_cap_lm.date=datetime(market_cap_lm.datestr,'InputFormat','dd-MMM-yyyy','Locale','en_US');


