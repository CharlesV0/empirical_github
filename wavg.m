function value = wavg(variable,weight)
%wavg Summary of this function goes here

value= sum(variable.*weight)/sum(weight);

end

