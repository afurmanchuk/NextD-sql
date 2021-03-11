---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                    Part 6: Dispensing medications for the study sample                              -----  
--------------------------------------------------------------------------------------------------------------- 
/* Tables for this eaxtraction: 
1. Table 1 (named here #FinalTable1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. DISPENSING and DEMOGRAPHIC table from PCORNET.*/
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
select c.PATID,'|' as Pipe,'|' as Pipe,
		b.DISPENSINGID,'|' as Pipe,
		b.NDC,'|' as Pipe,
		year(dateadd(dd,b.DISPENSE_DATE,'1960-01-01')) as DISPENSE_DATE_YEAR,'|' as Pipe,
		month(dateadd(dd,b.DISPENSE_DATE,'1960-01-01')) as DISPENSE_DATE_MONTH,'|' as Pipe,
		b.DISPENSE_DATE - c.FirstVisit as DAYS_from_FirstEncounter_Date,'|' as Pipe,
		b.DISPENSE_SUP,'|' as Pipe,
		b.DISPENSE_AMT,'|' as Pipe,
		b.RAW_NDC,'ENDALONAEND' as leinEND
into #NextD_DISPENSING_FINAL
from /* provide name of table 1 here: */ #FinalTable1 c 
join [dbo].[DISPENSING] b on c.PATID=b.PATID 
join dbo.DEMOGRAPHIC d on c.PATID=d.PATID
where convert(numeric(18,6),(b.DISPENSE_DATE -d.BIRTH_DATE))/365.25 between @LowerAge and @UpperAge  
	and b.DISPENSE_DATE between @LowerTimeFrame and  @UpperTimeFrame;
---------------------------------------------------------------------------------------------------------------
