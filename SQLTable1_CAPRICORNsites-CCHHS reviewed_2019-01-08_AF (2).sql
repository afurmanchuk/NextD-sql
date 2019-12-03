---------------------------------------------------------------------------------------------------------------
-----                                    Code producing Table 1:                                          -----  
-----           Study sample, flag for established patient, T2DM sample, Pregnancy events                 -----  
--------------------------------------------------------------------------------------------------------------- 
/* Tables for this eaxtraction: 
1. DIAGNOSIS,ENCOUNTER,DEMOGRAPHIC,PROCEDURES,LAB_RESULT_CM,PRESCRIBING tables from PCORNET.
2. CAP_ENCOUNTERS,CAP_DEMOGRAPHICS,CAP_DEATH,CAP_LABS tables from CAPRICORN.
3. Tabel with mapping (named here #GlobalIDtable) between PCORNET IDs and Global patient IDs provided by MRAIA. */
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                          Part 0: Defining Time farme for this study                               -----  
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
--In line 1185 specify database name with CAP tables;
use capricorn; /*specify PCOR database here*/
--declare study time frame variables:
DECLARE @studyTimeRestriction int;declare @UpperTimeFrame DATE; declare @LowerTimeFrame DATE;
---------------------------------------------------------------------------------------------------------------
-----              In this section User must provide time frame limits    
---------------------------------------------------------------------------------------------------------------
--Set your time frame below. If time frames not set, the code will use the whole time frame available from the database;
set @LowerTimeFrame='2010-01-01';
set @UpperTimeFrame='2019-10-31 23:59:59';--or specify current extraction  end date listed in iRB. 
--set age restrictions:
declare @UpperAge int; declare @LowerAge int;set @UpperAge=89; set @LowerAge=18;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                          Part 1: Defining Denominator or Study Sample                               -----  
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
-----                People with at least two encounters recorded on different days                       -----
-----                                                                                                     -----            
-----                       Encounter should meet the following requerements:                             -----
-----    Patient must be 18 years old >= age <= 89 years old during the encounter day.                    -----
-----    Encounter should be encounter types: 'AMBULATORY VISIT', 'EMERGENCY DEPARTMENT',                 -----
-----    'INPATIENT HOSPITAL STAY', 'OBSERVATIONAL STAY', 'NON-ACUTE INSTITUTIONAL STAY'.                 -----
-----                                                                                                     -----
-----          The date of the first encounter and total number of encounters is collected.               -----
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- Get all encounters for each patient sorted by date:
select e.PATID, e.ADMIT_DATE, row_number() over (partition by e.PATID order by e.ADMIT_DATE asc) rn 
into #Denominator_initial 
from dbo.ENCOUNTER e 
join dbo.DEMOGRAPHIC d 
on e.PATID=d.PATID
where d.BIRTH_DATE is not NULL and e.ENC_TYPE in ('IP','ED','OS','AV','IS') and (datediff(yy,d.BIRTH_DATE,e.ADMIT_DATE) between @LowerAge and @UpperAge) and (e.ADMIT_DATE between @LowerTimeFrame and  @UpperTimeFrame);
-- Collect visits reported on different days within the study period:
select uf.PATID, uf.ADMIT_DATE, row_number() over (partition by un.PATID order by uf.ADMIT_DATE asc) rn 
into #Denomtemp0
from #Denominator_initial un join #Denominator_initial uf on un.PATID = uf.PATID
where abs(datediff(dd,un.ADMIT_DATE,uf.ADMIT_DATE))>1;
-- Collect number of visits (from ones recorded on different days) for each person:
select x.PATID, count(distinct x.ADMIT_DATE) as NumberOfPermutations 
into #Denomtemp1 
from #Denomtemp0 x group by x.PATID order by x.PATID;
-- Collect date of the first visit:
select x.PATID, x.ADMIT_DATE as FirstVisit 
into #Denomtemp2 
from #Denomtemp0 x where x.rn=1;
---------------------------------------------------------------------------------------------------------------
-----                                    Part 2: Defining Pregnancy                                       ----- 
---------------------------------------------------------------------------------------------------------------
-----                             People with pregnancy-related encounters                                -----
-----                                                                                                     -----            
-----                       Encounter should meet the following requerements:                             -----
-----           Patient must be 18 years old >= age <= 89 years old during the encounter day.             -----
-----                                                                                                     -----
-----                 The date of the first encounter for each pregnancy is collected.                    -----
---------------------------------------------------------------------------------------------------------------
-- Cases with miscarriage, abortion, pregnancy, birth and pregnancy related complications diagnosis codes diagnosis codes:
select dia.PATID, dia.ADMIT_DATE as ADMIT_DATE
into #Miscarr_Abort
	from dbo.DIAGNOSIS as dia join #Denomtemp2 w on dia.PATID=w.PATID
	join dbo.ENCOUNTER e on dia.ENCOUNTERID=e.ENCOUNTERID 
	join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
	where (((dia.DX like '63[0-9]._%' or dia.DX like '6[4-7][0-9]._%' or dia.DX like 'V2[2-3].%' or dia.DX like 'V28.%') and dia.DX_TYPE = '09') or 
		  ((dia.DX like 'O%' or dia.DX like 'A34.%' or dia.DX like 'Z3[3-4].%' or dia.DX like 'Z36%') and dia.DX_TYPE = '10')
		  )
		and datediff(yy,d.BIRTH_DATE,dia.ADMIT_DATE) between @LowerAge and @UpperAge
		and dia.ADMIT_DATE between @LowerTimeFrame and  @UpperTimeFrame;
-- Cases with delivery procedures in ICD-9 coding:
select p.PATID, p.ADMIT_DATE as ADMIT_DATE
into #DelivProc 
from dbo.PROCEDURES as p 
	join #Denomtemp2 w on p.PATID=w.PATID
	join dbo.ENCOUNTER e on p.ENCOUNTERID=e.ENCOUNTERID 
	join dbo.DEMOGRAPHIC d on e.PATID=d.PATID	
	where ((p.PX like '7[2-5]._%' and p.PX_TYPE = '09') or (p.PX like '10%' and p.PX_TYPE = '10') or (p.PX like '59[0-9][0-9][0-9]' and p.PX_TYPE='CH') 
		  )
		and (datediff(yy,d.BIRTH_DATE,p.ADMIT_DATE) between @LowerAge and @UpperAge)
		and p.ADMIT_DATE between @LowerTimeFrame and  @UpperTimeFrame;
---------------------------------------------------------------------------------------------------------------
-- Collect all encounters related to pregnancy:
select x.PATID,x.ADMIT_DATE into #AllPregnancyWithAllDates
from
	(select a.PATID, a.ADMIT_DATE from #Miscarr_Abort as a
	union
	select c.PATID, c.ADMIT_DATE from #DelivProc as c
	)x
group by x.PATID, x.ADMIT_DATE;
---------------------------------------------------------------------------------------------------------------
-- Find separate pregnancy events:                                   
-- Calculate time difference between each pregnancy encounter, select the first encounter of each pregnancy event:
select x2.PATID,x2.ADMIT_DATE,x2.dif 
into #DeltasPregnancy
from
	(select x.PATID,x.ADMIT_DATE,DATEDIFF(m, Lag(x.ADMIT_DATE, 1,NULL) OVER(partition by x.PATID ORDER BY x.ADMIT_DATE), x.ADMIT_DATE) as dif
	from #AllPregnancyWithAllDates x
	)x2
