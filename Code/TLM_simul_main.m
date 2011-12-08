%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1 Start section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%measure time
tic;

%Everything empty
clc;
close all;
clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%IDM Parameters of simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
L=20000;                        %Length of simulated roadpart [L]=m
simtime=0.25*3600;              %Simulation time [s]
T_headway=1.1;                  %desired time until current position of front 
                                %car would be reached assuming the actual speed 
                                %[T_headway]=s. Corresponds to an average driver.
ac=1;                           %maximum acceleration of car / driver [a]=m. 
                                %Corresponds to an average driver.
b=1.5;                          %Desired agreeable deceleration without danger, 
                                %[b]=m/s^2. Corresponds to an average driver.
v0=160;                         %Desired maximum velocity [v0]=km/h. 
                                %Corresponds to an average driver.
v_ini=130;                      %Initial velocity of cars entering the road,
                                %[v_ini]=km/h.
s0=2;                           %Desired distance to front car at rest [s0]=m
l=5;                            %Length of a vehicle [l]=m
Q=0.2;                          %Rate of cars entering the observed part of the 
                                %road [Q]=1/s Note: The maximum capacity of the 
                                %road under ideal conditions 
                                %is Q_max=v0/(s_star+l)=0.763;
dt=1;                           %Iteration timestep [dt]=1
picturesequence=0.02;           %simulation demonstration with this picture 
                                %sequency (in seconds)

%Estimation errors (Set both values to 0 if you want to neglect this effect)
deltav_coeff=0.015;             %Coefficient that specifies the imprecision of the
                                %velocity difference estimation [deltav_coeff]=1/s
s_coeff=0.015;                  %Coefficient that specifies the imprecission of 
                                %the spatial difference estimation [s_coeff]=m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%HDM parameters of simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Finite reaction time (Set T_reaction to 0 if you want to neglect this effect)
T_reaction=0.8;                 %Reaction time [T_reaction]=s

%Temporal anticipation (Set this value to 0 (='off') if you want to 
%neglect this effect)
temporal_anticipation_switch=1; %Can be set to 1 (='on') or 0 (='off') 
                                %[temporal_anticipation_switch]=1
assert(temporal_anticipation_switch==1||temporal_anticipation_switch==0,...
'The variable "temporal_anticipation_switch" has not been assigned a valid value');

%Spatial anticipation (Set n=1 if you want to neglect this effect)
n=3;                            %Number of cars ahead used for spatial 
                                %anticipation [n]=1

%Individual drivers (vehicle parameters in 3)
individual_driver_switch=1;     %Can be set to 1 (='on') or 0 (='off') 
                                %[individual_driver_switch]=1
assert(individual_driver_switch==1||individual_driver_switch==0,...
'The variable "individual_driver_switch" has not been assigned a valid value');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Two lane parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
twolane=1;                      %Can be set to 1 (two lanes) or 0 (one lane)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Starting calculations and initialization of further variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cct=1/Q;                        %Car - creation time. Specifies the time 
                                %interval between two cars entering the road 
                                %according to Q
ionc=0;                         %index of newest (in terms of time) car that 
                                %has been created on the road; start with 0 
                                %cars on road
v0=v0/3.6;                      %Conversation km/h->m/s
timeidm=floor(T_reaction/dt);   %find timestep in which simulation can start 
                                %(due to reaction time)
carnumbmax=ceil(1+simtime*Q);   %maximum number of cars during simulation
timenumb=ceil(simtime/dt);      %number of timesteps
cadtype=zeros(1,carnumbmax);    %car and driver type (numbers correspond
                                %to section 3)

%First row of carresortmatrix contains cars on rigth lane; second row contains 
%cars on the left lane in the sequence in which they appear on the corresponding 
%lane of the road at the moment t. Furthermore zeros indicate that a care on 
%the other lane is between the own car and the next car on the own lane. 
%Hence the matrix contains the relative order on the road.
%E.g. [3,1,0,0,2,0;0,0,6,4,0,5] would mean: car 3 is the first (right
%lane), then car 1 (right lane) then car 6 (left lane), then car 4 (left
%lane) ans so on...
carresortmatrix=zeros(2,carnumbmax);
caronroad=zeros(1,carnumbmax);           %label each car, if it is still on road: 
                                         %2 = car is the first car on this line; 
                                         %1 = car on road, but not the first, 
                                         %0 = car not on road, resp. is "off"
