%% Rebuild new carresortmatrix
%After one timestep cars might have change order due to outdistancing 
function carresortmatrix=changeorder(carresortmatrix,x,ionc,time)
xintermediate=[];
    for c=1:ionc
        if(carresortmatrix(1,c)~=0)
            xintermediate=[xintermediate,x(time,carresortmatrix(1,c))];
        elseif(carresortmatrix(2,c)~=0)
            xintermediate=[xintermediate,x(time,carresortmatrix(2,c))];
        end
    end
    
   [~,order]=sort(xintermediate,'descend');
   carresortmatrix(:,1:ionc)=carresortmatrix(:,order);
end