where x2.dif is NULL or x2.dif>=12;
-- Number pregnancies:
select x.PATID, x.ADMIT_DATE, row_number() over (partition by x.PATID order by x.ADMIT_DATE asc) rn 
into #NumberPregnancy
from #DeltasPregnancy x;
-- Transponse pregnancy table into single row per patient. Currently allows 21 sepearate pregnacy events:
select * 
into #FinalPregnancy
from
	(select [PATID], [ADMIT_DATE], [rn]
	FROM   #NumberPregnancy x) as SourceTable
PIVOT
	(max(ADMIT_DATE)
    for [rn] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
	) as PivotTable;     
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                 Part3: Combine results from all parts of the code into final table:                 -----
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
select a.PATID as PATID, b.FirstVisit, a.NumberOfPermutations as NumerOfVisits,/* x.EventDate as DMonsetDate,*/ d.DEATH_DATE, 
p.[1] as Pregnancy1_Date, p.[2] as Pregnancy2_Date, p.[3] as Pregnancy3_Date, p.[4] as Pregnancy4_Date, p.[5] as Pregnancy5_Date,
p.[6] as Pregnancy6_Date, p.[7] as Pregnancy7_Date, p.[8] as Pregnancy8_Date, p.[9] as Pregnancy9_Date, p.[10] as Pregnancy10_Date
into #FinalStatTable01
from #Denomtemp1 a left join #Denomtemp2 b on a.PATID=b.PATID
left join dbo.DEATH d on a.PATID=d.PATID
left join #FinalPregnancy p on a.PATID=p.PATID;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                         Part 1: Defining Deabetes Mellitus sample                                   ----- 
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----        People with HbA1c having two measures on different days within 2 years interval              -----
-----                                                                                                     -----            
-----                         Lab should meet the following requerements:                                 -----
-----    Patient must be 18 years old >= age <= 89 years old during the lab ordering day.                 -----
-----    Lab value is >= 6.5 %.                                                                           -----
-----    Lab name is 'A1C' or LOINC codes '17855-8', '4548-4','4549-2','17856-6','41995-2',               -----
-----    '59261-8','62388-4','71875-9','54039-3'                                                          -----
-----    Lab should meet requerement for encounter types: 'AMBULATORY VISIT', 'EMERGENCY DEPARTMENT',     -----
-----    'INPATIENT HOSPITAL STAY', 'OBSERVATIONAL STAY', 'NON-ACUTE INSTITUTIONAL STAY'.                 -----
-----                                                                                                     -----
-----                  The first pair of labs meeting requerements is collected.                          -----
-----     The date of the first HbA1c lab out the first pair will be recorded as initial event.           -----
---------------------------------------------------------------------------------------------------------------
-- Get all labs for each patient sorted by date:
select i2.PATID, i2.LAB_ORDER_DATE, row_number() over (partition by i2.PATID order by i2.LAB_ORDER_DATE asc) rn 
into #A1c_initial
from
	(select i.*,
	case when i.[1] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[1]))>1 then 0 when i.[1] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[1]))<=1 then 1 when i.[1] is NULL then 0 end as C1,
	case when i.[2] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[2]))>1 then 0 when i.[2] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[2]))<=1 then 1 when i.[2] is NULL then 0 end as C2,
	case when i.[3] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[3]))>1 then 0 when i.[3] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[3]))<=1 then 1 when i.[3] is NULL then 0 end as C3,
	case when i.[4] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[4]))>1 then 0 when i.[4] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[4]))<=1 then 1 when i.[4] is NULL then 0 end as C4,
	case when i.[5] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[5]))>1 then 0 when i.[5] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[5]))<=1 then 1 when i.[5] is NULL then 0 end as C5,
	case when i.[6] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[6]))>1 then 0 when i.[6] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[6]))<=1 then 1 when i.[6] is NULL then 0 end as C6,
	case when i.[7] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[7]))>1 then 0 when i.[7] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[7]))<=1 then 1 when i.[7] is NULL then 0 end as C7,
	case when i.[8] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[8]))>1 then 0 when i.[8] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[8]))<=1 then 1 when i.[8] is NULL then 0 end as C8,
	case when i.[9] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[9]))>1 then 0 when i.[9] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[9]))<=1 then 1 when i.[9] is NULL then 0 end as C9,
	case when i.[10] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[10]))>1 then 0 when i.[10] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[10]))<=1 then 1 when i.[10] is NULL then 0 end as C10
	from 
		(select l.PATID, l.LAB_ORDER_DATE as LAB_ORDER_DATE,p.[1],p.[2],p.[3],p.[4],p.[5],p.[6],p.[7],p.[8],p.[9],p.[10]
		from dbo.LAB_RESULT_CM l join #Denomtemp2 w on l.PATID=w.PATID
		join dbo.ENCOUNTER e on l.ENCOUNTERID=e.ENCOUNTERID 
		join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
		left join #FinalPregnancy p on l.PATID=p.PATID
		where
			(l.[RAW_LAB_NAME] like '%HEMOGLOBIN A1C%' or l.[RAW_LAB_NAME] like '%A1C%' or l.[RAW_LAB_NAME] like '%HA1C%' or l.[RAW_LAB_NAME] like '%HbA1C%' or 
			l.LAB_LOINC in ('17855-8', '4548-4','4549-2','17856-6','41995-2','59261-8','62388-4','71875-9','54039-3'))
			and l.RESULT_NUM >6.5 and l.RESULT_UNIT in ('PERCENT','%')
			and (datediff(yy,d.BIRTH_DATE,l.LAB_ORDER_DATE) between @LowerAge and @UpperAge) 
			and l.LAB_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame
		) i
	) i2
where i2.C1=0 and i2.C1=0 and i2.C2=0 and i2.C3=0 and i2.C4=0 and i2.C5=0 and i2.C6=0 and i2.C7=0 and i2.C8=0 and i2.C9=0 and i2.C10=0;
-- The first date out the first pair of encounters is selected:
select uf.PATID, uf.LAB_ORDER_DATE,row_number() over (partition by un.PATID order by uf.LAB_ORDER_DATE asc) rn 
into #temp1
from #A1c_initial un join #A1c_initial uf on un.PATID = uf.PATID
where abs(datediff(dd,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))>1 and abs(datediff(yy,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))<=2;
select x.PATID, x.LAB_ORDER_DATE as EventDate into #A1c_final_FirstPair from #temp1 x where x.rn=1; 
---------------------------------------------------------------------------------------------------------------
-----     People with fasting glucose having two measures on different days within 2 years interval       -----
-----                                                                                                     -----            
-----                         Lab should meet the following requerements:                                 -----
-----    Patient must be 18 years old >= age <= 89 years old during the lab ordering day.                 -----
-----    Lab value is >= 126 mg/dL.                                                                       -----
-----    (LOINC codes '1558-6',  '10450-5', '1554-5', '17865-7','35184-1')                                -----
-----    Lab should meet requerement for encounter types: 'AMBULATORY VISIT', 'EMERGENCY DEPARTMENT',     -----
-----    'INPATIENT HOSPITAL STAY', 'OBSERVATIONAL STAY', 'NON-ACUTE INSTITUTIONAL STAY'.                 -----
-----                                                                                                     -----
-----                   The first pair of labs meeting requerements is collected.                         -----
-----   The date of the first fasting glucose lab out the first pair will be recorded as initial event.   -----
---------------------------------------------------------------------------------------------------------------
-----                                    Not available in PCORNET                                         -----
-----                               extraction is done from side table                                    -----
---------------------------------------------------------------------------------------------------------------
-- Get all labs for each patient sorted by date:
select i2.PATID, i2.LAB_ORDER_DATE, row_number() over (partition by i2.PATID order by i2.LAB_ORDER_DATE asc) rn 
into #FG_initial
from
	(select i.*,
	case when i.[1] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[1]))>1 then 0 when i.[1] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[1]))<=1 then 1 when i.[1] is NULL then 0 end as C1,
	case when i.[2] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[2]))>1 then 0 when i.[2] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[2]))<=1 then 1 when i.[2] is NULL then 0 end as C2,
	case when i.[3] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[3]))>1 then 0 when i.[3] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[3]))<=1 then 1 when i.[3] is NULL then 0 end as C3,
	case when i.[4] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[4]))>1 then 0 when i.[4] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[4]))<=1 then 1 when i.[4] is NULL then 0 end as C4,
	case when i.[5] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[5]))>1 then 0 when i.[5] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[5]))<=1 then 1 when i.[5] is NULL then 0 end as C5,
	case when i.[6] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[6]))>1 then 0 when i.[6] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[6]))<=1 then 1 when i.[6] is NULL then 0 end as C6,
	case when i.[7] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[7]))>1 then 0 when i.[7] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[7]))<=1 then 1 when i.[7] is NULL then 0 end as C7,
	case when i.[8] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[8]))>1 then 0 when i.[8] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[8]))<=1 then 1 when i.[8] is NULL then 0 end as C8,
	case when i.[9] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[9]))>1 then 0 when i.[9] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[9]))<=1 then 1 when i.[9] is NULL then 0 end as C9,
	case when i.[10] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[10]))>1 then 0 when i.[10] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[10]))<=1 then 1 when i.[10] is NULL then 0 end as C10
	from 
		(select l.PATID as PATID, l.LAB_ORDER_DATE,p.[1],p.[2],p.[3],p.[4],p.[5],p.[6],p.[7],p.[8],p.[9],p.[10]
		from dbo.LAB_RESULT_CM l join #Denomtemp2 w on l.PATID=w.PATID
		join dbo.ENCOUNTER e on l.ENCOUNTERID=e.ENCOUNTERID 
		join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
		left join #FinalPregnancy p on l.PATID=p.PATID
		where
			l.LAB_LOINC in ('1558-6',  '10450-5', '1554-5', '17865-7','35184-1') 
			and l.RESULT_NUM >= 126 and l.RESULT_UNIT='mg/dL' and l.RESULT_NUM is not NULL 
			and datediff(yy,d.BIRTH_DATE,l.LAB_ORDER_DATE) between @LowerAge and @UpperAge
			and l.LAB_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame
		) i
	) i2
