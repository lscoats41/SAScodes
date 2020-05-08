Filename Metar'/data/wta/Lamar_Projects/Sas_Conversion/UHDB_CleaningData/Eighties/Temp/198*.csv';
Filename Key '/data/wta/Lamar_Projects/Sas_Conversion/UHDB_CleaningData/Eighties/Temp/METARKEY.txt';
Libname Test '/data/wta/Lamar_Projects/Sas_Conversion/UHDB_CleaningData/Eighties/Data';
%Include '/data/wta/Lamar_Projects/Sas_Conversion/UHDB_CleaningData/Eighties/Codes/SeasonFormat.txt';

Data Work.MetarEighties;
	Length DATE $ 11.;
	LENGTH HIGHTEMP 3.;
	LENGTH LOWTEMP 3.;
	LENGTH HEATINDEX 3.;
	LENGTH WINDCHILL 3.;
	LENGTH HIGHDEWPOINT 3.;
	LENGTH LOWDEWPOINT 3.;
	LENGTH HIGHHUMIDITY 3.;
	LENGTH LOWHUMIDITY 3.;
	LENGTH HIGHWETBULB 3.;
	LENGTH LOWWETBULB 3.;
	LENGTH MAXSUSTAINED 3.;
	LENGTH MINSUSTAINED 3.;
	LENGTH WINDGUST 3.;
	LENGTH AVGCLOUDCOVER 3.;
	LENGTH AVGCLOUDCEILING 8.;
	LENGTH AVGVIS 4.1;
	LENGTH MINOFSUN 4.;
	LENGTH WATEREQ 7.2;
	LENGTH PRECIPHRS 3.;
	LENGTH SNOWFALL 5.2;
	LENGTH SNOWONGROUND 5.2;
	LENGTH HIGHPRESSURE 6.2;
	LENGTH LOWPRESSURE 6.2;
	LENGTH ICEAMOUNT 5.2;
	Infile Metar dsd dlm=',';
	Input STATIONCODE $ TYPE $ DATE $ TIMEZONE $ HIGHTEMP LOWTEMP HEATINDEX WINDCHILL HIGHDEWPOINT LOWDEWPOINT HIGHHUMIDITY LOWHUMIDITY HIGHWETBULB LOWWETBULB SOILMOISTURE MAXSUSTAINED MINSUSTAINED WINDGUST AVGCLOUDCOVER AVGCLOUDCEILING AVGVIS MINOFSUN WATEREQ PRECIPHRS SNOWFALL SNOWONGROUND HIGHPRESSURE LOWPRESSURE ICEAMOUNT ;
	TEMPDATE=put(input(DATE,anydtdte21.),MMDDYY10.);
	DECDATE=put(input(DATE,anydtdte21.),DATE11.);
	MONTH=substr(TEMPDATE,1,2);
	DAY=substr(DECDATE,1,2);
	YEAR=substr(DECDATE,8,4);
	TAVGCLOUDCEILING=AVGCLOUDCEILING*100;
	WEEKNUM=put(WEEK(input(TEMPDATE,MMDDYY10.),'u'),Z2.);
	Drop DATE SOILMOISTURE TEMPDATE AVGCLOUDCEILING;
	Rename DECDATE=DATE;
	Rename TAVGCLOUDCEILING=AVGCLOUDCEILING;
	IF LOWTEMP GT 36 THEN DO; SNOWONGROUND=0;SNOWFALL=0;ICEAMOUNT=0;end;
run;

Data Work.MetarKey;
	LENGTH CLIMATE_ID $ 4.;
	infile Key dsd dlm=',' LRECL=93 TRUNCOVER;
	Input OBJECTID $ IN_FID $ NEAR_FID $ NEAR_DIST  NEAR_RANK $ METAR $ TLAT  TLON  ID $ GRIDCODE $ CLIMATE_ID $;
	TLAT=round(TLAT,.001);
	TLON=round(TLON,.001);
	LAT=put(TLAT,Z6.3);
	LON=put(TLON,Z9.3);
	DROP TLAT TLON;
run;



%Macro CheckYrs;

%DO YEARS= 1980 %To 1989;

Proc Sql;
	Create Table Work.MetarData&YEARS. as Select A.*,Catx('-',substr(DATE,1,2),substr(DATE,4,3),substr(DATE,8,4)) as EXDATE,B.METAR,B.LAT,B.LON,B.CLIMATE_ID from Work.MetarEighties as A inner join Work.MetarKey as B on A.STATIONCODE=B.METAR WHERE A.YEAR="&YEARS.";
quit;



