/*** Block 5C: get most recent eGFR for patient who has eGFR ***/
IF OBJECT_ID('#GFRrecent') IS NOT NULL
	DROP TABLE @target_database_schema.#GFRrecent;
CREATE TABLE @target_database_schema.#GFRrecent (
	person_id INT NOT NULL
	,eGFRrecentVal FLOAT NOT NULL
	,eGFRrecentDt DATETIME2(6) NOT NULL
);

INSERT INTO @target_database_schema.#GFRrecent
SELECT person_id, eGFR AS eGFRrecentVal, measurement_date AS eGFRrecentDt
FROM (
	SELECT person_id, eGFR, measurement_date, ROW_NUMBER() OVER(PARTITION BY person_id ORDER by measurement_date DESC) AS rn
FROM @target_database_schema.#eGFR
) G
WHERE rn =1;


/* *** BLOCK 6: Dialysis co-occurrent with AKI, defined as AKI happens before or after 1 month of dialysis, 1 month is defined as 31 days (DATEDIFF in month is 1 if the difference between two dates is 1.5 months) ****/
IF OBJECT_ID('#DialysisCooccurrentWithAKI') IS NOT NULL
	DROP TABLE #DialysisCooccurrentWithAKI;
CREATE TABLE @target_database_schema.#DialysisCooccurrentWithAKI (
	person_id INT,
	dialysisDt DATETIME2(6),
	akiDt DATETIME2(6),
	dialysisAkiDiffDtAbs INT
);

INSERT INTO @target_database_schema.#DialysisCooccurrentWithAKI
SELECT DISTINCT T.subject_id, T.cohort_start_date AS dialysisDt, U.cohort_start_date AS akiDt,
	ABS(DATEDIFF(day, T.cohort_start_date, U.cohort_start_date)) AS dialysisAkiDiffDtAbs
FROM @target_database_schema.cohort T
LEFT JOIN @target_database_schema.cohort U
ON T.subject_id=U.subject_id 
WHERE T.cohort_definition_id = 1001 -- dialysis
AND U.cohort_definition_id = 1003 -- acute CK
AND ABS(DATEDiff(DAY, T.cohort_start_date, U.cohort_start_date)) <= 31 --For acute calculating of 1 month by using 31 days. 
;
 
/* *** BLOCK 7: eGFR co-occurrent with acute conditions (AKI/prerenal kidney injury/sepsis/volume depletion/shock), defined as acute conditions happen before or after 1 month of eGFR *** */
IF OBJECT_ID('#GfrCooccurrentWithAcuteCondition') IS NOT NULL
	DROP TABLE  @target_database_schema.#GfrCooccurrentWithAcuteCondition;
CREATE TABLE  @target_database_schema.#GfrCooccurrentWithAcuteCondition(
	person_id INT,
	eGfrDt DATETIME2(6),
	acuteConditionDt DATETIME2(6),
	eGfrAcuteConditionDiffDtAbs INT
	);
		
INSERT INTO @target_database_schema.#GfrCooccurrentWithAcuteCondition
SELECT DISTINCT T.person_id, T.measurement_date AS eGfrDt, U.cohort_start_date AS acuteConditionDt
	,  ABS(DATEDIFF(day, T.measurement_date, U.cohort_start_date)) AS eGfrAcuteConditionDiffDtAbs
FROM #eGFR T
LEFT JOIN @target_database_schema.cohort U
ON T.person_id=U.subject_id 
WHERE cohort_definition_id IN (1002,1003) -- AKD, Other acute conditions
AND ABS(DATEDIFF(day, T.measurement_date, U.cohort_start_date)) <= 31 --For acute calculating of 1 month by using 31 days.
 ;

/* *** BLOCK 8: A-staging: get all urine protein test and corresponding A stage first *** */
/*** Block 8B: A-staging for A24 and UACR */
IF OBJECT_ID('#protein_stage') IS NOT NULL
	DROP TABLE #protein_stage;
