Libname Test '/data/wta/Lamar_Projects/WindChillEnergy/Data';




%Macro WIND(Yr1=,Yr2=,Mths1=,Mths2=);
%Do Year = &Yr1. %to &Yr2.;
	Proc Sql;
		Create Table Work.WndChillMetrics_&Year. (StationID char(6), ObservationDate char(10),STATION_CODE char(10), Y_Coord num, X_Coord num, Month char(2), Year char(4),  MaxWndChill num,  MinWndChill num, DlyWndChillWtts num,DlyChillWttsAvg num);
	quit;

	%Do i= &Mths1. %to &Mths2.;
	%Let Month=%sysfunc(putN(&i.,Z2.));
	
		%IF &i. = 1 or &i.=3 or &i. = 5 or &i.=7 or &i. = 8 or &i.=10 or &i. = 12   %then %do;
		PROC SQL;
     		CONNECT TO odbc (dsn="ucc-archv-d3-ro" user="AES_DataReader" password="A3S_DataR3ad3r!");
   			CREATE TABLE Work.UHDBHourly&Month.&Year. AS SELECT * from connection to odbc
   			(execute[proc_getAESHistUCC_DateRange] "&Month./01/&Year.", "&Month./31/&Year.");
   			DISCONNECT FROM odbc;
		QUIT;%end;
    
	
		%IF &i. = 4 or &i.=6 or &i. = 9 or &i.=11 %then %do;
		PROC SQL;
     		CONNECT TO odbc (dsn="ucc-archv-d3-ro" user="AES_DataReader" password="A3S_DataR3ad3r!");
   			CREATE TABLE Work.UHDBHourly&Month.&Year. AS SELECT * from connection to odbc
   			(execute[proc_getAESHistUCC_DateRange] "&Month./01/&Year.", "&Month./30/&Year.");
   			DISCONNECT FROM odbc;
		QUIT;%end;
	
		%IF &i. = 2 and (&Year.=2012 or &Year.=2016) %then %do;
		PROC SQL;
     		CONNECT TO odbc (dsn="ucc-archv-d3-ro" user="AES_DataReader" password="A3S_DataR3ad3r!");
   			CREATE TABLE Work.UHDBHourly&Month.&Year. AS SELECT * from connection to odbc
   			(execute[proc_getAESHistUCC_DateRange] "&Month./01/&Year.", "&Month./29/&Year.");
   			DISCONNECT FROM odbc;
		QUIT;%end;
	   
	   
		%IF &i. = 2 and (&Year. ^=2012 or &Year. ^=2016) %then %do;
		PROC SQL;
	     	CONNECT TO odbc (dsn="ucc-archv-d3-ro" user="AES_DataReader" password="A3S_DataR3ad3r!");
	   		CREATE TABLE Work.UHDBHourly&Month.&Year. AS SELECT * from connection to odbc
	   		(execute[proc_getAESHistUCC_DateRange] "&Month./01/&Year.", "&Month./28/&Year.");
	   		DISCONNECT FROM odbc;
		QUIT;%end;   
		   
		   
		   
		Data Work.UHDB_Key;
			Length STATION_CODE $ 10.;
			Infile "/data/wta/Lamar_Projects/WindChillEnergy/Temp/UHDB_US_KEY.csv" dsd dlm=",";
			Input StationID STATION_CODE $ COUNTRY $ ISO_COUNTRY $ LATITUDE LONGITUDE ELEVATION STATE $;
			IF _N_ ^= 1;
		run;



		Proc Sql;
			Create table Work.UHDB_&Month._&Year as Select A.*,B.StationID,B.STATION_CODE, round(B.LATITUDE,.01) as Y_Coord, round(B.LONGITUDE,.01) as X_Coord from Work.UHDBHourly&Month.&Year. as A inner join Work.UHDB_Key as B on A.StationID=B.StationID;
		quit;

		Data Work.UHDBWndChill_&Month.&Year.;
			set Work.UHDB_&Month._&Year;
			Year=put(PartYear,Z4.);
			Month=put(MonthPart,z2.);
			StationID2=put(StationID,Z6.);
			Drop StationID;
			Rename StationID2=StationID;
			ObservationDate2=put(ObservationDate,$MMDDYY10.);
			Drop ObservationDate;
			Rename ObservationDate2=ObservationDate;
			If WIND_SPEED_Maximum GT 3 and TEMPERATURE_Maximum LE 50 then WindChillWttsA=(12.1452 + 11.6222 * sqrt(WIND_SPEED_Maximum*5280*(1/3.28)*(1/60)*(1/60))-1.16222*(WIND_SPEED_Maximum*5280*(1/3.28)*(1/60)*(1/60)))*(33-((TEMPERATURE_Maximum-32)*.556));
			ELSE WindChillWttsA=0;
			IF WIND_SPEED_Minimum GT 3 and TEMPERATURE_Maximum LE 50 then WindChillWttsB=(12.1452 + 11.6222 * sqrt(WIND_SPEED_Minimum *5280*(1/3.28)*(1/60)*(1/60))-1.16222*(WIND_SPEED_Minimum *5280*(1/3.28)*(1/60)*(1/60)))*(33-((TEMPERATURE_Maximum-32)*.556));
			ELSE WindChillWttsB=0;
			IF WIND_SPEED_Maximum GT 3 and TEMPERATURE_Minimum LE 50 then WindChillWttsC=(12.1452 + 11.6222 * sqrt(WIND_SPEED_Maximum*5280*(1/3.28)*(1/60)*(1/60))-1.16222*(WIND_SPEED_Maximum*5280*(1/3.28)*(1/60)*(1/60)))*(33-((TEMPERATURE_Minimum-32)*.556));
			ELSE WindChillWttsC=0;
			IF WIND_SPEED_Minimum GT 3 and TEMPERATURE_Minimum LE 50 then WindChillWttsD=(12.1452 + 11.6222 * sqrt(WIND_SPEED_Minimum *5280*(1/3.28)*(1/60)*(1/60))-1.16222*(WIND_SPEED_Minimum *5280*(1/3.28)*(1/60)*(1/60)))*(33-((TEMPERATURE_Minimum-32)*.556));
			Else WindChillWttsD=0;
			If WIND_SPEED_Average GT 3 and TEMPERATURE_Average LE 50 then HrlyChillWttsAvg=(12.1452 + 11.6222 * sqrt(WIND_SPEED_Average*5280*(1/3.28)*(1/60)*(1/60))-1.16222*(WIND_SPEED_Average*5280*(1/3.28)*(1/60)*(1/60)))*(33-((TEMPERATURE_Average-32)*.556));
			ELSE HrlyChillWttsAvg=0;
			Array WIND [*] WindChillWttsA WindChillWttsB WindChillWttsC WindChillWttsD;
			HrlyMAXWndChill=max(of WIND[*]);
			HrlyMINWndChill=min(of WIND[*]);
			HrlyWndChillWtts=(WindChillWttsA+WindChillWttsB+WindChillWttsC+WindChillWttsD)/4;
			Drop MonthPart PartYear;
		Run;
		
		Proc Sql;
			Create table Work.UHDBWndChill_&Month.&Year._II as Select StationID, ObservationDate, STATION_CODE, Y_Coord, X_Coord,Month, Year, Max(HrlyMAXWndChill) as MAXWndChill, Min(HrlyMINWndChill) as MINWndChill, Avg(HrlyWndChillWtts) as DlyWndChillWtts, Avg(HrlyChillWttsAvg) as DlyChillWttsAvg
				from Work.UHDBWndChill_&Month.&Year. group by StationID, ObservationDate, STATION_CODE, Y_Coord, X_Coord,Month, Year;
		quit;

		Proc Sql;
			Create Table Work.WndChillStats_&Month._&Year. as select A.*  from (Select StationID, ObservationDate,STATION_CODE,Y_Coord,X_Coord, Month, Year, MAXWndChill,MINWndChill, DlyWndChillWtts,DlyChillWttsAvg from Work.UHDBWndChill_&Month.&Year._II) as A;
		quit;
		
		Proc Append Base=Work.WndChillMetrics_&Year. Data=Work.WndChillStats_&Month._&Year. Force;
		run;
		
		Proc Datasets Library=Work;
			Delete WndChillStats_&Month._&Year. UHDBWndChill_&Month.&Year. UHDB_&Month._&Year UHDBHourly&Month.&Year.  UHDBWndChill_&Month.&Year._II;

	%END;

	Proc Export Data=Work.WndChillMetrics_&Year.
		DBMS=csv
		outfile="/data/wta/Lamar_Projects/WindChillEnergy/Data/WndChillMetricsDaily_&Year..csv"
		replace;
	run;

%END;
%MEND  WIND(Yr1=,Yr2=,Mths1=,Mths2=);