Data Work.MetarMissing&YEARS.;
	set Work.Metardata&YEARS.;
	Array Var [*] HIGHTEMP LOWTEMP HEATINDEX WINDCHILL HIGHDEWPOINT LOWDEWPOINT HIGHHUMIDITY LOWHUMIDITY HIGHWETBULB LOWWETBULB MAXSUSTAINED MINSUSTAINED WINDGUST AVGCLOUDCOVER AVGCLOUDCEILING AVGVIS MINOFSUN WATEREQ PRECIPHRS SNOWFALL SNOWONGROUND HIGHPRESSURE LOWPRESSURE ICEAMOUNT ;
	Array Miss [*] MISS_HT MISS_LT MISS_HI MISS_WC MISS_HDP MISS_LDP MISS_HH MISS_LH MISS_HWB MISS_LWB MISS_MAXW MISS_MINW MISS_WG MISS_CCL MISS_CCE MISS_VIS MISS_SMIN MISS_H2O MISS_PH MISS_SF MISS_SG MISS_HP MISS_LP MISS_ICE;
	DO i = 1 to dim(Var);
		If Var[i]=. then Miss[i]=1;
		Else Miss[i]=0;
	end;
	Drop HIGHTEMP LOWTEMP HEATINDEX WINDCHILL HIGHDEWPOINT LOWDEWPOINT HIGHHUMIDITY LOWHUMIDITY HIGHWETBULB LOWWETBULB MAXSUSTAINED MINSUSTAINED WINDGUST AVGCLOUDCOVER AVGCLOUDCEILING AVGVIS MINOFSUN WATEREQ PRECIPHRS SNOWFALL SNOWONGROUND HIGHPRESSURE LOWPRESSURE ICEAMOUNT ;
run;


Proc Sql;
	Create Table Work.MetarMissAnal&YEARS. as Select STATIONCODE,Count(*) as STATIONUM,Sum(MISS_HT) AS HTSUM, Sum(MISS_HT)/COUNT(*) AS AVGHT, Sum(MISS_LT) AS LTSUM, Sum(MISS_LT)/COUNT(*) AS AVGLT ,Sum(MISS_HI) AS HISUM, Sum(MISS_HI)/COUNT(*) AS AVGHI,
	Sum(MISS_WC) AS WCSUM, Sum(MISS_WC)/COUNT(*) AS AVGWC, Sum(MISS_HDP) AS HDPSUM, Sum(MISS_HDP)/COUNT(*) AS AVGHDP, Sum(MISS_LDP) AS LDPSUM, Sum(MISS_LDP)/COUNT(*) AS AVGLDP, Sum(MISS_HH) AS HHSUM, Sum(MISS_LDP)/COUNT(*) AS AVGHH, 
	Sum(MISS_LH) AS LHSUM, Sum(MISS_LH)/COUNT(*) AS AVGLH, Sum(MISS_HWB) AS HWBSUM, Sum(MISS_HWB)/COUNT(*) AS AVGHWB, Sum(MISS_LWB) AS LWBSUM, Sum(MISS_LWB)/COUNT(*) AS AVGLWB, Sum(MISS_MAXW) AS MAXWSUM, Sum(MISS_MAXW)/COUNT(*) AS AVGMAXW,
	Sum(MISS_MINW) AS MINWSUM, Sum(MISS_MINW)/COUNT(*) AS AVGMINW, Sum(MISS_WG) AS WGSUM, Sum(MISS_WG)/COUNT(*) AS AVGWG,Sum(MISS_CCL) AS CCLSUM, Sum(MISS_CCL)/COUNT(*) AS AVGCCL,Sum(MISS_CCE) AS CCESUM, Sum(MISS_CCE)/COUNT(*) AS AVGCCE,
	Sum(MISS_VIS) AS VISSUM, Sum(MISS_VIS)/COUNT(*) AS AVGVIS, Sum(MISS_SMIN) AS SMINSUM, Sum(MISS_SMIN)/COUNT(*) AS AVGSMIN, Sum(MISS_H2O) AS H2OSUM, Sum(MISS_H2O)/COUNT(*) AS AVGH2O, Sum(MISS_PH) AS PHSUM, Sum(MISS_PH)/COUNT(*) AS AVGPH,
	Sum(MISS_SF) AS SFSUM, Sum(MISS_SF)/COUNT(*) AS AVGSF,Sum(MISS_SG) AS SGSUM, Sum(MISS_SG)/COUNT(*) AS AVGSG,Sum(MISS_HP) AS HPSUM, Sum(MISS_HP)/COUNT(*) AS AVGHP,Sum(MISS_LP) AS LPSUM, Sum(MISS_LP)/COUNT(*) AS AVGLP,Sum(MISS_ICE) AS ICESUM, Sum(MISS_ICE)/COUNT(*) AS AVGICE from Work.MetarMissing&YEARS. group by STATIONCODE;
quit;



Data Work.MetarMissingPer&YEARS.;
	set Work.MetarMissAnal&YEARS.;
	Array PERMISS [*] AVGHT AVGLT AVGCCE AVGCCL AVGH2O AVGHDP AVGHH AVGHP AVGHI AVGHWB AVGICE AVGLDP AVGLH AVGLWB AVGMAXW AVGMINW AVGPH AVGSF AVGSG AVGSMIN AVGVIS AVGWC AVGWG;
	MISSPER=0;
	DO I = 1 TO DIM(PERMISS);
		IF PERMISS[I] GT .05 THEN MISSPER +1;
	END;
RUN;