CREATE TABLE @target_database_schema.#protein_stage (
	person_id INT,
	measurement_date DATETIME2(6),
	stage VARCHAR(100),
        eventtype VARCHAR(100),
	value_as_number FLOAT 
);
INSERT INTO  @target_database_schema.#protein_stage
    SELECT
      person_id,
      measurement_date,
      CASE WHEN value_as_number < 30
        THEN 'A1'
      WHEN value_as_number >= 30 AND value_as_number <= 300
        THEN 'A2'
      WHEN value_as_number > 300
        THEN 'A3' END AS stage,
      'albumin' as eventtype,
      value_as_number
    FROM
      (SELECT DISTINCT
         person_id,
         m.measurement_date,
         m.measurement_concept_id,
         case when unit_concept_id in (8723, 8751, 8909, 8576)
           then value_as_number -- mg/g, mg/l,mg/24h,mg
         when unit_concept_id = 8840
           then value_as_number / 10 --mg/dl
         when unit_concept_id in (8861, 8504, 8636)
           then value_as_number / 1000 --mg/ml,g/l,g
         when unit_concept_id = 8753
           then value_as_number/1500 --mmol/l
         else null end AS value_as_number,
         value_as_concept_id
       FROM @cdm_database_schema.MEASUREMENT m
       JOIN @target_database_schema.#ckd_codes ON concept_id = measurement_concept_id where category = 'albumin'
	   WHERE value_as_number IS NOT NULL
      ) alb;


/*** Block 8C: A-staging for P24 and UPCR (0 value corresponds to A1 stage) ***/
 INSERT INTO @target_database_schema.#protein_stage
    SELECT
      person_id,
      measurement_date,
      CASE WHEN PA1 >= PA2 AND PA1 >= PA3
        THEN 'A1'
      WHEN PA2 >= PA1 AND PA2 >= PA3
        THEN 'A2'
      WHEN PA3 >= PA1 AND PA3 >= PA2
        THEN 'A3' END AS stage,
      'protein' as eventtype,
      value_as_number
    FROM (
           SELECT
             *,
             1 - PA1 - PA2 AS PA3
           FROM (
                  SELECT
                    *,
                    CASE WHEN value_as_number = 0
                      THEN '1'
                    ELSE exp(13.136 - 2.497 * log(value_as_number)) /
                         (1 + exp(13.136 - 2.497 * log(value_as_number))) END AS PA1,
                    CASE WHEN value_as_number = 0
                      THEN '0'
                    ELSE exp(17.993 - 2.666 * log(value_as_number)) /
                         (1 + exp(17.993 - 2.666 * log(value_as_number))) - exp(13.136 - 2.497 * log(value_as_number))
                                                                          / (1 + exp(13.136 - 2.497 * log(value_as_number))) END           AS PA2
                  FROM
                    (SELECT DISTINCT
                       person_id,
                       m.measurement_date,
                       m.measurement_concept_id,
                       case when unit_concept_id in (8723, 8751, 8909, 8576)
                         then value_as_number -- mg/g, mg/l,mg/24h,mg
                       when unit_concept_id = 8840
                         then value_as_number / 10 --mg/dl
                       when unit_concept_id in (8861, 8504, 8636)
                         then value_as_number / 1000 --mg/ml,g/l,g
                       when unit_concept_id = 8753
                         then value_as_number/1500 --mmol/l
                       else null end AS value_as_number,
                       value_as_concept_id
                     FROM @cdm_database_schema.MEASUREMENT m
                       join @target_database_schema.#ckd_codes on measurement_concept_id = concept_id
                     where category = 'protein'
                     
			) pr1
                  where pr1.value_as_number is not null
        	 ) pr2
 	 ) pr3;


