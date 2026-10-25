% FIGURE3.M

clear; 

trivar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VAR Impulse response analysis 
[IRF]=irfvar(A,SIGMA(1:q,1:q),p,h);
    IRF(1,:)=cumsum(IRF(1,:));
    IRF(4,:)=cumsum(IRF(4,:));
    IRF(7,:)=cumsum(IRF(7,:));

% VAR bootstrap
randn('seed',1234);
nrep=2000;
IRFmat=zeros(nrep,(q^2)*(h+1));

[t,q]=size(y);				
y=y';
Y=y(:,p:t);	
for i=1:p-1
 	Y=[Y; y(:,p-i:t-i)];		
end;

Ur=zeros(q*p,t-p);   
Yr=zeros(q*p,t-p+1); 
U=Uhat;    
for r=1:nrep
    r    
	pos=fix(rand(1,1)*(t-p+1))+1;
	Yr(:,1)=Y(:,pos);

    % Recursive design WB
    eta=randn(1,size(Uhat,2));  eta=[eta; eta; eta];
	Ur(1:q,2:t-p+1)=U(1:q,:).*eta;	
    
	for i=2:t-p+1
		Yr(:,i)= V + A*Yr(:,i-1)+Ur(:,i); 
	end;

	yr=[Yr(1:q,:)];
	for i=2:p
		yr=[Yr((i-1)*q+1:i*q,1) yr];
    end;
    yr=yr';
    [Ar,SIGMAr]=olsvarc(yr,p);

    % Compute IRFs
    IRFr=irfvar(Ar,SIGMAr(1:q,1:q),p,h);
    IRFr(1,:)=cumsum(IRFr(1,:));
    IRFr(4,:)=cumsum(IRFr(4,:));
    IRFr(7,:)=cumsum(IRFr(7,:));
    IRFmat(r,:)=vec(IRFr)';
end;
IRFrstd=reshape((std(IRFmat)'),q^2,h+1);
CI1LO=IRF-1*IRFrstd; CI1UP=IRF+1*IRFrstd;
CI2LO=IRF-2*IRFrstd; CI2UP=IRF+2*IRFrstd;

horizon=0:h;

subplot(3,3,1)
plot(horizon,-IRF(1,:),'r-',horizon,-CI1LO(1,:),'b--',horizon,-CI1UP(1,:),'b--',horizon,-CI2LO(1,:),'b:',horizon,-CI2UP(1,:),'b:',horizon,zeros(size(horizon)));
title('Oil supply shock')
ylabel('Oil production')
axis([0 h -25 15])

subplot(3,3,2)
plot(horizon,-IRF(2,:),'r-',horizon,-CI1LO(2,:),'b--',horizon,-CI1UP(2,:),'b--',horizon,-CI2LO(2,:),'b:',horizon,-CI2UP(2,:),'b:',horizon,zeros(size(horizon)));
title('Oil supply shock')
ylabel('Real activity')
axis([0 h -5 10])

subplot(3,3,3)
plot(horizon,-IRF(3,:),'r-',horizon,-CI1LO(3,:),'b--',horizon,-CI1UP(3,:),'b--',horizon,-CI2LO(3,:),'b:',horizon,-CI2UP(3,:),'b:',horizon,zeros(size(horizon)));
title('Oil supply shock')
ylabel('Real price of oil')
axis([0 h -7 12])

subplot(3,3,4)
plot(horizon,IRF(4,:),'r-',horizon,CI1LO(4,:),'b--',horizon,CI1UP(4,:),'b--',horizon,CI2LO(4,:),'b:',horizon,CI2UP(4,:),'b:',horizon,zeros(size(horizon)));
title('Aggregate demand shock')
ylabel('Oil Production')
axis([0 h -25 15])

subplot(3,3,5)
plot(horizon,IRF(5,:),'r-',horizon,CI1LO(5,:),'b--',horizon,CI1UP(5,:),'b--',horizon,CI2LO(5,:),'b:',horizon,CI2UP(5,:),'b:',horizon,zeros(size(horizon)));
title('Aggregate demand shock')
ylabel('Real activity')
axis([0 h -5 10])

subplot(3,3,6)
plot(horizon,IRF(6,:),'r-',horizon,CI1LO(6,:),'b--',horizon,CI1UP(6,:),'b--',horizon,CI2LO(6,:),'b:',horizon,CI2UP(6,:),'b:',horizon,zeros(size(horizon)));
title('Aggregate demand shock')
ylabel('Real price of oil')
axis([0 h -7 12])

subplot(3,3,7)
plot(horizon,IRF(7,:),'r-',horizon,CI1LO(7,:),'b--',horizon,CI1UP(7,:),'b--',horizon,CI2LO(7,:),'b:',horizon,CI2UP(7,:),'b:',horizon,zeros(size(horizon)));
title('Oil-specific demand shock')
ylabel('Oil production')
xlabel('Months')
axis([0 h -25 15])

subplot(3,3,8)
plot(horizon,IRF(8,:),'r-',horizon,CI1LO(8,:),'b--',horizon,CI1UP(8,:),'b--',horizon,CI2LO(8,:),'b:',horizon,CI2UP(8,:),'b:',horizon,zeros(size(horizon)));
title('Oil-specific demand shock')
ylabel('Real activity')
xlabel('Months')
axis([0 h -5 10])

subplot(3,3,9)
plot(horizon,IRF(9,:),'r-',horizon,CI1LO(9,:),'b--',horizon,CI1UP(9,:),'b--',horizon,CI2LO(9,:),'b:',horizon,CI2UP(9,:),'b:',horizon,zeros(size(horizon)));
title('Oil-specific demand shock')
ylabel('Real price of oil')
xlabel('Months')
axis([0 h -7 12])

% Added by Rich Ryan
% Email: richryan@csub.edu
writematrix(IRF, '../dta/src/dat_figure3-IRF.csv');
writematrix(IRFrstd, '../dta/src/dat_figure3-CI.csv');
