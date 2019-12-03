/*********************************************************************/
This repository is meant to be used for the third nextD extraction round.

Description of Next-D project and all relevant details on data extraction beyond sql codes and this README file could be found at:
https://www.dropbox.com/home/diabetes%20project%20(working%20docs)/Definitions_StudySamples%26Variables?preview=Definitions_Part1_CAPRICORNversion-2019-11-13-AF.docx
https://www.dropbox.com/home/diabetes%20project%20(working%20docs)/Definitions_StudySamples%26Variables?preview=Definitions_Part2-2019-11-13-AF.docx
https://www.dropbox.com/home/diabetes%20project%20(working%20docs)/Definitions_StudySamples%26Variables?preview=Definitions_Appendix_A-2018-11-27-af.docx
https://www.dropbox.com/home/diabetes%20project%20(working%20docs)/Definitions_StudySamples%26Variables?preview=Definitions_Apendix_B-2018-12-14-AF.docx

/*********************************************************************/
Below we provide steps for the third data extraction for NEXT_D project. One also might want to review more user-friendly description of NEXTD data dictionary available in docx files .

Extraction steps

1.	Run SQLTable1_CAPRICORNsites-CCHHS reviewed_2019-01-08_AF.sql
•	In line 15 specify PCORI database name
•	In line 1185 specify database name with [CAP_DEMOGRAPHICS] table
2.	Collect PATID for patients in table #FinalStatTable1. Use old provided by MRAIA study global id (GLOBALID) and store it into crosswalk table #GlobalIDtable that will be used in all further tables. Produce table #Final_Table1. This table will used in all other codes.
3.	Run all other extraction codes in any order.

NextD_ExtractionCode_DEMOGRAPHICS_CAPRICORN_2019_01_08.sql
•	In line 10 specify PCORI database name
•	Collect MaritalStatus variable from source system into #MaritalStatusTable table. Change line 19 to ‘NULL’ as MaritalStatus in case your site does not populate this in the source system. Line 23 should be commented out in this case.

NextD_ExtractionCode_DEATHCAUSES_CAPRICORN_2019_01_08.sql
•	In line 11 specify PCORI database name

NextD_ExtractionCode_DIAGNOSES_CAPRICORN_2019_01_08.sql
•	In line 12 specify PCORI database name

NextD_ExtractionCode_DISPENSING_CAPRICORN_2019_01_08.sql
•	In line 11 specify PCORI database name

NextD_ExtractionCode_LABS_CAPRICORN_2019_01_08.sql
•	In line 12 specify PCORI database name

NextD_ExtractionCode_ENCOUNTERS_CAPRICORN_2019_01_08.sql
•	In line 11 specify PCORI database name

NextD_ExtractionCode_PRESCRIBING_CAPRICORN_2019_01_08.sql
•	In line 10 specify PCORI database name

NextD_ExtractionCode_PROCEDURES_CAPRICORN_2019_01_08.sql
•	In line 12 specify PCORI database name

NextD_ExtractionCode_VITALS_CAPRICORN_2019_01_08.sql
•	In line 10 specify PCORI database name

NextD_ExtractionCode_PROVIDERS_CAPRICORN_2019_01_08.sql
•	In line 12 specify PCORI database name
•	Convert NPI2ToxonomycodeCorssWalk_2018-01-01_AF.zip into #NEXTD_NPI_Remap

NextD_ExtractionCode_SES_CAPRICORN_2019_01_08.sql
•	In line 44 specify PCORI database name
•	Collect geocoding details and patient addresses from the source system. Convert those to #SES table.
•	Convert nhgis0561_20155_2015_tract_final_label_csv_2017-7-24-AF.zip file into #SESvariablestable.

NextD_Epic_InsuranceCoveragePerPatient_pro-ENROLLMENTtable-2019-11-26-SX.sql
•	Follow logic provided here:
https://github.com/afurmanchuk/NextD/blob/master/NextD_Epic_InsuranceCoveragePerPatient_pro-ENROLLMENTtable-2019-11-26-SX.sql

NextD_IDX_InsuranceCoveragePerPatient_pro-ENROLLMENTtable-2019-11-26-SX.sql 
•	Follow logic provided here:
https://github.com/afurmanchuk/NextD/blob/master/NextD_IDX_InsuranceCoveragePerPatient_pro-ENROLLMENTtable-2019-11-26-SX.sql

NextD_ExtractionCode_DISTANCES_CAPRICORN_2019_11_12.sql
•	Comment out lines 60-69
•	In line 56 provide name of side table with Facility addresses.
•	Save final table #NextD_DISTANCES_FINAL as pipe-delimited file

4.	Each code in step 3 will produce single table. Save #Final_Table1 (produced in step 2) and other tables (produced in step 3) as pipe-delimited files with row “ENDALONAEND” as row terminator. Load them to  
R:\IPHAM\Projects\ArcGis\NextDflatFileTempLocation\<NameOfYourSite>Duat