/*** Block 8D: A-staging for Dipstick Urine Analysis Protein. UA protein data range is Negative, Trace, 1+, 2+, 3+, 4+ ***/
/** UA Protein with co-occurrent SG **/
INSERT INTO #protein_stage
  SELECT DISTINCT
    person_id,
    uaProteinDate,
    CASE WHEN PA1 >= PA2 AND PA1 >= PA3
      THEN 'A1'
    WHEN PA2 >= PA1 AND PA2 >= PA3
      THEN 'A2'
    WHEN PA3 >= PA1 AND PA3 >= PA2
      THEN 'A3' END AS stage,
    'protein' as eventtype,
     uaProteinNumValue as value_as_number 
  FROM (
         SELECT
           *,
           PA1A2 - PA1 AS PA2,
           1 - PA1A2   AS PA3
         FROM (
                SELECT DISTINCT
                  T1.person_id,
                  T1.measurement_date  AS uaProteinDate,
                  CASE WHEN T1.value_as_concept_id in (45878583,9189) -- 'Negative'
                    THEN 0
                  WHEN T1.value_as_concept_id in (45881796,9192,45878303) -- 'Trace' 
                    THEN 1
                  WHEN T1.value_as_concept_id = 45878548 -- '1+'
                    THEN 2
                  WHEN T1.value_as_concept_id IN (45878148,45881916,45878148,45878305,45876467,45881623) --('2+', '3+', '4+')
                    THEN 3 END       AS uaProteinNumValue,
                  CASE WHEN T1.value_as_concept_id in (45878583,9189)
                    THEN exp(-141.736 + 140.813 * T2.value_as_number) / (1 + exp(-141.736 + 140.813 * T2.value_as_number))
                  WHEN T1.value_as_concept_id in (45881796,9192,45878303) -- 'Trace' 
                    THEN exp(-143.142 + 140.813 * T2.value_as_number) / (1 + exp(-143.142 + 140.813 * T2.value_as_number))
                  WHEN T1.value_as_concept_id = 45878548 -- '1+'
                    THEN exp(-145.145 + 140.813 * T2.value_as_number) / (1 + exp(-145.145 + 140.813 * T2.value_as_number))
                  WHEN T1.value_as_concept_id IN (45878148,45881916,45878148,45878305,45876467,45881623)--('2+', '3+', '4+')
                    THEN exp(-148.117 + 140.813 * T2.value_as_number) / (1 + exp(-148.117 + 140.813 * T2.value_as_number))
                  END                AS PA1,
                  CASE WHEN T1.value_as_concept_id in (45878583,9189)
                    THEN exp(-200.777 + 203.011 * T2.value_as_number) / (1 + exp(-200.777 + 203.011 * T2.value_as_number))
                  WHEN T1.value_as_concept_id  in (45881796,9192,45878303) -- 'Trace' 
                    THEN exp(-202.959 + 203.011 * T2.value_as_number) / (1 + exp(-202.959 + 203.011 * T2.value_as_number))
                  WHEN T1.value_as_concept_id = 45878548 -- '1+'
                    THEN exp(-204.642 + 203.011 * T2.value_as_number) / (1 + exp(-204.642 + 203.011 * T2.value_as_number))
                  WHEN T1.value_as_concept_id IN (45878148,45881916,45878148,45878305,45876467,45881623)--('2+', '3+', '4+')
                    THEN exp(-208.287 + 203.011 * T2.value_as_number) / (1 + exp(-208.287 + 203.011 * T2.value_as_number))
                  END                AS PA1A2,
                  T2.value_as_number AS SgValue
                FROM (select *
                      FROM @cdm_database_schema.MEASUREMENT
                        join @target_database_schema.#ckd_codes on measurement_concept_id = concept_id
                                          and category = 'protein') T1
                  LEFT JOIN
                  (SELECT *
                   FROM @cdm_database_schema.MEASUREMENT
                     join @target_database_schema.#ckd_codes on measurement_concept_id = concept_id
                                       and category = 'gravity'
		    where value_as_number < '1.05' and value_as_number > '1') T2
                    ON T1.person_id = T2.person_id
                       AND T1.measurement_date = T2.measurement_date
                                WHERE T2.value_as_number is not null

              ) pr1
       ) pr2;

