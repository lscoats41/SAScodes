
%Macro FinalStep(Y=);

Proc Sql;
	Create Table Final.CensusCount as Select Total_Population, Tracts_ID, &Y.*(Ages_00_00) as Ages_00_00_Sum, &Y.*(Ages_01_04) as Ages_01_04_Sum, &Y.*(Ages_05_09) as Ages_05_09_Sum, &Y.*(Ages_10_14) as Ages_10_14_Sum,  
				&Y.*(Ages_15_19) as Ages_15_19_Sum, &Y.*(Ages_20_24) as Ages_20_24_Sum, &Y.*(Ages_25_29) as Ages_25_29_Sum, &Y.*(Ages_30_34) as Ages_30_34_Sum,
				&Y.*(Ages_35_39) as Ages_35_39_Sum, &Y.*(Ages_40_44) as Ages_40_44_Sum, &Y.*(Ages_45_49) as Ages_45_49_Sum, &Y.*(Ages_50_54) as Ages_50_54_Sum,
				&Y.*(Ages_55_59) as Ages_55_59_Sum, &Y.*(Ages_60_64) as Ages_60_64_Sum, &Y.*(Ages_65_69) as Ages_65_69_Sum, &Y.*(Ages_70_74) as Ages_70_74_Sum,
				&Y.*(Ages_75_79) as Ages_75_79_Sum, &Y.*(Ages_80_84) as Ages_80_84_Sum, &Y.*(Ages_85_Plus) as Ages_85_Plus_Sum from Work.Census2010;
quit;

Proc Sql;
	Create Table Final.BirthCountSum as Select CensusTracts, Sum(BirthCount) as BirthCount_Sum  from Final.BirthCountAll group by CensusTracts;
quit;

Proc Sql;
	Create Table Final.DeathFinalPrepSum as Select CensusFips, Sum(Years00_00) as Years00_00_Sum, Sum(Years01_04) as Years01_04_Sum, Sum(Years05_09) as Years05_09_Sum, Sum(Years10_14) as Years10_14_Sum,  
				Sum(Years15_19) as Years15_19_Sum, Sum(Years20_24) as Years20_24_Sum, Sum(Years25_29) as Years25_29_Sum, Sum(Years30_34) as Years30_34_Sum,
				Sum(Years35_39) as Years35_39_Sum, Sum(Years40_44) as Years40_44_Sum, Sum(Years45_49) as Years45_49_Sum, Sum(Years50_54) as Years50_54_Sum,
				Sum(Years55_59) as Years55_59_Sum, Sum(Years60_64) as Years60_64_Sum, Sum(Years65_69) as Years65_69_Sum, Sum(Years70_74) as Years70_74_Sum,
				Sum(Years75_79) as Years75_79_Sum, Sum(Years80_84) as Years80_84_Sum, Sum(Years85_Plus) as Years85_Plus_Sum, sum(Total_Deaths) as Total_Deaths_Sum from Final.DeathFinalPrepAll group by CensusFips;
quit;


Proc Sql;
	Create Table Final.LifeTable as Select A.*,B.*,C.* from (Select * from Final.CensusCount) as A, (Select * from Final.DeathFinalPrepSum) as B, (Select * from Final.BirthCountSum) as C Where A.Tracts_ID=B.CensusFips and B.CensusFips=C.CensusTracts order by A.Tracts_ID;
quit;


Data Final.LifeCalcTable;
	set Final.LifeTable (rename=(CensusFips=Fips));
	Array Pop [19] Ages_00_00_Sum  Ages_01_04_Sum  Ages_05_09_Sum  Ages_10_14_Sum  Ages_15_19_Sum  Ages_20_24_Sum  Ages_25_29_Sum  Ages_30_34_Sum  Ages_35_39_Sum  Ages_40_44_Sum  Ages_45_49_Sum  Ages_50_54_Sum  Ages_55_59_Sum  Ages_60_64_Sum  Ages_65_69_Sum  Ages_70_74_Sum  Ages_75_79_Sum  Ages_80_84_Sum  Ages_85_Plus_Sum;
	Array Dth [19] Years00_00_Sum Years01_04_Sum Years05_09_Sum Years10_14_Sum Years15_19_Sum Years20_24_Sum Years25_29_Sum Years30_34_Sum Years35_39_Sum Years40_44_Sum Years45_49_Sum Years50_54_Sum Years55_59_Sum Years60_64_Sum Years65_69_Sum Years70_74_Sum Years75_79_Sum Years80_84_Sum Years85_Plus_Sum;
	
	****Calculated Functions for life expectancy for nMx, nQx, Ix, and nDx;
	**** Arrays first created;
	Array M [19] M1-M19; ****** Death Proportion;
	Array Q [19] Q1-Q19; ****** Birth and Midpoint;
	Array Ix [19] Ix1-Ix19;
	Array D [19] D1-D19;
		*nMx;
		Do i=1 to 19;
			M[i]=Dth[i]/Pop[i];
			*If M[i]=. then M[i]=0;
			*Else M[i]=M[i];

			*nQx;
			If i=1 then Q[i]=Dth[i]/BirthCount_Sum;
			If i=2 then Q[i]=(2*4*M[i])/(2+4*M[i]);
			IF (3 <= i <= 18) THEN Q[i] = (2*5*M[i])/(2+5*M[i]);
			IF i = 19 THEN Q[i] = 1;	
		
			*Ix and nDx;
			IF i = 1 THEN DO;
				Ix[i] = 100000;
				D[i] = ROUND(Q[i]*Ix[i],1);
			END;
			IF (2 <= i <= 19) THEN DO;
				Ix[i] = Ix[i-1] - D[i-1];
				D[i] = ROUND(Q[i]*Ix[i],1);
			END;

		END;

	*nLx calculations require that the above loop first be completed;
	*Tx calculations then require that the loop goes in reverse order from 19 to 1 and Ex calculations follow;
	ARRAY L [19] L1-L19 ;
	ARRAY T [19] T1-T19 ;
	ARRAY E [19] E1-E19 ;
		DO i = 19 TO 1 BY -1;
			
			**nLx;
			IF i = 1 THEN L[i] = ROUND(0.3*Ix[i] + 0.7*Ix[i+1],1);
			IF i = 2 THEN L[i] = 4*(Ix[i] + Ix[i+1])/2;
			IF (3 <= i <= 18) THEN L[i] = ROUND(5*(Ix[i] + Ix[i+1])/2,1);
			IF i = 19 THEN L[i] = ROUND(D[i]/M[i],1);

			*Tx;
			IF i = 19 THEN T[i] = L[i];
			IF (1 <= i <= 18) THEN T[i] = L[i] + T[i+1];
			
			
			*Ex;
			E[i] = T[i]/Ix[i];
		end;
	Keep Fips Total_Population Total_Deaths_Sum E1-E19;
	run;

Proc Export data= Final.LifeCalcTable (Where=(Total_Population GE 1000 or Total_Deaths_Sum GE 60))
	outfile="X:\GIS_Excess\Census_TractsPopulation\Data\MyLifeTableFips.csv"
	DBMS=csv
	replace;
run;
%Mend FinalStep;