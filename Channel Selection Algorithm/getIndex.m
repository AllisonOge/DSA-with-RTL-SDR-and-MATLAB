function index =  getIndex(value, arr)
%GETINDEX function
%   
    for index = 1:length(arr)
       if arr(index) == value
           break;
       end
    end
end

