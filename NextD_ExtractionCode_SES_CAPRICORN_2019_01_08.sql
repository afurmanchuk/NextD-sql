---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-----                      Part 10: Socio-economic status for the study sample                            -----
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
/* Tables for this eaxtraction:
1. Table 1 (named here #Final_Table1) with Next-D study sample IDs. See separate SQL code for producing this table.
2. Side table (named here #SESvariables) with census track labels.
3. Side table (named here #SES) with patient's addresses and details on geocoding accuracy (Locator and Score).
4. Tabel with mapping (named here #GlobalIDtable) between PCORNET IDs and Global patient IDs provided by MURAIA. */


/*
Values and explicit notations for Locator variable:

AddrPoint—Point address, such as 783 Rolling Meadows Lane, that can be a roof-top address or a point near to the exact location. It is usually a precise location of the address.
StreetAddr—Street address, such as 320 Madison St, that represents an interpolated location along a street given the house number within an address range.
BldgName—Building name, such as CN Tower.
StreetName—Street name only, such as Orchard Road. The street name feature may be a feature of many street segments chained together based on the name. The geocoded location is usually placed on the middle of the street feature.
Admin—A high level administrative area, such as a State or Province.
DepAdmin—A secondary administrative area, such as a county within a State.
SubAdmin—A local administrative area, such as a city.
Locality—A local residential settlement, such as a colonia in Mexico or a block (chochomoku) in Japan.
Zone—An alternative name of a locality, or a subdivision within a locality, such as a sub-block (gaiku chiban) in Japan.
PostLoc—A city or locality representing a postal administrative area.
Postal—Basic postal code, such as 60610.
PostalExt—Full postal code including its extension, such as a ZIP+4 code—91765-4383.
Place—A place-name in a gazetteer.
POI—A point of interest or landmark.
Intersection—Intersection address that contains an intersection connector, such as Union St & Carson Rd.
Coordinates—Geographic coordinates, such as -84.392 32.722.
SpatialOperator—The location that contains an offset distance from the found address, for example, 30 yards South from 342 Main St.
MGRS—A Military Grid Reference System (MGRS) location, such as 46VFM5319397841.
NULL
Range—interpolated based on address ranges from street segments
Street—center of the matched street
Intersection—intersection of two streets
Zip—centroid of the matched zip code
City—centroid of the matched city
*/
---------------------------------------------------------------------------------------------------------------
use capricorn;/*Specify PCORI database name here*/
select d.GLOBALID,
        b.GTRACT_ACSlikeLABEL, /*this is the fake id analogue of actual sensus tract ID. This ID is asked in order to avoid redundancy of the data*/
        b.Locator,
        b.Score,
        b.USA_ADDRESS,
        b.MILITARY_ADDRESS,
        b.COLLEGE_ADDRESS,
        b.RRHC_ADDRESS,
        b.PMB_ADDRESS,
        b.POBOX_ADDRESS,
        case when (b.patient_country in ('USA','United States of America','US')
                        or
                        b.STATE_C  in ('ALABAMA','ALASKA','ARIZONA','ARKANSAS','CALIFORNIA','COLORADO','CONNECTICUT','DELAWARE','DISTRICT OF COLUMBIA','FLORIDA','GEORGIA','HAWAII','IDAHO','ILLINOIS','INDIANA','IOWA','KANSAS','KENTUCKY','LOUISIANA','MAINE','MARYLAND','MASSACHUSETTS','MICHIGAN','MINNESOTA','MISSISSIPPI','MISSOURI','MONTANA','NEBRASKA','NEVADA','NEW HAMPSHIRE','NEW JERSEY','NEW MEXICO','NEW YORK','NORTH CAROLINA','NORTH DAKOTA','OHIO','OKLAHOMA','OREGON','PENNSYLVANIA','RHODE ISLAND','SOUTH CAROLINA','SOUTH DAKOTA','TENNESSEE','TEXAS','UTAH','VERMONT','VIRGINIA','WASHINGTON','WEST VIRGINIA','WISCONSIN','WYOMING',
                                    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
                                    'AMERICAN SAMOA','GUAM','NORTHERN MARIANA ISLANDS','PUERTO RICO','U.S. VIRGIN ISLANDS','VIRGIN ISLANDS','MINOR OUTLYING ISLANDS','BAJO NUEVO BANK','BAKER ISLAND','HOWLAND ISLAND','JARVIS ISLAND','JOHNSTON ATOLL','KINGMAN REEF','MIDWAY ISLANDS','NAVASSA ISLAND','PALMYRA ATOLL','SERRANILLA BANK','WAKE ISLAND'
                                    )
                        or
                        (b.STATE_C is NULL
                                        and
                                        (b.CITY like '%ALABAMA' or b.CITY like '%ALASKA' or b.CITY like '%ARIZONA' or b.CITY like '%ARKANSAS' or b.CITY like '%CALIFORNIA' or b.CITY like '%COLORADO' or b.CITY like '%CONNECTICUT' or b.CITY like '%DELAWARE' or b.CITY like '%DISTRICT OF COLUMBIA' or b.CITY like '%FLORIDA' or b.CITY like '%GEORGIA' or b.CITY like '%HAWAII' or b.CITY like '%IDAHO' or b.CITY like '%ILLINOIS' or b.CITY like '%INDIANA' or b.CITY like '%IOWA' or b.CITY like '%KANSAS' or b.CITY like '%KENTUCKY' or b.CITY like '%LOUISIANA' or b.CITY like '%MAINE' or b.CITY like '%MARYLAND' or b.CITY like '%MASSACHUSETTS' or b.CITY like '%MICHIGAN' or b.CITY like '%MINNESOTA' or b.CITY like '%MISSISSIPPI' or b.CITY like '%MISSOURI' or b.CITY like '%MONTANA' or b.CITY like '%NEBRASKA' or b.CITY like '%NEVADA' or b.CITY like '%NEW HAMPSHIRE' or b.CITY like '%NEW JERSEY' or b.CITY like '%NEW MEXICO' or b.CITY like '%NEW YORK' or b.CITY like '%NORTH CAROLINA' or b.CITY like '%NORTH DAKOTA' or b.CITY like '%OHIO' or b.CITY like '%OKLAHOMA' or b.CITY like '%OREGON' or b.CITY like '%PENNSYLVANIA' or b.CITY like '%RHODE ISLAND' or b.CITY like '%SOUTH CAROLINA' or b.CITY like '%SOUTH DAKOTA' or b.CITY like '%TENNESSEE' or b.CITY like '%TEXAS' or b.CITY like '%UTAH' or b.CITY like '%VERMONT' or b.CITY like '%VIRGINIA' or b.CITY like '%WASHINGTON' or b.CITY like '%WEST VIRGINIA' or b.CITY like '%WISCONSIN' or b.CITY like '%WYOMING' or b.CITY like '% AL' or b.CITY like '% AK' or b.CITY like '% AZ' or b.CITY like '% AR' or b.CITY like '% CA' or b.CITY like '% CO' or b.CITY like '% CT' or b.CITY like '% DE' or b.CITY like '% FL' or b.CITY like '% GA' or b.CITY like '% HI' or b.CITY like '% ID' or b.CITY like '% IL' or b.CITY like '% IN' or b.CITY like '% IA' or b.CITY like '% KS' or b.CITY like '% KY' or b.CITY like '% LA' or b.CITY like '% ME' or b.CITY like '% MD' or b.CITY like '% MA' or b.CITY like '% MI' or b.CITY like '% MN' or b.CITY like '% MS' or b.CITY like '% MO' or b.CITY like '% MT' or b.CITY like '% NE' or b.CITY like '% NV' or b.CITY like '% NH' or b.CITY like '% NJ' or b.CITY like '% NM' or b.CITY like '% NY' or b.CITY like '% NC' or b.CITY like '% ND' or b.CITY like '% OH' or b.CITY like '% OK' or b.CITY like '% OR' or b.CITY like '% PA' or b.CITY like '% RI' or b.CITY like '% SC' or b.CITY like '% SD' or b.CITY like '% TN' or b.CITY like '% TX' or b.CITY like '% UT' or b.CITY like '% VT' or b.CITY like '% VA' or b.CITY like '% WA' or b.CITY like '% WV' or b.CITY like '% WI' or b.CITY like '% WY' or b.CITY like '%AMERICAN SAMOA' or b.CITY like '%GUAM' or b.CITY like '%NORTHERN MARIANA ISLANDS' or b.CITY like '%PUERTO RICO' or b.CITY like '%U.S. VIRGIN ISLANDS' or b.CITY like '%VIRGIN ISLANDS' or b.CITY like '%MINOR OUTLYING ISLANDS' or b.CITY like '%BAJO NUEVO BANK' or b.CITY like '%BAKER ISLAND' or b.CITY like '%HOWLAND ISLAND' or b.CITY like '%JARVIS ISLAND' or b.CITY like '%JOHNSTON ATOLL' or b.CITY like '%KINGMAN REEF' or b.CITY like '%MIDWAY ISLANDS' or b.CITY like '%NAVASSA ISLAND' or b.CITY like '%PALMYRA ATOLL' or b.CITY like '%SERRANILLA BANK' or b.CITY like '%WAKE ISLAND'
                                        )
                        )
                        )