PROC SQL;
	CREATE TABLE Work.METARQUESTION&YEARS. AS SELECT STATIONCODE, MISSPER FROM Work.MetarMissingPer&YEARS.;
QUIT;

Proc Sql;
	Create Table Work.MetarRemoved&YEARS. as Select A.*,B.MISSPER from Work.METARDATA&YEARS. as A inner join Work.metarquestion&YEARS. as B on A.STATIONCODE=B.STATIONCODE WHERE B.MISSPER GT 1;
QUIT;
	
Proc Sql;
	Create Table Work.MetarGOOD&YEARS. as Select A.*,B.MISSPER from Work.METARDATA&YEARS. as A inner join Work.metarquestion&YEARS. as B on A.STATIONCODE=B.STATIONCODE WHERE B.MISSPER LT 1;
QUIT;


Proc Datasets library=Work;
	Delete METARDATA&YEARS. MISSPER&YEARS. MetarMissing&YEARS. MetarMissAnal&YEARS. MetarMissingPer&YEARS.;
RUN;

******* Time to Analyze Ranges;

Data Work.MetarRangesCk&YEARS.;
	set Work.MetarGOOD&YEARS.;
	COUNT_ERROR=0;
	If (-141 GT HIGHTEMP or 141 LT HIGHTEMP) or (-141 GT LOWTEMP or 141 LT LOWTEMP) then DO; TEMPRANGE=1;COUNT_ERROR +1;END;
		Else if (HIGHTEMP-LOWTEMP) LT -108 or (HIGHTEMP-LOWTEMP) GT 108 then DO; TEMPRANGE=1;COUNT_ERROR +1;END;
	ELSE TEMPRANGE=0;
	IF (WATEREQ LT 0 or WATEREQ GT 18) or (PRECIPHRS LT 0 or PRECIPHRS GT 24) then DO; PRECIPRANGE=1;COUNT_ERROR +1;END;
	ELSE PRECIPRANGE=0;
run;

Proc Sql;
	Create Table Work.MetarBetter&YEARS. as Select A.*,B.* from(Select * from Work.MetarRangesCk&YEARS.) as A inner join (Select STATIONCODE , Sum(COUNT_ERROR)/COUNT(*) as RANGEPER from Work.MetarRangesCk&YEARS. group by STATIONCODE) as B
	on A.STATIONCODE=B.STATIONCODE Where B.RANGEPER LT .05 order by A.STATIONCODE, A.YEAR,A.MONTH,A.DAY;
QUIT;

Proc Sql;
	Create Table Work.DescriptStats&YEARS. as Select A.STATIONCODE, A.CLIMATE_ID,(A.HTMPMEAN-(A.STDHTEMP*3)) AS LOWHTEMPRANGE,(A.HTMPMEAN+(A.STDHTEMP*3)) AS HIGHHTEMPRANGE, (A.LTMPMEAN-(A.STDLTEMP*3)) AS LOWLTEMPRANGE,
		(A.LTMPMEAN+(A.STDLTEMP*3)) AS HIGHLTEMPRANGE,(A.HINDEXMEAN+(A.STDINDEX*3)) AS HINDEXRANGE,(A.HINDEXMEAN -(A.STDINDEX*3)) AS LINDEXRANGE, (A.WNDCHILLMEAN+(A.STDWNDCHILL*3)) AS HWNDCHILLRANGE,(A.WNDCHILLMEAN -(A.STDWNDCHILL*3)) AS LWNDCHILLRANGE,
		(A.HDWPMEAN +(A.STDHDWP*3)) as MAXHDWPRANGE,(A.HDWPMEAN -(A.STDHDWP*3)) as MINHDWPRANGE,(A.LDWPMEAN -(A.STDLDWP*3)) as MINLDWPRANGE,(A.LDWPMEAN +(A.STDLDWP*3)) as MAXLDWPRANGE, (A.HWTBMEAN +(A.STDHWTB*3))as MAXHWTBRANGE,(A.HWTBMEAN -(A.STDHWTB*3))as MINHWTBRANGE,
		(A.LWTBMEAN -(A.STDLWTB*3))as MINLWTBRANGE, (A.LWTBMEAN +(A.STDLWTB*3))as MAXLWTBRANGE   
		FROM(Select Avg(HIGHTEMP) as HTMPMEAN, Std(HIGHTEMP) as STDHTEMP, Avg(LOWTEMP) as LTMPMEAN, Std(LOWTEMP) as STDLTEMP,
		Avg(HEATINDEX) as HINDEXMEAN, Std(HEATINDEX) as STDINDEX, Avg(WINDCHILL) as WNDCHILLMEAN, Std(WINDCHILL) as STDWNDCHILL, Avg(HIGHDEWPOINT) as HDWPMEAN, Std(HIGHDEWPOINT) as STDHDWP,
		Avg(LOWDEWPOINT) as LDWPMEAN, Std(LOWDEWPOINT) as STDLDWP, Avg(HIGHWETBULB) as HWTBMEAN, Std(HIGHWETBULB) as STDHWTB, Avg(LOWWETBULB) as LWTBMEAN, Std(LOWWETBULB) as STDLWTB,  Avg(HIGHPRESSURE) as HPRESSMEAN, Std(HIGHPRESSURE) as STDHPRESS,
		Avg(LOWPRESSURE) as LPRESSMEAN, Std(LOWPRESSURE) as STDLPRESS, STATIONCODE, CLIMATE_ID FROM Work.METARBETTER&YEARS. GROUP BY CLIMATE_ID,STATIONCODE) as A;
