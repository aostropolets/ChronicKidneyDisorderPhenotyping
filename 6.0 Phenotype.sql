
--????????????????  непонятно зачем
/*** Block 5C: get most recent eGFR for patient who has eGFR ***/


CREATE TEMP TABLE @target_database_schema.GFRrecent
AS
SELECT person_id, eGFR AS eGFRrecentVal, measurement_date AS eGFRrecentDt
FROM (
	SELECT person_id, eGFR, measurement_date, ROW_NUMBER() OVER(PARTITION BY person_id ORDER by measurement_date DESC) AS rn
FROM eGFR
) G
WHERE rn =1;



/*** Block 5D: Check how many Cr cannot be converted to eGFR ***/
/* Analyze how many Cr cannot be converted into eGFR because of missing height information */
SELECT * FROM #tmpGFR WHERE eGFR IS NULL AND crVal >0;
SELECT COUNT(DIstinct person_id) FROM #tmpGFR WHERE eGFR IS NULL AND crVal >0;
SELECT * FROM #tmpGFR WHERE eGFR IS NULL AND crVal = 0; 


--proteins
CREATE TEMP TABLE @target_database_schema.albumin_stage
  as
    SELECT
      person_id,
      measurement_date,
      CASE WHEN value_as_number < 30
        THEN 'A1'
      WHEN value_as_number >= 30 AND value_as_number <= 300
        THEN 'A2'
      WHEN value_as_number > 300
        THEN 'A3' END AS P
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
       FROM @cdm_database_schema.MEASUREMENT ms
       WHERE measurement_concept_id IN (select concept_id
                                        FROM @target_database_schema.ckd_codes
                                        where category = 'albumin')
      ) alb;

CREATE TEMP TABLE @target_database_schema.protein_stage
  as
    SELECT
      person_id,
      measurement_date,
	  value_as_number,
      CASE WHEN PA1 >= PA2 AND PA1 >= PA3
        THEN 'A1'
      WHEN PA2 >= PA1 AND PA2 >= PA3
        THEN 'A2'
      WHEN PA3 >= PA1 AND PA3 >= PA2
        THEN 'A3' END AS Pstage
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
                       join @target_database_schema.ckd_codes on measurement_concept_id = concept_id
                     where category = 'protein') pr1
         ) pr2
  ) pr3;
-- value_as_string doesn't exist, check what there is instead


/* *** BLOCK 6: Dialysis co-occurrent with AKI, defined as AKI happens before or after 1 month of dialysis, 1 month is defined as 31 days (DATEDIFF in month is 1 if the difference between two dates is 1.5 months) *** */

CREATE TEMP TABLE @target_database_schema.DialysisCooccurrentWithAKI
AS
SELECT DISTINCT T.person_id, T.cohort_start_date AS dialysisDt, U.cohort_start_date AS akiDt
	, (DATE_PART('day', T.cohort_start_date)-  DATE_PART('day',U.cohort_start_date)) AS dialysisAkiDiffDtAbs

FROM @cdm_database_schema.cohort T
LEFT JOIN
	(SELECT DISTINCT * 
	FROM @target_database_schema.cohort T
	WHERE cohort_definition_id = 1003 -- acute CK
	) U
ON T.subject_id=U.subject_id 
WHERE T.cohort_definition_id = 1001 -- dialysis
AND (DATE_PART('day', T.cohort_start_date)-  DATE_PART('day',U.cohort_start_date)) <= 31 --For acute calculating of 1 month by using 31 days. 
 ;
 
/* *** BLOCK 7: eGFR co-occurrent with acute conditions (AKI/prerenal kidney injury/sepsis/volume depletion/shock), defined as acute conditions happen before or after 1 month of eGFR *** */
CREATE TEMP TABLE @target_database_schema.GfrCooccurrentWithAcuteCondition
AS
SELECT DISTINCT T.person_id, T.measurement_date AS eGfrDt, U.cohort_start_date AS acuteConditionDt
	, (DATE_PART('day', T.cohort_start_date)-  DATE_PART('day',U.cohort_start_date)) AS eGfrAcuteConditionDiffDtAbs
