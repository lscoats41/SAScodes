Libname Test '/data/wta/Lamar_Projects/WindChillEnergy/Data';
%Include '/data/wta/Lamar_Projects/WindChillEnergy/Codes/WindChillEnergyHourly.sas';




%Macro Main;
	%WIND(Yr1=2018,Yr2=2018,Mths1=1,Mths2=9);
%Mend;
%Main;