QUIT;


Proc Sql;
	Create Table Work.MetarBetterTest&YEARS. as Select A.STATIONCODE, A.HWNDCHILLRANGE, A.LWNDCHILLRANGE, A.MAXHDWPRANGE,A.MINHDWPRANGE,A.MINLDWPRANGE,A.MAXLDWPRANGE,A.MAXHWTBRANGE,
	A.MINHWTBRANGE,A.MINLWTBRANGE,A.MAXLWTBRANGE,B.* from Work.DescriptStats&YEARS. as A inner join Work.METARBETTER&YEARS. as B on A.STATIONCODE=B.STATIONCODE;
quit;

Proc Datasets library=Work;
	Delete DescriptStats&YEARS. MetarGOOD&YEARS. MetarRangesCk&YEARS.  MetarRemoved&YEARS. METARQUESTION&YEARS.;
RUN;



Data Work.MetarRangesCk2&YEARS.;
	set Work.MetarBetterTest&YEARS.;
	COUNT_ERROR2=0;
	IF HEATINDEX LT -134 or HEATINDEX GT 134 then DO; INDEXRANGE=1;COUNT_ERROR2 +1;END;
	ELSE INDEXRANGE=0;
	IF WINDCHILL LT LWNDCHILLRANGE or WINDCHILL GT HWNDCHILLRANGE Then DO; CHILLRANGE=1;COUNT_ERROR2 +1;END;
	ELSE CHILLRANGE=0;
	IF (HIGHDEWPOINT LT -22 or HIGHDEWPOINT GT 100) or (LOWDEWPOINT LT -22 or LOWDEWPOINT GT 100) or (HIGHWETBULB LT -22 or HIGHWETBULB GT 100) or (LOWWETBULB LT -22 or LOWWETBULB GT 100) then DO; DEWRANGE=1;COUNT_ERROR2 +1;END;
	Else DEWRANGE=0;
	IF (HIGHHUMIDITY LT 0 or HIGHHUMIDITY GT 100) or (LOWHUMIDITY LT 0 or LOWHUMIDITY GT 100) then DO; HUMIDRANGE=1;COUNT_ERROR2 +1;END;
	Else HUMIDRANGE=0;
	IF (MAXSUSTAINED LT 0 or MAXSUSTAINED GT 243) or (MINSUSTAINED LT 0 or MINSUSTAINED GT 243) or (WINDGUST LT 0 or WINDGUST GT 266) Then DO; WINDRANGE=1;COUNT_ERROR2 +1;END;
	Else WINDRANGE=0;
	IF (AVGCLOUDCOVER LT 0 or AVGCLOUDCOVER GT 100) or (AVGCLOUDCEILING LT 0 or AVGCLOUDCEILING GT 28000) then DO;CLOUDRANGE=1;COUNT_ERROR2 +1;END;
	ELSE CLOUDRANGE=0;
	IF AVGVIS LT 0 or AVGVIS GT 100 then DO; VISRANGE=1;COUNT_ERROR2 +1;END;
	ELSE VISRANGE=0;
	IF MINOFSUN LT 0 or MINOFSUN GT 1440 then DO; MINSUNRANGE=1;COUNT_ERROR2 +1;END;
	ELSE MINSUNRANGE=0;
	IF (LOWPRESSURE LT 25 or LOWPRESSURE GT 34) or (HIGHPRESSURE LT 25 or HIGHPRESSURE GT 34) then DO; PRESSRANGE=1; COUNT_ERROR2 +1;END;
	ELSE PRESSRANGE=0;
	IF (SNOWONGROUND LT 0 or SNOWONGROUND GT 110) or (SNOWFALL LT 0 or SNOWFALL GT 30) or (ICEAMOUNT LT 0 or ICEAMOUNT GT 1) Then DO; FREEZERANGE=1;COUNT_ERROR2 +1;END;
	ELSE FREEZERANGE=0;	
	Drop HWNDCHILLRANGE LWNDCHILLRANGE MAXHDWPRANGE MINHDWPRANGE MINHDWPRANGE MINLDWPRANGE MAXLDWPRANGE MAXHWTBRANGE MINHWTBRANGE MINLWTBRANGE;
run;

Proc Sql;
	Create Table Work.MetarBetter2&YEARS. as Select A.*,B.* from(Select * from Work.MetarRangesCk2&YEARS.) as A inner join (Select STATIONCODE , Sum(COUNT_ERROR2)/COUNT(*) as RANGEPER from Work.MetarRangesCk2&YEARS. group by STATIONCODE) as B
	on A.STATIONCODE=B.STATIONCODE Where B.RANGEPER LT .05 order by A.STATIONCODE, A.YEAR,A.MONTH,A.DAY;
