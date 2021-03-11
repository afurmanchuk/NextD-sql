Execution plan:

1. Run FinalTable1_2021-03-02.sql 
    It will produce FinalTable 1 with relevant patient’s IDs that will be utilized in other provided codes.

2. The remaining 12 codes could be run in any order after the FinalTable1 is generated.
    Codes for producing NextD_PROVIDER will need extra mapping with provided along with this set files NPI2ToxonomycodeCorssWalk_2018-01-01_AF.zip 

3. Save each output table as a separate pipeline delimited file. Use “ALONAENDALONA” as line terminator. 
    Produced files should then be archived
 ----------------------------------------------------------------------   

Study period: 2010-01-01 - 2020-12-31 
CDM version: >= v6.1, without date shifts
----------------------------------------------------------------------

Script name: FinalTable1_2021-02-03.sql
Execution order: 1
Tables required: 
+PCORNET_CDM.DEMOGRAPHIC
+PCORNET_CDM.ENCOUNTER

Table produced:
+FinalTable1;

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_DEMOGRAPHICS-2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalsTable1
+PCORNET_CDM.DEMOGRAPHIC

Table produced:
+NextD_DEMOGRAPHIC_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_ENCOUNTER-2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
+PCORNET_CDM.ENCOUNTER
+NEXT_OriginalNPIFROMBaseTaxonomy

Table produced:
+NextD_ENCOUNTER_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_PRESCRIBING-2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
+PCORNET_CDM.DEMOGRAPHIC
+PCORNET_CDM.PRESCRIBING
+PCORNET_CDM.ENCOUNTER

Table produced:
+NextD_PRESCRIBING_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_DISPENSING-2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
+PCORNET_CDM.DISPENSING
+PCORNET_CDM.DEMOGRAPHIC

Table produced:
+NextD_DISPENSING_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_VITAL-2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
+PCORNET_CDM.DEMOGRAPHIC
+PCORNET_CDM.VITAL

Table produced:
+NextD_VITAL_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_LABS_GPCsites-2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
+PCORNET_CDM.DEMOGRAPHIC
+PCORNET_CDM.LAB_RESULT_CM

Table produced:
+NextD_LABS_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_DIAGNOSIS-2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
+PCORNET_CDM.DEMOGRAPHIC
+PCORNET_CDM.DIAGNOSIS

Table produced:
+NextD_DIAGNOSIS_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_PROCEDURES-2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
+PCORNET_CDM.DEMOGRAPHIC
+PCORNET_CDM.PROCEDURES;

Table produced:
+NextD_PROCEDURES_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_PROVIDER-2021-02-03.sql
Execution order: 2.*
Tables required: 
+NEXT_OriginalNPIFROMBaseTaxonomy
+PCORNET_CDM.PROVIDER

Table produced:
+NextD_PROVIDER_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_SES_2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
+Local table with information on geocoding accuracy, and GEOIIDs

Table produced:
+NextD_SES_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_DEATH_2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
++PCORNET_CDM.DEATH

Table produced:
+NextD_DEATH_FINAL

----------------------------------------------------------------------

Script name: NextD_ExtractionCode_DEATH_2021-02-03.sql
Execution order: 2.*
Tables required: 
+FinalTable1
++PCORNET_CDM.DEATH_CAUSE

Table produced:
+NextD_DEATH_CAUSE_FINAL

----------------------------------------------------------------------
