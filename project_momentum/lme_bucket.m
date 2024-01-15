function value = lme_bucket(lme, lme20, lme40 ,lme60, lme80)

if isnan(lme)
    value=blanks(1);
elseif lme<=lme20 && lem>=0
    value='VL';
elseif lme<=lme40
    value='L';
elseif lme<=lme60
    value='M';
elseif lme<=lme80
    value='H';
elseif lme>lme80
    value='VH';
else
    value=blanks(1);
end

end