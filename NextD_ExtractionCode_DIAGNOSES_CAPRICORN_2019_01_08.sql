---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                             Part 7: Diagnoses for the study sample                                  -----  
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
/* Tables for this eaxtraction: 
1. Table 1 (named here #Final_Table1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. DIAGNOSIS and DEMOGRAPHIC table from PCORNET.
3. Tabel with mapping (named here #GlobalIDtable) between PCORNET IDs and Global patient IDs provided by MRAIA. */
---------------------------------------------------------------------------------------------------------------
-----                            Declare study time frame variables:                                      -----
use capricorn;
DECLARE @studyTimeRestriction int;declare @UpperTimeFrame DATE; declare @LowerTimeFrame DATE;
-----                             Specify time frame and age limits                                       -----
--Set extraction time frame below. If time frames not set, the code will use the whole time frame available from the database
set @LowerTimeFrame='2010-01-01';
set @UpperTimeFrame='2019-10-31 23:59:59';/* insert here thw end exctraction date from iRB*/
--set age restrictions:
declare @UpperAge int; declare @LowerAge int;set @UpperAge=89; set @LowerAge=18;
---------------------------------------------------------------------------------------------------------------
select i.PATID,
		i.ENCOUNTERID,
		i.DIAGNOSISID,
		i.DX,
		i.PDX,
		i.DX_TYPE,
		i.DX_SOURCE,
		i.DX_ORIGIN ,
		i.ENC_TYPE,
		i.ADMIT_DATE_YEAR, 
		i.ADMIT_DATE_MONTH, 
		i.ADMIT_DATE_DAYSFROMFISRTVISIT 
into #NextD_DIAGNOSIS 
from (select c.PATID,
		b.ENCOUNTERID,
		b.DIAGNOSISID,
		b.DX,
		b.PDX,
		b.DX_TYPE,
		b.DX_SOURCE,
		b.DX_ORIGIN ,
		b.ENC_TYPE,
		case when c.[Pregnancy1_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy1_Date]))>1 then 0 when c.[Pregnancy1_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy1_Date]))<=1 then 1 when c.[Pregnancy1_Date] is NULL then 0 end as C1,
		case when c.[Pregnancy2_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy2_Date]))>1 then 0 when c.[Pregnancy2_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy2_Date]))<=1 then 1 when c.[Pregnancy2_Date] is NULL then 0 end as C2,
		case when c.[Pregnancy3_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy3_Date]))>1 then 0 when c.[Pregnancy3_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy3_Date]))<=1 then 1 when c.[Pregnancy3_Date] is NULL then 0 end as C3,
		case when c.[Pregnancy4_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy4_Date]))>1 then 0 when c.[Pregnancy4_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy4_Date]))<=1 then 1 when c.[Pregnancy4_Date] is NULL then 0 end as C4,
		case when c.[Pregnancy5_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy5_Date]))>1 then 0 when c.[Pregnancy5_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy5_Date]))<=1 then 1 when c.[Pregnancy5_Date] is NULL then 0 end as C5,
		case when c.[Pregnancy6_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy6_Date]))>1 then 0 when c.[Pregnancy6_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy6_Date]))<=1 then 1 when c.[Pregnancy6_Date] is NULL then 0 end as C6,
		case when c.[Pregnancy7_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy7_Date]))>1 then 0 when c.[Pregnancy7_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy7_Date]))<=1 then 1 when c.[Pregnancy7_Date] is NULL then 0 end as C7,
		case when c.[Pregnancy8_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy8_Date]))>1 then 0 when c.[Pregnancy8_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy8_Date]))<=1 then 1 when c.[Pregnancy8_Date] is NULL then 0 end as C8,
		case when c.[Pregnancy9_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy9_Date]))>1 then 0 when c.[Pregnancy9_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy9_Date]))<=1 then 1 when c.[Pregnancy9_Date] is NULL then 0 end as C9,
		case when c.[Pregnancy10_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy10_Date]))>1 then 0 when c.[Pregnancy10_Date] is not NULL and ABS(datediff(yy,b.ADMIT_DATE,c.[Pregnancy10_Date]))<=1 then 1 when c.[Pregnancy10_Date] is NULL then 0 end as C10,
		year(b.ADMIT_DATE) as ADMIT_DATE_YEAR,
		month(b.ADMIT_DATE) as ADMIT_DATE_MONTH,
		datediff(dd,c.FirstVisit,b.ADMIT_DATE) as ADMIT_DATE_DAYSFROMFISRTVISIT
		from /* provide name of table 1 here: */ #Final_Table1 c 
		left join [dbo].[DIAGNOSIS] b on c.PATID=b.PATID 
		left join  dbo.DEMOGRAPHIC d on c.PATID=d.PATID
		where datediff(yy,d.BIRTH_DATE,b.ADMIT_DATE) between @LowerAge and @UpperAge 
				and b.ADMIT_DATE between @LowerTimeFrame and @UpperTimeFrame
	) i
where i.C1=0 and i.C1=0 and i.C2=0 and i.C3=0 and i.C4=0 and i.C5=0 and i.C6=0 and i.C7=0 and i.C8=0 and i.C9=0 and i.C10=0;
---------------------------------------------------------------------------------------------------------------
select d.GLOBALID,
		i.ENCOUNTERID,
		i.DIAGNOSISID,
		i.DX,
		i.PDX,
		i.DX_TYPE,
		i.DX_SOURCE,
		i.DX_ORIGIN ,
		i.ENC_TYPE,
		i.ADMIT_DATE_YEAR, 
		i.ADMIT_DATE_MONTH, 
		i.ADMIT_DATE_DAYSFROMFISRTVISIT 
into #NextD_DIAGNOSIS_FINAL
from #NextD_DIAGNOSIS i 
join  /* provide name the table containing c.PATID,Hashes, and Global patient id*/ #GlobalIDtable d 
on i.PATID=d.PATID;
---------------------------------------------------------------------------------------------------------------
/* Save #NextD_DIAGNOSIS_FINAL as csv file. 
Use "|" symbol as field terminator and 
"ENDALONAEND" as row terminator. */ 
---------------------------------------------------------------------------------------------------------------