where i2.C1=0 and i2.C1=0 and i2.C2=0 and i2.C3=0 and i2.C4=0 and i2.C5=0 and i2.C6=0 and i2.C7=0 and i2.C8=0 and i2.C9=0 and i2.C10=0;
-- The first date out the first pair of encounters is selected:		
select uf.PATID, uf.LAB_ORDER_DATE,
row_number() over (partition by un.PATID order by uf.LAB_ORDER_DATE asc) rn into #temp2
from #FG_initial un join #FG_initial uf on un.PATID = uf.PATID
where abs(datediff(dd,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))>1 and abs(datediff(yy,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))<=2;
select x.PATID, x.LAB_ORDER_DATE as EventDate into #FG_final_FirstPair from #temp2 x where x.rn=1; 
---------------------------------------------------------------------------------------------------------------
-----     People with random glucose having two measures on different days within 2 years interval        -----
-----                                                                                                     -----            
-----                         Lab should meet the following requerements:                                 -----
-----    Patient must be 18 years old >= age <= 89 years old during the lab ordering day.                 -----
-----    Lab value is >= 200 mg/dL.                                                                       -----
-----    (LOINC codes '2345-7', '2339-0','10450-5','17865-7','1554-5','6777-7','54246-4',                 -----
-----    '2344-0','41652-9')                                                                              -----
-----    Lab should meet requerement for encounter types: 'AMBULATORY VISIT', 'EMERGENCY DEPARTMENT',     -----
-----    'INPATIENT HOSPITAL STAY', 'OBSERVATIONAL STAY', 'NON-ACUTE INSTITUTIONAL STAY'.                 -----
-----                                                                                                     -----
-----                   The first pair of labs meeting requerements is collected.                         -----
-----   The date of the first random glucose lab out the first pair will be recorded as initial event.    -----
---------------------------------------------------------------------------------------------------------------
-----                                    Not available in PCORNET                                         -----
-----                               extraction is done from side table                                    -----
---------------------------------------------------------------------------------------------------------------
-- Get all labs for each patient sorted by date:
select i2.PATID, i2.LAB_ORDER_DATE, row_number() over (partition by i2.PATID order by i2.LAB_ORDER_DATE asc) rn 
into #RG_initial
from
	(select i.*,
	case when i.[1] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[1]))>1 then 0 when i.[1] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[1]))<=1 then 1 when i.[1] is NULL then 0 end as C1,
	case when i.[2] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[2]))>1 then 0 when i.[2] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[2]))<=1 then 1 when i.[2] is NULL then 0 end as C2,
	case when i.[3] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[3]))>1 then 0 when i.[3] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[3]))<=1 then 1 when i.[3] is NULL then 0 end as C3,
	case when i.[4] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[4]))>1 then 0 when i.[4] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[4]))<=1 then 1 when i.[4] is NULL then 0 end as C4,
	case when i.[5] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[5]))>1 then 0 when i.[5] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[5]))<=1 then 1 when i.[5] is NULL then 0 end as C5,
	case when i.[6] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[6]))>1 then 0 when i.[6] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[6]))<=1 then 1 when i.[6] is NULL then 0 end as C6,
	case when i.[7] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[7]))>1 then 0 when i.[7] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[7]))<=1 then 1 when i.[7] is NULL then 0 end as C7,
	case when i.[8] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[8]))>1 then 0 when i.[8] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[8]))<=1 then 1 when i.[8] is NULL then 0 end as C8,
	case when i.[9] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[9]))>1 then 0 when i.[9] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[9]))<=1 then 1 when i.[9] is NULL then 0 end as C9,
	case when i.[10] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[10]))>1 then 0 when i.[10] is not NULL and ABS(datediff(yy,i.LAB_ORDER_DATE,i.[10]))<=1 then 1 when i.[10] is NULL then 0 end as C10
	from (
		select l.PATID as PATID, l.LAB_ORDER_DATE,p.[1],p.[2],p.[3],p.[4],p.[5],p.[6],p.[7],p.[8],p.[9],p.[10]
		from dbo.LAB_RESULT_CM l join #Denomtemp2 w on l.PATID=w.PATID
		join dbo.ENCOUNTER e on l.ENCOUNTERID=e.ENCOUNTERID 
		join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
		left join #FinalPregnancy p on l.PATID=p.PATID
		where
			(l.LAB_LOINC in ('2345-7', '2339-0','10450-5','17865-7','1554-5','6777-7','54246-4','2344-0','41652-9')
			and l.RESULT_NUM >= 200 and l.RESULT_UNIT='mg/dL' and RESULT_NUM is not NULL) 
			and datediff(yy, d.BIRTH_DATE,l.LAB_ORDER_DATE) between @LowerAge and @UpperAge
			and l.LAB_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame
		) i
	) i2
where i2.C1=0 and i2.C1=0 and i2.C2=0 and i2.C3=0 and i2.C4=0 and i2.C5=0 and i2.C6=0 and i2.C7=0 and i2.C8=0 and i2.C9=0 and i2.C10=0;
-- The first date out the first pair of encounters is selected:		
select uf.PATID, uf.LAB_ORDER_DATE, row_number() over (partition by un.PATID order by uf.LAB_ORDER_DATE asc) rn 
into #temp3
from #RG_initial un join #RG_initial uf on un.PATID = uf.PATID
where abs(datediff(dd,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))>1 and abs(datediff(yy,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))<=2;
select x.PATID, x.LAB_ORDER_DATE as EventDate into #RG_final_FirstPair from #temp3 x where x.rn=1; 
---------------------------------------------------------------------------------------------------------------
-----     People with one random glucose & one HbA1c having both measures on different days within        -----
-----                                        2 years interval                                             -----
-----                                                                                                     -----            
-----                         Lab should meet the following requerements:                                 -----
-----    Patient must be 18 years old >= age <= 89 years old during the lab ordering day.                 -----
-----    See corresponding sections above for the Lab values requerements.                                -----  
-----    Lab should meet requerement for encounter types: 'AMBULATORY VISIT', 'EMERGENCY DEPARTMENT',     -----
-----    'INPATIENT HOSPITAL STAY', 'OBSERVATIONAL STAY', 'NON-ACUTE INSTITUTIONAL STAY'.                 -----
-----                                                                                                     -----
-----               The first pair of HbA1c labs meeting requerements is collected.                       -----
-----        The date of the first lab out the first pair will be recorded as initial event.              -----
---------------------------------------------------------------------------------------------------------------
-- Get lab values from corresponding tables produced above:
select uf.PATID, uf.LAB_ORDER_DATE as RG_date, un.LAB_ORDER_DATE as A1c_date,row_number() over (partition by un.PATID order by CASE WHEN uf.LAB_ORDER_DATE  < un.LAB_ORDER_DATE THEN uf.LAB_ORDER_DATE ELSE un.LAB_ORDER_DATE END asc) rn 
into #temp4
from #A1c_initial un join #RG_initial uf on un.PATID = uf.PATID
where abs(datediff(dd,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))>1 and abs(datediff(yy,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))<=2;
-- Select the date for the first lab within the first pair:
select x.PATID, case when RG_date < A1c_date then RG_date
				when RG_date > A1c_date then A1c_date else RG_date
				end as EventDate 
into #A1cRG_final_FirstPair
from #temp4 x where rn=1;
---------------------------------------------------------------------------------------------------------------
-----     People with one fasting glucose & one HbA1c having both measures on different days within       -----
-----                                        2 years interval                                             -----
-----                                                                                                     -----            
-----                         Lab should meet the following requerements:                                 -----
-----    Patient must be 18 years old >= age <= 89 years old during the lab ordering day.                 -----
-----    See corresponding sections above for the Lab values requerements.                                -----  
-----    Lab should meet requerement for encounter types: 'AMBULATORY VISIT', 'EMERGENCY DEPARTMENT',     -----
-----    'INPATIENT HOSPITAL STAY', 'OBSERVATIONAL STAY', 'NON-ACUTE INSTITUTIONAL STAY'.                 -----
-----                                                                                                     -----
-----               The first pair of HbA1c labs meeting requerements is collected.                       -----
-----           The date of the first lab out the first pair will be recorded as initial event.           -----
---------------------------------------------------------------------------------------------------------------
-- Get lab values from corresponding tables produced above:
select uf.PATID, uf.LAB_ORDER_DATE as FG_date, un.LAB_ORDER_DATE as A1c_date,row_number() over (partition by un.PATID order by CASE WHEN uf.LAB_ORDER_DATE  < un.LAB_ORDER_DATE THEN uf.LAB_ORDER_DATE ELSE un.LAB_ORDER_DATE END asc) rn 
into #temp5
from #A1c_initial un join #FG_initial uf on un.PATID = uf.PATID
where abs(datediff(dd,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))>1 and abs(datediff(yy,un.LAB_ORDER_DATE,uf.LAB_ORDER_DATE))<=2;
-- Select the date for the first lab within the first pair:
select x.PATID,case when FG_date < A1c_date then FG_date
				when FG_date > A1c_date then A1c_date else FG_date
				end as EventDate into #A1cFG_final_FirstPair
