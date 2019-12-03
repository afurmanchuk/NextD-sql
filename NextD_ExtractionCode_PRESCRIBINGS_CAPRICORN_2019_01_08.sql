---------------------------------------------------------------------------------------------------------------
-----                    Part 3: Prescibed medications for the study sample                               -----  
--------------------------------------------------------------------------------------------------------------- 
/* Tables for this eaxtraction: 
1. Table 1 (named here #Final_Table1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. PRESCRIBING, ENCOUNTER, and DEMOGRAPHIC tables from PCORNET.
3. Tabel with mapping (named here #GlobalIDtable) between PCORNET IDs and Global patient IDs provided by MRAIA. */
---------------------------------------------------------------------------------------------------------------
-----                            Declare study time frame variables:
use capricorn;/*Specify PCORI database name here*/
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
		i.PRESCRIBINGID,
		i.RXNORM_CUI,
		i.RX_ORDER_DATE_YEAR,
		i.RX_ORDER_DATE_MONTH,
		i.RX_ORDER_DATE_DAYSFROMFIRSTVISIT,
		i.RX_START_DATE_YEAR,
		i.RX_START_DATE_MONTH,
		i.RX_START_DATE_DAYSFROMFIRSTVISIT,
		i.RX_PROVIDERID,
		i.RX_DAYS_SUPPLY,
		i.RX_REFILLS,
		i.RX_BASIS,
		i.RAW_RX_MED_NAME  
into #NextD_PRESCRIBING
from (select c.PATID,
		a.ENCOUNTERID,
		b.PRESCRIBINGID,
		b.RXNORM_CUI,
		case when c.[Pregnancy1_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy1_Date]))>1 then 0 when c.[Pregnancy1_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy1_Date]))<=1 then 1 when c.[Pregnancy1_Date] is NULL then 0 end as C1,
		case when c.[Pregnancy2_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy2_Date]))>1 then 0 when c.[Pregnancy2_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy2_Date]))<=1 then 1 when c.[Pregnancy2_Date] is NULL then 0 end as C2,
		case when c.[Pregnancy3_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy3_Date]))>1 then 0 when c.[Pregnancy3_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy3_Date]))<=1 then 1 when c.[Pregnancy3_Date] is NULL then 0 end as C3,
		case when c.[Pregnancy4_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy4_Date]))>1 then 0 when c.[Pregnancy4_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy4_Date]))<=1 then 1 when c.[Pregnancy4_Date] is NULL then 0 end as C4,
		case when c.[Pregnancy5_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy5_Date]))>1 then 0 when c.[Pregnancy5_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy5_Date]))<=1 then 1 when c.[Pregnancy5_Date] is NULL then 0 end as C5,
		case when c.[Pregnancy6_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy6_Date]))>1 then 0 when c.[Pregnancy6_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy6_Date]))<=1 then 1 when c.[Pregnancy6_Date] is NULL then 0 end as C6,
		case when c.[Pregnancy7_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy7_Date]))>1 then 0 when c.[Pregnancy7_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy7_Date]))<=1 then 1 when c.[Pregnancy7_Date] is NULL then 0 end as C7,
		case when c.[Pregnancy8_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy8_Date]))>1 then 0 when c.[Pregnancy8_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy8_Date]))<=1 then 1 when c.[Pregnancy8_Date] is NULL then 0 end as C8,
		case when c.[Pregnancy9_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy9_Date]))>1 then 0 when c.[Pregnancy9_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy9_Date]))<=1 then 1 when c.[Pregnancy9_Date] is NULL then 0 end as C9,
		case when c.[Pregnancy10_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy10_Date]))>1 then 0 when c.[Pregnancy10_Date] is not NULL and ABS(datediff(yy,b.RX_ORDER_DATE,c.[Pregnancy10_Date]))<=1 then 1 when c.[Pregnancy10_Date] is NULL then 0 end as C10,
		year(b.RX_ORDER_DATE) as RX_ORDER_DATE_YEAR,
		month(b.RX_ORDER_DATE) as RX_ORDER_DATE_MONTH,
		datediff(dd,c.FirstVisit,b.RX_ORDER_DATE) as RX_ORDER_DATE_DAYSFROMFIRSTVISIT,
		b.RX_PROVIDERID,
		year(b.RX_START_DATE) as RX_START_DATE_YEAR,
		month(b.RX_START_DATE) as RX_START_DATE_MONTH,
		datediff(dd,c.FirstVisit,b.RX_START_DATE) as RX_START_DATE_DAYSFROMFIRSTVISIT,
		b.RX_DAYS_SUPPLY,
		b.RX_REFILLS,
		b.RX_BASIS,
		b.RAW_RX_MED_NAME
		from /* provide name of table 1 here: */ #Final_Table1 c 
		join [dbo].[ENCOUNTER] a on c.PATID=a.PATID
		join [dbo].[PRESCRIBING] b on c.PATID=b.PATID 
		join [dbo].[DEMOGRAPHIC] d on c.PATID=d.PATID
		where (datediff(yy,d.BIRTH_DATE,b.RX_ORDER_DATE) between @LowerAge and @UpperAge) and (b.RX_ORDER_DATE between @LowerTimeFrame and @UpperTimeFrame)
) i
where i.C1=0 and i.C1=0 and i.C2=0 and i.C3=0 and i.C4=0 and i.C5=0 and i.C6=0 and i.C7=0 and i.C8=0 and i.C9=0 and i.C10=0;
---------------------------------------------------------------------------------------------------------------
select d.GLOBALID,
		i.ENCOUNTERID,
		i.PRESCRIBINGID,
		i.RXNORM_CUI,
		i.RX_ORDER_DATE_YEAR,
		i.RX_ORDER_DATE_MONTH,
		i.RX_ORDER_DATE_DAYSFROMFIRSTVISIT,
		i.RX_START_DATE_YEAR,
		i.RX_START_DATE_MONTH,
		i.RX_START_DATE_DAYSFROMFIRSTVISIT,
		i.RX_PROVIDERID,
		i.RX_DAYS_SUPPLY,
		i.RX_REFILLS,
		i.RX_BASIS,
		i.RAW_RX_MED_NAME 
into #NextD_PRESCRIBING_FINAL
from #NextD_PRESCRIBING i 
join  /* provide name the table containing c.PATID,Hashes, and Global patient id*/ #GlobalIDtable d 
on i.PATID=d.PATID;
---------------------------------------------------------------------------------------------------------------
/* Save #NextD_PRESCRIBING_FINAL as csv file. 
Use "|" symbol as field terminator and 
"ENDALONAEND" as row terminator. */ 
---------------------------------------------------------------------------------------------------------------