/** UA Protein without SG **/
INSERT INTO #protein_stage
SELECT DISTINCT T1.person_id, T1.measurement_date,
CASE WHEN T1.value_as_concept_id  in (45878583,9189) -- 'Negative'
	THEN 'A1'
	WHEN T1.value_as_concept_id  in (45881796,9192,45878303) -- 'Trace' 
	THEN 'A1'
	WHEN T1.value_as_concept_id  = 45878548 -- '1+'
	THEN 'A2'
	WHEN T1.value_as_concept_id  IN (45878148,45881916,45878148,45878305,45876467,45881623)--('2+', '3+', '4+') 
	THEN 'A3' END AS stage,
'protein' as eventtype,
CASE WHEN T1.value_as_concept_id  in (45878583,9189) -- 'Negative'
	THEN 0
	WHEN T1.value_as_concept_id  in (45881796,9192,45878303) -- 'Trace' 
	THEN 1
	WHEN T1.value_as_concept_id  = 45878548 -- '1+'
	THEN 2
	WHEN T1.value_as_concept_id  IN (45878148,45881916,45878148,45878305,45876467,45881623)--('2+', '3+', '4+') 
	THEN 3 END AS value_as_number
FROM ( select * FROM @cdm_database_schema.MEASUREMENT join @target_database_schema.#ckd_codes on measurement_concept_id = concept_id 
	and category ='protein') T1
JOIN 
	(SELECT *
	FROM @cdm_database_schema.MEASUREMENT 
	join @target_database_schema.#ckd_codes on measurement_concept_id = concept_id 
	and category ='gravity'
        where value_as_number < '1.05' and value_as_number > '1') T2
ON T1.person_id = T2.person_id 
 AND T1.measurement_date = T2.measurement_date
 --AND CAST(T1.eventStartDate AS DATE)= CAST(T2.eventStartDate AS DATE) /* UA protein and SG are measured at the same datetime--depends on each instition's lab order habit*/

;

/* Test #stages */
SELECT * FROM (
SELECT *, ROW_NUMBER() OVER(PARTITION BY person_id, measurement_date ORDER by stage DESC) AS rn
 FROM (SELECT DISTINCT person_id, measurement_date, stage FROM #protein_stage) K1
 ) K1
 WHERE rn>1; 

/* *** BLOCK 9: For deriving proteinuria status, retrieve most recent A staging and its prior Astaging *** */
/*** Block 9A: get Urine Test that is close to the most recent eGFR. The urine test is no later than 24 month (730 days) before recent eGFR [-24m, now] */
IF OBJECT_ID('#UrineTestCloseToRntGfr') IS NOT NULL
	DROP TABLE @target_database_schema.#UrineTestCloseToRntGfr;
CREATE TABLE @target_database_schema.#UrineTestCloseToRntGfr (
	person_id INT
	,urineTestDt DATETIME2(6)
	,urineTestType VARCHAR(100)
	,urineTestNumVal FLOAT
	,Astage VARCHAR(80) NOT NULL
	,rn INT NOT NULL
	,eGFRrecentVal FLOAT
	,eGFRrecentDt DATETIME2(6)
	);
	
INSERT INTO @target_database_schema.#UrineTestCloseToRntGfr
    SELECT
      G.person_id,
      U.measurement_date as urineTestDt,
      U.eventtype as urineTestType,
      U.value_as_number as urineTestNumVal,
      U.stage as AStage,
      ROW_NUMBER()
      OVER (
        PARTITION BY G.person_id
        ORDER by U.measurement_date DESC ) AS rn,
      G.eGFR as eGFRrecentVal,
      G.measurement_date as eGFRrecentDt 
    FROM @target_database_schema.#EGFR G
       LEFT JOIN @target_database_schema.#protein_stage U
        ON G.person_id = U.person_id
    WHERE DATEDIFF(DAY, U.measurement_date, G.measurement_date) <= 730; --For acute calculating of 24 months by using 730 days.
    
