clear
close all
crsp=readtable('crsp_port.csv');
beta=readtable('beta.csv');
beta=beta(:,[1,2,5]);
beta.Properties.VariableNames={'permno','date','beta'};
beta.date=datetime(beta.date,'ConvertFrom','yyyyMMdd','format','yyyy/MM/dd');
Rf=readtable('Rf_mkt.CSV');

crsp.yymm=12*year(crsp.date)+month(crsp.date);
crsplag=crsp;
crsplag.yymm=crsplag.yymm-1;
crsplag.ereturn=crsplag.retadj;
crsplag.wt=crsplag.me;
crsp=innerjoin(crsp,crsplag(:,{'ereturn','yymm','permno','wt'}),'Keys',{'yymm','permno'});
crsp.me=log(crsp.me);

%% portfolio analysis

%Merge
Rf.yymm=floor(Rf.Var1/100)*12+mod(Rf.Var1,100)-1;
Rf.Mkt_RF=Rf.Mkt_RF/100;
Rf.RF=Rf.RF/100;
crsp1=innerjoin(crsp,Rf(:,{'RF','yymm'}),'Keys','yymm');
crsp1.ereturn=crsp1.ereturn-crsp1.RF;

%Portfolio Analyse
crsp1.sortvar=crsp1.me;
%crsp1.sortvar=crsp1.beme;

flexsort_5=@(x){flexsort(x,5)};
[G_date,jdate]=findgroups(crsp1.date);

var_sort=cell2mat(splitapply(flexsort_5,crsp1.sortvar,G_date));

[G_port,jdate,portgroup]=findgroups(crsp1.date,var_sort);
wavg_fun=@(x,y)wavg(x,y);

Port_return=splitapply(wavg_fun,crsp1.ereturn,crsp1.wt,G_port);

Port_return_table=table(jdate,portgroup,Port_return);

Port_return_res =unstack(Port_return_table...
    (:,{'jdate','portgroup','Port_return'}),'Port_return','portgroup');


Port_return_res.yymm=year(Port_return_res.jdate)*12+month(Port_return_res.jdate);
Port_return_res=innerjoin(Port_return_res...
    ,Rf(:,{'yymm','Mkt_RF'}),'Keys','yymm');

Port=table2array(Port_return_res(:,2:6));
Spread=Port(:,5)-Port(:,1);
Sharpe=mean(Port)./std(Port);
%Figuring
figure;
subplot(2,2,1);
plot(Port);
xlim([1 length(Port)])
title('Excess Return')

subplot(2,2,2);
Annual_return=(geomean(Port+1)-1)*12;
bar(Annual_return)
title('Annualized Excess Return')

subplot(2,2,3)
plot(Spread)
title('Spread Between Portfolios')
xlim([1 length(Port)])

subplot(2,2,4);
bar(Sharpe)
title('Sharpe Ratio')

sgtitle('Sort by size')