QUIT;




	

***** Time to Analyze Daily Change Values;
	
Data Work.MetarDelta&YEARS.;
	DO UNTIL(LAST.STATIONCODE);
	set Work.MetarBetter2&YEARS.;
	by STATIONCODE;
		Array Var [*] HIGHTEMP LOWTEMP HEATINDEX WINDCHILL HIGHDEWPOINT LOWDEWPOINT HIGHHUMIDITY LOWHUMIDITY HIGHWETBULB LOWWETBULB MAXSUSTAINED MINSUSTAINED WINDGUST AVGCLOUDCOVER AVGCLOUDCEILING AVGVIS MINOFSUN WATEREQ PRECIPHRS SNOWFALL SNOWONGROUND HIGHPRESSURE LOWPRESSURE ICEAMOUNT ;
		Array DIFF [*] DIFHITEMP DIFLWTEMP DIFINDEX DIFWNDC DIFHDWPT DIFLWDPT DIFHHUMID DIFLHUMID DIFHWTB DIFLWTB DIFMXW DIFMNW DIFWG DIFACCVR DIFACCL DIFAVIS DIFMINSUN DIFH2OEQ DIFPRECHRS DIFSF DIFSG DIFHP DIFLWP DIFICE;
		DO I = 1 TO DIM(VAR);
			DIFF[I]=dif(Var[I]);
			IF DIFF[I]=. THEN DIFF[I]=0;
		END;
	OUTPUT;
	END;
	DROP I;
run;

Data Work.Metardelta2&YEARS.;
	set Work.MetarDelta&YEARS.;
	COUNT_ERROR3=0;
	Array Diffs [*] DIFHITEMP DIFLWTEMP DIFINDEX DIFWNDC DIFHDWPT DIFLWDPT DIFHHUMID DIFLHUMID DIFHWTB DIFLWTB ;
	Array FlagDiff [*] HITEMPFLG LWTEMPFLG INDEXFLG WNDCFLG HDWPTFLG LWDPTFLG HHUMIDFLG LHUMIDFLG HWTBFLG LWTBFLG;
		do I= 1 to dim(Diffs);
			IF Diffs[I] GT 50 or Diffs[I] LT -50 then do; FlagDiff[I]=1;COUNT_ERROR3+1;END;
			ELSE FlagDiff[I]=0;
		end;
	Drop I DIFHITEMP DIFLWTEMP DIFINDEX DIFWNDC DIFHDWPT DIFLWDPT DIFHHUMID DIFLHUMID DIFHWTB DIFLWTB DIFMXW DIFMNW DIFWG DIFACCVR DIFACCL DIFAVIS DIFMINSUN DIFH2OEQ DIFPRECHRS DIFSF DIFSG DIFHP DIFLWP DIFICE;
run;


Proc Datasets library=Work;
	Delete MetarBetter2&YEARS. MetarRangesCk2&YEARS. MetarDelta&YEARS. MetarBetterTest&YEARS.  MetarBetter&YEARS.;
RUN;

Proc Sql;
	Create Table Work.MetarBetter3&YEARS. as Select A.*,B.* from(Select * from Work.Metardelta2&YEARS.) as A inner join (Select STATIONCODE , Sum(COUNT_ERROR3)/COUNT(*) as DIFRANGEPER from Work.Metardelta2&YEARS. group by STATIONCODE) as B
	on A.STATIONCODE=B.STATIONCODE Where B.DIFRANGEPER LT .05 order by A.STATIONCODE, A.YEAR,A.MONTH,A.DAY;
QUIT;

