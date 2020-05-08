Libname Temp "X:\BirthFileRecords\Geocoded_Birthfile\Temp";


%Macro FixBirths(Year=,Var=);



Proc Sql;
	Create Table Work.CensusTracts as Select Tracts_ID from &Var.  order by 1;
quit;


Proc Import out=Work.BirthCount&Year.
	datafile="X:\BirthFileRecords\Geocoded_Birthfile\Temp\CensusBirthCounts.xlsx"
	DBMS=Excel
	replace;
	Sheet="BirthCount&Year.";
run;


Proc Sql;
	Create Table Work.BirthNull&Year. as Select 0 as BirthCount,put(&Year.,z4.) as DOBYear,Tracts_ID as CensusTracts
	from Work.CensusTracts where Tracts_ID not in (Select CensusTracts from Work.BirthCount&Year.) order by 2;
quit;


Proc Sql;
	Insert into Work.BirthCount&Year. Select * from Work.BirthNull&Year.;
quit;


Proc Export data=Work.BirthCount&Year.
	outfile="X:\BirthFileRecords\Geocoded_Birthfile\Temp\BirthStateRevisedCensusCount.xlsx"
	DBMS=Excel
	replace;
	Sheet="BirthCount&Year.";
run;

%Mend FixBirths;