FROM eGFR T
LEFT JOIN
	(SELECT DISTINCT * 
	FROM @target_database_schema.cohort T
	WHERE cohort_definition_id IN (1002,1003) -- AKD, Other acute conditions
	) U
ON T.person_id=U.subject_id 
WHERE (DATE_PART('day', T.cohort_start_date)-  DATE_PART('day',U.cohort_start_date)) <= 31 --For acute calculating of 1 month by using 31 days.
 ;


/*** Block 8D: A-staging for Dipstick Urine Analysis Protein. UA protein data range is Negative, Trace, 1+, 2+, 3+, 4+ ***/
/** UA Protein with co-occurrent SG **/
INSERT INTO protein_stage
  SELECT DISTINCT
    person_id,
    measurement_date,
    uaProteinNumValue,
    CASE WHEN PA1 >= PA2 AND PA1 >= PA3
      THEN 'A1'
    WHEN PA2 >= PA1 AND PA2 >= PA3
      THEN 'A2'
    WHEN PA3 >= PA1 AND PA3 >= PA2
      THEN 'A3' END AS Pstage
  FROM (
         SELECT
           *,
           PA1A2 - PA1 AS PA2,
           1 - PA1A2   AS PA3
         FROM (
                SELECT DISTINCT
                  T1.person_id,
                  T1.measurement_date  AS uaProteinDate,
                  CASE WHEN T1.value_as_string = 'Negative'
                    THEN 0
                  WHEN T1.value_as_string = 'Trace'
                    THEN 1
                  WHEN T1.value_as_string = '1+'
                    THEN 2
                  WHEN T1.value_as_string IN ('2+', '3+', '4+')
                    THEN 3 END       AS uaProteinNumValue,
                  CASE WHEN T1.value_as_string = 'Negative'
                    THEN exp(-141.736 + 140.813 * T2.eventNumValue) / (1 + exp(-141.736 + 140.813 * T2.eventNumValue))
                  WHEN T1.value_as_string = 'Trace'
                    THEN exp(-143.142 + 140.813 * T2.eventNumValue) / (1 + exp(-143.142 + 140.813 * T2.eventNumValue))
                  WHEN T1.value_as_string = '1+'
                    THEN exp(-145.145 + 140.813 * T2.eventNumValue) / (1 + exp(-145.145 + 140.813 * T2.eventNumValue))
                  WHEN T1.value_as_string IN ('2+', '3+', '4+')
                    THEN exp(-148.117 + 140.813 * T2.eventNumValue) / (1 + exp(-148.117 + 140.813 * T2.eventNumValue))
                  END                AS PA1,
                  CASE WHEN T1.value_as_string = 'Negative'
                    THEN exp(-200.777 + 203.011 * T2.eventNumValue) / (1 + exp(-200.777 + 203.011 * T2.eventNumValue))
                  WHEN T1.value_as_string = 'Trace'
                    THEN exp(-202.959 + 203.011 * T2.eventNumValue) / (1 + exp(-202.959 + 203.011 * T2.eventNumValue))
                  WHEN T1.value_as_string = '1+'
                    THEN exp(-204.642 + 203.011 * T2.eventNumValue) / (1 + exp(-204.642 + 203.011 * T2.eventNumValue))
                  WHEN T1.value_as_string IN ('2+', '3+', '4+')
                    THEN exp(-208.287 + 203.011 * T2.eventNumValue) / (1 + exp(-208.287 + 203.011 * T2.eventNumValue))
                  END                AS PA1A2,
                  T2.value_as_number AS SgValue
                FROM (select *
                      FROM @cdm_database_schema.MEASUREMENT
                        join @target_database_schema.ckd_codes on measurement_concept_id = concept_id
                                          and category = 'protein') T1
                  LEFT JOIN
                  (SELECT *
                   FROM @cdm_database_schema.MEASUREMENT
                     join @target_database_schema.ckd_codes on measurement_concept_id = concept_id
                                       and category = 'gravity') T2
                    ON T1.person_id = T2.person_id
                       AND T1.measurement_date = T2.measurement_date
                                WHERE T2.value_as_number is not null

              ) pr1
       ) pr2;

