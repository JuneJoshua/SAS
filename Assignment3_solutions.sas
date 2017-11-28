/* Assignment3.sas */
/*
1-17 – Include your corrected code for Assignments 1 & 2.
*/

/* use missing='' so that missing numeric values are printed as a blank rather than a dot */
options missing='';

/*
Using the last data set that you created, generate the following output:
18 – Use PROC REPORT to create the summary table.
*/

title Summary of Mean Analyte Results by Weight Category and Sex;
proc report data=pat_info_by nowd headline;
  column wt_cat sex site_name,(result1-result3);
  define wt_cat / group 'Weight Category';
  define sex / group left;
  define site_name /across '-Site-';
  define result1 / analysis mean format=8.2 'Mean Result1';
  define result2 / analysis mean format=8.2 'Mean Result2';
  define result3 / analysis mean format=8.2 'Mean Result3';
  break after wt_cat / skip;
run;

/*
19 – Use PROC REPORT to create the listing.
*/

title Listing of Baseline Patient Characteristics;
proc report data=pat_info_by nowd headskip; /* Note: 'headskip' option can be removed if break statement is changed to 'break before' */
  column site pt_id dosedate age sex race wt_cat bmi bmicat result1 result2 abschg;
  define site / order noprint;
  define pt_id / order width=7 'Patient';
  define dosedate / display left format=mmddyy10.;
  define age / display 'Age' width=3;
  define sex /display left;
  define race / display left;
  define wt_cat / display 'Weight Category';
  define bmi / display;        
  define bmicat / computed 'BMI Category';
  define result1 / display 'Analyte Result 1';        
  define result2 / display ' Analyte Result 2';
  define abschg / computed 'Absolute Change';
  compute bmicat / character length=12;
    if . < bmi < 18.5 then bmicat='Underweight';
	else if 18.5 <= bmi < 25 then bmicat='Normal';
	else if 25 <= bmi < 30 then bmicat='Overweight';
	else if bmi >= 30 then bmicat='Obese';
  endcomp;
  compute abschg;
    if nmiss(result1,result2)=0 then 
    abschg=result2-result1;
  endcomp;
  break after site / skip;
run;
   
