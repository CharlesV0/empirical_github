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

%% test