then 1 else 0 end as USA_ADDRESS,
--Military PO Box:
case when (b.CITY like 'APO' or b.CITY  like 'FPO' or b.CITY  like 'DPO' or b.CITY  like '% APO %' or b.CITY  like '% FPO %' or b.CITY  like '% DPO %' or b.CITY  like '% APO' or b.CITY  like '% FPO' or b.CITY  like '% DPO' or b.CITY  like 'APO %' or b.CITY  like 'FPO %' or b.CITY  like '% DPO' or b.ADD_LINE_1  like 'APO' or b.ADD_LINE_1  like 'FPO' or b.ADD_LINE_1  like 'DPO' or b.ADD_LINE_2  like 'APO' or b.ADD_LINE_2  like 'FPO'  or b.ADD_LINE_2  like 'DPO' or b.ADD_LINE_1  like '% APO %' or b.ADD_LINE_1  like '% FPO %' or b.ADD_LINE_1  like '% DPO %' or b.ADD_LINE_2  like '% APO %' or b.ADD_LINE_2  like '% FPO %' or b.ADD_LINE_2  like '% DPO %' or b.ADD_LINE_1  like '% APO' or b.ADD_LINE_1  like '% FPO' or b.ADD_LINE_1  like '% DPO' or b.ADD_LINE_2  like '% APO' or b.ADD_LINE_2  like '% FPO' or b.ADD_LINE_2  like '% DPO' or b.ADD_LINE_1  like 'APO[ ,]%' or b.ADD_LINE_1  like 'FPO[ ,]%' or b.ADD_LINE_1  like 'DPO[ ,]%' or b.ADD_LINE_2  like 'APO[ ,]%' or b.ADD_LINE_2  like 'FPO[ ,]%' or b.ADD_LINE_2  like 'DPO[ ,]%' or b.ADD_LINE_1  like '%[ ,]APO[ ,]%' or b.ADD_LINE_1  like '%[ ,]FPO[ ,]%' or b.ADD_LINE_1  like '%[ ,]DPO[ ,]%' or b.ADD_LINE_2  like '%[ ,]APO[ ,]%' or b.ADD_LINE_2  like '%[ ,]FPO[ ,]%' or b.ADD_LINE_2  like '%[ ,]DPO[ ,]%' or b.ADD_LINE_1  like '%[ ,]APO[ ,]%' or b.ADD_LINE_1 like '%[ ,]FPO[ ,]%' or b.ADD_LINE_1 like '%[ ,]DPO[ ,]%' or b.ADD_LINE_2 like '%[ ,]APO[ ,]%' or b.ADD_LINE_2 like '%[ ,]FPO[ ,]%' or b.ADD_LINE_2  like '%[ ,]DPO[ ,]%' or b.ADD_LINE_1 like 'APOAA%' or b.ADD_LINE_1 like '%[ ,]APOAA%' or b.ADD_LINE_1 like 'APOAE%' or b.ADD_LINE_1 like '%[ ,]APOAE%' or b.ADD_LINE_1 like 'APOAP%' or b.ADD_LINE_1  like '%[ ,]APOAP%' or b.ADD_LINE_2  like 'APOAA%' or b.ADD_LINE_2  like '%[ ,]APOAA%' or b.ADD_LINE_2  like 'APOAE%' or b.ADD_LINE_2  like '%[ ,]APOAE%' or b.ADD_LINE_2  like 'APOAP%' or b.ADD_LINE_2  like '%[ ,]APOAP%' or b.ADD_LINE_1  like 'APOAA%' or b.ADD_LINE_1  like '%[ ,]APOAA%' or b.ADD_LINE_1  like 'APOAE%' or b.ADD_LINE_1  like '%[ ,]APOAE%' or b.ADD_LINE_1  like 'APOAP%' or b.ADD_LINE_1  like '%[ ,]APOAP%' or b.ADD_LINE_2  like 'APOAA%' or b.ADD_LINE_2  like '%[ ,]APOAA%' or b.ADD_LINE_2  like 'APOAE%' or b.ADD_LINE_2  like '%[ ,]APOAE%' or b.ADD_LINE_2  like 'APOAP%' or b.ADD_LINE_2  like '%[ ,]APOAP%' or b.ADD_LINE_1  like 'FPOAA%' or b.ADD_LINE_1  like '%[ ,]FPOAA%' or b.ADD_LINE_1  like 'FPOAE%' or b.ADD_LINE_1  like '%[ ,]FPOAE%' or b.ADD_LINE_1  like 'FPOAP%' or b.ADD_LINE_1  like '%[ ,]FPOAP%' or b.ADD_LINE_2  like 'FPOAA%' or b.ADD_LINE_2  like '%[ ,]FPOAA%' or b.ADD_LINE_2  like 'FPOAE%' or b.ADD_LINE_2  like '%[ ,]FPOAE%' or b.ADD_LINE_2  like 'FPOAP%' or b.ADD_LINE_2  like '%[ ,]FPOAP%' or b.ADD_LINE_1  like 'DPOAA%' or b.ADD_LINE_1  like '%[ ,]DPOAA%' or  b.ADD_LINE_1  like 'DPOAE%' or b.ADD_LINE_1  like '%[ ,]DPOAE%' or b.ADD_LINE_1  like 'DPOAP%' or b.ADD_LINE_1  like '%[ ,]DPOAP%' or b.ADD_LINE_2  like 'DPOAA%' or  b.ADD_LINE_2  like '%[ ,]DPOAA%' or b.ADD_LINE_2  like 'DPOAE%' or b.ADD_LINE_2  like '%[ ,]DPOAE%' or b.ADD_LINE_2  like 'DPOAP%' or b.ADD_LINE_2  like '%[ ,]DPOAP%'
                    )
