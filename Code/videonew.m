% Functions plots the cars, as they move on the road
function videonew(x,totalcarressortmatrix,totalcaronroad,timeidm,...
    timenumb,picturesequence,twolane)

h=figure;
set(h,'Outerposition',[1,550,1900,250]);

for time=(timeidm+2):timenumb  
    
  indices_of_cars_on_road=find(totalcaronroad{time}~=0);

  xvalues=zeros(1,length(indices_of_cars_on_road));
  yvalues=zeros(1,length(indices_of_cars_on_road));

for k=1:length(indices_of_cars_on_road)
    [row,colum]=find(totalcarressortmatrix{time}==indices_of_cars_on_road(k));
    if(row==1) 
        yvalues(k)=-1;
    elseif(row==2) 
        yvalues(k)=1;
    end
    
    if(~twolane)
        yvalues(k)=0;
    end
        
    xvalues(k)=x(time,indices_of_cars_on_road(k));
end

   plot(xvalues,yvalues,'r.');
   grid on;
   grid minor;
   
   if(twolane)
       title('Car behavior of HDM model on a two lane system','fontsize',14);
       ylim([-2,2]);
       ylabel('Right - left lane');
   else
       title('Car behavior of HDM model on a one lane system','fontsize',14);
       ylim([-1,1]);
       ylabel('Lane');
   end
   
   xlim([0,20000]);
   xlabel('Position [m]');
   pause(picturesequence);
   
end