from #temp5 x where rn=1;
---------------------------------------------------------------------------------------------------------------
-----               People with two visits (inpatient, outpatient, or emergency department)               -----
-----             relevant to type 1 Diabetes Mellitus or type 2 Diabetes Mellitus diagnosis              -----
-----                        recorded on different days within 2 years interval                           -----
-----                                                                                                     -----            
-----                         Visit should meet the following requerements:                               -----
-----    Patient must be 18 years old >= age <= 89 years old during on the visit day.                     -----
-----    Visit should should be of encounter types: 'AMBULATORY VISIT', 'EMERGENCY DEPARTMENT',           -----
-----    'INPATIENT HOSPITAL STAY', 'OBSERVATIONAL STAY', 'NON-ACUTE INSTITUTIONAL STAY'.                 -----
-----                                                                                                     -----
-----                  The first pair of visits meeting requerements is collected.                        -----
-----     The date of the first visit out the first pair will be recorded as initial event.               -----
---------------------------------------------------------------------------------------------------------------
-- Get all visits of specified types for each patient sorted by date:
select i2.PATID, i2.ADMIT_DATE, row_number() over (partition by i2.PATID order by i2.ADMIT_DATE asc) rn 
into #Visits_initial
from
	(select i.*,
	case when i.[1] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[1]))>1 then 0 when i.[1] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[1]))<=1 then 1 when i.[1] is NULL then 0 end as C1,
	case when i.[2] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[2]))>1 then 0 when i.[2] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[2]))<=1 then 1 when i.[2] is NULL then 0 end as C2,
	case when i.[3] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[3]))>1 then 0 when i.[3] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[3]))<=1 then 1 when i.[3] is NULL then 0 end as C3,
	case when i.[4] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[4]))>1 then 0 when i.[4] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[4]))<=1 then 1 when i.[4] is NULL then 0 end as C4,
	case when i.[5] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[5]))>1 then 0 when i.[5] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[5]))<=1 then 1 when i.[5] is NULL then 0 end as C5,
	case when i.[6] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[6]))>1 then 0 when i.[6] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[6]))<=1 then 1 when i.[6] is NULL then 0 end as C6,
	case when i.[7] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[7]))>1 then 0 when i.[7] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[7]))<=1 then 1 when i.[7] is NULL then 0 end as C7,
	case when i.[8] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[8]))>1 then 0 when i.[8] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[8]))<=1 then 1 when i.[8] is NULL then 0 end as C8,
	case when i.[9] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[9]))>1 then 0 when i.[9] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[9]))<=1 then 1 when i.[9] is NULL then 0 end as C9,
	case when i.[10] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[10]))>1 then 0 when i.[10] is not NULL and ABS(datediff(yy,i.ADMIT_DATE,i.[10]))<=1 then 1 when i.[10] is NULL then 0 end as C10
	from (
		select e.PATID, l.ADMIT_DATE as ADMIT_DATE,p.[1],p.[2],p.[3],p.[4],p.[5],p.[6],p.[7],p.[8],p.[9],p.[10]
		from dbo.DIAGNOSIS l join #Denomtemp2 w on l.PATID=w.PATID
		join dbo.ENCOUNTER e on l.ENCOUNTERID=e.ENCOUNTERID 
		join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
		left join #FinalPregnancy p on l.PATID=p.PATID
		where
			(((l.DX like '250.%' or l.DX like '357.2' or l.DX like '362.0[1-7]')and l.DX_TYPE = '09') or 
			((l.DX like 'E1[0,1].%' or l.DX like 'E08.42' or l.DX like 'E13.42') and l.DX_TYPE = '10')) 
			and l.ENC_TYPE in ('IP','ED','OS','AV','IS') and datediff(yy, d.BIRTH_DATE, l.ADMIT_DATE) between @LowerAge and @UpperAge
			and l.ADMIT_DATE between @LowerTimeFrame and  @UpperTimeFrame
		) i
	) i2
where i2.C1=0 and i2.C1=0 and i2.C2=0 and i2.C3=0 and i2.C4=0 and i2.C5=0 and i2.C6=0 and i2.C7=0 and i2.C8=0 and i2.C9=0 and i2.C10=0;	
-- Select the date for the first visit within the first pair:
select uf.PATID, uf.ADMIT_DATE,row_number() over (partition by un.PATID order by uf.ADMIT_DATE asc) rn 
into #temp6
from #Visits_initial un join #Visits_initial uf on un.PATID = uf.PATID
where abs(datediff(dd,un.ADMIT_DATE,uf.ADMIT_DATE))>1 and abs(datediff(yy,un.ADMIT_DATE,uf.ADMIT_DATE))<=2;
select x.PATID, x.ADMIT_DATE as EventDate into #Visits_final_FirstPair from #temp6 x where x.rn=1; 
---------------------------------------------------------------------------------------------------------------
-----            People with at least one ordered medications specific to Diabetes Mellitus               -----
-----                                                                                                     -----            
-----                         Medication should meet the following requerements:                          -----
-----     Patient must be 18 years old >= age <= 89 years old during the ordering of medication           -----
-----    Medication should relate to encounter types:'AMBULATORY VISIT', 'EMERGENCY DEPARTMENT',          -----
-----    'INPATIENT HOSPITAL STAY', 'OBSERVATIONAL STAY', 'NON-ACUTE INSTITUTIONAL STAY'.                 -----
-----                                                                                                     -----
-----                The date of the first medication meeting requerements is collected.                  -----
---------------------------------------------------------------------------------------------------------------
--  Sulfonylurea:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #SulfonylureaByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%Acetohexamide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%D[i,y]melor%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%glimep[e,i]ride%') 
		--This is combination of glimeperide-rosiglitazone :
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Avandaryl%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Amaryl%') 
		--this is combination of glimepiride-pioglitazone:
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Duetact') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%gliclazide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Uni Diamicron%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%glipizide%') 
		--this is combination of metformin-glipizide :
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Metaglip%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glucotrol%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Min[i,o]diab%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glibenese%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glucotrol XL%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glipizide XL%')
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%glyburide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glucovance%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%glibenclamide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%DiaBeta%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glynase%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Micronase%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%chlorpropamide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Diabinese%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Apo-Chlorpropamide%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glucamide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Novo-Propamide%')   
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulase%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%tolazamide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Tolinase%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glynase PresTab%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Tolamide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%tolbutamide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Orinase%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Tol-Tab%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Apo-Tolbutamide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Novo-Butamide%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glyclopyramide%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Deamelin[-]S%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Gliquidone%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glurenorm%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIBORNURIDE %')   
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLUTRIL%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIBORNURID%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIBORNURIDA%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIBORNURIDE%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIBORNURIDUM%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLYMIDINE SODIUM%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLYCODIAZINE%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GONDAFON%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIDIAZINE%')  
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLYMIDINE%') 
		)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #SulfonylureaByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1007411','1007582','1008873','102845','102846','102847','102848','102849','102850','105369','105371','105372','105373','105374','10633','10635','1153126','1153127','1155467','1155468','1155469','1155470','1155471','1155472','1156197','1156198','1156199','1156200','1156201','1157121','1157122','1157238','1157239','1157240','1157241','1157242','1157243','1157244','1157245','1157246','1157247','1157642','1157643','1157644','1157805','1157806','1165203','1165204','1165205','1165206','1165207','1165208','1165845','1169680','1169681','1170663','1170664','1171233','1171234','1171246','1171247','1171929','1171930','1171933','1171934','1171961','1171962','1173427','1173428','1175878','1175879','1175880','1175881','1176496','1176497','1177973','1177974','1178082','1178083','1179112','1179113','1179291','1179292','1183952','1183954','1183958','1361492','1361493','1361494','1361495','151615','151616','151822','153591','153592','153842','153843','153844','153845','173','197306','197307','197495','197496','197737','198291','198292','198293','198294','199245','199246','199247','199825','201056','201057','201058','201059','201060','201061','201062','201063','201064','201919','201921','201922','203289','203295','203679','203680','203681','205828','205830','205872','205873','205875','205876','205879','205880','207953','207954','207955','208012','209204','214106','214107','217360','217364','217370','218942','220338','221173','227211','2404','245266','246391','246522','246523','246524','250919','252259','252960','25789','25793','260286','260287','261351','261532','261974','285129','310488','310489','310490','310534','310536','310537','310539','313418','313419','314000','314006','315107','315239','315273','315274','315647','315648','315978','315979','315980','315987','315988','315989','315990','315991','315992','316832','316833','316834','316835','316836','317379','317637','328851','330349','331496','332029','332808','332810','333394','336701','351452','352381','353028','353626','358839','358840','362611','367762','368204','368586','368696','368714','369297','369304','369373','369500','369555','369557','369562','370529','371465','371466','371467','372318','372319','372320','372333','372334','374149','374152','374635','375952','376236','376868','378730','378822','378823','379559','379565','379568','379570','379572','379802','379803','379804','380849','389137','393405','393406','429841','430102','430103','430104','430105','432366','432780','432853','433856','438506','440285','440286','440287','4815','4816','4821','542029','542030','542031','542032','563154','563155','564035','564036','564037','564038','565327','565408','565409','565410','565667','565668','565669','565670','565671','565672','565673','565674','565675','566055','566056','566057','566718','566720','566761','566762','566764','566765','566768','566769','568684','568685','568686','568742','569831','573945','573946','574089','574090','574571','574612','575377','602543','602544','602549','602550','606253','647235','647236','647237','647239','669981','669982','669983','669984','669985','669986','669987','700835','706895','706896','731455','731457','731461','731462','731463','844809','844824','844827','847706','847707','847708','847710','847712','847714','847716','847718','847720','847722','847724','849585','861731','861732','861733','861736','861737','861738','861740','861741','861742','861743','861745','861747','861748','861750','861752','861753','861755','861756','861757','865567','865568','865569','865570','865571','865572','865573','865574','881404','881405','881406','881407','881408','881409','881410','881411','93312')
