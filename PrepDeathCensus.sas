Libname Temp "X:\DeathFileRecords\Geocoded_Deathfile\Temp";


%Macro FixDeaths(Year=,Var=);

Proc Sql;
	Select Count(Tracts_ID) into :TractNum from &Var.;
quit;

%Let Last= %eval(&TractNum*19);

Proc Sql;
	Create Table Work.CensusTracts as Select Tracts_ID from &Var. order by 1;
quit;

%Put &Last.;

Data Work.CensusKey;
	Do i= 1 to &Last.;
		Do K= 1 to 1497;
			set Work.CensusTracts;
			Do j= 1 to 19;
				Array AgeRange [19] $ _Temporary_ ('00_00' '01_04' '05_09' '10_14' '15_19' '20_24' '25_29' '30_34' '35_39' '40_44' '45_49' '50_54' '55_59' '60_64' '65_69' '70_74' '75_79' '80_84' '85_Plus');
				Length Tracts_Key $ 20.;
				Tracts_Key = Cats(Tracts_ID,AgeRange[j]);
				AgeGroup=AgeRange[j];
				output;
			end;
		end;
	end;
	Drop i K j;
run;


Proc Import out=Work.DeathCount&Year.
	datafile="X:\DeathFileRecords\Geocoded_Deathfile\Temp\DeathStateCensusCount.xlsx"
	DBMS=Excel
	replace;
	Sheet="DeathCount&Year.";
run;

Proc Sql;
	Create Table Work.DeathKey&Year. as Select *, cats(CensusFips,AgeGroup) as Tracts_Key from Work.DeathCount&Year. Where CensusFips in (Select Tracts_ID from Work.CensusKey) order by CensusFips;
quit;


Proc Sql;
	Create Table Work.DeathNull&Year. as Select 0 as DeathCount, Tracts_ID as CensusFips, AgeGroup, put(&Year.,Z4.) as DDODYr
	from Work.CensusKey where Tracts_Key not in (Select Tracts_Key from Work.DeathKey&Year.) order by Tracts_ID;
quit;


Proc Sql;
	Insert into Work.DeathCount&Year. Select * from Work.DeathNull&Year.;
quit;

Proc Sql;
	Create Table Work.DeathPrep&Year. as Select DeathCount, CensusFips, DDODYr, AgeGroup from Work.DeathCount&Year. order by CensusFips, AgeGroup;
quit;

Data Work.DeathFinalPrep&Year.;
	Do i=1 to &Last.;
		Total_Deaths=0;
		Do j= 1 to 19;
			set Work.DeathPrep&Year.;
			Array Group [19] Years00_00 Years01_04 Years05_09 Years10_14 Years15_19 Years20_24 Years25_29 Years30_34 Years35_39 Years40_44 Years45_49 Years50_54 Years55_59 Years60_64 Years65_69 Years70_74 Years75_79 Years80_84 Years85_Plus; 
			Group[j]=DeathCount;
			Total_Deaths=Total_Deaths + DeathCount;
		end;
		output;
	end;
	Drop i j DeathCount AgeGroup;
run;

Proc Export data=Work.DeathFinalPrep&Year.
	outfile="X:\DeathFileRecords\Geocoded_Deathfile\Temp\DeathStateRevisedCensusCount.xlsx"
	DBMS=Excel
	replace;
	Sheet="DeathCount&Year.";
run;

%Mend FixDeaths;

