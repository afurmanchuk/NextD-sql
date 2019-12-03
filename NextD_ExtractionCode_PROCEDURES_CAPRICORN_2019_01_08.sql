---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                             Part 8: Procedures for the study sample                                 -----  
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
/* Tables for this eaxtraction: 
1. Table 1 (named here #Final_Table1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. PROCEDURES and DEMOGRAPHIC table from PCORNET.
3. Tabel with mapping (named here #GlobalIDtable) between CAPRICORN IDs and Global patient IDs provided by MRAIA. */
---------------------------------------------------------------------------------------------------------------
-----                            Declare study time frame variables:                                      -----
use capricorn;/*Specify PCORI database name here*/
DECLARE @studyTimeRestriction int;declare @UpperTimeFrame DATE; declare @LowerTimeFrame DATE;
-----                             Specify time frame and age limits                                       -----
--Set extraction time frame below. If time frames not set, the code will use the whole time frame available from the database
set @LowerTimeFrame='2010-01-01';
set @UpperTimeFrame='2019-10-31 23:59:59';/* insert here thw end exctraction date from iRB*/
--set age restrictions:
declare @UpperAge int; declare @LowerAge int;set @UpperAge=89; set @LowerAge=18;
---------------------------------------------------------------------------------------------------------------
select c.PATID,
		b.ENCOUNTERID,
		b.PROCEDURESID,
		b.ENC_TYPE,
		year(b.ADMIT_DATE) as ADMIT_DATE_YEAR,
		month(b.ADMIT_DATE) as ADMIT_DATE_MONTH,
		datediff(dd,c.FirstVisit,b.ADMIT_DATE) as ADMIT_DATE_DAYSFROMFIRSTVISIT,
		b.PROVIDERID,
		year(b.PX_DATE) as PX_DATE_YEAR,
		month(b.PX_DATE) as PX_DATE_MONTH,
		datediff(dd,c.FirstVisit,b.PX_DATE) as PX_DATE_DAYSFROMFIRSTVISIT,
		b.PX,b.PX_TYPE ,
		b.PX_SOURCE,
		b.PPX,
		b.PROVIDERID
	  into #NextD_PROCEDURES
	  from /* provide name of table 1 here: */ #Final_Table1 c 
	  left join [dbo].[PROCEDURES] b on c.PATID=b.PATID 
	  left join dbo.DEMOGRAPHIC d on c.PATID=d.PATID
	  where (datediff(yy,d.BIRTH_DATE,b.ADMIT_DATE) between @LowerAge and @UpperAge) and (b.ADMIT_DATE between @LowerTimeFrame and @UpperTimeFrame);
---------------------------------------------------------------------------------------------------------------
select d.GLOBALID,
		i.ENCOUNTERID,
		i.PROCEDURESID,
		i.ENC_TYPE,
		i.ADMIT_DATE_YEAR,
		i.ADMIT_DATE_MONTH,
		i.ADMIT_DATE_DAYSFROMFIRSTVISIT,
		i.PX_DATE_YEAR,
		i.PX_DATE_MONTH,
		i.PX_DATE_DAYSFROMFIRSTVISIT,
		i.PX,
		i.PX_TYPE,
		i.PX_SOURCE,
		i.PPX,
		i.PROVIDERID
into #NextD_PROCEDURES_FINAL
from #NextD_PROCEDURES i 
join  /* provide name the table containing c.PATID,Hashes, and Global patient id*/ #GlobalIDtable d 
on i.PATID=c.PATID;
---------------------------------------------------------------------------------------------------------------
/* Save #NextD_PROCEDURES_FINAL as csv file. 
Use "|" symbol as field terminator and 
"ENDALONAEND" as row terminator. */ 
---------------------------------------------------------------------------------------------------------------