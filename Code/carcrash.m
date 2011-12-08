%Test if cars have crahsed and calculate distances
function s=carcrash(time,ionc,caronroad,carresortmatrix,x)
s=zeros(1,ionc);    
for auto=1:ionc
        if(caronroad(auto)==1)   
            [r,c]=find(carresortmatrix==auto);
            frontcar=[];             
        
            for k=1:c-1 %Iterate over cars in front of actual car on the same lane
                if(isempty(frontcar)&&carresortmatrix(r,c-k)~=0&&...
                        caronroad(carresortmatrix(r,c-k))~=0)
                    frontcar=carresortmatrix(r,c-k); %Found car in front
                    break;
                end
            end
            
            %If order of cars on the same lane has changed in this time
            %step (car drove through another car) one of the two asserts 
            %will yield an error, stating a car crash.
            assert(~isempty(frontcar),'Car crash!'); 
            s(auto)=x(time,frontcar)-x(time,auto); %determine real distances
            assert(s(auto)>=0,['Car crash! Car ',num2str(auto),' and car ',...
                num2str(frontcar),' have crashed.']);
        end
    end
end