then 1 else 0 end as MILITARY_ADDRESS,
--College/Campus PO Box office:
case when (b.ADD_LINE_1  like '%CPO%' or b.ADD_LINE_2  like '%CPO%' or b.ADD_LINE_1  like '%C[. ]P[. ]O[. ]%' or b.ADD_LINE_2  like '%C[. ]P[. ]O[. ]%' or b.ADD_LINE_1  like 'CPO%' or b.ADD_LINE_2  like 'CPO%' or b.ADD_LINE_1  like 'C[. ]P[. ]O[. ]%' or b.ADD_LINE_2  like 'C[. ]P[. ]O[. ]%'
                    )
then 1 else 0 end as COLLEGE_ADDRESS,
--Rural Route & Hiyway contract Route Addresses:
case when (     (UPPER(b.ADD_LINE_1)  like '%[ -]RR%' or UPPER(b.ADD_LINE_1)  like 'RR%' or UPPER(b.ADD_LINE_1)  like '%[ -]HC[ #]%' or UPPER(b.ADD_LINE_1)  like '%[ -]HC[0-9]%' or UPPER(b.ADD_LINE_1)  like 'HC[# ]%' or UPPER(b.ADD_LINE_1)  like 'HC[0-9]%'
                                                )
                                                and
                                                (UPPER(b.ADD_LINE_1)  like '%[ .,]BOX[ #]%' or UPPER(b.ADD_LINE_1)  like 'BOX%' or UPPER(b.ADD_LINE_1)  like '%[ .,]BOX[0-9]%' or UPPER(b.ADD_LINE_1)  like '%[ .,]BOX' or UPPER(b.ADD_LINE_1)  like '%[0-9]BOX'
                                                )
                                                and
                                                (UPPER(b.ADD_LINE_1) not like '%P[O,0]BOX %' and UPPER(b.ADD_LINE_1) not like '%P[O,0][., ]BOX%' and      UPPER(b.ADD_LINE_1) not like '%P[.,/] [O,0] BOX%' and UPPER(b.ADD_LINE_1) not like '%P[.,/ ][O,0][., ]BOX%' and UPPER(b.ADD_LINE_1) not like '%P[.,/ ][O,0][., ] BOX%' and UPPER(b.ADD_LINE_1) not like '%P[.,/] [O,0][.,] BOX%' and  UPPER(b.ADD_LINE_1) not like '%P[.,/] [O,0][.,] BOX%' and UPPER(b.ADD_LINE_1) not like '%UPS BOX%' and UPPER(b.ADD_LINE_1) not like '%UNIT%'
                                                )
                                    )
                    or
                    (      (UPPER(b.ADD_LINE_2)  like '%[ -]RR%' or UPPER(b.ADD_LINE_2)  like 'RR%' or UPPER(b.ADD_LINE_2)  like '%[ -]HC[ #]%' or UPPER(b.ADD_LINE_2)  like '%[ -]HC[0-9]%' or UPPER(b.ADD_LINE_2)  like 'HC[# ]%' or UPPER(b.ADD_LINE_2)  like 'HC[0-9]%')
                                and
                                (UPPER(b.ADD_LINE_2)  like '%[ .,]BOX[ #]%' or UPPER(b.ADD_LINE_2)  like 'BOX%' or UPPER(b.ADD_LINE_2)  like '%[ .,]BOX[0-9]%' or UPPER(b.ADD_LINE_2)  like '%[ .,]BOX' or UPPER(b.ADD_LINE_2)  like '%[0-9]BOX')
                                and
                                (UPPER(b.ADD_LINE_2) not like '%P[O,0]BOX %' and UPPER(b.ADD_LINE_2) not like '%P[O,0][., ]BOX%' and      UPPER(b.ADD_LINE_2) not like '%P[.,/] [O,0] BOX%' and UPPER(b.ADD_LINE_2) not like '%P[.,/ ][O,0][., ]BOX%' and UPPER(b.ADD_LINE_2) not like '%P[.,/ ][O,0][., ] BOX%' and UPPER(b.ADD_LINE_2) not like '%P[.,/] [O,0][.,] BOX%' and  UPPER(b.ADD_LINE_2) not like '%P[.,/] [O,0][.,] BOX%' and UPPER(b.ADD_LINE_2) not like '%UPS BOX%' and UPPER(b.ADD_LINE_2) not like '%UNIT%')
                    )
                or
                    (      (UPPER(b.ADD_LINE_1)  like '%[ -]RR%' or UPPER(b.ADD_LINE_1)  like 'RR%' or UPPER(b.ADD_LINE_1)  like '%[ -]HC[ #]%' or UPPER(b.ADD_LINE_1)  like '%[ -]HC[0-9]%' or UPPER(b.ADD_LINE_1)  like 'HC[# ]%' or UPPER(b.ADD_LINE_1)  like 'HC[0-9]%')
                                and
                                (UPPER(b.ADD_LINE_2)  like '%[ .,]BOX[ #]%' or UPPER(b.ADD_LINE_2)  like 'BOX%' or UPPER(b.ADD_LINE_2)  like '%[ .,]BOX[0-9]%' or UPPER(b.ADD_LINE_2)  like '%[ .,]BOX' or UPPER(b.ADD_LINE_2)  like '%[0-9]BOX')
                                and
                                (UPPER(b.ADD_LINE_2) not like '%P[O,0]BOX %' and UPPER(b.ADD_LINE_2) not like '%P[O,0][., ]BOX%' and      UPPER(b.ADD_LINE_2) not like '%P[.,/] [O,0] BOX%' and UPPER(b.ADD_LINE_2) not like '%P[.,/ ][O,0][., ]BOX%' and UPPER(b.ADD_LINE_2) not like '%P[.,/ ][O,0][., ] BOX%' and UPPER(b.ADD_LINE_2) not like '%P[.,/] [O,0][.,] BOX%' and  UPPER(b.ADD_LINE_2) not like '%P[.,/] [O,0][.,] BOX%' and UPPER(b.ADD_LINE_2) not like '%UPS BOX%' and UPPER(b.ADD_LINE_1) not like '%UNIT%' and UPPER(b.ADD_LINE_2) not like '%UNIT%')
                    )
                    or
                    (      (UPPER(b.ADD_LINE_2)  like '%[ -]RR%' or UPPER(b.ADD_LINE_2)  like 'RR%' or UPPER(b.ADD_LINE_2)  like '%[ -]HC[ #]%' or UPPER(b.ADD_LINE_2)  like '%[ -]HC[0-9]%' or UPPER(b.ADD_LINE_2)  like 'HC[# ]%' or UPPER(b.ADD_LINE_2)  like 'HC[0-9]%')
                                and
                                (UPPER(b.ADD_LINE_1)  like '%[ .,]BOX[ #]%' or UPPER(b.ADD_LINE_1)  like 'BOX%' or UPPER(b.ADD_LINE_1)  like '%[ .,]BOX[0-9]%' or UPPER(b.ADD_LINE_1)  like '%[ .,]BOX' or UPPER(b.ADD_LINE_1)  like '%[0-9]BOX')
                                and
                                (UPPER(b.ADD_LINE_1) not like '%P[O,0]BOX %' and UPPER(b.ADD_LINE_1) not like '%P[O,0][., ]BOX%' and      UPPER(b.ADD_LINE_1) not like '%P[.,/] [O,0] BOX%' and UPPER(b.ADD_LINE_1) not like '%P[.,/ ][O,0][., ]BOX%' and UPPER(b.ADD_LINE_1) not like '%P[.,/ ][O,0][., ] BOX%' and UPPER(b.ADD_LINE_1) not like '%P[.,/] [O,0][.,] BOX%' and  UPPER(b.ADD_LINE_1) not like '%P[.,/] [O,0][.,] BOX%' and UPPER(b.ADD_LINE_1) not like '%UPS BOX%' and UPPER(b.ADD_LINE_1) not like '%UNIT%'  and UPPER(b.ADD_LINE_1) not like '%UNIT%')
                    )