and datediff(yy, d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

--  Alpha-glucosidase inhibitor:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #AlphaGlucosidaseInhByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
UPPER(a.RAW_RX_MED_NAME) like UPPER('%acarbose%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Precose%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glucobay%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%miglitol%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glyset%') or
UPPER(a.RAW_RX_MED_NAME) like UPPER('%Voglibose%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Basen%') 
   )
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #AlphaGlucosidaseInhByByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1153649','1153650','1157268','1157269','1171936','1171937','1185237','1185238','151826','16681','199149','199150','200132','205329','205330','205331','209247','209248','213170','213485','213486','213487','217372','30009','315246','315247','315248','316304','316305','316306','368246','368300','370504','372926','569871','569872','573095','573373','573374','573375')
and datediff(yy, d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

--Glucagon-like Peptide-1 Agonists:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #GLP1AByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%Lixisenatide%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Adlyxin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Lyxumia%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Albiglutide%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Tanzeum%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Eperzan%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Dulaglutide%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Trulicity%') 
		)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #GLP1AByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1440051','1440052','1440053','1440056','1534763','1534797','1534798','1534800','1534801','1534802','1534804','1534805','1534806','1534807','1534819','1534820','1534821','1534822','1534823','1534824','1551291','1551292','1551293','1551295','1551296','1551297','1551299','1551300','1551301','1551302','1551303','1551304','1551305','1551306','1551307','1551308','1649584','1649586','1659115','1659117','1803885','1803886','1803887','1803888','1803889','1803890','1803891','1803892','1803893','1803894','1803895','1803896','1803897','1803898','1803902','1803903','1858991','1858992','1858993','1858994','1858995','1858997','1858998','1859000','1859001','1859002')
and datediff(yy, d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

--  Dipeptidyl peptidase IV inhibitor:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #DPIVInhByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%alogliptin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Kazano%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Oseni%')
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Nesina%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Anagliptin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Suiny%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%linagliptin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Jentadueto%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Jentadueto XR%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glyxambi%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Tradjenta%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%saxagliptin%') 
		or --this is combination of metformin-saxagliptin :
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%Kombiglyze XR%')
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Onglyza%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%sitagliptin%') 
		or --this is combination of metformin-vildagliptin :
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%Eucreas%') 
		or --this is combination of sitagliptin-simvastatin:
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%Juvisync%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Epistatin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Synvinolin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Zocor%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Janumet%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('% Janumet XR%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Januvia%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Teneligliptin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Tenelia%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Vildagliptin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Galvus%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Zomelis%')
		)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #DPIVInhByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1043560','1043561','1043562','1043563','1043565','1043566','1043567','1043568','1043569','1043570','1043572','1043574','1043575','1043576','1043578','1043580','1043582','1043583','1043584','1158518','1158519','1159662','1159663','1161605','1161606','1161607','1161608','1164580','1164581','1167814','1167815','1181729','1181730','1189800','1189801','1189802','1189803','1189804','1189806','1189808','1189810','1189811','1189814','1189818','1189821','1189823','1189827','1243826','1243827','1243829','1243833','1243834','1243835','1243839','1243842','1243843','1243844','1243845','1243846','1243848','1243849','1243850','1312409','1312411','1312415','1312416','1312418','1312422','1312423','1312425','1312429','1368008','1368009','1368012','1368019','1368020','1368035','1368036','1546030','1727500','1925495','1925496','1925497','1925498','1925500','1925501','1925504','593411','596554','621590','638596','665031','665032','665033','665034','665035','665036','665037','665038','665039','665040','665041','665042','665043','665044','700516','729717','757603','757708','757709','757710','757711','757712','857974','858034','858035','858036','858037','858038','858039','858040','858041','858042','858043','858044','861769','861770','861771','861819','861820','861821')
and datediff(yy, d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- Meglitinide:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #MeglitinideByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID 
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%nateglinide%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Starlix%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Prandin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NovoNorm%') 
		)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #MeglitinideByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1157407','1157408','1158396','1158397','1161599','1161600','1178121','1178122','1178433','1178434','1184631','1184632','200256','200257','200258','213218','213219','213220','219335','226911','226912','226913','226914','274332','284529','284530','311919','314142','316630','316631','330385','330386','331433','368289','373759','374648','389139','393408','402943','402944','402959','430491','430492','446631','446632','573136','573137','573138','574042','574043','574044','574957','574958','73044','802646','802742','805670','861787','861788','861789','861790','861791','861792')
and datediff(yy, d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

--  Amylinomimetics:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #AmylinomimeticsByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%Pramlintide%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Symlin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%SymlinPen 120%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%SymlinPen 60%') 
		)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #AmylinomimeticsByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1161690','1185508','1360096','1360184','139953','1657563','1657565','356773','356774','486505','582702','759000','861034','861036','861038','861039','861040','861041','861042','861043','861044','861045')
and datediff(yy, d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

--  Insulin:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #InsulinByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin aspart%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NovoLog%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin glulisine%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Apidra%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin lispro%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Humalog%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin inhaled%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Afrezza%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Regular insulin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Humulin R%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Novolin R%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin NPH%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Humulin N%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Novolin N%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin detemir%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Levemir%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin glargine%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Lantus%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Lantus SoloStar%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Toujeo%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Basaglar%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin degludec%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Tresiba%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin aspart protamine%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin aspart%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Actrapid%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Hypurin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Iletin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulatard%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insuman%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Mixtard%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NovoMix%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NovoRapid%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Oralin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Abasaglar%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%V-go%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Ryzodeg%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Insulin lispro protamine%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('insulin lispro%') 
		)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #InsulinByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('106888','106889','106891','1087799','108813','108814','108815','108816','108822','1157459','1160696','1164093','1164094','1164095','1167138','1167139','1167140','1167141','1167142','1167934','1168563','1171292','1171293','1171295','1171296','1172691','1172692','1175624','1176722','1176723','1176724','1176725','1176726','1176727','1176728','1177009','1178119','1178120','1178127','1178128','1184075','1184076','1184077','1359484','1359684','1359719','1359855','1359856','1359934','1360281','1360383','1360435','1362705','1362706','1362707','1362708','1362711','1362712','1362713','1362714','1362719','1362720','1362721','1362722','1362723','1362724','1362725','1362726','1362727','1362728','1362729','1362730','1362731','1362732','1372685','1372741','139825','142138','150831','150973','150978','152598','152599','152602','152640','152644','152647','153383','153384','153386','153389','1543203','1543205','1543206','1543207','1544490','1544569','1544571','1604538','1604539','1604540','1604541','1604543','1604544','1604545','1604546','1650260','1650264','1651315','1653197','1653198','1653200','1653203','1653204','1653206','1653209','1653497','1653499','1653506','1654190','1654192','1654863','1654866','1654911','1654912','1656706','1670007','1670008','1670009','1670010','1670011','1670012','1670013','1670014','1670015','1670016','1670017','1670018','1670020','1670021','1670022','1670023','1670024','1670025','1727493','1731316','1731317','1731319','1736859','1736860','1736861','1736862','1736863','1736864','1798388','1858992','1858993','1858994','1858995','1858997','1858998','1859000','1859001','1859002','1860165','1860166','1860167','1860169','1860170','1860172','1860173','1860174','1862102','203209','217704','217705','217707','217708','225569','226290','226291','226292','226293','226294','261111','261112','261551','274783','284810','285018','311021','311026','311027','311030','311033','311036','311041','343226','349670','351857','351858','351859','351860','351926','362585','362622','362777','363150','363221','363534','365573','365583','365670','365674','365677','365680','366206','372909','372910','375170','378864','379740','379744','379745','379746','379747','379750','379756','379757','384982','386083','386084','386086','386087','386088','386089','386091','386092','386098','400560','405228','484320','484321','484322','485210','564390','564391','564392','564601','564602','564603','564605','564820','564881','564885','564994','564995','564998','565176','565253','565254','565255','565256','574358','574359','575068','575137','575141','575142','575143','575146','575148','575626','575627','575628','575629','575679','607583','616236','616237','616238','6926','724343','803192','803193','803194','847198','847199','847200','847201','847204','847205','847230','847232','847239','847241','847259','847261','847279','900788','92880','92881','92942','93398','93558','93560','977838','977840','977841','977842')
