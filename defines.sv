`define Ceil(ParamName, Expression) \
 parameter ParamName``_F = Expression;\
 parameter integer ParamName``_R = ParamName``_F;\
 parameter integer ParamName = (ParamName``_R == ParamName``_F || ParamName``_R > ParamName``_F) ? ParamName``_R : (ParamName``_R + 1);