then 1 else 0 end as RRHC_ADDRESS,
--Private mail box /private PO Box:
case when (UPPER(b.ADD_LINE_1) like '%MAILBOX%' or UPPER(b.ADD_LINE_1) like '%MAIL BOX%' or UPPER(b.ADD_LINE_1) like 'PMB[0-9]%' or  UPPER(b.ADD_LINE_1) like 'PMB %' or UPPER(b.ADD_LINE_1) like '%[0-9]PMB' or UPPER(b.ADD_LINE_1)  like '%[0-9] PMB' or UPPER(b.ADD_LINE_1)  like 'PMB[-#]%' or UPPER(b.ADD_LINE_1)  like 'PMB' or UPPER(b.ADD_LINE_1)  like '% PMB %' or UPPER(b.ADD_LINE_1)  like '%[,/-]PMB[0-9]%' or UPPER(b.ADD_LINE_1)  like '%[,/-]PMB [0-9]%' or UPPER(b.ADD_LINE_1)  like '%[,/-]PMB' or UPPER(b.ADD_LINE_1)  like '% PMB[0-9]%' or UPPER(b.ADD_LINE_1)  like '%[,/] PMB[0-9]%' or UPPER(b.ADD_LINE_1)  like '%[,/] PMB [0-9]%' or UPPER(b.ADD_LINE_1)  like '% PMB' or UPPER(b.ADD_LINE_2)  like 'PMB[0-9]%' or UPPER(b.ADD_LINE_2)  like 'PMB %' or UPPER(b.ADD_LINE_2)  like '%[0-9]PMB' or UPPER(b.ADD_LINE_2)  like '%[0-9]PMB' or UPPER(b.ADD_LINE_2)  like 'PMB[-#]%' or UPPER(b.ADD_LINE_2)  like 'PMB' or UPPER(b.ADD_LINE_2)  like '% PMB %' or UPPER(b.ADD_LINE_2)  like '%[,/-]PMB[0-9]%' or UPPER(b.ADD_LINE_2)  like '%[,/-]PMB [0-9]%' or UPPER(b.ADD_LINE_2)  like '%[,/-]PMB' or UPPER(b.ADD_LINE_2)  like '% PMB[0-9]%' or UPPER(b.ADD_LINE_2)  like '%[,/] PMB[0-9]%' or  UPPER(b.ADD_LINE_2)  like '%[,/] PMB [0-9]%' or UPPER(b.ADD_LINE_2)  like '% PMB'
                                    )
