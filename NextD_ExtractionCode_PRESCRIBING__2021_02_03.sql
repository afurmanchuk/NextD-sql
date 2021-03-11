---------------------------------------------------------------------------------------------------------------
-----                    Part 5: Prescibed medications for the study sample                               -----  
--------------------------------------------------------------------------------------------------------------- 
/* Tables for this eaxtraction: 
1.  PRESCRIBING, DEMOGRAPHIC, ENCOUNTER tables from PCORNET.
*/
---------------------------------------------------------------------------------------------------------------
use /*provide here the name of PCORI database here: */PCORI_SAS;
---------------------------------------------------------------------------------------------------------------
-----                            Declare study time frame variables:
DECLARE @studyTimeRestriction int;declare @UpperTimeFrame int; declare @LowerTimeFrame int;
-----                             Specify time frame and age limits                                       -----
--Set extraction time frame below. If time frames not set, the code will use the whole time frame available from the database
set @LowerTimeFrame=18263;--'2010-01-01';
set @UpperTimeFrame=22280;--'2020-12-31';
--set age restrictions:
declare @UpperAge int; declare @LowerAge int;set @UpperAge=89; set @LowerAge=18;
---------------------------------------------------------------------------------------------------------------
select c.PATID,'|' as Pipe1,
		a.ENCOUNTERID,'|' as Pipe2,
		b.PRESCRIBINGID,'|' as Pipe3,
		b.RXNORM_CUI,'|' as Pipe4,
		year(dateadd(dd,b.RX_ORDER_DATE,'1960-01-01')) as PX_ORDER_DATE_YEAR,'|' as Pipe,5
		month(dateadd(dd,b.RX_ORDER_DATE,'1960-01-01')) as PX_ORDER_DATE_MONTH,'|' as Pipe6,
		b.RX_ORDER_DATE - c.FirstVisit as DAYS_from_FirstEncounter_Date1,'|' as Pipe7,
		year(dateadd(dd,b.RX_START_DATE,'1960-01-01')) as RX_START_DATE_YEAR,'|' as Pipe8,
		month(dateadd(dd,b.RX_START_DATE,'1960-01-01')) as PX_START_DATE_MONTH,'|' as Pipe9,
		b.RX_START_DATE - c.FirstVisit as DAYS_from_FirstEncounter_Date2,'|' as Pipe10,
		b.RX_PROVIDERID,'|' as Pipe11,
		b.RX_DAYS_SUPPLY,'|' as Pipe12,
		b.RX_REFILLS ,'|' as Pipe13,
		b.RX_BASIS,'|' as Pipe14,
		b.RAW_RX_MED_NAME,'ENDALONAEND' as lineEND
into #NextD_PRESCRIBING_FINAL
from /* provide name of table 1 here: */ #FinalTable1 c 
join dbo.[ENCOUNTER] a on c.PATID=a.PATID
join  dbo.[PRESCRIBING] b on c.ENCOUNTERID=b.ENCOUNTERID 
join  [dbo].[DEMOGRAPHIC] d on c.PATID=d.PATID
where convert(numeric(18,6),(b.RX_ORDER_DATE-d.BIRTH_DATE))/365.25 between @LowerAge and @UpperAge 
	and b.RX_ORDER_DATE between @LowerTimeFrame and @UpperTimeFrame;
---------------------------------------------------------------------------------------------------------------