/** UA Protein without SG **/
INSERT INTO protein_stage
SELECT DISTINCT T1.person_id, T1.measurement_start_date
, CASE WHEN T1.value_as_string = 'Negative' THEN 0
	WHEN T1.value_as_string = 'Trace' THEN 1
	WHEN T1.value_as_string = '1+' THEN 2
	WHEN T1.value_as_string IN ('2+', '3+', '4+') THEN 3 END AS eventNumValue
,CASE WHEN T1.value_as_string = 'Negative' THEN 'A1'
	WHEN T1.value_as_string = 'Trace' THEN 'A1'
	WHEN T1.value_as_string = '1+' THEN 'A2'
	WHEN T1.value_as_string IN ('2+', '3+', '4+') THEN 'A3' END AS Astage
FROM ( select * FROM @cdm_database_schema.MEASUREMENT join @target_database_schema.ckd_codes on measurement_concept_id = concept_id 
	and category ='protein') T1
LEFT JOIN 
	(SELECT *
	FROM @cdm_database_schema.MEASUREMENT 
	join @target_database_schema.ckd_codes on measurement_concept_id = concept_id 
	and category ='gravity') T2
ON T1.person_id = T2.person_id 
 AND T1.measurement_start_date = T2.measurement_start_date
 --AND CAST(T1.eventStartDate AS DATE)= CAST(T2.eventStartDate AS DATE) /* UA protein and SG are measured at the same datetime--depends on each instition's lab order habit*/
WHERE T2.value_as_number is not null
;


