---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                             Part 9: DEATH_CAUSE for the study sample                                -----  
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
/* Tables for this eaxtraction: 
1. Table 1 (named here #Final_Table1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. DEATH_CAUSE table from PCORNET.
3. Tabel with mapping (named here #GlobalIDtable) between PCORNET IDs and Global patient IDs provided by MRAIA. */
---------------------------------------------------------------------------------------------------------------
use capricorn;/*specify PCOR database here*/
select c.PATID,
		b.DEATH_CAUSE, 
		b.DEATH_CAUSE_CODE,
		b.DEATH_CAUSE_TYPE,
		b.DEATH_CAUSE_SOURCE,
		b.DEATH_CAUSE_CONFIDENCE 
into #NextD_DEATH_CAUSE
from /* provide name of table 1 here: */ #Final_Table1 c 
left join /* provide name of PCORNET table DEATH_CAUSE here: */ [dbo].[DEATH_CAUSE] b on c.PATID=b.PATID;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
select d.GLOBALID,i.DEATH_CAUSE, i.DEATH_CAUSE_CODE,i.DEATH_CAUSE_TYPE ,i.DEATH_CAUSE_SOURCE ,i.DEATH_CAUSE_CONFIDENCE
into #NextD_DEATH_CAUSE_FINAL
from #NextD_DEATH_CAUSE i join  /* provide name the table containing c.PATID,Hashes, and Global patient id*/ #GlobalIDtable d 
on i.PATID=d.PATID;
---------------------------------------------------------------------------------------------------------------
/* Save #NextD_DEATH_CAUSE_FINAL as csv file. 
Use "|" symbol as field terminator and 
"ENDALONAEND" as row terminator. */ 
---------------------------------------------------------------------------------------------------------------