x=zeros(timenumb,carnumbmax);            %space coordinate of each car
v=zeros(timenumb,carnumbmax)+v_ini/3.6;  %actual velocity
a=zeros(timenumb,carnumbmax);            %maximum acceleration
s=zeros(timenumb,carnumbmax);            %distance to car in front
beta=((1+timeidm)*dt-T_reaction)/...     %Technical coefficient for including 
(((1+timeidm)*dt-T_reaction)+...         %T_reaction
(T_reaction-timeidm*dt));  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2 Car and driver types section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%sleeping driver correspondig to 1
p_sleep=1/3;              %fraction of this driver- /cartype under all cars
T_headway_sleep=1.5*T_headway;
ac_sleep=0.7*ac;
b_sleep=0.7*b;
v0_sleep=0.9*v0;

%normal driver corresponding to 2
p_normal=1/3;             %fraction of this driver- /cartype under all cars
T_headway_normal=T_headway;
ac_normal=ac;
b_normal=b;
v0_normal=v0;

% agressive driver corresponding to 3
p_aggressive=1/3;         %fraction of this driver- /cartype under all cars
T_headway_aggressive=0.5*T_headway;
ac_aggressive=1.3*ac;
b_aggressive=1.3*b;
v0_agressive=1.1*v0;

%Define struct with car and driver parameters
switch individual_driver_switch
    case 0
        cadpara=struct('T_headway',{T_headway, T_headway, T_headway},...
            'ac',{ac, ac, ac},'b',{b, b, b},'v0',{v0, v0, v0});  
        assert(p_sleep+p_normal+p_aggressive==1,...
            'Sum of probabilites for car types is no equal to 1');
    case 1
        cadpara=struct('T_headway',{T_headway_sleep, T_headway_normal,...
            T_headway_aggressive},'ac',{ac_sleep, ac_normal,...
            ac_aggressive},'b',{b_sleep, b_normal, b_aggressive},...
            'v0',{v0_sleep, v0_normal, v0_agressive});  
        assert(p_sleep+p_normal+p_aggressive==1,...
            'Sum of probabilites for car types is no equal to 1');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3 Two lane model section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for time=(timeidm+2):timenumb
     
    %% boundary conditions at the beginning of the road
    if(Q~=0&&cct>=1/Q)                     %is it time for a new car?
        ionc=ionc+1;                       %create new car on the right lane 
                                           %of the road at the beginning of 
                                           %the simulated road part
        carresortmatrix(:,ionc)=[ionc;0];
        caronroad(ionc)=1;
         
        %Determine type of car and driver entering roadpart according to
        %probabilities
        type=rand(1);
        if(type<=p_sleep)
            cadtype(ionc)=1;
        elseif(type>p_sleep&&type<=(p_sleep+p_normal))
            cadtype(ionc)=2;
        elseif(type>(p_sleep+p_normal)&&type<=(p_sleep+p_normal+p_aggressive))
            cadtype(ionc)=3;
        end            
            
        cct=cct-1/Q;                       %set car creation time to zero
    end   
    
        %Time increase
        cct=cct+dt;       
      
      if(twolane)     
      %% find new carresortmatrix that changes due to cars changing the lane 
      %in this time step
      carresortmatrix=lanechangev2(carresortmatrix,time,...
          cadpara,cadtype,x,v);      
      end       
      
      %% Set cars inactive that have left the simulated roadpart and determine 
      %first cars on each lane
      caronroad=deactivate(x,carresortmatrix,caronroad,time,L);                
         
    %% Specifing car behavior according to IDCM       
    for auto=1:ionc  
                   
        if(caronroad(auto)==1)
                  
            %Spatial anticipation and reaction time     
            [r,c]=find(carresortmatrix==auto);
            gthcar=[];
        
            %Determine all cars up to n-th car in front of the actual car. 
            %If there are less than n cars in front, use the ones that are 
            %available
            for k=1:c-1 %Iterate over cars in front of actual car
            
                if(length(gthcar)<n&&carresortmatrix(r,c-k)~=0&&...
                        caronroad(carresortmatrix(r,c-k))~=0)
                    gthcar=[gthcar,carresortmatrix(r,c-k)];
                end
              
                if(carresortmatrix(r,c-k)~=0&&...
                        caronroad(carresortmatrix(r,c-k))==2)
                    break;
                end              
                            
            end
        
            %s_reaction contains the distances from the actual car to each car
            %in front. Same is true for the velocity differences
            s_reaction=zeros(1,length(gthcar));
            deltav_reaction=zeros(1,length(gthcar));       
        
            for g=1:length(gthcar)            
                s_reaction(g)=beta*x(time-1-timeidm,gthcar(g))+(1-beta)*...
                    x(time-2-timeidm,gthcar(g))-(beta*x(time-1-timeidm,auto)...
                    +(1-beta)*x(time-2-timeidm,auto));
                deltav_reaction(g)=beta*v(time-1-timeidm,auto)+(1-beta)*...
                    v(time-2-timeidm,auto)-(beta*v(time-1-timeidm,gthcar(g))...
                    +(1-beta)*v(time-2-timeidm,gthcar(g)));
            end
        
            a_reaction=beta*a(time-1-timeidm,auto)+(1-beta)*a(time-2-timeidm,auto);      
            v_reaction=beta*v(time-1-timeidm,auto)+(1-beta)*v(time-2-timeidm,auto);
        
            %Estimation errors 
            s_est=s_reaction+s_coeff....       %Distance estimation error  
                *randn(1,length(gthcar));      %corresponds to standard normal 
                                               %distribution                                                       
            a_est=a_reaction;                  %No information about accelleration                                                         
            deltav_est=deltav_reaction+...     %Velocity difference errors based
                deltav_coeff.*s_reaction.*...  %on standard normal distribution
                randn(1,length(gthcar));       %and proportional to the
                                               %corresponding vehicle ahead   
            v_est=v_reaction;                  %No estimation errors here                                                         
        
               
            %Temporal anticipation
            switch temporal_anticipation_switch
                case 1
                    s_temp=s_est-T_reaction.*deltav_est;
                    v_temp=v_est+T_reaction*a_est;
                    deltav_temp=deltav_est;
                case 0
                    s_temp=s_est;
                    v_temp=v_est;
                    deltav_temp=deltav_est;
            end
           
               
            %Physical model for driving
            s_star=s0+v_temp*(cadpara(cadtype(auto)).T_headway)+...
                v_temp.*deltav_temp./(2*sqrt((cadpara(cadtype(auto)).ac)*...
                (cadpara(cadtype(auto)).b)));
            a_traffic=sum(-(cadpara(cadtype(auto)).ac)*(s_star./s_temp).^2);
            a_free=cadpara(cadtype(auto)).ac...
                *(1-(v_temp/(cadpara(cadtype(auto)).v0))^4); 
            a(time-1,auto)=a_free+a_traffic;
        
            %Update quantities for this time step according to physical model
            v(time,auto)=v(time-1,auto)+dt*a(time-1,auto);
            x(time,auto)=x(time-1,auto)+v(time-1,auto)*dt+0.5*a(time-1,auto)*dt^2;          
        
        elseif(caronroad(auto)==2)
            
            %Specify behavior of the first cars on each lane
            a_free=cadpara(cadtype(auto)).ac*(1-(v(time-1,auto)/...
                (cadpara(cadtype(auto)).v0))^4); 
            a(time-1,auto)=a_free;
            v(time,auto)=v(time-1,auto)+dt*a(time-1,auto);
            x(time,auto)=x(time-1,auto)+v(time-1,auto)*dt+0.5*a(time-1,auto)*dt^2;
              
        end                    
    end  
    
    
    %% Rebuild new carresortmatrix
    %After one timestep cars might have change order due to outdistancing
    if(twolane)    
    carresortmatrix=changeorder(carresortmatrix,x,ionc,time);
    end
    
    %Save overall information about carorder
    totalcarressortmatrix{time}=carresortmatrix; 
    totalcaronroad{time}=caronroad;   
    
     
   %% Test if cars have crashed
   s_intermediate=carcrash(time,ionc,caronroad,carresortmatrix,x);
   s(time,1:ionc)=s_intermediate;   
  
end

telapsed=toc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4 Analyzing section
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Make plotresults
results(a,v,x,s,12,22,false,simtime);

%Make video
videonew(x,totalcarressortmatrix,totalcaronroad,timeidm,timenumb,...
    picturesequence,twolane);