/*** Block 9B: A-staging: get most recent urine test and the prior urine test.
 The prior urine test is measured at least 3 months prior to the latest urine test ***/
 IF OBJECT_ID('#UrineTestCloseToRntGfr2') IS NOT NULL
	DROP TABLE @target_database_schema.#UrineTestCloseToRntGfr2;
CREATE TABLE @target_database_schema.#UrineTestCloseToRntGfr2 (
	person_id INT
	,urineTestDt DATETIME2(6)
	,urineTestType VARCHAR(100)
	,urineTestNumVal FLOAT
	,Astage VARCHAR(80) NOT NULL
	,diffMonth INT NOT NULL
	,rn INT NOT NULL
	,eGFRrecentVal FLOAT
	,eGFRrecentDt DATETIME2(6)
	);  
 
INSERT INTO @target_database_schema.#UrineTestCloseToRntGfr2 
SELECT UJ.person_id, UJ.urineTestDt, UJ.urineTestNumVal, UJ.Astage, UJ.diffMonth
, ROW_NUMBER() OVER(PARTITION BY person_id ORDER by UJ.urineTestDt DESC) AS rn
,UJ.eGFRrecentVal
,UJ.urineTestDt
FROM (
SELECT U.*
, DATEDIFF(MONTH, U.urineTestDt, J.urineTestDt) 
AS diffMonth
, DATEDIFF(DAY, U.urineTestDt, J.urineTestDt)
 AS diffDay
FROM @target_database_schema.#UrineTestCloseToRntGfr U 
 
LEFT JOIN (SELECT * FROM @target_database_schema.#UrineTestCloseToRntGfr WHERE rn = 1) J
ON U.person_id = J.person_id 
) UJ
WHERE UJ.diffDay = 0 OR UJ.diffMonth >= 3; --this is to keep the most recent urine test and the 3-month-earlier_previous one

/*** Block 9C: A-staging: get most recent Astaging and the prior Astaging ***/
CREATE TABLE @target_database_schema.#Astaging (

	person_id INT
,
	recentAstage VARCHAR(100)
,
	priorAstage VARCHAR(100)

);

