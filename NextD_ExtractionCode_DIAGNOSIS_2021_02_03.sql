---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                             Part 4: Diagnoses for the study sample                                  -----  
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
/* Tables for this eaxtraction: 
1. Table 1 (named here #FinalTable1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. DIAGNOSIS and DEMOGRAPHIC table from PCORNET. */
---------------------------------------------------------------------------------------------------------------
use /*provide here the name of PCORI database here: */PCORI_SAS;
---------------------------------------------------------------------------------------------------------------
-----                            Declare study time frame variables:                                      -----
DECLARE @studyTimeRestriction int;declare @UpperTimeFrame int; declare @LowerTimeFrame int;
-----                             Specify time frame and age limits                                       -----
--Set extraction time frame below. If time frames not set, the code will use the whole time frame available from the database
set @LowerTimeFrame=18263;--'2010-01-01';
set @UpperTimeFrame=22280;--'2020-12-31';
--set age restrictions:
declare @UpperAge int; declare @LowerAge int;set @UpperAge=89; set @LowerAge=18;
---------------------------------------------------------------------------------------------------------------
select c.PATID,'|' as Pipe1,
		b.ENCOUNTERID,'|' as Pipe2,
		b.DIAGNOSISID,'|' as Pipe3,
		b.DX,'|' as Pipe4,
		b.PDX,'|' as Pipe5,
		b.DX_POA,'|' as Pipe6,
		b.DX_TYPE,'|' as Pipe7,
		b.DX_SOURCE,'|' as Pipe8,
		b.DX_ORIGIN,'|' as Pipe9,
		b.ENC_TYPE,'|' as Pipe10,
		year(dateadd(dd,b.ADMIT_DATE,'1960-01-01')) as ADMIT_DATE_YEAR,'|' as Pipe11,
		month(dateadd(dd,b.ADMIT_DATE,'1960-01-01')) as ADMIT_DATE_MONTH,'|' as Pipe12,
		b.ADMIT_DATE - c.FirstVisit as DAYS_from_FirstEncounter_Date,'ENDALONAEND' as lineEND
into #NextD_DIAGNOSIS_FINAL 
from /* provide name of table 1 here: */ #FinalTable1 c 
join  dbo.DIAGNOSIS b on c.PATID=b.PATID 
join dbo.DEMOGRAPHIC d on c.PATID=d.PATID
where convert(numeric(18,6),(b.ADMIT_DATE-d.BIRTH_DATE))/365.25 between @LowerAge and @UpperAge 
	and b.ADMIT_DATE between @LowerTimeFrame and @UpperTimeFrame;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
/* Save #NextD_DIAGNOSIS_FINAL as csv file. 
Use "|" symbol as field terminator and 
"ENDALONAEND" as row terminator. */ 
---------------------------------------------------------------------------------------------------------------