Proc Sql;
	Create Table Work.MetarWeekAvg&YEARS. as Select A.STATIONCODE,A.WEEKNUM, A.WeekHITEMP, A.WeekLOTEMP,B.WeekPrecip,B.WeekPrecipHRS,C.WeekHEATINDEX,D.WeekWINDCHILL,E.WeekHIGHDEWPOINT, E.WeekLOWDEWPOINT, E.WeekHIGHWETBULB, E.WeekLOWWETBULB,F.WeekHHUMIDITY,F.WeekLHUMIDITY,G.WeekMAXSUSTAINED,G.WeekMINSUSTAINED,G.WeekWINDGUST,
	H.WeekAVGCLOUDCOVER, H.WeekAVGCLOUDCEILING, I.WeekAVGVIS,J.WeekLOWPRESSURE,J.WeekHIGHPRESSURE,K.WeekSNOWONGROUND,K.WeekSNOWFALL,K.WeekICEAMOUNT,L.WeekMINOFSUN from(Select STATIONCODE,WEEKNUM, Avg(HIGHTEMP) as WeekHITEMP, Avg(LOWTEMP) as WeekLOTEMP from Work.MetarBetter3&YEARS. Where (HIGHTEMP^=. and LOWTEMP^=.) and TEMPRANGE=0 and (HITEMPFLG=0 and LWTEMPFLG=0) group by STATIONCODE, WEEKNUM) as A,
	(Select STATIONCODE,WEEKNUM,Avg(WATEREQ) as WeekPrecip,	Avg(PRECIPHRS) as WeekPrecipHRS	from Work.MetarBetter3&YEARS. Where (WATEREQ^=. and PRECIPHRS^=.) and PRECIPRANGE=0 group by STATIONCODE, WEEKNUM) as B,
	(Select STATIONCODE,WEEKNUM,Avg(HEATINDEX) as WeekHEATINDEX from Work.MetarBetter3&YEARS. Where HEATINDEX ^=. and INDEXRANGE=0 and INDEXFLG=0 group by STATIONCODE, WEEKNUM) as C,
	(Select STATIONCODE,WEEKNUM,Avg(WINDCHILL) as WeekWINDCHILL from Work.MetarBetter3&YEARS. Where WINDCHILL ^=. and CHILLRANGE=0 and WNDCFLG=0 group by STATIONCODE, WEEKNUM) as D,
	(Select STATIONCODE,WEEKNUM,Avg(HIGHDEWPOINT) as WeekHIGHDEWPOINT,Avg(LOWDEWPOINT) as WeekLOWDEWPOINT,Avg(HIGHWETBULB) as WeekHIGHWETBULB,Avg(LOWWETBULB) as WeekLOWWETBULB	from Work.MetarBetter3&YEARS. Where (HIGHDEWPOINT ^=. and LOWDEWPOINT ^=. and HIGHWETBULB ^=. and LOWWETBULB ^=.) and DEWRANGE=0 and (HDWPTFLG = 0 and LWDPTFLG = 0 and HWTBFLG = 0 and LWTBFLG = 0) group by STATIONCODE, WEEKNUM) as E,
	(Select STATIONCODE,WEEKNUM,Avg(HIGHHUMIDITY) as WeekHHUMIDITY,Avg(LOWHUMIDITY) as WeekLHUMIDITY from Work.MetarBetter3&YEARS. Where (HIGHHUMIDITY ^=. and LOWHUMIDITY ^=.) and HUMIDRANGE=0 and (HHUMIDFLG = 0	and LHUMIDFLG = 0) group by STATIONCODE, WEEKNUM) as F,
	(Select STATIONCODE,WEEKNUM,Avg(MAXSUSTAINED) as WeekMAXSUSTAINED, Avg(MINSUSTAINED) as WeekMINSUSTAINED, Avg(WINDGUST) as WeekWINDGUST from Work.MetarBetter3&YEARS. Where (MAXSUSTAINED ^=. and MINSUSTAINED ^=. and WINDGUST ^=.) and WINDRANGE=0 group by STATIONCODE, WEEKNUM) as G,
	(Select STATIONCODE,WEEKNUM,Avg(AVGCLOUDCOVER) as WeekAVGCLOUDCOVER, Avg(AVGCLOUDCEILING) as WeekAVGCLOUDCEILING from Work.MetarBetter3&YEARS. Where (AVGCLOUDCOVER ^=. and AVGCLOUDCEILING ^=.) and CLOUDRANGE=0 group by STATIONCODE, WEEKNUM) as H,
	(Select STATIONCODE,WEEKNUM,Avg(AVGVIS) as WeekAVGVIS from Work.MetarBetter3&YEARS. Where (AVGVIS ^=.) and VISRANGE=0 group by STATIONCODE, WEEKNUM) as I,
	(Select STATIONCODE,WEEKNUM,Avg(LOWPRESSURE) as WeekLOWPRESSURE,Avg(HIGHPRESSURE) as WeekHIGHPRESSURE from Work.MetarBetter3&YEARS. Where (HIGHPRESSURE ^=.	and	LOWPRESSURE ^=. ) and PRESSRANGE=0 group by STATIONCODE, WEEKNUM) as J,
	(Select STATIONCODE,WEEKNUM,Avg(SNOWONGROUND) as WeekSNOWONGROUND,Avg(SNOWFALL) as WeekSNOWFALL,Avg(ICEAMOUNT) as WeekICEAMOUNT	from Work.MetarBetter3&YEARS. Where (SNOWFALL ^=.	and	SNOWONGROUND ^=. and ICEAMOUNT ^=.) and FREEZERANGE=0 group by STATIONCODE, WEEKNUM) as K,
	(Select STATIONCODE,WEEKNUM,Avg(MINOFSUN) as WeekMINOFSUN from Work.MetarBetter3&YEARS. Where (MINOFSUN ^=.) and MINSUNRANGE=0	group by STATIONCODE, WEEKNUM) as L
	Where(A.STATIONCODE=B.STATIONCODE and B.STATIONCODE=C.STATIONCODE and C.STATIONCODE=D.STATIONCODE and D.STATIONCODE=E.STATIONCODE and E.STATIONCODE=F.STATIONCODE and F.STATIONCODE=G.STATIONCODE and G.STATIONCODE=H.STATIONCODE and H.STATIONCODE=I.STATIONCODE and I.STATIONCODE=J.STATIONCODE and J.STATIONCODE=K.STATIONCODE and K.STATIONCODE=L.STATIONCODE)
	and (A.WEEKNUM=B.WEEKNUM and B.WEEKNUM=C.WEEKNUM and C.WEEKNUM=D.WEEKNUM and D.WEEKNUM=E.WEEKNUM and E.WEEKNUM=F.WEEKNUM and F.WEEKNUM=G.WEEKNUM and G.WEEKNUM=H.WEEKNUM and H.WEEKNUM=I.WEEKNUM and I.WEEKNUM=J.WEEKNUM and J.WEEKNUM=K.WEEKNUM and K.WEEKNUM=L.WEEKNUM);