INSERT INTO @target_database_schema.#Astaging 
SELECT DISTINCT J1.person_id
,J1.Astage AS recentAstage
,J2.Astage AS priorAstage
FROM (SELECT * FROM @target_database_schema.#UrineTestCloseToRntGfr2 WHERE rn = 1) J1
LEFT JOIN (SELECT * FROM @target_database_schema.#UrineTestCloseToRntGfr2 WHERE rn =2) J2
ON J1.person_id = J2.person_id;


/* *** BLOCK 10: Get CKD case/control definition/algorithm related variables *** */
CREATE TABLE @target_database_schema.#AlgVar (
	person_id INT NOT NULL
	,diseaseName VARCHAR(50) NOT NULL
	,caseControlUnknown VARCHAR(50) NOT NULL
	,C00 INT NOT NULL
	,C01 INT NOT NULL
	,C02 INT NOT NULL
	,C03 INT NOT NULL
	,C04 FLOAT
	,C05 date
	,C06 FLOAT
	,C07 date
	,C12 INT NOT NULL
	,C13 INT NOT NULL
	,C14 VARCHAR(100)
	,C15 VARCHAR(10)
	,C19 INT NOT NULL
	,C20 VARCHAR(100)
	,C21 VARCHAR(100)
	);
INSERT INTO @target_database_schema.#AlgVar
SELECT DISTINCT J.person_id
	,'CKD' AS diseaseName
	,'CASE/CONTROL/UNKNOWN' AS caseControlUnknown
	,coalesce(J0.transplantCnt, 0) AS C00
	,coalesce(J1.dialysisCnt, 0) AS C01
	,coalesce(J2.eGFRCnt, 0) AS C02
	,coalesce(J3.ckdOtherDisCnt, 0) AS C03
	,J4.eGFRrecentNotCooccurAcuteConditionVal AS C04
	,J4.eGFRrecentNotCooccurrAcuteConditionDt AS C05
	,J6.eGFRlt90EarliestVal AS C06
	,J6.eGFRlt90EarliestDt AS C07
	,coalesce(J12.crCnt, 0) AS C12
	,coalesce(J13.dialysisCooccurAkiCnt, 0) AS C13
	,J14.eGFRrecentCooccurAcuteConditionVal AS C14
	,J14.eGFRrecentCooccurAcuteConditionDt AS C15
	,coalesce(J19.urineTestCloseToRntGfrCnt,0) AS C19
	,J20.recentAstage AS C20
	,J20.priorAstage AS C21
FROM @cdm_database_schema.PERSON J
LEFT JOIN (
/* had a kidney transplant */
	SELECT subject_id
		,COUNT(DISTINCT cohort_start_date) AS transplantCnt
	FROM @target_database_schema.cohort
	WHERE cohort_definition_id =1000 -- transplant 
	GROUP BY subject_id
	) J0 
ON J.person_id = J0.subject_id

LEFT JOIN (
/* Chronic dialysis */
	SELECT subject_id
		,COUNT(DISTINCT cohort_start_date) AS dialysisCnt
	FROM @target_database_schema.cohort
	WHERE cohort_definition_id = 1001 -- dialysis 
	GROUP BY subject_id
	) J1 
ON J.person_id = J1.subject_id

LEFT JOIN (
/* Has CKD-EPI eGFR */
	SELECT person_id
		,COUNT(DISTINCT measurement_date) AS eGFRCnt
	FROM @target_database_schema.#eGFR
	GROUP BY person_id
	) J2
ON J.person_id = J2.person_id

LEFT JOIN (
/* diagnosed with CKD or other type of kidney disease*/
	SELECT subject_id
		,COUNT(DISTINCT cohort_start_date) AS ckdOtherDisCnt
	FROM @target_database_schema.cohort
	WHERE cohort_definition_id in (1004,1005) -- CKD and other KD
	GROUP BY subject_id
	) J3
ON J.person_id = J3.subject_id

LEFT JOIN (
/* recent eGFR NOT co-occurrent with Aki, Prerenal kideny injury, sepsis, volume depletion, shock */
	SELECT person_id, eGFRrecentVal AS eGFRrecentNotCooccurAcuteConditionVal, eGFRrecentDt AS eGFRrecentNotCooccurrAcuteConditionDt
	FROM @target_database_schema.#GFRrecent G
	WHERE eGFRrecentDt NOT IN (SELECT DISTINCT eGfrDt FROM  #GfrCooccurrentWithAcuteCondition a
		WHERE a.person_id=G.person_id)
	) J4
ON J.person_id = J4.person_id

LEFT JOIN (
/* eGFR < 90 earliest: this is to infer "has at least one CKD-EPI eGFR <90 more than 3 months prior"*/
	SELECT person_id, eGFR AS eGFRlt90EarliestVal, measurement_date AS eGFRlt90EarliestDt
	FROM (
		SELECT person_id, eGFR, measurement_date, ROW_NUMBER() OVER(PARTITION BY person_id ORDER by measurement_date ASC) AS rn
 		FROM @target_database_schema.#eGFR
		WHERE eGFR <90 ) G
	WHERE G.rn=1
	) J6
ON J.person_id = J6.person_id

LEFT JOIN (
/* Cr measurement */
SELECT person_id
		,COUNT(DISTINCT measurement_date) AS crCnt
	FROM @target_database_schema.#creatinine
	GROUP BY person_id
	) J12
ON J.person_id = J12.person_id

LEFT JOIN (
/* Dialysis co-occurrent with Aki */
SELECT person_id
		,COUNT(DISTINCT dialysisDt) AS dialysisCooccurAkiCnt
	FROM @target_database_schema.#DialysisCooccurrentWithAKI
	GROUP BY person_id
	) J13
ON J.person_id = J13.person_id

LEFT JOIN (
/* recent eGFR co-occurrent with Acute Condition (Aki, Prerenal kideny injury, sepsis, volume depletion, shock) */
	SELECT person_id, value_as_number AS eGFRrecentCooccurAcuteConditionVal, 
	eGFRrecentDt AS eGFRrecentCooccurAcuteConditionDt
	FROM @target_database_schema.#UrineTestCloseToRntGfr2 G
	WHERE eGFRrecentDt IN (
		SELECT DISTINCT eGfrDt FROM  #GfrCooccurrentWithAcuteCondition A
	WHERE A.person_id=G.person_id)
	) J14
ON J.person_id = J14.person_id

LEFT JOIN (
/* Has a urine test from the present to 24M before the most recent eGFR */
	SELECT person_id, COUNT (urineTestDt) AS urineTestCloseToRntGfrCnt 
	FROM @target_database_schema.#UrineTestCloseToRntGfr
	GROUP BY person_id
	) J19
ON J.person_id = J19.person_id

/* A staging */
LEFT JOIN  @target_database_schema.#Astaging J20
ON J.person_id = J20.person_id
;

/* *** BLOCK 11: Phenotyping *** */
DROP TABLE  @target_database_schema.#phenotypePre;
CREATE TABLE  @target_database_schema.#phenotypePre (
	person_id INT
	,transplantCnt INT
	,dialysisCnt INT
	,dialysisCooccurAkiCnt INT
	,crCnt INT
	,eGFRCnt INT
	,ckdOtherDisCnt INT
	,eGFRrecentNotCooccurAcuteConditionVal FLOAT
	,eGFRrecentNotCooccurrAcuteConditionDt DATETIME2(6)
	,eGFRrecentCooccurAcuteConditionVal FLOAT
	,eGFRrecentCooccurAcuteConditionDt DATETIME2(6)
	,eGFRlt90EarliestVal FLOAT
	,eGFRlt90EarliestDt DATETIME2(6)
	,urineTestCloseToRntGfrCnt INT
	,recentAstage VARCHAR(100)
	,priorAstage VARCHAR(100)
	,NKF_Stage_detail VARCHAR(200)
	,NKF_Stage VARCHAR(200)
	,CaseControlUnknownStatus VARCHAR(200)
	);
	
