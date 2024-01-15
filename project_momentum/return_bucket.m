function value = return_bucket(return_rate, rr20, rr40 , rr60, rr80)

if isnan(return_rate)
    value=blanks(1);
elseif return_rate<=rr20 && lem>=0
    value='VL';
elseif return_rate<=rr40
    value='L';
elseif return_rate<=rr60
    value='M';
elseif return_rate<=rr80
    value='H';
elseif return_rate>rr80
    value='VH';
else
    value=blanks(1);
end
