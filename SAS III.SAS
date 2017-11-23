/* Assignment3.sas */
/* Names: Joshua Song
Hassasn Ahmed
Sanchit Thakrar*/
proc format;
  value sex 
    1=Female 
    2=Male
     ;
  value race 
    1=Asian 
    2=Black 
    3=Caucasian 
    4=Other
     ;
run;

/*
Create a SAS data set called STUDY as follows:
1 - Read in the data in suppTRP-1062.txt.
Create the variable Site with length of 1.
Create the variable Pt as character of length 2.
All other variables should be created as numeric with the default length of 8.
*/

data study;
  /* on infile statement need (1) dsd or dlm=',' (2) missover or truncover */
  infile '/courses/dc4508e5ba27fe300/c_629/suppTRP-1062.txt' dlm=',' missover;

  /* Method 1: use informat and input statements */
  /* informat can be either mmddyy8. or mmddyy10. */
  informat Site $1. Pt $2. Dosedate mmddyy10.;
  input Site Pt Sex Race Dosedate Height Weight Result1 Result2 Result3;

  /* Method 2: use an input statement - any of these will work */
  * input Site:$1. Pt:$2. Sex:8. Race:8. Dosedate:mmddyy10. Height:8. Weight:8. Result1-Result3:8.;
  * input Site:$1. Pt:$2. Sex Race Dosedate:mmddyy10. Height Weight Result1-Result3;

/*
2 - Using if-then statements, create a new variable called Doselot (Dose Lot).
If the dose date is in 1997, then the dose lot is S0576. 
If the dose date is in 1998 and on or before 10 January 1998, then the dose lot is P1122. 
If the dose date is after 10 January 1998, then the dose lot is P0526. 
*/
  
  if '01JAN1997'd <= dosedate <= '31DEC1997'd then doselot='S0576';
  else if '31DEC1997'd < dosedate <= '10JAN1998'd then doselot='P1122';
  else if dosedate > '10JAN1998'd then doselot='P0526';

/*
3 - Using two do loops, create two new variables called prot_amend (Protocol Amendment) and 
Limit (Lower Limit of Detection).
If the dose lot is P0526 then the Protocol Amendment is B.
For all other dose lots, the Protocol Amendment is A.
The Lower Limit of Detection is 0.03 for female patients who received dose lot P0526.
The Lower Limit of Detection is 0.02 for male patients who received dose lot P0526.
The Lower Limit of Detection is 0.02 for patients who received dose lots S0576 and P1122.
*/

  if doselot='P0526' then do;
    prot_amend='B';
    if sex=1 then limit=0.03;
    else if sex=2 then limit=0.02;
  end;
  else if doselot = 'S0576' or doselot='P1122' then do;
    prot_amend='A';
    limit=0.02;
  end;

/*
4 - Using a select statement, use the variable Site to create a new variable called site_name (Site Name) which contains the name of the Study Site.
The Site values and associated names are:
J=Aurora Health Associates, Q=Omaha Medical Center, R=Sherwin Heights Healthcare
*/

length site_name $30;
  select(site);
    when ('J') site_name='Aurora Health Associates';
    when ('Q') site_name='Omaha Medical Center';
    when ('R') site_name='Sherwin Heights Healthcare';
    otherwise;
  end;

/* 
5 - Create and apply formats to the Sex and Race variables.
The decodes for sex are 1=Female, 2=Male
The decodes for race are 1=Asian, 2=Black, 3=Caucasian, 4=Other
*/

  format sex sex. race race. dosedate date.;

/*
6 - Using the descriptive information provided previously, create labels for these variables:
 
Site, Pt, Dosedate, Doselot, prot_amend, Limit, site_name
*/

  label site='Study Site' 
        pt='Patient'
        dosedate='Dose Date'
        doselot='Dose Lot'
        prot_amend='Protocol Amendment'
        limit='Lower Limit of Detection'
        site_name='Site Name';
run;

/*
7 -  DEMOG1062 is a permanent SAS data set located on the server in the directory /courses/u_ucsd.edu1/i_536036/c_629/saslib
Create a new data set called PAT_INFO by merging STUDY and DEMOG1062 by their two common variables. 
Also add items in 8-12 to PAT_INFO. 
Note: Your code should create a single data set called PAT_INFO, which contains the merge code and items 8-12. 
PAT_INFO should contain 15 observations and 21 variables.
*/
libname class "/courses/dc4508e5ba27fe300/c_629/saslib" access=readonly;

