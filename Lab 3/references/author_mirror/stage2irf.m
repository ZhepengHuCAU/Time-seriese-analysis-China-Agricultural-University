% STAGE2IRF.M

function [irf1hat,irf1a,irf1b,cumirf1hat,cumirf1a,cumirf1b]=stage2irf(y,q)

t=length(q); 
pp=12; 

% Z is set of original regressors: eight lags of q and four lags of y
Z=[ones(1,t-pp)]; 
for i=0:pp
    Z=[Z; q(pp+1-i:t-i,1)'];
end;
Z=Z';

% y is dependent variable
y=y(pp+1:t,1);

% OLS
bhat=inv(Z'*Z)*Z'*y;
ehat=y-Z*bhat;

% Impulse response point estimate
irf1hat=bhat(2:end);
cumirf1hat=cumsum(irf1hat);

randn('seed',1234)
nrep=20000; IRF1=zeros(nrep,13); cumIRF1=zeros(nrep,13);

% Block bootstrap
for j=1:nrep    
    block=4;
    yr=[]; Zr=[];
    for ii=1:ceil(length(y)/block)
    	pos=ceil(rand(1,1)*(length(ehat)-block));    
        yr=[yr; y(pos:pos+block-1,:)]; 
        Zr=[Zr; Z(pos:pos+block-1,:)]; 
    end;
    yr=yr(1:length(y),1); Zr=Zr(1:length(y),:);
    br=inv(Zr'*Zr)*Zr'*yr; 

    IRF1(j,:)=br(2:end)';
    cumIRF1(j,:)=cumsum(IRF1(j,:));
end;  

irf1std=std(IRF1);
irf1a=[irf1hat'+1*irf1std; irf1hat'-1*irf1std];
irf1b=[irf1hat'+2*irf1std; irf1hat'-2*irf1std];

cumirf1std=std(cumIRF1);
cumirf1a=[cumirf1hat'+1*cumirf1std; cumirf1hat'-1*cumirf1std];
cumirf1b=[cumirf1hat'+2*cumirf1std; cumirf1hat'-2*cumirf1std];
