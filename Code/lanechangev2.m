function carresortmatrix=lanechangev2(carresortmatrix,...
    time,cadpara,cadtype,x,v)
%% find actual carresortmatrix that changes due to changing the lane and 
%outdistancing taking place in this time step
    
    %Physical model for changing to left lane
        %Motivation to outdistance given by criterion 1 and 2
        %1 criterion for switching to left lane: There is a driver in front
        %  very close
        %2 criterion for switching to left lane: Driver in front goes much slower
        
        %Criterion 3 to 4 state whether it is possible to change the lane
        %3 criterion for switching to left lane: Next car on left lane is 
        %  farer or at least equal far away
        %  than next car on this (right) lane
        %4 criterion for switching to left lane: No car on left lane from
        %  behind is too close
        
        
    %Physical model for changing to right lane 
       %Motivation to switch to right lane is given by traffic rule
       %to drive on right lane if possible. Criterion 1 to 2 state whether
       %it is possible to change the line
       %1 criterion for switching to right lane: On the right lane is
       %  enough space to front car in order to move in according to IDM 
       %2 criterion for switching to right lane: On right lane is enough
       %  space to the rear car according to IDM
    
       
       %Create an intermediate matrix, such that lane change effects become
       %effective not before ALL cars made their decisions. The lane changes are
       %then updated in the end => Same boundary conditions for all cars.
       carresortmatrixintermediate=carresortmatrix;
       
       %Find out number of cars created so far => iteration boundary
       [~,cars]=find(carresortmatrix~=0);
       numberofcars=max(cars);
       
              
    for auto=1:numberofcars       
                           
        [r,c]=find(carresortmatrix==auto); %finds row and colum indices of 
                                           %this car in the carresortmatrix
        
            switch r
            
            %test, if car should move to left lane in this time step, if it is 
            %on right line
            case 1
                
                %1. criterion
                %Who is in front?
                r_front=r; 
                  
                if(c>1&&sum(carresortmatrix(r,1:c-1))~=0) %Someone in front?
                    for k=1:numberofcars
                        if(carresortmatrix(r,c-k)~=0)
                            c_front=c-k;
                            break;
                        end
                    end
                        autofront=...      %found the next car in front
                            carresortmatrix(r_front,c_front); 
                                            
                    if((cadpara(cadtype... %This is the 1st criterion
                            (auto)).v0)>(x(time-1,autofront)-x(time-1,auto))) 
                        crit1=true;
                    else
                        crit1=false;
                    end                       
                
                    %2. criterion
                    if(v(time-1,autofront)... %This is the 2nd criterion
                            <0.9*(cadpara(cadtype(auto)).v0)) 
                        crit2=true;
                    else
                        crit2=false;
                    end  
                else
                    crit1=false;
                    crit2=false;
                    autofront=[];
                end
               
                
                %3. criterion
                %Who is in front on left lane?
                r_frontleft=r+1;  
                if(c>1&&sum(...            %Someone in front on the left lane?
                        carresortmatrix(r_frontleft,1:c-1))~=0) 
                    for k=1:numberofcars
                        if(carresortmatrix(r_frontleft,c-k)~=0)
                            c_frontleft=c-k;
                            break;
                        end
                    end
                    
                    autofrontleft=...      %Found next car in front on left lane
                        carresortmatrix(r_frontleft,c_frontleft); 
                    
                    if(~isempty(autofront))
                        if(x(time-1,...    %This is the 3rd criterion
                                autofrontleft)>=x(time-1,autofront)) 
                            crit3=true;
                        else
                            crit3=false;
                        end
                    else
                        if(x(time-1,...    %Alternative criterion
                                autofrontleft)-x(time-1,auto)>4*...
                                (cadpara(cadtype(auto)).v0))  
                            crit3=true;
                        else
                            crit3=false;
                        end
                    end
                        
                else
                    crit3=true;
                end
                
                                  
                %4. criterion
                %Who is in the back on left lane?
                r_rearleft=r+1; 
                if(sum...              %Someone in the rear on the left lane?
                        (carresortmatrix(r_rearleft,c+1:end))~=0) 
                    for k=1:numberofcars
                        if(carresortmatrix(r_rearleft,c+k)~=0)
                            c_rearleft=c+k;
                        break;
                        end
                    end
                        
                    autorearleft=carresortmatrix(r_rearleft,c_rearleft);
                    
                    if(x(time-1,auto)-...        %This is the 5th criterion
                            x(time-1,autorearleft)>4*...
                            (cadpara(cadtype(autorearleft)).v0)) 
                        crit4=true;
                    else
                        crit4=false;
                    end
                else                    
                crit4=true;
                end
        
                %Car changes lane if all criteria are fulfilles
                if(crit1&&crit2&&crit3&&crit4)
                   carresortmatrixintermediate(r,c)=0;
                   carresortmatrixintermediate(r+1,c)=auto;
                end
                
        
            %test, if car should move to right line in this time step, if it is
            %on left line
            case 2
            
                %1. criterion
                r_frontright=r-1;
                if(c>1&&sum...         %Someone in front on the right lane?
                        (carresortmatrix(r_frontright,1:c-1))~=0) 
                    for k=1:numberofcars
                        if(carresortmatrix(r_frontright,c-k)~=0)
                            c_frontright=c-k;
                        break;
                        end
                    end
                    
                    autofrontright=...%Found next car in front on the right lane
                        carresortmatrix(r_frontright,c_frontright); 
                                        
                    if((x(time-1,autofrontright)... %This is the 1st criterion
                            -x(time-1,auto))>4*cadpara(cadtype(auto)).v0) 
                        crit1=true;
                    else
                        crit1=false;
                    end                             
                else
                    crit1=true;                    
                end
                                   
                %2. criterion
                r_rearright=r-1;
                if(sum(...              %Someone in the back on the right lane?
                        carresortmatrix(r_rearright,c+1:end))~=0) 
                    for k=1:numberofcars
                        if(carresortmatrix(r_rearright,c+k)~=0)
                            c_rearright=c+k;
                            break;
                        end
                    end
                    
                    autorearright=...   %found car in the rear on right lane
                        carresortmatrix(r_rearright,c_rearright); 
                               
                    if(x(time-1,auto)-x(time-1,autorearright)>...
                            4*cadpara(cadtype(autorearright)).v0)
                        crit2=true;
                    else
                        crit2=false;
                    end   
                else
                    crit2=true;
                end
                  
                %Car changes lane if all criteria are fulfilles
                if(crit1&&crit2)
                   carresortmatrixintermediate(r,c)=0;
                   carresortmatrixintermediate(r-1,c)=auto;
                end
            
            end        
    end
    carresortmatrix=carresortmatrixintermediate;    
end