proc sort data=study;
  by site pt;
run; 

proc sort data=class.demog1062 out=demog;
  by site pt;
run;

data pat_info;
  merge study demog;
  by site pt;

/*
8 - Create a variable called pt_id by concatenating Site and Pt and adding a hyphen between the two variables. 
An example value of pt_id should look like: Z-99. Label the variable 'Site-Patient'.
*/
/* Comments: cats function can also be replaced with cat or catx('-',site,pt) */

  if not missing(site) and not missing(pt) then 
  pt_id=cats(site,'-',pt); 

/*  
9 - Use 1 statement to create a variable dose_qtr by concatenating the letter 'Q' to the number which corresponds to the quarter of the year in which the dose date falls. 
Values of dose_qtr should look like Q1, Q2, etc. 
*/

  if not missing(dosedate) then dose_qtr=cats('Q',qtr(dosedate));

/*
10 - Create a variable mean_result which is the mean of result1, result2, and result3. 
The mean should be calculated using all non-missing values of the three variables. 
Format mean_result to 2 decimal places.
*/

  if nmiss(of result1-result3) < 3 then mean_result=mean(of result1-result3);

/*
11 - Create a variable BMI which is calculated as:  Weight ÷ (Height)2 x 703
Format BMI to 1 decimal place.
*/

  if nmiss(weight,height)=0 and height ne 0 then 
  BMI=weight*703/(height**2);

/*
12 - Create a variable est_end which is the Estimated Termination Date for the patient. 
Use an assignment statement. Do not use a function.
If Protocol Amendment is A then est_end is 120 days after Dose Date.
If Protocol Amendment is B then est_end is 90 days after Dose Date.
Apply a format so that the est_end is displayed as mm/dd/yyyy.
Label the variable 'Estimated Termination Date'.
*/
  /* option 1: use if-then statements */
  if prot_amend='A' then est_end=dosedate+120;
  else if prot_amend='B' then est_end=dosedate+90;
  /* option 2: use select statement */
  select(prot_amend);
    when ('A') est_end=dosedate+120;
    when ('B') est_end=dosedate+90;
    otherwise;
  end;

  label pt_id='Site-Patient' 
        est_end='Estimated Termination Date';

  format mean_result 8.2 bmi 4.1 est_end mmddyy10.;
run;

/*
13 - Using the data set PAT_INFO, generate the following output using PROC PRINT:
*/
/* comment: There are two ways to prevent the datetime and page numbers at the top of the output window 
   from interfering with your output.
   (1) use options nodate nonumber; - this turns off these options
   (2) use title2 or title3 to move your output below the datetime and page numbers */

options nodate nonumber;
title3 Listing of Baseline Patient Information for Patients Having Weight > 250 ;
proc print data=pat_info double split='*';
  where weight > 250; 
  by site site_name;
  id site site_name;
  var pt age sex race height weight dosedate doselot;
  label age='Age' 
        dosedate='Date of*First Dose'
		doselot='Dose Lot Number';
  format dosedate mmddyy.;
run;

/* turn off title */
title;

/*
14 - Use the data set PAT_INFO and one PROC MEANS to do the following:
Create output stratified by Sex for the variables Result1, Result2, Result3, Height, and Weight. 
The display should show the number of non-missing values, mean, standard error, minimum value, maximum value and be formatted to one decimal point.
Also create an output data set that contains the median value of Weight stratified by Sex. 
Name the variable that contains the median value of weight med_wt. 
Your output data set should contain two observations and two variables, Sex and med_wt.
*/
/*
15 - Combine the data sets PAT_INFO and the output data set from item 14 by the variable Sex and create a new variable called wt_cat as follows:
If the patient's weight is less than or equal to the median weight for all patients of that sex, then wt_cat=1.
If the patient's weight is more than the median weight for all patients of that sex, then wt_cat=2.
Label this variable 'Median Weight Category'.
Create and apply a descriptive format to wt_cat: 
For wt_cat=1, the descriptor is '<= Median Weight'
For wt_cat=2, the descriptor is '> Median Weight'
Hint: Your new data set should contain 15 observations.
*/
/* There are 2 solutions to 14 & 15 */

/* Option 1 - use a CLASS statement */

/* Item 14 */

proc means data=pat_info n mean stderr min max maxdec=1 nway;
  class sex;
  var result1-result3 height weight; 
  output out=med_wt_class(drop = _:) median(weight)=med_wt;
run;

