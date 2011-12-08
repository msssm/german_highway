function results(a,v,x,s,fstcar,lstcar,normalize,simtime)
%RESULTS generates the plotting results.
%a=acceleration values in m/s^2
%v=velocity values in m/s
%x=location values in m
%s=distance values in m
%carnumber=number of cars that should be plotted
%simtime=simulation time in s
%normalize: true <=> velocity is plotted such that every car starts at 
%t=0 (normalized)

%Pre-calculations
firstcar=fstcar;
lastcar=lstcar;
plotlength=ceil(simtime);
vkmh=3.6*v;                                     

if normalize==true                              
    vplt=zeros(length(vkmh(:,1)),length(vkmh(1,:)));    
    splt=zeros(length(s(:,1)),length(s(1,:)));
    aplt=zeros(length(a(:,1)),length(a(1,:)));
    xplt=zeros(length(x(:,1)),length(x(1,:)));
    for jj=1:length(vkmh(1,:))                  %iteration over cars
        kk=1;                                   
        for ii=1:length(vkmh(:,1))              %iteration over time
            if x(ii,jj)~=0 && x(ii-1,jj)~=0     %deletes all the zeros from the
                                                %columns, every car starts at 
                                                %first column
                vplt(kk,jj)=vkmh(ii,jj);        
                splt(kk,jj)=s(ii,jj);
                aplt(kk,jj)=a(ii,jj);
                xplt(kk,jj)=x(ii,jj);
                kk=kk+1;
            end
        end
    end
else
    vplt=vkmh;                                 
    splt=s;
    for jj=1:length(vkmh(1,:))                 %iteration over cars
        for ii=1:length(vkmh(:,1))             %iteration over time
            if  x(ii,jj)==0
                vplt(ii,jj)=NaN;               %replaces all zeros with NaN 
                                               %so they don't appear in the plot
                splt(ii,jj)=NaN;
                aplt(ii,jj)=NaN;
                xplt(ii,jj)=NaN;
            else
                vplt(ii,jj)=vkmh(ii,jj);
                splt(ii,jj)=s(ii,jj);
                aplt(ii,jj)=a(ii,jj);
                xplt(ii,jj)=x(ii,jj);
            end
        end
    end
end

%create legend
for car=firstcar:lastcar 
    label{car-firstcar+1}=['Car ',num2str(car)];
end

%velocity
figure;                                          
plot(1:plotlength,vplt(1:plotlength,firstcar:lastcar));
title(['v[t] for cars ',int2str(firstcar),' through ',int2str(lastcar),'.']);
xlabel('Time [s]');
ylabel('Car velocity v [km/h]');
legend(label);
grid on;

%distance
figure;
plot(1:plotlength,splt(1:plotlength,firstcar:lastcar));
title(['s[t] for cars ',int2str(firstcar),' through ',int2str(lastcar),'.']);
xlabel('Time [s]');
ylabel('Distance to front car s [m]');
legend(label);
grid on;

%acceleration
figure;
plot(1:plotlength,aplt(1:plotlength,firstcar:lastcar));
title(['a[t] for cars ',int2str(firstcar),' through ',int2str(lastcar),'.']);
xlabel('Time [s]');
ylabel('Accelleration a [m]');
legend(label);
grid on;

%location
figure;
plot(1:plotlength,xplt(1:plotlength,firstcar:lastcar));
title(['x[t] for cars ',int2str(firstcar),' through ',int2str(lastcar),'.']);
xlabel('Time [s]');
ylabel('Location x [m]');
legend(label);
grid on;

end