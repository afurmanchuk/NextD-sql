---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                      Part 12: Socio-economic status for the study sample                            -----  
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
/* Tables for this eaxtraction: 
1. Table 1 (named here #FinalTable1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. Side table (named here #SES) 
for CAPRICORN sites will be asked to mapp their patient's census tract IDs into given list of SES variables  */
---------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
/*use code below if you are member of CAPRICORN consortium:*/
select c.PATID,b.*/*here will be list of SES variables for each patient */
into #NextD_SES
from /* provide name of table 1 here: */ #FinalTable1 c 
left join /* provide name of non-PCORNET table with SES data here: */ #SES b on c.PATID=b.PATID;
---------------------------------------------------------------------------------------------------------------