quit;
	
Proc Sql;
	Create Table Work.MetarFinalRV&YEARS. as Select A.*,B.* from (Select * from Work.MetarBetter3&YEARS.) as A, (Select * from Work.MetarWeekAvg&YEARS.) as B Where A.STATIONCODE=B.STATIONCODE and A.WEEKNUM =B.WEEKNUM;
Quit;


Proc Datasets library=Work;
	Delete MetarBetter3&YEARS. MetarWeekAvg&YEARS. Metardelta2&YEARS.;
RUN;



Data Work.MetarUpdated&YEARS.;
	set Work.MetarFinalRV&YEARS.;
	If (HIGHTEMP =.) or	TEMPRANGE=1 or (HITEMPFLG=1) then HIGHTEMP=WeekHITEMP;
	If (LOWTEMP =.) or	TEMPRANGE=1 or (LWTEMPFLG=1) then LOWTEMP=WeekLOTEMP;
	IF (WATEREQ	=.) or PRECIPRANGE=1 then WATEREQ=WeekPrecip;
	IF (PRECIPHRS =.) or PRECIPRANGE=1 then PRECIPHRS=WeekPrecipHRS;
	IF (HEATINDEX =.) or INDEXRANGE=1 or (INDEXFLG=1) then HEATINDEX = WeekHEATINDEX;
	IF (WINDCHILL =	.) or CHILLRANGE=1 or	(WNDCFLG=1) then WINDCHILL = WeekWINDCHILL;
	IF	HIGHDEWPOINT =. or	DEWRANGE=1 or	HDWPTFLG=1 Then HIGHDEWPOINT = WeekHIGHDEWPOINT;
	If	LOWDEWPOINT =. or DEWRANGE=1 or LWDPTFLG =1 then LOWDEWPOINT = WeekLOWDEWPOINT;
	IF	HIGHWETBULB =. or DEWRANGE=1 or HWTBFLG =1 then HIGHWETBULB = WeekHIGHWETBULB;
	IF	LOWWETBULB =. or DEWRANGE=1 or LWTBFLG =1 then LOWWETBULB = WeekLOWWETBULB;
	IF	HIGHHUMIDITY =.	or HUMIDRANGE=1 or HHUMIDFLG = 1 then HIGHHUMIDITY = WeekHHUMIDITY;
	IF LOWHUMIDITY =. 	or HUMIDRANGE=1 or LHUMIDFLG = 1 then LOWHUMIDITY=WeekLHUMIDITY;
	IF MAXSUSTAINED =. or WINDRANGE	= 1 then MAXSUSTAINED=WeekMAXSUSTAINED;
	IF MINSUSTAINED =. or WINDRANGE	= 1 then MINSUSTAINED = WeekMINSUSTAINED;
	IF WINDGUST =. or WINDRANGE	= 1 then WINDGUST = WeekWINDGUST;
	IF AVGCLOUDCOVER =. or CLOUDRANGE = 1 then AVGCLOUDCOVER=WeekAVGCLOUDCOVER;
	If AVGCLOUDCEILING =. or CLOUDRANGE = 1 then AVGCLOUDCEILING=WeekAVGCLOUDCEILING;
	IF AVGVIS  =. or  VISRANGE=0  then AVGVIS = WeekAVGVIS;
	IF HIGHPRESSURE =. or PRESSRANGE = 1 then HIGHPRESSURE = WeekHIGHPRESSURE;
	IF LOWPRESSURE =. or PRESSRANGE = 1 then LOWPRESSURE = WeekLOWPRESSURE;
	IF SNOWFALL =. or FREEZERANGE= 1 then SNOWFALL=WeekSNOWFALL;
	IF SNOWONGROUND =. or FREEZERANGE= 1 then SNOWONGROUND=SNOWONGROUND;
	IF ICEAMOUNT =. or FREEZERANGE= 1 then ICEAMOUNT=WeekICEAMOUNT;
	IF MINOFSUN =. or  MINSUNRANGE=1 then MINOFSUN = WeekMINOFSUN;
run;

