% FIGURE2.M
clear;

trivar

% Compute structural shocks Ehat
Ehat=inv(chol(SIGMA)')*Uhat(1:q,:);
q1=Ehat(1,:); q1=[(q1(1,1)+q1(1,2))/2 q1];
q2=Ehat(2,:); q2=[(q2(1,1)+q2(1,2))/2 q2];
q3=Ehat(3,:); q3=[(q3(1,1)+q3(1,2))/2 q3];

% Average monthly shocks by quarter
time=1975:1:2007;
for i=1:length(time)
   q1a(i)=(q1(12*(i-1)+1)+q1(12*(i-1)+2)+q1(12*(i-1)+3)+q1(12*(i-1)+4)+q1(12*(i-1)+5)+q1(12*(i-1)+6)+q1(12*(i-1)+7)+q1(12*(i-1)+8)+q1(12*(i-1)+9)+q1(12*(i-1)+10)+q1(12*(i-1)+11)+q1(12*(i-1)+12))/12;
   q2a(i)=(q2(12*(i-1)+1)+q2(12*(i-1)+2)+q2(12*(i-1)+3)+q2(12*(i-1)+4)+q2(12*(i-1)+5)+q2(12*(i-1)+6)+q2(12*(i-1)+7)+q2(12*(i-1)+8)+q2(12*(i-1)+9)+q2(12*(i-1)+10)+q2(12*(i-1)+11)+q2(12*(i-1)+12))/12;
   q3a(i)=(q3(12*(i-1)+1)+q3(12*(i-1)+2)+q3(12*(i-1)+3)+q3(12*(i-1)+4)+q3(12*(i-1)+5)+q3(12*(i-1)+6)+q3(12*(i-1)+7)+q3(12*(i-1)+8)+q3(12*(i-1)+9)+q3(12*(i-1)+10)+q3(12*(i-1)+11)+q3(12*(i-1)+12))/12;
end;

subplot(3,1,1)
plot(time,q1a,time,zeros(size(q1a))); axis tight;
title('Oil Supply Shock')
axis([1975 2007 -1 +1])
%axis([1976 1983 -1 +1])

subplot(3,1,2)
plot(time,q2a,time,zeros(size(q2a))); axis tight;
title('Aggregate Demand Shock')
axis([1975 2007 -1 +1])
%axis([1976 1983 -1 +1])

subplot(3,1,3)
plot(time,q3a,time,zeros(size(q3a))); axis tight;
title('Oil-Specific Demand Shock')
axis([1975 2007 -1 +1])
%axis([1976 1983 -1 +1])