and datediff(yy, d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

--  Sodium glucose cotransporter (SGLT) 2 inhibitors:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #SGLT2InhByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%dapagliflozin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%F[a,o]rxiga%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%canagliflozin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Invokana%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Invokamet%') 
		or  UPPER(a.RAW_RX_MED_NAME) like UPPER('%Xigduo XR%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Sulisent%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%empagliflozin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Jardiance%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Synjardy%') 
		--this one is combination of linagliptin-empagliflozin, see also Dipeptidyl Peptidase IV Inhibitors section
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glyxambi%') 
		)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #SGLT2InhByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1163230','1163790','1169415','1186578','1242961','1242963','1242964','1242965','1242967','1242968','1359640','1359802','1359979','1360105','1360454','1360495','1544916','1544918','1544919','1544920','1598264','1598265','1598267','1598268','1598269','1653594','1653597','1653600','1653610','1653611','1653613','1653614','1653616','1653619','1653625','1727493','1860164','1860165','1860166','1860167','1860169','1860170','1860172','1860173','1860174','475968','604751','60548','847908','847910','847911','847913','847914','847915','847916','847917','897120','897122','897123','897124','897126')
and datediff(yy, d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- Combinations:
-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #T2DMcombinations
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1043567','1043574','1043582','104490','104491','1166403','1166404','1167810','1167811','1171248','1171249','1175658','1175659','1184627','1184628','1185049','1185624','1187973','1187974','1189806','1189810','1189811','1189812','1189813','1189814','1189818','1189823','1189827','1243022','1243026','1243029','1243033','1243036','1243037','1243038','1243039','1243040','1243829','1243833','1243835','1243839','1243843','1243845','1243848','1243850','1312411','1312415','1312418','1312422','1312425','1312429','1368387','1368391','1368394','1368395','1368396','1368397','1368398','1368405','1368409','1368412','1368416','1368419','1368423','1368426','1368430','1368433','1368434','1368435','1368436','1368437','1368440','1368444','1372692','1372706','1372716','1372717','1372738','1372754','152923','1545151','1545152','1545153','1545154','1545155','1545156','1545158','1545159','1545162','1545163','1545165','1545166','1593775','1593831','1593833','1593835','1602110','1602111','1602112','1602113','1602114','1602115','1602119','1602120','1796090','1796091','1796093','1796095','1796096','1796098','1810998','1810999','1811001','1811003','1811005','1811007','1811009','1811011','1811013','1940498','196503','208220','213319','284743','352764','368276','563653','563654','565109','568935','573220','607816','647208','731455','731457','731461','731462','731463','757603','805670','847706','847707','847708','847710','847712','847714','847716','847718','847720','847722','847724','849585','861732','861733','861737','861738','861741','861742','861745','861747','861750','861752','861755','861756','861757','861770','861771','861788','861789','861791','861792','861820','861821')
and datediff(yy, d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;
---------------------------------------------------------------------------------------------------------------
-----                   Combine all medications specific to Diabetes Mellitus                             -----
-----         The date of the first medication of any kind will be recorded for each patient              -----
---------------------------------------------------------------------------------------------------------------
select i3.PATID, i3.EventDate into #InclusionMeds_final
from 
	(select i2.PATID, i2.MedDate as EventDate, row_number() over (partition by i2.PATID order by i2.MedDate asc) rn 
	from
		(select i.*,
		case when i.[1] is not NULL and ABS(datediff(yy,i.MedDate,i.[1]))>1 then 0 when i.[1] is not NULL and ABS(datediff(yy,i.MedDate,i.[1]))<=1 then 1 when i.[1] is NULL then 0 end as C1,
		case when i.[2] is not NULL and ABS(datediff(yy,i.MedDate,i.[2]))>1 then 0 when i.[2] is not NULL and ABS(datediff(yy,i.MedDate,i.[2]))<=1 then 1 when i.[2] is NULL then 0 end as C2,
		case when i.[3] is not NULL and ABS(datediff(yy,i.MedDate,i.[3]))>1 then 0 when i.[3] is not NULL and ABS(datediff(yy,i.MedDate,i.[3]))<=1 then 1 when i.[3] is NULL then 0 end as C3,
		case when i.[4] is not NULL and ABS(datediff(yy,i.MedDate,i.[4]))>1 then 0 when i.[4] is not NULL and ABS(datediff(yy,i.MedDate,i.[4]))<=1 then 1 when i.[4] is NULL then 0 end as C4,
		case when i.[5] is not NULL and ABS(datediff(yy,i.MedDate,i.[5]))>1 then 0 when i.[5] is not NULL and ABS(datediff(yy,i.MedDate,i.[5]))<=1 then 1 when i.[5] is NULL then 0 end as C5,
		case when i.[6] is not NULL and ABS(datediff(yy,i.MedDate,i.[6]))>1 then 0 when i.[6] is not NULL and ABS(datediff(yy,i.MedDate,i.[6]))<=1 then 1 when i.[6] is NULL then 0 end as C6,
		case when i.[7] is not NULL and ABS(datediff(yy,i.MedDate,i.[7]))>1 then 0 when i.[7] is not NULL and ABS(datediff(yy,i.MedDate,i.[7]))<=1 then 1 when i.[7] is NULL then 0 end as C7,
		case when i.[8] is not NULL and ABS(datediff(yy,i.MedDate,i.[8]))>1 then 0 when i.[8] is not NULL and ABS(datediff(yy,i.MedDate,i.[8]))<=1 then 1 when i.[8] is NULL then 0 end as C8,
		case when i.[9] is not NULL and ABS(datediff(yy,i.MedDate,i.[9]))>1 then 0 when i.[9] is not NULL and ABS(datediff(yy,i.MedDate,i.[9]))<=1 then 1 when i.[9] is NULL then 0 end as C9,
		case when i.[10] is not NULL and ABS(datediff(yy,i.MedDate,i.[10]))>1 then 0 when i.[10] is not NULL and ABS(datediff(yy,i.MedDate,i.[10]))<=1 then 1 when i.[10] is NULL then 0 end as C10
		from 
			(select x.PATID,x.MedDate,p.[1],p.[2],p.[3],p.[4],p.[5],p.[6],p.[7],p.[8],p.[9],p.[10]
			from
				(select a1.PATID,a1.MedDate 
				from #SulfonylureaByNames_initial as a1
				union
				select a2.PATID,a2.MedDate 
				from #SulfonylureaByRXNORM_initial a2
				union
				select a3.PATID,a3.MedDate 
				from #GLP1AByNames_initial a3
				union
				select a3.PATID,a3.MedDate 
				from #GLP1AByRXNORM_initial a3
				union
				select b1.PATID, b1.MedDate
				from #AlphaGlucosidaseInhByNames_initial as b1
				union
				select b2.PATID,b2.MedDate 
				from #AlphaGlucosidaseInhByByRXNORM_initial b2
				union
				select d1.PATID, d1.MedDate
				from #DPIVInhByNames_initial as d1
				union
				select d2.PATID,d2.MedDate 
				from #DPIVInhByRXNORM_initial d2
				union
				select e1.PATID, e1.MedDate
				from #MeglitinideByNames_initial as e1
				union
				select e2.PATID,e2.MedDate 
				from #MeglitinideByRXNORM_initial e2
				union
				select f1.PATID, f1.MedDate
				from #AmylinomimeticsByNames_initial as f1
				union
				select f2.PATID,f2.MedDate 
				from #AmylinomimeticsByRXNORM_initial f2
				union
				select g1.PATID, g1.MedDate
				from #InsulinByNames_initial as g1	
				union
				select g2.PATID,g2.MedDate 
				from #InsulinByRXNORM_initial g2
				union
				select h1.PATID, h1.MedDate
				from #SGLT2InhByNames_initial as h1
				union
				select h2.PATID,h2.MedDate 
				from #SGLT2InhByRXNORM_initial h2
				union 
				select h3.PATID,h3.MedDate from #T2DMcombinations h3 
				) x
			left join #FinalPregnancy p
			on x.PATID=p.PATID
			) i
		) i2
	where i2.C1=0 and i2.C1=0 and i2.C2=0 and i2.C3=0 and i2.C4=0 and i2.C5=0 and i2.C6=0 and i2.C7=0 and i2.C8=0 and i2.C9=0 and i2.C10=0
) i3
where i3.rn=1;
---------------------------------------------------------------------------------------------------------------
-----           People with at least one ordered medications non-specific to Diabetes Mellitus            -----
-----                                                   &                                                 ----- 
-----one lab or one visit record described above. Both recorded on different days within study period.    -----
-----                                                                                                     -----            
-----           Medication and another encounter should meet the following requerements:                  -----
-----        Patient must be 18 years old >= age <= 89 years old during the recorded encounter            -----
-----     Encounter should relate to encounter types: 'AMBULATORY VISIT', 'EMERGENCY DEPARTMENT',         -----
-----    'INPATIENT HOSPITAL STAY', 'OBSERVATIONAL STAY', 'NON-ACUTE INSTITUTIONAL STAY'.                 -----
-----                                                                                                     -----
-----                The date of the first medication meeting requerements is collected.                  -----
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                  People with medications non-specific to Diabetes Mellitus                          -----
-----                                 meeting one more requerement                                        -----
-----                         18 >= Age <=89 during the lab ordering day                                  -----
-----                    the date the first time med is recorded will be used                             -----

---------------------------------------------------------------------------------------------------------------
--  Biguanide:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #BiguanideByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glucophage%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Fortamet%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Glumetza%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Riomet%') 
		or
		(
			UPPER(a.RAW_RX_MED_NAME) like UPPER('%METFORMIN %') 
			and not (
					UPPER(a.RAW_RX_MED_NAME) like UPPER('%ACARBOSE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%MIGLITOL%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%VOGLIBOSE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ALOGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ANAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%LINAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%SAXAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%SITAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%TENELIGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%VILDAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%LIXISENATIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ALBIGLUTIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%DULAGLUTIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%DAPAGLIFLOZIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%CANAGLIFLOZIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%EMPAGLIFLOZIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Sulfonylureas:%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ACETOHEXAMIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIMEPIRIDE%')
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLICLAZIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIPIZIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLYBURIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIBENCLAMIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%CHLORPROPAMIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%TOLAZAMIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%TOLBUTAMIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLYCLOPYRAMIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIQUIDONE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIBORNURIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLYMIDINE SODIUM %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%PRAMLINTIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NATEGLINIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%REPAGLINIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLULISINE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%REGULAR INSULIN %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NPH %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%DETEMIR %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLARGINE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%DEGLUDEC %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%INSULIN %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ASPART%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%LISPRO %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ACTRAPID%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%HYPURIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ILETIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%INSULATARD%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%INSUMAN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%MIXTARD%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NOVOMIX%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NOVORAPID%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ORALIN %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ABASAGLAR%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%RYZODEG%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%V-GO%')
					)		
		)
)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #BiguanideByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1008476','105376','105377','1161601','1161602','1161609','1161610','1161611','1171244','1171245','1171254','1171255','1172629','1172630','1182890','1182891','1185325','1185326','1185653','1185654','151827','152161','1807888','1807894','1807915','1807917','204045','204047','235743','285065','316255','316256','330861','332809','361841','368254','368526','372803','372804','405304','406082','406257','428759','431724','438507','541766','541768','541774','541775','583192','583194','583195','645109','647241','6809','802051','860974','860975','860976','860977','860978','860979','860980','860981','860982','860983','860984','860985','860995','860997','860998','860999','861000','861001','861002','861003','861004','861005','861006','861007','861008','861009','861010','861011','861012','861014','861015','861016','861017','861018','861019','861020','861021','861022','861023','861024','861025','861026','861027','861027','861730','875864','875865','876009','876010','876033','977566')
and (datediff(yy,d.BIRTH_DATE,a.RX_ORDER_DATE) between @LowerAge and @UpperAge)
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

--  Thiazolidinedione:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #ThiazolidinedioneByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
		UPPER(a.RAW_RX_MED_NAME) like UPPER('%Avandia%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Actos%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Noscal%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Re[z,s]ulin%') 
		or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Romozin%') 
		or ((UPPER(a.RAW_RX_MED_NAME) like UPPER('%ROSIGLITAZONE%') 
			or UPPER(a.RAW_RX_MED_NAME) like UPPER('%PIOGLITAZONE%') 
			or UPPER(a.RAW_RX_MED_NAME) like UPPER('%TROGLITAZONE%')
			) 
			and not (UPPER(a.RAW_RX_MED_NAME) like UPPER('%ACARBOSE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%MIGLITOL%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%VOGLIBOSE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ALOGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ANAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%LINAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%SAXAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%SITAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%TENELIGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%VILDAGLIPTIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%LIXISENATIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ALBIGLUTIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%DULAGLUTIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%DAPAGLIFLOZIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%CANAGLIFLOZIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%EMPAGLIFLOZIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ACETOHEXAMIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIMEPIRIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLICLAZIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIPIZIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLYBURIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIBENCLAMIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%CHLORPROPAMIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%TOLAZAMIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%TOLBUTAMIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLYCLOPYRAMIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIQUIDONE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLIBORNURIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLYMIDINE SODIUM %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%PRAMLINTIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NATEGLINIDE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%REPAGLINIDE%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLULISINE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%REGULAR INSULIN %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NPH %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%DETEMIR %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%GLARGINE %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%DEGLUDEC %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%INSULIN %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ASPART%')
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%LISPRO %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ACTRAPID%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%HYPURIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ILETIN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%INSULATARD%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%INSUMAN%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%MIXTARD%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NOVOMIX%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%NOVORAPID%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ORALIN %') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%ABASAGLAR%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%RYZODEG%') 
					or UPPER(a.RAW_RX_MED_NAME) like UPPER('%V-GO%')
				)
			)
		)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;