/* Note: If the variables on the var statement are re-ordered, the output statement can be simplified as follows:
proc means data=pat_info n mean stderr min max maxdec=1 nway;
  class sex;
  var weight result1-result3 height; 
  output out=med_wt_class(drop = _:) median=med_wt;
run;
*/

/* Item 15 */

proc format;
  value wt_cat
    1 = '<= Median Weight'
	2 = '> Median Weight'
	  ;
run;

proc sort data=pat_info;
  by sex;
run;

data pat_info_class;
  merge pat_info med_wt_class;
  by sex;
  if . < weight <= med_wt then wt_cat=1;
  else if weight > med_wt then wt_cat=2;
  format wt_cat wt_cat.;
  label wt_cat='Median Weight Category';
run;

/* Option 2 - use a BY statement */

/* Item 14 */

proc sort data=pat_info;
  by sex;
run;

proc means data=pat_info n mean stderr min max maxdec=1;
  by sex;
  var result1-result3 height weight; 
  output out=med_wt_by(drop = _:) median(weight)=med_wt;
run;

/* Item 15 */

proc format;
  value wt_cat
    1 = '<= Median Weight'
	2 = '> Median Weight'
	  ;
 run;

data pat_info_by;
  merge pat_info med_wt_by;
  by sex;
  if . < weight <= med_wt then wt_cat=1;
  else if weight > med_wt then wt_cat=2;
  format wt_cat wt_cat.;
  label wt_cat='Median Weight Category';
run;

/*                                                                                        
16 - Using your data set from Item 15 and one PROC FREQ to do the following:
Show the frequency distributions of (1) Dose Lot Numbers and (2) Median Weight Category. Exclude missing values from the frequency distributions.
Generate a two-way table for Race by Weight. Include missing values in the frequency distribution. 
Use formats to group Race and Weight variables as follows:
If Race is Caucasian then display the race as 'White'.
If Race is anything else (including missing) then display the race as 'Other'.
Group Weight into the following 4 categories: < 200, 200 to < 300, >= 300, Missing 
*/

proc format;
  value races
    other ='Other' 3='White';
  value wt
    .        = 'Missing'
    low-<200 = '<200'
    200-<300 = '200-<300'
    300-high = '>=300'; 
run;

proc freq data=pat_info_by;
  tables doselot wt_cat;
  tables race*weight / missing;
  format race races. weight wt.;
run;

/*
17 - Using your data set from Item 15 and one PROC UNIVARIATE to do the following:
Generate summary statistics for Height stratified by Median Weight Category. 
Identify the extreme values using the Site-Patient identifier variable.
*/
/* Note: Either a BY statement or a CLASS statement can be used. 
   However, using CLASS eliminates the need to sort the data. */

proc univariate data=pat_info_by;
 class wt_cat;
 var height; 
 id pt_id;
run;

/*Prewritten Code for Part XVIII*/
/* No errors or warnings yet but it is a good starting point */

title 'Summary of Mean Analyte Results by Weight Category and Sex';
proc report data = pat_info_by nowindows headline;
column wt_cat sex(site_name,(result1 result2 result3));  
define wt_cat / group left 'Weight Category';
define sex	/ group left;

define site_name / across '-Site-';
define result1 / analysis mean 'Mean Result1' width = 6 format = 4.3;
define result2 / analysis mean 'Mean Result2' width = 6 format = 4.3;
define result3 / analysis mean 'Mean Result3' width = 6 format = 4.3;
break after wt_cat /skip;

run;
/* Prewritten Code for Part XIX */
title "Listing of Baseline Patient Characteristics";
proc report;
column pt_id dosedate age sex race wt_cat BMI cat_BMI result1 result2 absChange;
format dosedate mmddyy.;
define result1 /display 'Analyte Result 1';
define result2 / display'Analyte Result 2';
define age / 'Age';
define wt_cat / "Weight Category";
define absChange / computed 'Absolute Change' width=8 format=4.1;
	compute absChange;
	absChange = result2 - result1; 
	endcomp;
define BMI / display'BMI';
define cat_BMI /'BMI Category';
compute cat_BMI/ character length =11;
if BMI > 18.5 then cat_BMI = 'UNDERWEIGHT';
	else if BMI > 18.5 and BMI < 30 then cat_BMI = 'OVERWEIGHT';
	else if BMI > 18.5 and BMI < 25 then cat_BMI = 'NORMAL';
	else if BMI > 30 then cat_BMI = 'OBESE';
	endcomp;
run;