then 1 else 0 end as PMB_ADDRESS,
--USPS PO Box:
case when (UPPER(b.ADD_LINE_1)  like '%P[O,0]BOX %' or UPPER(b.ADD_LINE_2)  like '%P[O,0]BOX %' or UPPER(b.ADD_LINE_1)  like '%P[O,0][., ]BOX%' or UPPER(b.ADD_LINE_2)  like '%P[O,0][., ]BOX%' or UPPER(b.ADD_LINE_1)  like '%P[.,/] [O,0] BOX%' or UPPER(b.ADD_LINE_2)  like '%P[.,/] [O,0] BOX%' or UPPER(b.ADD_LINE_1)  like '%P[.,/ ][O,0][., ]BOX%' or UPPER(b.ADD_LINE_2)  like '%P[.,/ ][O,0][., ]BOX%' or UPPER(b.ADD_LINE_1)  like '%P[.,/ ][O,0][., ] BOX%' or UPPER(b.ADD_LINE_2)  like '%P[.,/ ][O,0][., ] BOX%' or UPPER(b.ADD_LINE_1)  like '%P[.,/] [O,0][.,] BOX%' or UPPER(b.ADD_LINE_2)  like '%P[.,/] [O,0][.,] BOX%' or UPPER(b.ADD_LINE_1)  like '%P[.,/] [O,0][.,] BOX%' or UPPER(b.ADD_LINE_2)  like '%P[.,/] [O,0][.,] BOX%' or UPPER(b.ADD_LINE_1)  like '%UPS BOX%' or UPPER(b.ADD_LINE_2)  like '%UPS BOX%'
                                    )
                                    and
                                    (UPPER(b.ADD_LINE_1) not like '% APT%' and UPPER(b.ADD_LINE_2) not like '% APT%' and UPPER(b.ADD_LINE_1) not like 'APT%' and UPPER(b.ADD_LINE_2) not like 'APT%'
                                    )
                                    and
                                    (b.STATE_C  in ('ALABAMA','ALASKA','ARIZONA','ARKANSAS','CALIFORNIA','COLORADO','CONNECTICUT','DELAWARE','DISTRICT OF COLUMBIA','FLORIDA','GEORGIA','HAWAII','IDAHO','ILLINOIS','INDIANA','IOWA','KANSAS','KENTUCKY','LOUISIANA','MAINE','MARYLAND','MASSACHUSETTS','MICHIGAN','MINNESOTA','MISSISSIPPI','MISSOURI','MONTANA','NEBRASKA','NEVADA','NEW HAMPSHIRE','NEW JERSEY','NEW MEXICO','NEW YORK','NORTH CAROLINA','NORTH DAKOTA','OHIO','OKLAHOMA','OREGON','PENNSYLVANIA','RHODE ISLAND','SOUTH CAROLINA','SOUTH DAKOTA','TENNESSEE','TEXAS','UTAH','VERMONT','VIRGINIA','WASHINGTON','WEST VIRGINIA','WISCONSIN','WYOMING',
												'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
												'AMERICAN SAMOA','GUAM','NORTHERN MARIANA ISLANDS','PUERTO RICO','U.S. VIRGIN ISLANDS','VIRGIN ISLANDS','MINOR OUTLYING ISLANDS','BAJO NUEVO BANK','BAKER ISLAND','HOWLAND ISLAND','JARVIS ISLAND','JOHNSTON ATOLL','KINGMAN REEF','MIDWAY ISLANDS','NAVASSA ISLAND','PALMYRA ATOLL','SERRANILLA BANK','WAKE ISLAND'
												)
                                    or
                                                (b.STATE_C is NULL
                                                and
                                                (b.CITY like '%ALABAMA' or b.CITY like '%ALASKA' or b.CITY like '%ARIZONA' or b.CITY like '%ARKANSAS' or b.CITY like '%CALIFORNIA' or b.CITY like '%COLORADO' or b.CITY like '%CONNECTICUT' or b.CITY like '%DELAWARE' or b.CITY like '%DISTRICT OF COLUMBIA' or b.CITY like '%FLORIDA' or b.CITY like '%GEORGIA' or b.CITY like '%HAWAII' or b.CITY like '%IDAHO' or b.CITY like '%ILLINOIS' or b.CITY like '%INDIANA' or b.CITY like '%IOWA' or b.CITY like '%KANSAS' or b.CITY like '%KENTUCKY' or b.CITY like '%LOUISIANA' or b.CITY like '%MAINE' or b.CITY like '%MARYLAND' or b.CITY like '%MASSACHUSETTS' or b.CITY like '%MICHIGAN' or b.CITY like '%MINNESOTA' or b.CITY like '%MISSISSIPPI' or b.CITY like '%MISSOURI' or b.CITY like '%MONTANA' or b.CITY like '%NEBRASKA' or b.CITY like '%NEVADA' or b.CITY like '%NEW HAMPSHIRE' or b.CITY like '%NEW JERSEY' or b.CITY like '%NEW MEXICO' or b.CITY like '%NEW YORK' or b.CITY like '%NORTH CAROLINA' or b.CITY like '%NORTH DAKOTA' or b.CITY like '%OHIO' or b.CITY like '%OKLAHOMA' or b.CITY like '%OREGON' or b.CITY like '%PENNSYLVANIA' or b.CITY like '%RHODE ISLAND' or b.CITY like '%SOUTH CAROLINA' or b.CITY like '%SOUTH DAKOTA' or b.CITY like '%TENNESSEE' or b.CITY like '%TEXAS' or b.CITY like '%UTAH' or b.CITY like '%VERMONT' or b.CITY like '%VIRGINIA' or b.CITY like '%WASHINGTON' or b.CITY like '%WEST VIRGINIA' or b.CITY like '%WISCONSIN' or b.CITY like '%WYOMING' or
                                                b.CITY like '% AL' or b.CITY like '% AK' or b.CITY like '% AZ' or b.CITY like '% AR' or b.CITY like '% CA' or b.CITY like '% CO' or b.CITY like '% CT' or b.CITY like '% DE' or b.CITY like '% FL' or b.CITY like '% GA' or b.CITY like '% HI' or b.CITY like '% ID' or b.CITY like '% IL' or b.CITY like '% IN' or b.CITY like '% IA' or b.CITY like '% KS' or b.CITY like '% KY' or b.CITY like '% LA' or b.CITY like '% ME' or b.CITY like '% MD' or b.CITY like '% MA' or b.CITY like '% MI' or b.CITY like '% MN' or b.CITY like '% MS' or b.CITY like '% MO' or b.CITY like '% MT' or b.CITY like '% NE' or b.CITY like '% NV' or b.CITY like '% NH' or b.CITY like '% NJ' or b.CITY like '% NM' or b.CITY like '% NY' or b.CITY like '% NC' or b.CITY like '% ND' or b.CITY like '% OH' or b.CITY like '% OK' or b.CITY like '% OR' or b.CITY like '% PA' or b.CITY like '% RI' or b.CITY like '% SC' or b.CITY like '% SD' or b.CITY like '% TN' or b.CITY like '% TX' or b.CITY like '% UT' or b.CITY like '% VT' or b.CITY like '% VA' or b.CITY like '% WA' or b.CITY like '% WV' or b.CITY like '% WI' or b.CITY like '% WY' or
                                                b.CITY like '%AMERICAN SAMOA' or b.CITY like '%GUAM' or b.CITY like '%NORTHERN MARIANA ISLANDS' or b.CITY like '%PUERTO RICO' or b.CITY like '%U.S. VIRGIN ISLANDS' or b.CITY like '%VIRGIN ISLANDS' or b.CITY like '%MINOR OUTLYING ISLANDS' or b.CITY like '%BAJO NUEVO BANK' or b.CITY like '%BAKER ISLAND' or b.CITY like '%HOWLAND ISLAND' or b.CITY like '%JARVIS ISLAND' or b.CITY like '%JOHNSTON ATOLL' or b.CITY like '%KINGMAN REEF' or b.CITY like '%MIDWAY ISLANDS' or b.CITY like '%NAVASSA ISLAND' or b.CITY like '%PALMYRA ATOLL' or b.CITY like '%SERRANILLA BANK' or b.CITY like '%WAKE ISLAND'
                                                )
                                        )
                                    )
                                    and
            --Military po box:
                                    (b.CITY not like 'APO' and b.CITY not like 'FPO' and b.CITY not like 'DPO' and b.CITY not like '% APO %' and b.CITY not like '% FPO %' and b.CITY not like '% DPO %' and b.CITY not like '% APO' and b.CITY not like '% FPO' and b.CITY not like '% DPO' and b.CITY not like 'APO %' and b.CITY not like 'FPO %' and b.CITY not like '% DPO' and b.ADD_LINE_1 not like 'APO' and b.ADD_LINE_1 not like 'FPO' and b.ADD_LINE_1 not like 'DPO' and b.ADD_LINE_2 not like 'APO' and b.ADD_LINE_2 not like 'FPO'  and b.ADD_LINE_2 not like 'DPO' and b.ADD_LINE_1 not like '% APO %' and b.ADD_LINE_1 not like '% FPO %' and b.ADD_LINE_1 not like '% DPO %' and b.ADD_LINE_2 not like '% APO %' and b.ADD_LINE_2 not like '% FPO %' and b.ADD_LINE_2 not like '% DPO %' and b.ADD_LINE_1 not like '% APO' and b.ADD_LINE_1 not like '% FPO' and b.ADD_LINE_1 not like '% DPO' and b.ADD_LINE_2 not like '% APO' and b.ADD_LINE_2 not like '% FPO' and b.ADD_LINE_2 not like '% DPO' and b.ADD_LINE_1 not like 'APO[ ,]%' and b.ADD_LINE_1 not like 'FPO[ ,]%' and b.ADD_LINE_1 not like 'DPO[ ,]%' and b.ADD_LINE_2 not like 'APO[ ,]%' and b.ADD_LINE_2 not like 'FPO[ ,]%' and b.ADD_LINE_2 not like 'DPO[ ,]%' and b.ADD_LINE_1 not like '%[ ,]APO[ ,]%' and b.ADD_LINE_1 not like '%[ ,]FPO[ ,]%' and b.ADD_LINE_1 not like '%[ ,]DPO[ ,]%' and b.ADD_LINE_2 not like '%[ ,]APO[ ,]%' and b.ADD_LINE_2 not like '%[ ,]FPO[ ,]%' and b.ADD_LINE_2 not like '%[ ,]DPO[ ,]%' and b.ADD_LINE_1 not like '%[ ,]APO[ ,]%' and b.ADD_LINE_1 not like '%[ ,]FPO[ ,]%' and b.ADD_LINE_1 not like '%[ ,]DPO[ ,]%' and b.ADD_LINE_2 not like '%[ ,]APO[ ,]%' and b.ADD_LINE_2 not like '%[ ,]FPO[ ,]%' and b.ADD_LINE_2 not like '%[ ,]DPO[ ,]%' and b.ADD_LINE_1 not like 'APOAA%' and b.ADD_LINE_1 not like '%[ ,]APOAA%' and b.ADD_LINE_1 not like 'APOAE%' and b.ADD_LINE_1 not like '%[ ,]APOAE%' and b.ADD_LINE_1 not like 'APOAP%' and b.ADD_LINE_1 not like '%[ ,]APOAP%' and b.ADD_LINE_2 not like 'APOAA%' and b.ADD_LINE_2 not like '%[ ,]APOAA%' and b.ADD_LINE_2 not like 'APOAE%' and b.ADD_LINE_2 not like '%[ ,]APOAE%' and b.ADD_LINE_2 not like 'APOAP%' and b.ADD_LINE_2 not like '%[ ,]APOAP%' and b.ADD_LINE_1 not like 'APOAA%' and b.ADD_LINE_1 not like '%[ ,]APOAA%' and b.ADD_LINE_1 not like 'APOAE%' and b.ADD_LINE_1 not like '%[ ,]APOAE%' and b.ADD_LINE_1 not like 'APOAP%' and b.ADD_LINE_1 not like '%[ ,]APOAP%' and b.ADD_LINE_2 not like 'APOAA%' and b.ADD_LINE_2 not like '%[ ,]APOAA%' and b.ADD_LINE_2 not like 'APOAE%' and b.ADD_LINE_2 not like '%[ ,]APOAE%' and b.ADD_LINE_2 not like 'APOAP%' and b.ADD_LINE_2 not like '%[ ,]APOAP%' and b.ADD_LINE_1 not like 'FPOAA%' and b.ADD_LINE_1 not like '%[ ,]FPOAA%' and b.ADD_LINE_1 not like 'FPOAE%' and b.ADD_LINE_1 not like '%[ ,]FPOAE%' and b.ADD_LINE_1 not like 'FPOAP%' and b.ADD_LINE_1 not like '%[ ,]FPOAP%' and b.ADD_LINE_2 not like 'FPOAA%' and b.ADD_LINE_2 not like '%[ ,]FPOAA%' and b.ADD_LINE_2 not like 'FPOAE%' and b.ADD_LINE_2 not like '%[ ,]FPOAE%' and b.ADD_LINE_2 not like 'FPOAP%' and b.ADD_LINE_2 not like '%[ ,]FPOAP%' and b.ADD_LINE_1 not like 'DPOAA%' and b.ADD_LINE_1 not like '%[ ,]DPOAA%' and b.ADD_LINE_1 not like 'DPOAE%' and b.ADD_LINE_1 not like '%[ ,]DPOAE%' and b.ADD_LINE_1 not like 'DPOAP%' and b.ADD_LINE_1 not like '%[ ,]DPOAP%' and b.ADD_LINE_2 not like 'DPOAA%' and b.ADD_LINE_2 not like '%[ ,]DPOAA%' and b.ADD_LINE_2 not like 'DPOAE%' and b.ADD_LINE_2 not like '%[ ,]DPOAE%' and b.ADD_LINE_2 not like 'DPOAP%' and b.ADD_LINE_2 not like '%[ ,]DPOAP%'
                                    )
                                    and
                --College post office:
                                    (b.ADD_LINE_1 not like '%CPO%' and b.ADD_LINE_2 not like '%CPO%' and b.ADD_LINE_1 not like '%C[. ]P[. ]O[. ]%' and b.ADD_LINE_2 not like '%C[. ]P[. ]O[. ]%' and b.ADD_LINE_1 not like 'CPO%' and b.ADD_LINE_2 not like 'CPO%' and b.ADD_LINE_1 not like 'C[. ]P[. ]O[. ]%' and b.ADD_LINE_2 not like 'C[. ]P[. ]O[. ]%'
                                    )
                                    and
                                    (UPPER(b.ADD_LINE_1) not like 'PMB[0-9]%' and  UPPER(b.ADD_LINE_1) not like 'PMB %' and UPPER(b.ADD_LINE_1) not like '%[0-9]PMB' and UPPER(b.ADD_LINE_1) not like '%[0-9] PMB' and UPPER(b.ADD_LINE_1) not like 'PMB[-#]%' and UPPER(b.ADD_LINE_1) not like 'PMB' and UPPER(b.ADD_LINE_1) not like '% PMB %' and UPPER(b.ADD_LINE_1) not like '%[,/-]PMB[0-9]%' and UPPER(b.ADD_LINE_1) not like '%[,/-]PMB [0-9]%' and UPPER(b.ADD_LINE_1) not like '%[,/-]PMB' and UPPER(b.ADD_LINE_1) not like '% PMB[0-9]%' and UPPER(b.ADD_LINE_1) not like '%[,/] PMB[0-9]%' and UPPER(b.ADD_LINE_1) not like '%[,/] PMB [0-9]%' and UPPER(b.ADD_LINE_1) not like '% PMB' and UPPER(b.ADD_LINE_2) not like 'PMB[0-9]%' and UPPER(b.ADD_LINE_2) not like 'PMB %' and UPPER(b.ADD_LINE_2) not like '%[0-9]PMB' and UPPER(b.ADD_LINE_2) not like '%[0-9]PMB' and UPPER(b.ADD_LINE_2) not like 'PMB[-#]%' and UPPER(b.ADD_LINE_2) not like 'PMB' and UPPER(b.ADD_LINE_2) not like '% PMB %' and UPPER(b.ADD_LINE_2) not like '%[,/-]PMB[0-9]%' and UPPER(b.ADD_LINE_2) not like '%[,/-]PMB [0-9]%' and UPPER(b.ADD_LINE_2) not like '%[,/-]PMB' and UPPER(b.ADD_LINE_2) not like '% PMB[0-9]%' and UPPER(b.ADD_LINE_2) not like '%[,/] PMB[0-9]%' and  UPPER(b.ADD_LINE_2) not like '%[,/] PMB [0-9]%' and UPPER(b.ADD_LINE_2) not like '% PMB'
                                    )