-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #ThiazolidinedioneByRXNORM_initial 
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1157987','1157988','1163231','1163232','1163389','1163390','153722','153723','153724','199984','199985','200065','212281','212282','213041','253198','259319','261241','261242','261243','261266','261267','261268','312440','312441','312859','312860','312861','316869','316870','316871','317573','331478','332435','332436','33738','358499','358500','358530','358809','368230','368234','368317','373801','374252','374606','378729','386116','430343','565366','565367','565368','572491','572492','572980','574470','574471','574472','574495','574496','574497','72610','84108')
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

--  Glucagon-like Peptide-1 Agonist:
-- collect meds based on matching names:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #GLP1AexByNames_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where (
UPPER(a.RAW_RX_MED_NAME) like UPPER('%Exenatide%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Byetta%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Bydureon%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Liraglutide%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Victoza%') 
or UPPER(a.RAW_RX_MED_NAME) like UPPER('%Saxenda%') 
)
and datediff(yy, d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;
-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #GLP1AexByRXNORM_initial
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1163230','1163790','1169415','1186578','1242961','1242963','1242964','1242965','1242967','1242968','1359640','1359802','1359979','1360105','1360454','1360495','1544916','1544918','1544919','1544920','1598264','1598265','1598267','1598268','1598269','1653594','1653597','1653600','1653610','1653611','1653613','1653614','1653616','1653619','1653625','1727493','1860164','1860165','1860166','1860167','1860169','1860170','1860172','1860173','1860174','475968','604751','60548','847908','847910','847911','847913','847914','847915','847916','847917','897120','897122','897123','897124','897126')
and datediff(yy,d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;

-- Combinations:
-- collect meds based on matching RXNORM codes:
select a.PATID, a.RX_ORDER_DATE as MedDate
into #Nont2dmCombinations
from dbo.PRESCRIBING a join #Denomtemp2 w on a.PATID=w.PATID
join dbo.ENCOUNTER e on a.ENCOUNTERID=e.ENCOUNTERID
join dbo.DEMOGRAPHIC d on e.PATID=d.PATID
where a.RXNORM_CUI in ('1169920','1169923','1175016','1175021','352450','602411','731442','806287','861761','861762','861764','861765','861784','861785','861796','861797','861807','861808','861817','861818','861823','861824','899991','899992','899993','899995','899998','900000','900002')
and datediff(yy,d.BIRTH_DATE, a.RX_ORDER_DATE) between @LowerAge and @UpperAge
and a.RX_ORDER_DATE between @LowerTimeFrame and  @UpperTimeFrame;
---------------------------------------------------------------------------------------------------------------
--  Combine all meds:  
select y.PATID, y.MedDate into #InclusionUnderRestrictionMeds_initial
from 
	(select x.PATID,x.MedDate
	from
		(select a1.PATID,a1.MedDate from #BiguanideByNames_initial as a1
		union
		select a2.PATID,a2.MedDate from #BiguanideByRXNORM_initial as a2
		union
		select b1.PATID, b1.MedDate from #ThiazolidinedioneByNames_initial as b1
		union
		select b2.PATID, b2.MedDate from #ThiazolidinedioneByRXNORM_initial as b2
		union
		select c1.PATID, c1.MedDate from #GLP1AexByNames_initial as c1
		union
		select c2.PATID, c2.MedDate from #GLP1AexByRXNORM_initial as c2
		union
		select c3.PATID, c3.MedDate from #Nont2dmCombinations as c3
		) x
	) y;
-- Get set of patients having one med & one visit:
select x.PATID, x.MedDate  into #p1
from #InclusionUnderRestrictionMeds_initial x join #Visits_initial y on x.PATID=y.PATID
where abs(datediff(dd,x.MedDate,y.ADMIT_DATE))>1;

-- Get set of patients having one med & one HbA1c:
select x.PATID, x.MedDate  into #p2
from #InclusionUnderRestrictionMeds_initial x join #A1c_initial y on x.PATID=y.PATID
where abs(datediff(dd,x.MedDate,y.LAB_ORDER_DATE))>1;

-- Get set of patients having one med & fasting glucose measurement:
select x.PATID, x.MedDate  into #p3
from #InclusionUnderRestrictionMeds_initial x join #FG_initial y on x.PATID=y.PATID
where abs(datediff(dd,x.MedDate,y.LAB_ORDER_DATE))>1;

-- Get set of patients having one med & random glucose measurement:
select x.PATID, x.MedDate  into #p4
from #InclusionUnderRestrictionMeds_initial x join #RG_initial y on x.PATID=y.PATID
where abs(datediff(dd,x.MedDate,y.LAB_ORDER_DATE))>1;

-- Get set of patients having one med & A1c & fasting glucose measurement:
/*select x.PATID, x.MedDate  into #p5
from #InclusionUnderRestrictionMeds_initial x join #A1cFG_final_FirstPair y on x.PATID=y.PATID
where abs(datediff(dd,x.MedDate,y.EventDate))>1;

-- Get set of patients having one med &  A1c & random glucose measurement:
select x.PATID, x.MedDate  into #p6
from #InclusionUnderRestrictionMeds_initial x join #A1cRG_final_FirstPair y on x.PATID=y.PATID
where abs(datediff(dd,x.MedDate,y.EventDate))>1;*/

-- Collect all non-specific to Diabetes Mellitus meds:
select i3.PATID, i3.EventDate into #InclusionUnderRestrictionMeds_final
from 
	(select i2.PATID, i2.MedDate as EventDate, row_number() over (partition by i2.PATID order by i2.MedDate asc) rn 
	from
		(select i.*,
		case when i.[1] is not NULL and ABS(datediff(yy,i.MedDate,i.[1]))>1 then 0 when i.[1] is not NULL and ABS(datediff(yy,i.MedDate,i.[1]))<=1 then 1 when i.[1] is NULL then 0 end as C1,
		case when i.[2] is not NULL and ABS(datediff(yy,i.MedDate,i.[2]))>1 then 0 when i.[2] is not NULL and ABS(datediff(yy,i.MedDate,i.[2]))<=1 then 1 when i.[2] is NULL then 0 end as C2,
		case when i.[3] is not NULL and ABS(datediff(yy,i.MedDate,i.[3]))>1 then 0 when i.[3] is not NULL and ABS(datediff(yy,i.MedDate,i.[3]))<=1 then 1 when i.[3] is NULL then 0 end as C3,
		case when i.[4] is not NULL and ABS(datediff(yy,i.MedDate,i.[4]))>1 then 0 when i.[4] is not NULL and ABS(datediff(yy,i.MedDate,i.[4]))<=1 then 1 when i.[4] is NULL then 0 end as C4,
		case when i.[5] is not NULL and ABS(datediff(yy,i.MedDate,i.[5]))>1 then 0 when i.[5] is not NULL and ABS(datediff(yy,i.MedDate,i.[5]))<=1 then 1 when i.[5] is NULL then 0 end as C5,
		case when i.[6] is not NULL and ABS(datediff(yy,i.MedDate,i.[6]))>1 then 0 when i.[6] is not NULL and ABS(datediff(yy,i.MedDate,i.[6]))<=1 then 1 when i.[6] is NULL then 0 end as C6,
		case when i.[7] is not NULL and ABS(datediff(yy,i.MedDate,i.[7]))>1 then 0 when i.[7] is not NULL and ABS(datediff(yy,i.MedDate,i.[7]))<=1 then 1 when i.[7] is NULL then 0 end as C7,
		case when i.[8] is not NULL and ABS(datediff(yy,i.MedDate,i.[8]))>1 then 0 when i.[8] is not NULL and ABS(datediff(yy,i.MedDate,i.[8]))<=1 then 1 when i.[8] is NULL then 0 end as C8,
		case when i.[9] is not NULL and ABS(datediff(yy,i.MedDate,i.[9]))>1 then 0 when i.[9] is not NULL and ABS(datediff(yy,i.MedDate,i.[9]))<=1 then 1 when i.[9] is NULL then 0 end as C9,
		case when i.[10] is not NULL and ABS(datediff(yy,i.MedDate,i.[10]))>1 then 0 when i.[10] is not NULL and ABS(datediff(yy,i.MedDate,i.[10]))<=1 then 1 when i.[10] is NULL then 0 end as C10
		from 
			(select x.PATID,x.MedDate,p.[1],p.[2],p.[3],p.[4],p.[5],p.[6],p.[7],p.[8],p.[9],p.[10]
			from
				(select a.PATID, a.MedDate  
				from #p1 as a
				union
				select b.PATID, b.MedDate  
				from #p2 as b
				union
				select c.PATID, c.MedDate  
				from #p3 as c
				union
				select d.PATID, d.MedDate  
				from #p4 as d
				)x
			left join #FinalPregnancy p
			on x.PATID=p.PATID
			) i
		) i2
	where i2.C1=0 and i2.C1=0 and i2.C2=0 and i2.C3=0 and i2.C4=0 and i2.C5=0 and i2.C6=0 and i2.C7=0 and i2.C8=0 and i2.C9=0 and i2.C10=0
) i3
where i3.rn=1;
------------------------------------------------------------------------------------
-----                                      Defining onset date                                            -----
---------------------------------------------------------------------------------------------------------------
select y.PATID, y.EventDate into #All
from 
	(select x.PATID,x.EventDate,row_number() over (partition by x.PATID order by x.EventDate asc) rn
	from
		(select a.PATID,a.EventDate 
		from #Visits_final_FirstPair as a
		union all
		select b.PATID, b.EventDate
		from #InclusionMeds_final as b
		union all
		select c.PATID, c.EventDate
		from #A1c_final_FirstPair as c
		union all
		select d.PATID, d.EventDate
		from #FG_final_FirstPair as d
		union all
		select e.PATID, e.EventDate
		from #RG_final_FirstPair as e
		union all
		select f.PATID, f.EventDate
		from #A1cFG_final_FirstPair as f
		union all
		select g.PATID, g.EventDate
		from #A1cRG_final_FirstPair as g
		union all
		select h.PATID, h.EventDate
		from #InclusionMeds_final as h
		union all
		select k.PATID, k.EventDate
		from #InclusionUnderRestrictionMeds_final as k
		) x
	) y
where y.rn=1;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                 Part4: Combine results from all parts of the code into final table:                 -----
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
select a.*, x.EventDate as DMonsetDate,c.ZIPPREFIX
into #FinalStatTable1
from #FinalStatTable01 a 
left join #All x on a.PATID=x.PATID
left join /* specify database name with CAP tables */ [Capricron].[dbo].[CAP_DEMOGRAPHICS] c on a.PATID=c.PATID;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                          Part5: Add up established patient flag:                                    -----
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
select d.GLOBALID,a.*,b.EstablishedPatientFlag
into #Final_Table1
from #FinalStatTable1 a 
left join /* provide name the table containing PATID, and flag specifiyng if patient had/or not any king of records in the system prior the study period*/ #EstablishedPatientTable b on a.PATID=b.PATID
join  /* provide name the table containing PATID, Hashes, and Global patient id*/ #GlobalIDtable d on a.PATID=d.PATID;
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----  Please, save table #Final_Table1 localy. It will be used in all further data extractions       ------
/* Save #Final_Table1 as csv file. 
Use "|" symbol as field terminator and 
"ENDALONAEND" as row terminator. */ 
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------