Proc Sql;
	Create Table Test.MetarEighties&YEARS.  (DATE Char(11), LAT Char(8), LON Char(10), HIGHTEMP num, LOWTEMP num, HEATINDEX num, WINDCHILL num, HIGHDEWPOINT num, LOWDEWPOINT num, HIGHHUMIDITY num,
				LOWHUMIDITY num, HIGHWETBULB num, LOWWETBULB num, MAXSUSTAINED num, MINSUSTAINED num, WINDGUST num, AVGCLOUDCOVER num, AVGCLOUDCEILING num, AVGVIS num, MINOFSUN num, WATEREQ num,
				PRECIPHRS num, SNOWFALL num, SNOWONGROUND num, HIGHPRESSURE num, LOWPRESSURE num, ICEAMOUNT num);
quit;
	

*******Proc Sql;
	*********Insert into Test.MetarEighties&YEARS. Select A.* from (Select DATE, LAT, LON, HIGHTEMP, LOWTEMP, HEATINDEX, WINDCHILL, HIGHDEWPOINT, LOWDEWPOINT, HIGHHUMIDITY, LOWHUMIDITY, HIGHWETBULB, LOWWETBULB,
													**********MAXSUSTAINED, MINSUSTAINED, WINDGUST, AVGCLOUDCOVER, AVGCLOUDCEILING, AVGVIS, MINOFSUN, WATEREQ, PRECIPHRS, SNOWFALL, SNOWONGROUND, HIGHPRESSURE, LOWPRESSURE,ICEAMOUNT from Work.MetarUpdated&YEARS.) as A;
*********quit;

Proc Sql;
	Insert into Test.MetarEighties&YEARS. Select A.* from (Select EXDATE AS DATE, LAT, LON, HIGHTEMP FORMAT=3.0, LOWTEMP FORMAT=3.0, HEATINDEX FORMAT=3.0, WINDCHILL FORMAT=3.0, HIGHDEWPOINT FORMAT=3.0, LOWDEWPOINT FORMAT=3.0, HIGHHUMIDITY FORMAT=3.0, LOWHUMIDITY FORMAT=3.0, HIGHWETBULB FORMAT=3.0, 
	LOWWETBULB FORMAT=3.0, MAXSUSTAINED FORMAT=3.0, MINSUSTAINED FORMAT=3.0, WINDGUST FORMAT=3.0, AVGCLOUDCOVER FORMAT=3.0, AVGCLOUDCEILING FORMAT=8.0, AVGVIS FORMAT=4.1, MINOFSUN FORMAT=4.0, WATEREQ FORMAT=7.2, PRECIPHRS FORMAT=3.0, SNOWFALL FORMAT=5.2, SNOWONGROUND FORMAT=5.2, HIGHPRESSURE FORMAT=6.2,
	LOWPRESSURE FORMAT=6.2,ICEAMOUNT FORMAT=5.2 from Work.MetarUpdated&YEARS.) as A;
quit;


Proc Append BASE=Test.MetarEightiesFinal DATA=Test.MetarEighties&YEARS. FORCE;
run;

Proc Datasets library=Test;
	Delete MetarFinalRV&YEARS. MetarEighties&YEARS.;
RUN;

%END;
%MEND;
%CheckYrs;



Proc Sort Data=Test.MetarEightiesFinal;
	By DATE LAT LON;
run;


Ods csvall file='/data/wta/Lamar_Projects/Sas_Conversion/UHDB_CleaningData/Eighties/Data/METAR_DATA_8089.csv';

Proc Print data=Test.MetarEightiesFinal noobs;
	Var DATE LAT LON HIGHTEMP LOWTEMP HEATINDEX WINDCHILL HIGHDEWPOINT LOWDEWPOINT HIGHHUMIDITY LOWHUMIDITY HIGHWETBULB LOWWETBULB MAXSUSTAINED MINSUSTAINED WINDGUST AVGCLOUDCOVER AVGCLOUDCEILING AVGVIS MINOFSUN WATEREQ PRECIPHRS SNOWFALL HIGHPRESSURE LOWPRESSURE ICEAMOUNT;
	Format DATE $DATE11.
		   HIGHTEMP 3.0
		   LOWTEMP 3.0
		   HEATINDEX 3.0
		   WINDCHILL 3.0
		   HIGHDEWPOINT 3.0
		   LOWDEWPOINT 3.0
		   HIGHHUMIDITY 3.0
		   LOWHUMIDITY 3.0
		   HIGHWETBULB 3.0
		   LOWWETBULB 3.0
		   MAXSUSTAINED 3.0
		   MINSUSTAINED 3.0
		   AVGCLOUDCOVER 3.0
		   AVGCLOUDCEILING 8.0
		   AVGVIS 4.1
		   MINOFSUN 3.0
		   WATEREQ 7.2
		   PRECIPHRS 3.0
		   SNOWFALL 5.2
		   SNOWONGROUND 5.2
		   HIGHPRESSURE 6.2
		   LOWPRESSURE 6.2
		   ICEAMOUNT 5.2;
 run;


 ods csvall close;


******Proc Export data=Test.MetarEightiesFinal
	DBMS=csv
	outfile='/data/wta/Lamar_Projects/Sas_Conversion/UHDB_CleaningData/Eighties/Data/METAR_DATA_8089.csv'
	replace;
******run;







	
	
	
