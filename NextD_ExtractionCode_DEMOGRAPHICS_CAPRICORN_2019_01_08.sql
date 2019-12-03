---------------------------------------------------------------------------------------------------------------
-----                            Part 1: Demographics for the study sample                                -----  
--------------------------------------------------------------------------------------------------------------- 
/* Tables for this eaxtraction: 
1. Table 1 (named here #Final_Table1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. Demographics table from PCORNET.
3. External source table (#MaritalStatusTable) with marital status on patients in study sample.
4. Tabel with mapping (nmaed here #GlobalIDtable) between PCORNET IDs and Global patient IDs provided by MRAIA. */
--------------------------------------------------------------------------------------------------------------- 
use capricorn;/*Specify PCORI database name here*/
select c.PATID,
		year(a.BIRTH_DATE) as BIRTH_DATE_YEAR,
		month(a.BIRTH_DATE) as BIRTH_DATE_MONTH,
		datediff(dd,c.FirstVisit,a.BIRTH_DATE) as BIRTH_DATE_DAYSFROMFIRSTVISIT,
		a.SEX,
		a.RACE,
		a.HISPANIC,
		a.PAT_PREF_LANGUAGE_SPOKEN,
		b.MaritalStatus 
into #NextD_DEMOGRAPHIC
from /* provide name of table 1 here: */ #Final_Table1 c 
left join [dbo].[DEMOGRAPHIC] a on c.PATID =a.PATID 
left join /* provide name of external source table with marital status information here: */ #MaritalStatusTable b on c.PATID =b.PATID;
--------------------------------------------------------------------------------------------------------------- 
select d.GLOBALID,
		a.BIRTH_DATE_YEAR,
		a.BIRTH_DATE_MONTH,
		a.BIRTH_DATE_DAYSFROMFIRSTVISIT,
		a.SEX,
		a.RACE,
		a.HISPANIC,
		a.PAT_PREF_LANGUAGE_SPOKEN,
		b.MaritalStatus 
into #NextD_DEMOGRAPHIC_FINAL
from  #NextD_DEMOGRAPHIC a
join  /* provide name the table containing c.PATID,Hashes, and Global patient id*/ 
#GlobalIDtable d on a.PATID=d.PATID;
--------------------------------------------------------------------------------------------------------------- 
/* Save #NextD_DEMOGRAPHIC_FINAL as csv file. 
Use "|" symbol as field terminator and 
"ENDALONAEND" as row terminator. */ 
--------------------------------------------------------------------------------------------------------------- 
