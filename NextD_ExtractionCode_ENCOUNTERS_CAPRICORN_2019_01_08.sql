---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                             Part 2: Encounters for the study sample                                 -----  
--------------------------------------------------------------------------------------------------------------- 
/* Tables for this eaxtraction: 
1. Table 1 (named here #Final_Table1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. ENCOUNTER tables from PCORI.
3. Tabel with mapping (named here #GlobalIDtable) between PCORNET IDs and Global patient IDs provided by MRAIA. */
--------------------------------------------------------------------------------------------------------------- 
-----  Declare study time frame variables:
use capricorn;/*Specify PCORI database name here*/
DECLARE @studyTimeRestriction int;declare @UpperTimeFrame DATE; declare @LowerTimeFrame DATE;
-----                             Specify time frame and age limits                                       -----
--Set extraction time frame below. If time frames not set, the code will use the whole time frame available from the database
set @LowerTimeFrame='2010-01-01';
set @UpperTimeFrame='2019-10-31 23:59:59';/* insert here thw end exctraction date from iRB*/
--set age restrictions:
declare @UpperAge int; declare @LowerAge int;set @UpperAge=89; set @LowerAge=18;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
select a1.[PATID],
      a.ENCOUNTERID,
      a.PROVIDERID,
      year(a.ADMIT_DATE) as ADMIT_DATE_YEAR,
      month(a.ADMIT_DATE) as ADMIT_DATE_MONTH,
      datediff(dd,c.FirstVisit,a.ADMIT_DATE) as ADMIT_DATE_DAYSFROMFIRSTVISIT,
	  year(a.DISCHARGE_DATE) as DISCHARGE_DATE_YEAR,
      month(a.DISCHARGE_DATE) as DISCHARGE_DATE_MONTH,
      datediff(dd,c.FirstVisit,a.DISCHARGE_DATE) as DISCHARGE_DATE_DAYSFROMFIRSTVISIT,
      a.ENC_TYPE,
      a.FACILITYID,
      a.DISCHARGE_DISPOSITION,
      a.DISCHARGE_STATUS,
	  a.ADMITTING_SOURCE,
      a.FACILITY_TYPE
into #NEXTD_ENCOUNTERS
from /* provide name of table 1 here: */ #Final_Table1 c 
join [dbo].[ENCOUNTER] a on c.[PATID]=a.[PATID]
join [dbo].[DEMOGRAPHIC] b on c.[PATID]=b.[PATID]
where datediff(yy,b.BIRTH_DATE,a.ADMIT_DATE) between @LowerAge and @UpperAge 
		and a.ADMIT_DATE between @LowerTimeFrame and @UpperTimeFrame;
--------------------------------------------------------------------------------------------------------------- 
select a.GLOBALID,
	  a.ENCOUNTERID,
      a.PROVIDERID,
      a.ADMIT_DATE_YEAR,
      a.ADMIT_DATE_MONTH,
      a.ADMIT_DATE_DAYSFROMFIRSTVISIT,
	  a.DISCHARGE_DATE_YEAR,
      a.DISCHARGE_DATE_MONTH,
      a.DISCHARGE_DATE_DAYSFROMFIRSTVISIT,
      a.ENC_TYPE,
      a.FACILITYID,
      a.DISCHARGE_DISPOSITION,
      a.DISCHARGE_STATUS,
	  a.ADMITTING_SOURCE,
      a.FACILITY_TYPE
into #NextD_ENCOUNTER_FINAL
from #NEXTD_ENCOUNTERS a
join /* provide name the table containing c.PATID,Hashes, and Global patient id*/ #GlobalIDtable d 
on i.[PATID]=d.[PATID];
 --------------------------------------------------------------------------------------------------------------- 
 /* Save #NextD_ENCOUNTER_FINAL as csv file. 
Use "|" symbol as field terminator and 
"ENDALONAEND" as row terminator. */ 
--------------------------------------------------------------------------------------------------------------- 