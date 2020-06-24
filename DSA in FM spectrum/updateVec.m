function [pdf_arr, result_arr_out] = updateVec( prob_OFF_OFF, prob_ON_OFF, result_arr, selectedChan, result)
%UPDATEVEC 
% update result vec
result_arr(selectedChan) = result;
result_arr_out = result_arr;
% update belief vector
pdf_arr = single.empty;
for i = 1:length(result_arr)
    if result_arr_out(i) == 0
        pdf_arr(i) = prob_OFF_OFF(i);
    else
        pdf_arr(i) = prob_ON_OFF(i);
    end    
end 
end