INSERT INTO  @target_database_schema.#phenotypePre
SELECT DISTINCT *
,CASE WHEN NKF_Stage_detail IN ('CKD Stage 1', 'CKD Stage 2', 'CKD Stage 3a', 'CKD Stage 3b', 'CKD Stage 4', 'CKD Stage 5', 
'ESRD after transplant', 'ESRD on dialysis') THEN NKF_Stage_detail
WHEN NKF_Stage_detail LIKE 'CKD%control' THEN NKF_Stage_detail
WHEN NKF_Stage_detail LIKE 'Indeterminate%' THEN 'Unknown'
ELSE NULL END AS NKF_Stage
,CASE WHEN NKF_Stage_detail IN ('CKD Stage 1', 'CKD Stage 2', 'CKD Stage 3a', 'CKD Stage 3b', 'CKD Stage 4', 'CKD Stage 5', 
'ESRD after transplant', 'ESRD on dialysis') THEN 'Case'
WHEN NKF_Stage_detail LIKE 'CKD%control' THEN 'Control' 
WHEN NKF_Stage_detail LIKE 'Indeterminate%' THEN 'Unknown'
ELSE NULL END AS CaseControlUnknownStatus
FROM (
SELECT DISTINCT 
 A.person_id
,A.C00 AS transplantCnt
,A.C01 AS dialysisCnt
,A.C13 AS dialysisCooccurAkiCnt
,A.C12 AS crCnt
,A.C02 AS eGFRCnt
,A.C03 AS ckdOtherDisCnt
,A.C04 AS eGFRrecentNotCooccurAcuteConditionVal
,A.C05 AS eGFRrecentNotCooccurrAcuteConditionDt
,A.C14 AS eGFRrecentCooccurAcuteConditionVal
,A.C15 AS eGFRrecentCooccurAcuteConditionDt
,A.C06 AS eGFRlt90EarliestVal
,A.C07 AS eGFRlt90EarliestDt
,A.C19 AS urineTestCloseToRntGfrCnt
,A.C20 AS recentAstage
,A.C21 AS priorAstage

,CASE WHEN C00 > 0 /* Transplant CKD 5 */ THEN 'ESRD after transplant'
 WHEN C00 = 0 AND C01 >0 AND C13 >0 /* Dialysis co-occurrent with AKI */ THEN 'Indeterminate - Dialysis co-occurr with AKI'
 WHEN C00 = 0 AND C01 >0 AND C13 =0 /* Dialysis not co-occurrent with AKI */ THEN 'ESRD on dialysis'
 WHEN C00 =0 AND C01 = 0 AND C02 = 0 THEN 'Indeterminate - No eGFR'
 WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C15 IS NOT NULL THEN 'Indeterminate - recent eGFR co-occur with acute conditions'
 
 /* left branch after the common filter */
 WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 <90 AND C04 >= 60 AND (C03 >0 OR (C06 IS NOT NULL AND DATEDIFF(MONTH, C07, C05)>=3)) THEN 'CKD Stage 2' 
 WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 <60 AND C04 >= 45 AND (C03 >0 OR (C06 IS NOT NULL AND DATEDIFF(MONTH, C07, C05)>=3)) THEN 'CKD Stage 3a'
 WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 <45 AND C04 >= 30 AND (C03 >0 OR (C06 IS NOT NULL AND DATEDIFF(MONTH, C07, C05)>=3)) THEN 'CKD Stage 3b'
 WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 <30 AND C04 >= 15 AND (C03 >0 OR (C06 IS NOT NULL AND DATEDIFF(MONTH, C07, C05)>=3)) THEN 'CKD Stage 4'
 WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 <15 AND (C03 >0 OR (C06 IS NOT NULL AND DATEDIFF(MONTH, C07, C05)>=3)) THEN 'CKD Stage 5'

WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C04 IS NOT NULL AND C04<90 AND C03 =0 AND (C06 IS NULL OR (C06 IS NOT NULL AND DATEDIFF(MONTH, C07, C05)<3)) THEN 'Indeterminate - no CKD or other kidney disease dx and no second qualified eGFR'

/* Right branch after the common filters */
/* Stage 1*/
WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 >=90 AND C03 >0 THEN 'CKD Stage 1'

 /* Control */
WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 >= 90 AND C03 = 0 AND C19 =0 THEN 'CKD G1-control'  -- Added CKD G1-Control

WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 >= 90 AND C03 = 0 AND C19 > 0 AND C20 IN ('A1') THEN 'CKD G1A1-control' 
 
/* Stage 1 */
WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 >= 90 AND C03 = 0 AND C19 > 0 AND C20 IN ('A2','A3') AND C21 IN ('A2','A3') THEN 'CKD Stage 1'

WHEN C00 =0 AND C01 = 0 AND C02 > 0 AND C05 IS NOT NULL AND C04 >= 90 AND C03 = 0 AND C19 > 0 AND C20 IN ('A2','A3') AND (C21 NOT IN ('A2','A3') OR C21 IS NULL) THEN 'Indeterminate - no qualified previous A-staging for defining G1A1-control' --

END AS NKF_Stage_detail
FROM @target_database_schema.#AlgVar A
) U
;