--просто посмотреть на результат
/* Test #tmpUrineTest */
SELECT * FROM (
SELECT *, ROW_NUMBER() OVER(PARTITION BY person_id, eventStartDate ORDER by Astage DESC) AS rn
 FROM (SELECT DISTINCT person_id, eventStartDate, ruleAstage FROM #tmpUrineTest) K1
 ) K1
 WHERE rn>1; 
 

/* *** BLOCK 9: For deriving proteinuria status, retrieve most recent A staging and its prior Astaging *** */
/*** Block 9A: get Urine Test that is close to the most recent eGFR. The urine test is no later than 24 month (730 days) before recent eGFR [-24m, now] */

CREATE TEMP TABLE @target_database_schema.UrineTestCloseToRntGfr
  AS
    SELECT
      G.person_id,
      U.measurement_date,
      U.value_as_number,
      U.Pstage,
      ROW_NUMBER()
      OVER (
        PARTITION BY G.person_id
        ORDER by U.measurement_date DESC ) AS rn,
      G.value_as_number,
      G.measurement_date as pdate
    FROM @target_database_schema.EGFR G
      JOIN @target_database_schema.protein_stage U
        ON G.person_id = U.person_id
    WHERE (DATE_PART('day', U.measurement_date) -  DATE_PART('day',G.measurement_date) )<=730; --For acute calculating of 24 months by using 730 days.

    
/*** Block 9B: A-staging: get most recent urine test and the prior urine test.
 The prior urine test is measured at least 3 months prior to the latest urine test ***/
CREATE TEMP TABLE @target_database_schema.UrineTestCloseToRntGfr2 
AS
SELECT UJ.person_id, UJ.measurement_start_date, UJ.value_as_number, UJ.Astage, UJ.diffMonth
, ROW_NUMBER() OVER(PARTITION BY person_id ORDER by UJ.measurement_start_date DESC) AS rn
,UJ.eGFRrecentVal
,UJ.measurement_start_date
FROM (
SELECT U.*
, (DATE_PART('month', U.measurement_date) -  DATE_PART('month',J.measurement_date)  --DATEDIFF(MONTH, U.measurement_start_date, J.measurement_start_date) 
AS diffMonth
, (DATE_PART('day', U.measurement_date) -  DATE_PART('day',J.measurement_date)    --DATEDIFF(DAY, U.measurement_start_date, J.measurement_start_date)
 AS diffDay
FROM UrineTestCloseToRntGfr U 
 
LEFT JOIN (SELECT * FROM UrineTestCloseToRntGfr WHERE rn = 1) J
ON U.person_id = J.person_id 
) UJ
WHERE UJ.diffDay = 0 OR UJ.diffMonth >= 3; --this is to keep the most recent urine test and the 3-month-earlier_previous one

/*** Block 9C: A-staging: get most recent Astaging and the prior Astaging ***/
CREATE TEMP TABLE @target_database_schema.Astaging 
AS
SELECT DISTINCT J1.person_id
,J1.Astage AS recentAstage
,J2.Astage AS priorAstage
FROM (SELECT * FROM UrineTestCloseToRntGfr2 WHERE rn = 1) J1
LEFT JOIN (SELECT * FROM rineTestCloseToRntGfr2 WHERE rn =2) J2
ON J1.person_id = J2.person_id;


/* *** BLOCK 10: Get CKD case/control definition/algorithm related variables *** */
CREATE TEMP TABLE @target_database_schema.AlgVar (
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
INSERT INTO AlgVar
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
	FROM @target_database_schema.eGFR
	GROUP BY person_id
	) J2
ON J.person_id = J2.subject_id

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
	SELECT subject_id, eGFRrecentVal AS eGFRrecentNotCooccurAcuteConditionVal, eGFRrecentDt AS eGFRrecentNotCooccurrAcuteConditionDt
	FROM @target_database_schema.GFRrecent G
	WHERE eGFRrecentDt NOT IN (SELECT DISTINCT eGfrDt FROM  GfrCooccurrentWithAcuteCondition 
		WHERE GfrCooccurrentWithAcuteCondition.person_id=G.person_id)
	) J4
ON J.person_id = J4.subject_id

LEFT JOIN (
/* eGFR < 90 earliest: this is to infer "has at least one CKD-EPI eGFR <90 more than 3 months prior"*/
	SELECT person_id, eGFR AS eGFRlt90EarliestVal, crDt AS eGFRlt90EarliestDt
	FROM (
		SELECT person_id, eGFR, measurement_date, ROW_NUMBER() OVER(PARTITION BY person_id ORDER by crDt ASC) AS rn
 		FROM @target_database_schema.eGFR
		WHERE eGFR <90 ) G
	WHERE G.rn=1
	) J6
ON J.person_id = J6.person_id

LEFT JOIN (
/* Cr measurement */
SELECT person_id
		,COUNT(DISTINCT measurement_date) AS crCnt
	FROM @target_database_schema.creatinine
	GROUP BY person_id
	) J12
ON J.person_id = J12.person_id

LEFT JOIN (
/* Dialysis co-occurrent with Aki */
SELECT subject_id
		,COUNT(DISTINCT dialysisDt) AS dialysisCooccurAkiCnt
	FROM @target_database_schema.DialysisCooccurrentWithAKI
	GROUP BY person_id
	) J13
ON J.person_id = J13.subject_id

LEFT JOIN (
/* recent eGFR co-occurrent with Acute Condition (Aki, Prerenal kideny injury, sepsis, volume depletion, shock) */
	SELECT subject_id, value_as_number AS eGFRrecentCooccurAcuteConditionVal, 
	eGFRrecentDt AS eGFRrecentCooccurAcuteConditionDt
	FROM @target_database_schema.UrineTestCloseToRntGfr2 G
	WHERE measurement_date IN (
		SELECT DISTINCT measurement_date FROM  GfrCooccurrentWithAcuteCondition 
	WHERE GfrCooccurrentWithAcuteCondition.person_id=G.person_id)
	) J14
ON J.person_id = J14.subject_id

LEFT JOIN (
/* Has a urine test from the present to 24M before the most recent eGFR */
	SELECT person_id, COUNT(measurement_date) AS urineTestCloseToRntGfrCnt 
	FROM @target_database_schema.UrineTestCloseToRntGfr
	GROUP BY person_id
	) J19
ON J.person_id = J19.person_id

/* A staging */
LEFT JOIN Astaging J20
ON J.person_id = J20.person_id
;

/* *** BLOCK 11: Phenotyping *** */
DROP TABLE phenotypePre;
CREATE TABLE phenotypePre (
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
	
INSERT INTO phenotypePre
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
SELECT DISTINCT CL.PATIENT_ID AS person_id
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
FROM @cdm_database_schema.PERSON CL
LEFT JOIN AlgVar A
ON CL.person_id = A.person_id
) U
;


