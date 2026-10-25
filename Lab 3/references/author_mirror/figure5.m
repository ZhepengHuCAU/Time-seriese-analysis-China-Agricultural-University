% FIGURE5.M
clear;

trivar

% Compute structural shocks Ehat
Ehat=inv(chol(SIGMA)')*Uhat(1:q,:);
q1=Ehat(1,:); q1=[(q1(1,1)+q1(1,2))/2 q1];
q2=Ehat(2,:); q2=[(q2(1,1)+q2(1,2))/2 q2];
q3=Ehat(3,:); q3=[(q3(1,1)+q3(1,2))/2 q3];

% Average monthly shocks by quarter
time=1975+1/4:1/4:2007+4/4;
for i=1:length(time)
   q1q(i)=(q1(3*(i-1)+1)+q1(3*(i-1)+2)+q1(3*(i-1)+3))/3;
   q2q(i)=(q2(3*(i-1)+1)+q2(3*(i-1)+2)+q2(3*(i-1)+3))/3;
   q3q(i)=(q3(3*(i-1)+1)+q3(3*(i-1)+2)+q3(3*(i-1)+3))/3;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Source: BEA website for real chained 2000 dollar GDP,74.IV-07.IV
load beagdp.txt; gdp=beagdp(:,3); y=dif(log(gdp))*400;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time=0:12;

[irf2hat,irf2a,irf2b,cumirf2hat,cumirf2a,cumirf2b]=stage2irf(y,q1q');
subplot(3,2,1)
plot(time,-cumirf2hat,'b-',time,-cumirf2a,'g--',time,-cumirf2b,'b:',time,zeros(size(time)),'k-'); axis([0 12 -15 10])
ylabel('Real GDP')
title('Crude Oil Supply Shock')

[irf3hat,irf3a,irf3b,cumirf3hat,cumirf3a,cumirf3b]=stage2irf(y,q2q');
subplot(3,2,3)
plot(time,cumirf3hat,'b-',time,cumirf3a,'b--',time,cumirf3b,'b:',time,zeros(size(time)),'k-'); axis([0 12 -15 10])
ylabel('Real GDP')
title('Aggregate Demand Shock')

[irf4hat,irf4a,irf4b,cumirf4hat,cumirf4a,cumirf4b]=stage2irf(y,q3q');
subplot(3,2,5)
plot(time,cumirf4hat,'b-',time,cumirf4a,'b--',time,cumirf4b,'b:',time,zeros(size(time)),'k-'); axis([0 12 -15 10])
ylabel('Real GDP')
title('Oil-Market Specific Demand Shock')
xlabel('Quarters')

% Added by Rich Ryan
% Email: RichRyan@csub.edu
dat = [time' cumirf2hat     cumirf2b'     cumirf3hat     cumirf3b'     cumirf4hat     cumirf4b'];
writematrix(dat, '../dta/src/dat_figure5-irf2-gdp.csv');

clear;

trivar
Ehat=inv(chol(SIGMA)')*Uhat(1:q,:);
q1=Ehat(1,:); 
q2=Ehat(2,:); 
q3=Ehat(3,:); 

% Compute structural shocks Ehat
Ehat=inv(chol(SIGMA)')*Uhat(1:q,:);
q1=Ehat(1,:); q1=[(q1(1,1)+q1(1,2))/2 q1];
q2=Ehat(2,:); q2=[(q2(1,1)+q2(1,2))/2 q2];
q3=Ehat(3,:); q3=[(q3(1,1)+q3(1,2))/2 q3];

% Average monthly shocks by quarter
time=1975+1/4:1/4:2007+4/4;
for i=1:length(time)
   q1q(i)=(q1(3*(i-1)+1)+q1(3*(i-1)+2)+q1(3*(i-1)+3))/3;
   q2q(i)=(q2(3*(i-1)+1)+q2(3*(i-1)+2)+q2(3*(i-1)+3))/3;
   q3q(i)=(q3(3*(i-1)+1)+q3(3*(i-1)+2)+q3(3*(i-1)+3))/3;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Source: FRED
time=(1975+1/4:1/4:2007+4/4)';
load cpi.txt; cpi=log(cpi(:,3)); 
for i=1:length(time)
   infl(i,1)=(cpi(i*3+1)-cpi((i-1)*3+1))*400;
end;   
y=infl; 

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time=0:12;

[irf2hat_cpi,irf2a_cpi,irf2b_cpi,cumirf2hat_cpi,cumirf2a_cpi,cumirf2b_cpi]=stage2irf(y,q1q');
subplot(3,2,2)
plot(time,-cumirf2hat_cpi,'b-',time,-cumirf2a_cpi,'b--',time,-cumirf2b_cpi,'b:',time,zeros(size(time)),'k-'); axis([0 12 -20 30])
ylabel('CPI')
title('Crude Oil Supply Shock')

[irf3hat_cpi,irf3a_cpi,irf3b_cpi,cumirf3hat_cpi,cumirf3a_cpi,cumirf3b_cpi]=stage2irf(y,q2q');
subplot(3,2,4)
plot(time,cumirf3hat_cpi,'b-',time,cumirf3a_cpi,'b--',time,cumirf3b_cpi,'b:',time,zeros(size(time)),'k-'); axis([0 12 -20 30])
ylabel('CPI')
title('Aggregate Demand Shock')

[irf4hat_cpi,irf4a_cpi,irf4b_cpi,cumirf4hat_cpi,cumirf4a_cpi,cumirf4b_cpi]=stage2irf(y,q3q');
subplot(3,2,6)
plot(time,cumirf4hat_cpi,'b-',time,cumirf4a_cpi,'b--',time,cumirf4b_cpi,'b:',time,zeros(size(time)),'k-'); axis([0 12 -20 30])
ylabel('CPI')
title('Oil-Market Specific Demand Shock')
xlabel('Quarters')

% Added by Rich Ryan
% Email: RichRyan@csub.edu
dat = [time' cumirf2hat_cpi cumirf2b_cpi' cumirf3hat_cpi cumirf3b_cpi' cumirf4hat_cpi cumirf4b_cpi'];
writematrix(dat, '../dta/src/dat_figure5-irf2-cpi.csv');
