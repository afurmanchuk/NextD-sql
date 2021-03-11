---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                             Part 7: Procedures for the study sample                                 -----  
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
/* Tables for this eaxtraction: 
1. Table 1 (named here #FinalTable1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. PROCEDURES and DEMOGRAPHIC table from PCORNET. */
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
	b.PROCEDURESID,'|' as Pipe3,
	b.ENC_TYPE,'|' as Pipe4,
	year(dateadd(dd,b.ADMIT_DATE,'1960-01-01')) as ADMIT_DATE_YEAR,'|' as Pipe5,
	month(dateadd(dd,b.ADMIT_DATE,'1960-01-01')) as ADMIT_DATE_MONTH,'|' as Pipe6,
	b.ADMIT_DATE - c.FirstVisit as DAYS_from_FirstEncounter_Date1,'|' as Pipe7,
	b.PROVIDERID,'|' as Pipe8,
	year(dateadd(dd,b.PX_DATE,'1960-01-01')) as PX_DATE_YEAR,'|' as Pipe9,
	month(dateadd(dd,b.PX_DATE,'1960-01-01')) as PX_DATE_MONTH,'|' as Pipe10,
	b.PX_DATE - c.FirstVisit as DAYS_from_FirstEncounter_Date2,'|' as Pipe11,
	b.PX,'|' as Pipe12,
	b.PPX,'|' as Pipe13,
	b.PX_TYPE ,'|' as Pipe14,
	b.PX_SOURCE,'ENDALONAEND' as lineEND
	into #NextD_PROCEDURES_FINAL
from /* provide name of table 1 here: */ #FinalTable1 c 
join /* provide name of PCORNET table PROCEDURES here: */ [dbo].[PROCEDURES] b on c.PATID=b.PATID 
join /* provide name of PCORNET table DEMOGRAPPHIC here: */ [dbo].DEMOGRAPHIC d on c.PATID=d.PATID
where convert(numeric(18,6),(b.ADMIT_DATE - d.BIRTH_DATE))/365.25 between @LowerAge and @UpperAge 
	and b.ADMIT_DATE between @LowerTimeFrame and @UpperTimeFrame;
---------------------------------------------------------------------------------------------------------------
