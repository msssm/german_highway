%Function deactivates cars, if they have left the simulated roadpart (save
%computational ressources) This is done by setting the corresponding entry
%in caronroad to 0. Furthermore the first car on each lane that is still on
%the simulated roadpart is identified and labeld by setting the
%corresponding entry in the caronroad vector to 2 (instead of 1 as for all
%other cars)
function caronroad=deactivate(x,carresortmatrix,caronroad,time,L)
       
maxcolum=length(carresortmatrix(1,:));
      
newset=[true,true]; 
fc=[0,0];
           %rightlane
         for row=1:2
           for colum=maxcolum:-1:1
               if(carresortmatrix(row,colum)~=0)
                   if(x(time,carresortmatrix(row,colum))>=L)
                       caronroad(carresortmatrix(row,colum))=0;
                       newset(row)=false;
                   end
                   if(newset(row))
                   fc(row)=carresortmatrix(row,colum);
                   end
               end
           end
           if(fc(row)~=0)
           caronroad(fc(row))=2;
           end
         end           
end