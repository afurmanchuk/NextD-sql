---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                             Part 10: DEATH_CAUSE for the study sample                                -----  
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
/* Tables for this eaxtraction: 
1. Table 1 (named here #FinalTable1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. DEATH_CAUSE table from PCORNET. */
---------------------------------------------------------------------------------------------------------------
use /*provide here the name of PCORI database here: */PCORI_SAS;
select c.PATID,
			year(dateadd(dd,b.DEATH_DATE,'1960-01-01')) as DEATH_DATE_YEAR,
			month(dateadd(dd,b.DEATH_DATE,'1960-01-01')) as DEATH_DATE_MONTH,
			b.DEATH_DATE-c.FirstVisit as DAYS_from_FirstEncounter_Date,
			b.DEATH_SOURCE 
into #NextD_DEATH_FINAL
from /* provide name of table 1 here: */ #FinalTable1 c 
left join [dbo].[DEATH] b on c.PATID=b.PATID;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
/* Save #NextD_DEATH_CAUSE_FINAL as csv file. 
Use "|" symbol as field terminator and 
"ENDALONAEND" as row terminator. */ 
---------------------------------------------------------------------------------------------------------------