then 1 else 0 end as POBOX_ADDRESS,
        b.DeGAUSS
into #NextD_SES
from /* provide name of table 1 here: */ #Final_Table1 c
join  /* provide name the table containing c.PATID,Hashes, and Global patient id*/ #GlobalIDtable d on c.PATID=d.PATID
left join /* provide name of non-PCORNET table with patient's addreses,SES data and details of geocoding here: */ #SES b on c.PATID=b.PATID;

select GTRACT_ACSlikeLABEL,
				prop_white,prop_black,prop_hispanic,prop_nh_white,prop_nh_black,prop_h_white,prop_h_black,prop_asian,prop_other,prop_female,prop_yrs_under_5,prop_yrs_5_19,prop_yrs_20_24,
				prop_yrs_35_44,prop_yrs_25_34,prop_yrs_45_54,prop_yrs_55_64,prop_yrs_65_74,prop_yrs_75_84,prop_yrs_85_plus,prop_married,prop_never_married,prop_divorced,prop_widowed,
				prop_lt_high_school,prop_high_school,prop_some_college,prop_college_grad,prop_english,prop_spanish,prop_other_language,prop_poor_english,prop_employer,prop_direct,
				prop_medicare,prop_medicaid,prop_tricare_va,prop_medicare_medicaid,prop_no_insurance,prop_employed,prop_unemployed,prop_nilf,prop_full_time,prop_part_time,prop_vet,
				median_hh_income,median_earnings,per_capita_income,prop_hh_size_1,prop_hh_size_2,prop_hh_size_3,prop_hh_size_4plus,prop_home_owner,median_gross_rent,prop_us_native_born,
				prop_us_foreign_born,prop_non_us,prop_poverty,prop_disabled,prop_food_stamps,tdi,moe_prop_white,moe_prop_black,moe_prop_hispanic,moe_prop_nh_white,moe_prop_nh_black,
				moe_prop_h_white,moe_prop_h_black,moe_prop_asian,moe_prop_other,moe_prop_female,moe_prop_yrs_under_5,moe_prop_yrs_5_19,moe_prop_yrs_20_24,moe_prop_yrs_35_44,moe_prop_yrs_25_34,
				moe_prop_yrs_45_54,moe_prop_yrs_55_64,moe_prop_yrs_65_74,moe_prop_yrs_75_84,moe_prop_yrs_85_plus,moe_prop_married,moe_prop_never_married,moe_prop_divorced,moe_prop_widowed,
				moe_prop_lt_high_school,moe_prop_high_school,moe_prop_some_college,moe_prop_college_grad,moe_prop_english,moe_prop_spanish,moe_prop_other_language,moe_prop_poor_english,
				moe_prop_employer,moe_prop_direct,moe_prop_medicare,moe_prop_medicaid,moe_prop_tricare_va,moe_prop_medicare_medicaid,moe_prop_no_insurance,moe_prop_employed,moe_prop_unemployed,
				moe_prop_nilf,moe_prop_full_time,moe_prop_part_time,moe_prop_vet,moe_median_hh_income,moe_median_earnings,moe_per_capita_income,moe_prop_hh_size_1,moe_prop_hh_size_2,
				moe_prop_hh_size_3,moe_prop_hh_size_4plus,moe_prop_home_owner,moe_median_gross_rent,moe_prop_us_native_born,moe_prop_us_foreign_born,moe_prop_non_us,moe_prop_poverty,
				moe_prop_disabled,moe_prop_food_stamps,primary_RUCA,secondary_RUCA,Dep_index
into #NextD_SES
from /* create table from distributed flat file here: */ #SESvariables b on c.PATID=b.PATID;
---------------------------------------------------------------------------------------------------------------
/* Save #NextD_SES as csv file.
Use "|" symbol as field terminator and
"ENDALONAEND" as row terminator. */
---------------------------------------------------------------------------------------------------------------
  