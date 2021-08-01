/*proc import datafile=‪'C:\Users\54133\Desktop\listings.csv' out=data dbms=csv replace;*/


%web_drop_table(WORK.IMPORT);


FILENAME REFFILE '/home/u58309233/proj/donnees.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.IMPORT;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.IMPORT; RUN;


%web_open_table(WORK.IMPORT);
proc print data=import;
run;

data data;
set import;
   new = input(host_acceptance_rate	, 8.);
   drop host_acceptance_rate	;
   rename new=host_acceptance_rate	;
   new1 = input(host_response_rate	, 8.);
   drop host_response_rate	;
   rename new1=host_response_rate	;
drop host_since VAR1 ;
run;



data data;
set data;
if host_response_time="N/A" then host_response_time= .;
if missing(price) then delete;
run;
proc means data=data n nmiss;
var
    
    host_response_rate host_acceptance_rate latitude longitude accommodates beds minimum_nights maximum_nights availability_365 
    number_of_reviews review_scores_rating reviews_per_month year;
run;

/*proc mi data=data out=dataImpute seed=17349087 nimpute=1;
class id                  host_id          host_response_time            
 host_is_superhost      host_has_profile_pic   host_identity_verified neighbourhood_cleansed                             
property_type          room_type                        bathrooms_text                            
                   instant_bookable                    ; 
fcs nbiter=1000 discrim(id                  host_id          host_response_time            
 host_is_superhost      host_has_profile_pic   host_identity_verified neighbourhood_cleansed                             
property_type          room_type                        bathrooms_text                            
                   instant_bookable            /CLASSEFFECTS=include );

var id host_id host_response_time host_is_superhost host_has_profile_pic host_identity_verified neighbourhood_cleansed property_type
    room_type bathrooms_text instant_bookable
    
    host_response_rate host_acceptance_rate latitude longitude accommodates beds minimum_nights maximum_nights availability_365 
    number_of_reviews review_scores_rating reviews_per_month year
	;
run;
proc print data=dataimpute;
run;*/

data data;
set data;
if missing(host_response_rate) or missing(host_acceptance_rate) or missing(beds) or missing(review_scores_rating) or missing(reviews_per_month)
 then delete;
 run;


ods graphics on;
proc transreg data=data;
model BoxCox(price/lambda=-2 to 2 by .1) =  class(property_type);
run;
ods graphics off;

data data;
set data;
price_boxcox=log(price);
run;

 proc robustreg data =data method=m (SCALE=HUBER(D=2.5) WF=HUBER(c=1.345));  
model price_boxcox =host_response_rate host_acceptance_rate latitude longitude accommodates beds minimum_nights maximum_nights availability_365 
    number_of_reviews review_scores_rating reviews_per_month year;
output out=stat weight=weights;
run;



ods graphics on /LABELMAX=10100 ;
proc glmselect data = stat plots=all;
class host_response_time host_is_superhost host_has_profile_pic host_identity_verified neighbourhood_cleansed property_type
    room_type bathrooms_text instant_bookable;
model price_boxcox=host_response_time host_is_superhost host_has_profile_pic host_identity_verified neighbourhood_cleansed property_type
    room_type bathrooms_text instant_bookable  host_response_rate host_acceptance_rate latitude longitude accommodates beds minimum_nights maximum_nights availability_365 
    number_of_reviews review_scores_rating reviews_per_month year/
selection=stepwise(select=bic )stats=all stop=8;
weight weights;
run;

/* accommodates neighbourhood_cleans property_type minimum_nights reviews_per_month host_is_superhost availability_365*/






proc glmselect data = stat plots=all;
class  host_response_time host_is_superhost host_has_profile_pic host_identity_verified neighbourhood_cleansed property_type
    room_type bathrooms_text instant_bookable;
model price_boxcox= host_response_time host_is_superhost host_has_profile_pic host_identity_verified neighbourhood_cleansed property_type
    room_type bathrooms_text instant_bookable  host_response_rate host_acceptance_rate latitude longitude accommodates beds minimum_nights maximum_nights availability_365 
    number_of_reviews review_scores_rating reviews_per_month year/
    selection=forward(select=ADJRSQ ) stats=all stop=8;
weight weights;
run;

/* meme*/

proc glmselect data = stat plots=all;
class host_response_time host_is_superhost host_has_profile_pic host_identity_verified neighbourhood_cleansed property_type
    room_type bathrooms_text instant_bookable;
model price_boxcox=host_response_time host_is_superhost host_has_profile_pic host_identity_verified neighbourhood_cleansed property_type
    room_type bathrooms_text instant_bookable  host_response_rate host_acceptance_rate latitude longitude accommodates beds minimum_nights maximum_nights availability_365 
    number_of_reviews review_scores_rating reviews_per_month year/
    selection=lasso(choose=bic stop=L1 L1=0.1 L1choice=value) stats=all stop=8;
weight weights;
run;




ods graphics on;
proc glm data = stat plots=all;
class neighbourhood_cleansed property_type host_is_superhost;
model price_boxcox=accommodates neighbourhood_cleansed property_type minimum_nights reviews_per_month host_is_superhost availability_365/e ss1 ss3 solution;
lsmeans neighbourhood_cleansed property_type host_is_superhost/stderr pdiff;
output out=verif2 r=residus2 p=predite;
weight weights;
run; quit;


ods graphics on;
proc glm data = stat plots=all;
class neighbourhood_cleansed property_type host_is_superhost;
model price =accommodates neighbourhood_cleansed property_type minimum_nights reviews_per_month host_is_superhost availability_365/e ss1 ss3 solution;
lsmeans neighbourhood_cleansed property_type host_is_superhost/stderr pdiff;
output out=verif1 r=residus1 p=predite;
weight weights;
run;




data data2;
set verif1;
residus = log(weights)*residus1;
predstart = log(weights)*predite1;
run;

data data3;
set data2;
trans=0;
keep  residus trans;
run;

data data4;
set verif2;
trans=1;
residus=log(weights)*residus2;
keep residus trans;
run;
data data5;
set data3 data4;
run;


ods graphics on;
proc sgpanel data=data5 noautolegend ;
  title "residus normal et residus avec poids";
  panelby trans;
  histogram residus ;
  density residus;
run;
title;
