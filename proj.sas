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



proc mi data=data out=dataImpute seed=17349087 nimpute=1;
class    host_response_time               ; 
fcs nbiter=1000 discrim( host_response_time /CLASSEFFECTS=exclude );

var 
    host_response_time
    host_response_rate host_acceptance_rate latitude longitude accommodates beds minimum_nights maximum_nights availability_365 
    number_of_reviews review_scores_rating reviews_per_month year
	;
run;
proc print data=dataimpute;
run;

data dataImpute;
set dataImpute;
drop host_response_time;
 run;


ods graphics on;
proc transreg data=dataImpute;
model BoxCox(price/lambda=-2 to 2 by .1) =  class(property_type);
run;
ods graphics off;

data data;
set dataImpute;
price_boxcox=log(price);
run;
ods graphics on;
 proc robustreg data =data method=m (SCALE=HUBER(D=2.5) WF=HUBER(c=1.345));  
model price_boxcox =host_response_rate host_acceptance_rate latitude longitude accommodates beds minimum_nights maximum_nights availability_365 
    number_of_reviews review_scores_rating reviews_per_month year;
output out=stat weight=weights;
run;

proc means data=stat;
var weights;
run;
data weight;
set stat;
keep weights;
run;

data weight;
set weight;
if weights=1 then poid=.;
else poid=1;
run;

proc means data=weight n nmiss;
var poid;
run;
proc glm data=stat plots=all;
class  host_is_superhost host_has_profile_pic  neighbourhood_cleansed property_type
    room_type bathrooms_text instant_bookable;
model price_boxcox= host_is_superhost host_has_profile_pic  neighbourhood_cleansed property_type
    room_type bathrooms_text instant_bookable  host_response_rate host_acceptance_rate latitude longitude accommodates beds minimum_nights maximum_nights availability_365 
    number_of_reviews review_scores_rating reviews_per_month year;
    run;
ods graphics on /LABELMAX=10100 ;
proc glmselect data = stat plots=all;
class  host_is_superhost host_has_profile_pic  neighbourhood_cleansed property_type
     bathrooms_text ;
model price_boxcox= host_is_superhost host_has_profile_pic  neighbourhood_cleansed property_type
     bathrooms_text    longitude accommodates  minimum_nights  availability_365 
    number_of_reviews   /
selection=stepwise(select=bic )stats=all stop=8;
weight weights;
run;

/* neighbourhood_cleansed property_type bathrooms_text longitude accommodates minimum_nights availability_365*/






proc glmselect data = stat plots=all;
class  host_is_superhost host_has_profile_pic  neighbourhood_cleansed property_type
     bathrooms_text ;
model price_boxcox= host_is_superhost host_has_profile_pic  neighbourhood_cleansed property_type
     bathrooms_text    longitude accommodates  minimum_nights  availability_365 
    number_of_reviews   /
    selection=stepwise(choose=cv ) CVMETHOD=RANDOM(5) stats=all stop=8 hierarchy=single;;
weight weights;
run;

/*neighbourhood_cleans room_type longitude accommodates minimum_nights availability_365 property_type*/

proc glmselect data = stat plots=all;
class  host_is_superhost host_has_profile_pic  neighbourhood_cleansed property_type
     bathrooms_text ;
model price_boxcox= host_is_superhost host_has_profile_pic  neighbourhood_cleansed property_type
     bathrooms_text    longitude accommodates  minimum_nights  availability_365 
    number_of_reviews   /
    selection=lasso(choose=bic stop=L1 L1=0.1 L1choice=value) stats=all stop=8;
weight weights;
run;

/* neighbourhood_cleansed property_type minimum_nights bathrooms_text longitude accommodates availability_365*/
proc glmselect data = stat plots=all;
class  neighbourhood_cleansed  property_type;
model price_boxcox=neighbourhood_cleansed property_type  longitude accommodates minimum_nights availability_365/
    selection=stepwise(choose=cv ) CVMETHOD=RANDOM(5) stats=all stop=8 hierarchy=single;;
weight weights;
run;

/*pour la graphic de EQM*/




ods graphics on;
proc glmselect data = stat plots=all;
class  neighbourhood_cleansed  property_type;
model price_boxcox=neighbourhood_cleansed |property_type | longitude | accommodates | minimum_nights | availability_365@2
/ selection=stepwise(choose=cv ) CVMETHOD=RANDOM(5) stats=all stop=11 hierarchy=single;
weight weights;
run;




ods graphics on;
proc glm data = stat plots=all;
class neighbourhood_cleansed property_type ;
model price_boxcox=neighbourhood_cleansed property_type  longitude accommodates minimum_nights availability_365 /e ss1 ss3 solution;
lsmeans neighbourhood_cleansed property_type / stderr pdiff;
output out=verif2 r=residus2 p=predite;
weight weights;
run; quit;


ods graphics on;
proc glm data = stat plots=all;
class neighbourhood_cleansed property_type ;
model price =neighbourhood_cleansed property_type  longitude accommodates minimum_nights availability_365/e ss1 ss3 solution;
lsmeans neighbourhood_cleansed property_type /stderr pdiff;
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

proc reg data=stat;
model price_boxcox = accommodates  minimum_nights reviews_per_month  availability_365 / vif tol collin collinoint;
weight weights;
run;quit;


