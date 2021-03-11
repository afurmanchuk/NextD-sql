---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                             Part 3: Encounters for the study sample                                 -----  
--------------------------------------------------------------------------------------------------------------- 
/* Tables for this eaxtraction: 
1. Table 1 (named here #FinalStatTable1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. PCORI ENCOUNTER table*/
--------------------------------------------------------------------------------------------------------------- 
use /*provide here the name of PCORI database here: */PCORI_SAS;
--------------------------------------------------------------------------------------------------------------- 
----  Declare study time frame variables:
DECLARE @studyTimeRestriction int;declare @UpperTimeFrame int; declare @LowerTimeFrame int;
-----                             Specify time frame and age limits                                       -----
--Set extraction time frame below. If time frames not set, the code will use the whole time frame available from the database
set @LowerTimeFrame=18263;--'2010-01-01';
set @UpperTimeFrame=22280;--'2020-12-31';
--set age restrictions:
declare @UpperAge int; declare @LowerAge int;set @UpperAge=89; set @LowerAge=18;
---------------------------------------------------------------------------------------------------------------
/* Steps for insurance remap (omit if not remapping):

1. Load provided by NU team remapping table named MasterReMap. It has following columns:
[RAW_financial_class_dsc],[RAW_cdf_meaning],[RAW_BENEFIT_PLAN_NAME],[RAW_PRODUCT_TYPE],[RAW_PAYOR_NAME],[RAW_EPM_ALT_IDFR],[RAW_SHORT_NAME],[NewCategory]
2. Load table (named here #RawNPIValuesTable) with coresponding NPI values for each encounter of interest.
3. Remap raw values into new insurance and provider categories :*/
---------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------- 
--------------------------------------------------------------------------------------------------------------- 
--------------------------------------------------------------------------------------------------------------- 
select c.PATID,'|' as Pipe,1
		a.ENCOUNTERID,'|' as Pipe2,
		a.PROVIDERID,'|' as Pipe3,
		year(dateadd(dd,a.ADMIT_DATE,'1960-01-01')) as ADMIT_DATE_YEAR,'|' as Pipe4,
		month(dateadd(dd,a.ADMIT_DATE,'1960-01-01')) as ADMIT_DATE_MONTH,'|' as Pipe5,
		a.ADMIT_DATE - c.[FirstVisit] as DAYS_from_FirstEncounter_Date1,'|' as Pipe6,
		year(dateadd(dd,a.DISCHARGE_DATE,'1960-01-01')) as DISCHARGE_DATE_YEAR,'|' as Pipe7,
		month(dateadd(dd,a.DISCHARGE_DATE,'1960-01-01')) as DISCHARGE_DATE_MONTH,'|' as Pipe8,
		a.ADMIT_DATE - c.[FirstVisit] as DAYS_from_FirstEncounter_Date2,'|' as Pipe9,
		a.ENC_TYPE,'|' as Pipe10,
		a.FACILITYID,'|' as Pipe11,
		a.FACILITY_TYPE,'|' as Pipe12,
		a.DISCHARGE_DISPOSITION,'|' as Pipe13,
		a.DISCHARGE_STATUS,'|' as Pipe14,
		a.ADMITTING_SOURCE,'|' as Pipe15,
		a.PROVIDERID,'|' as Pipe16,
		a.[PAYER_TYPE_PRIMARY],'|' as Pipe17,
		a.[PAYER_TYPE_ SECONDARY],'ENDALONAEND' as lineEND
into #NextD_ENCOUNTER_FINAL
from /* provide name of table 1 here: */ #FinalTable1 c 
join [dbo].[ENCOUNTER] a on c.PATID=a.PATID
join dbo.DEMOGRAPHIC d on c.PATID=d.PATID		
where convert(numeric(18,6),(a.ADMIT_DATE-d.BIRTH_DATE))/365.25 between @LowerAge and @UpperAge 
and a.ADMIT_DATE between @LowerTimeFrame and @UpperTimeFrame; 
--------------------------------------------------------------------------------------------------------------- 
