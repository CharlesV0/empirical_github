function value=flexsort(vec,N)
A=linspace(1,100,N+1);
B=prctile(vec,A);
value=ones(length(vec),1);
for i =1:N
    value((B(i)<=vec)&(vec<=B(i+1)))=i;
end
end