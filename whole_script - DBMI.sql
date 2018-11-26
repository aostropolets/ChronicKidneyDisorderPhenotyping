
IF OBJECT_ID('#ckd_codes') IS NOT NULL
	DROP TABLE #ckd_codes;
create table #ckd_codes
(category nvarchar(400),
concept_id int,
concept_name nvarchar(400),
concept_code nvarchar(400),
vocabulary_id nvarchar(400),
domain_id nvarchar(400),

);


insert into #ckd_codes (category,concept_id,concept_name,concept_code,vocabulary_id,domain_id )
select c.category,
      c.concept_id,
      c.concept_name,
      c.concept_code,
      c.vocabulary_id,
      c.domain_id
      from
        (
          select
            'height' as category,
            c.*
          from ohdsi_cumc_deid_pending.dbo.concept c
          where concept_id in (4030731, 3014149, 3008989, 3015514, 3019171, 3013842, 3023357, 3023540, 3035463, 3036277)
          union all
          select
            'creatinine',
            c.*
          from ohdsi_cumc_deid_pending.dbo.concept c
          where concept_id in (3045558,4150621,3042112,3050975,3026387,3026726,3004239,3024742,3013280,3053284,3014654,3040071,3022243,40760461,42868736,3040510,
                              21491015,21492443,3033837,40762044,3021126,4324383,3006701,3010663,3037459,3037441,40762091,3008392,3012506,3013296,3028031,3013539,
                              3026275,3032932,3043954,3004171,3016647,3011002,3016723,3051825,3025065,3003447,3022016,43055681,3012179,40762887,3045443,4276116,
                              3041339,3049517,3018968,3005717,3027322,40760837,3014699,3022673,3045262,3019491,3048925,3052562,4013964,3015872,3007795,3041045,
                              3001349,3016662,3027111,40757505,3038830,3007760,3024275,3007196,3040209,3041716,40757506,40758722,3035090,40768326,43055236,3026249,
                              3025645,3021074,3007081,3025715,3042571,3041735,3036094,3038385,21491016,3007349,3041197,3017250,3044547,4155367,46235076,3019397,
                              3010529,3014724,42868738,4230629,3045369,3045571,3048276,3040006,3006181,3020564,3027362,40762895,40760463,3025813,3037052,40760462,
                              3009508,3023157,3020847,3040495)
          union all
          select
            'albumin',
            c.* --	mass/time
          from ohdsi_cumc_deid_pending.dbo.concept c
          where concept_id in
                (46236963, 3033268, 3050449, 3018097, 3027035, 043771, 40766204, 3005577, 3040290, 3043179, 40759673, 3049506, 40761549)
          union all
          select
            'albumin',
            c.* --	mass/volume
          from ohdsi_cumc_deid_pending.dbo.concept c
          where concept_id in
                (3008512, 3012516, 46236875, 3039775, 3018104, 3030511, 3008960, 37393656, 4193719, 40760483, 3005031, 3039436, 3046828, 3000034)
          union all
          select
            'albumin',
            c.* -- albumin general codes
          from ohdsi_cumc_deid_pending.dbo.concept c
          where concept_id in (4017498, 2212188, 2212189, 4152996)
          union all
          select
            'protein',
            c.* -- general
          from ohdsi_cumc_deid_pending.dbo.concept c
          where concept_id in (4152995, 4064934)
          union all
          select
            'alb/creat_ratio',
            c.*
          from ohdsi_cumc_deid_pending.dbo.concept c
          where
            concept_id in (3000819, 3034485, 3002812, 3000837, 46235897, 3020682, 3043209, 3002827, 3001802, 40762252,
                                    46235435, 3022826, 46235434, 3023556, 4154347)
          union all
          select
            'egfr',
            c.*
          from ohdsi_cumc_deid_pending.dbo.concept c
          where concept_id in
                (3029829, 3029859, 3030104, 3045262, 36304157, 36306178, 40478895, 40478963, 40483219, 40485075,
                  40490315, 40764999, 40771922, 42869913, 4478827544790183, 44806420, 46236952, 46236975, 3049187,
                  3053283, 36303797)
          union all
          select
            'gravity',
            c.*
          from ohdsi_cumc_deid_pending.dbo.concept c
          where concept_id in
                (2212165, 2212166, 2212577, 3000330, 3019150, 3029991, 3032448, 3033543, 3034076, 3039919, 3043812, 4147583)
        ) c
;

INSERT INTO #ckd_codes
(
  category,
  concept_id,
  concept_name,
  concept_code,
  vocabulary_id,
  domain_id
)
SELECT 'transplant' AS category,
       c.concept_id,
       c.concept_name,
       c.concept_code,
       c.vocabulary_id,
       c.domain_id
FROM ohdsi_cumc_deid_pending.dbo.concept_ancestor
  JOIN ohdsi_cumc_deid_pending.dbo.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
  JOIN ohdsi_cumc_deid_pending.dbo.concept c
    ON concept_id_1 = c.concept_id
   AND cr.invalid_reason IS NULL
   AND relationship_id IN ('Maps to', 'Maps to value', 'Has asso proc') 
   AND c.invalid_reason IS NULL
WHERE ancestor_concept_id IN (
--------procedures------
4163566,-- SNOMED Renal replacement
4322471,-- transplant of kidney
4146256,-- transplant nephrectomy
2877118,-- ICD10 0TY0
2833286,-- ICD10 0TY1
4082531,--US scan of transpl
4180454,--Examination of live donor after kidney transplant
42690461,-- Fluoroscopy guided removal of nephrostomy tube from transplanted kidney
------ conditions ----
42539502,-- transplanted kidney present
4324887--Disorder related to renal transplantation
)
AND   c.vocabulary_id NOT IN ('MeSH','PPI','SUS');


INSERT INTO #ckd_codes
(
  category,
  concept_id,
  concept_name,
  concept_code,
  vocabulary_id,
  domain_id
)
SELECT 'dialysis' AS category,
       c.concept_id,
       c.concept_name,
       c.concept_code,
       c.vocabulary_id,
       c.domain_id
FROM ohdsi_cumc_deid_pending.dbo.concept_ancestor
  JOIN ohdsi_cumc_deid_pending.dbo.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
  JOIN ohdsi_cumc_deid_pending.dbo.concept c
    ON concept_id_1 = c.concept_id
   AND cr.invalid_reason IS NULL
   AND relationship_id IN ('Maps to', 'Maps to value', 'Has asso proc', 'Followed by', 'Has due to') 
   AND c.invalid_reason IS NULL
WHERE ancestor_concept_id IN (
4019967,-- Dependence on renal dialysis
4059475,--  H/O: renal dialysis
4300837,--  Dialysis care assessment
4300838,--  Dialysis care education
4146536,-- Renal dialysis
438624,-- Complication of renal dialysis
4026915,--  Revision of arteriovenous shunt for renal dialysis
4289454,-- Venous catheterization for renal dialysis
4272012,--Insertion of cannula for hemodialysis
4300839,--Dialysis care management
45887996--End-Stage Renal Disease Services
)
AND   c.vocabulary_id NOT IN ('MeSH','PPI','SUS');


INSERT INTO #ckd_codes
  (category, concept_id, concept_name, concept_code, vocabulary_id, domain_id)
SELECT
  'AKD' AS category,
  c.concept_id,
  c.concept_name,
  c.concept_code,
  c.vocabulary_id,
  c.domain_id
FROM ohdsi_cumc_deid_pending.dbo.concept_ancestor
  JOIN ohdsi_cumc_deid_pending.dbo.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
  JOIN ohdsi_cumc_deid_pending.dbo.concept c
    ON concept_id_1 = c.concept_id
       AND cr.invalid_reason IS NULL
       AND relationship_id IN ('Maps to', 'Maps to value', 'Has asso proc', 'Followed by', 'Has due to')
       AND c.invalid_reason IS NULL
WHERE ancestor_concept_id IN (
  197320, --Acute renal failure syndrome
          444044, --Acute tubular necrosis
          761083, --Acute injury of kidney -- coundn't find a common parent w/o nephritis
          37116430, --Acute kidney failure stage 1
          37116431, --Acute kidney failure stage 2
          37116432, --Acute kidney failure stage 3
          4228827, --Acute milk alkali syndrome
          4111399, --Acute pericarditis secondary to uremia
          4232873, --Acute postoperative renal failure
          40481064, --Acute renal cortical necrosis
          4126305, --Acute renal impairment
  37399017, --Hemorrhagic fever with renal syndrome
  37116834, --Postpartum acute renal failure
  42536547--Ischemia of kidney (in SNOMED only acute)
  )
  AND c.vocabulary_id NOT IN ('MeSH', 'PPI', 'SUS')
;

INSERT INTO #ckd_codes
(
  category,
  concept_id,
  concept_name,
  concept_code,
  vocabulary_id,
  domain_id
)
  SELECT
    'CKD' AS category,
    c.concept_id,
    c.concept_name,
    c.concept_code,
    c.vocabulary_id,
    c.domain_id
  FROM ohdsi_cumc_deid_pending.dbo.concept_ancestor
    JOIN ohdsi_cumc_deid_pending.dbo.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
    JOIN ohdsi_cumc_deid_pending.dbo.concept c
      ON concept_id_1 = c.concept_id
         AND cr.invalid_reason IS NULL
         AND relationship_id IN ('Maps to', 'Maps to value', 'Has asso proc', 'Followed by', 'Has due to')
         AND c.invalid_reason IS NULL
  WHERE ancestor_concept_id IN (
    193782, -- End-stage renal disease
    46271022, -- Chronic kidney disease
    196991, --Chronic renal impairment
    40769275  --	Estimated or measured glomerular filtration rate less than 50 percent [Reported]
  )
        AND c.vocabulary_id NOT IN ('MeSH', 'PPI', 'SUS');

INSERT INTO #ckd_codes
(
  category,
  concept_id,
  concept_name,
  concept_code,
  vocabulary_id,
  domain_id
)
  SELECT
    'other_acute' AS category,
    c.concept_id,
    c.concept_name,
    c.concept_code,
    c.vocabulary_id,
    c.domain_id
  FROM ohdsi_cumc_deid_pending.dbo.concept_ancestor
    JOIN ohdsi_cumc_deid_pending.dbo.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
    JOIN ohdsi_cumc_deid_pending.dbo.concept c
      ON concept_id_1 = c.concept_id
         AND cr.invalid_reason IS NULL
         AND relationship_id IN ('Maps to', 'Maps to value', 'Has asso proc', 'Followed by', 'Has due to')
         AND c.invalid_reason IS NULL
  WHERE ancestor_concept_id IN (
    132797, -- Sepsis
    436375, --	Hypovolemia
    201965-- Shock
  )
        AND c.vocabulary_id NOT IN ('MeSH', 'PPI', 'SUS');

-- didn't get additional codes
INSERT INTO #ckd_codes
(
  category,
  concept_id,
  concept_name,
  concept_code,
  vocabulary_id,
  domain_id
)
  SELECT
    'CKD' AS category,
    c.concept_id,
    c.concept_name,
    c.concept_code,
    c.vocabulary_id,
    c.domain_id
  FROM ohdsi_cumc_deid_pending.dbo.concept_ancestor
    JOIN ohdsi_cumc_deid_pending.dbo.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
    JOIN ohdsi_cumc_deid_pending.dbo.concept c
      ON concept_id_1 = c.concept_id
         AND cr.invalid_reason IS NULL
         AND relationship_id IN ('Maps to', 'Maps to value', 'Has asso proc', 'Followed by', 'Has due to')
         AND c.invalid_reason IS NULL
  WHERE ancestor_concept_id IN (
    193782, -- End-stage renal disease
    46271022, -- Chronic kidney disease
    196991 --Chronic renal impairment
  )
        AND c.vocabulary_id NOT IN ('MeSH', 'PPI', 'SUS')
;

INSERT INTO #ckd_codes
(
  category,
  concept_id,
  concept_name,
  concept_code,
  vocabulary_id,
  domain_id
)
  SELECT
    'other_KD' AS category,
    c.concept_id,
    c.concept_name,
    c.concept_code,
    c.vocabulary_id,
    c.domain_id
  FROM ohdsi_cumc_deid_pending.dbo.concept_ancestor
    JOIN ohdsi_cumc_deid_pending.dbo.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
    JOIN ohdsi_cumc_deid_pending.dbo.concept c
      ON concept_id_1 = c.concept_id
         AND cr.invalid_reason IS NULL
         AND relationship_id IN ('Maps to', 'Maps to value', 'Has asso proc', 'Followed by', 'Has due to')
         AND c.invalid_reason IS NULL
  WHERE ancestor_concept_id IN
        (198124, --kidney disease
         75650, --proteinuria
         193955, --Tuberculosis of kidney
         201313--Hypertensive renal disease
        )
        AND c.vocabulary_id NOT IN ('MeSH', 'PPI', 'SUS');


IF OBJECT_ID('ohdsi_cumc_deid_pending.results.#creatinine') IS NOT NULL
DROP TABLE ohdsi_cumc_deid_pending.results.#creatinine;
CREATE TABLE ohdsi_cumc_deid_pending.results.#creatinine (
	person_id INT,
	gender_concept_id INT,
	race_concept_id INT,
	measurement_date DATETIME2(6),
	measurement_concept_id INT,
	ageAtMeasYear INT,
	year_of_birth INT,
	crVal VARCHAR(100),
	value_as_concept_id INT,
	genderFactor FLOAT,
	raceFactor FLOAT,
	kappaFactor FLOAT,
	alphaFactor FLOAT,
	minCrK FLOAT,
	maxCrK FLOAT
	);
		
	
INSERT INTO ohdsi_cumc_deid_pending.results.#creatinine 
SELECT cr.*,
	  CASE WHEN value_as_number/kappaFactor < 1 THEN value_as_number/kappaFactor ELSE 1 END AS minCrK,
	  CASE WHEN value_as_number/kappaFactor > 1 THEN value_as_number/kappaFactor ELSE 1 END AS maxCrK
	  FROM (
	SELECT DISTINCT m.person_id, gender_concept_id, race_concept_id,  
		measurement_date,
		measurement_concept_id, 
		year(measurement_date) - year_of_birth AS ageAtMeasYear,
		year_of_birth,	
		case 
		when unit_concept_id = 8840 then value_as_number-- mg/dl
		when unit_concept_id = 8842 then value_as_number*0.0001 -- ng/ml
		when unit_concept_id = 8749 then value_as_number*0.0113  -- mcmol/l
		when unit_concept_id = 9586 then value_as_number*11300 -- mol/l
		when unit_concept_id = 8753 then value_as_number*11.3 -- mmol/l 
		when unit_concept_id = 8636 then value_as_number*1000-- g/l
		else null end as crVal,
		value_as_concept_id,
        CASE 
		WHEN gender_concept_id = 8532 -- female 
		THEN 1.018
		ELSE 1 END AS genderFactor,
		CASE 
		WHEN race_concept_id in (8516,38003598) THEN 1.159 --black
		ELSE 1 END AS raceFactor,
		CASE 
        WHEN gender_concept_id = 8532 THEN 0.7 -- female 
		ELSE 0.9 END AS kappaFactor,
		CASE 
        WHEN gender_concept_id = 8532 THEN -0.329 -- female 
        ELSE -0.411	 END AS alphaFactor
	FROM ohdsi_cumc_deid_pending.dbo.person p
    JOIN ohdsi_cumc_deid_pending.dbo.MEASUREMENT m on p.person_id = m.person_id
    JOIN ohdsi_cumc_deid_pending.results.#CKD_codes on measurement_concept_id = concept_id and category = 'creatinine' 
    WHERE m.value_as_number IS NOT NULL and m.value_as_number>0
	) CR 
    ;

IF OBJECT_ID('#height') IS NOT NULL
	DROP TABLE #height;
CREATE TABLE #height (
	person_id INT,
	measurement_date DATETIME2(6),
	measurement_concept_id INT,
	ht VARCHAR(100),
	value_as_concept_id INT
	);
	

INSERT INTO #height
    SELECT DISTINCT
      m.person_id,
      m.measurement_date,
      m.measurement_concept_id,
      case when m.unit_concept_id = 8533
        then m.value_as_number * 2.54 --	Inches
      when m.unit_concept_id = 8547
        then m.value_as_number * 100 -- m
      when m.unit_concept_id = 8582
        then m.value_as_number --cm
      else null end AS ht,
      m.value_as_concept_id
    FROM ohdsi_cumc_deid_pending.dbo.MEASUREMENT m
      JOIN #creatinine c on m.person_id = c.person_id
    WHERE m.measurement_concept_id IN (select concept_id
                                     from #ckd_codes
                                     where category = 'height')
          AND DATEADD(year, 1, c.measurement_date) >= m.measurement_date
          AND DATEADD(year, -1, c.measurement_date) <= m.measurement_date
	  AND m.value_as_number IS NOT NULL;


CREATE TABLE #EGFR (
	person_id INT,
	gender_concept_id INT,
	race_concept_id INT,
	measurement_date DATETIME2(6),
	measurement_concept_id INT,
	ageAtMeasYear INT,
	year_of_birth INT,
	crVal VARCHAR(100),
	value_as_concept_id INT,
	genderFactor FLOAT,
	raceFactor FLOAT,
	kappaFactor FLOAT,
	alphaFactor FLOAT,
	minCrK FLOAT,
	maxCrK FLOAT,		
	Ht FLOAT,
	eGFR FLOAT,
	Estage VARCHAR(2),	
);

INSERT INTO #EGFR
    SELECT
      egfr.*,
      CASE WHEN eGFR > 90
        THEN '1'
      WHEN eGFR > 60 and eGFR < cast(89 as float)
        THEN '2'
      WHEN eGFR > 45 and eGFR < cast(59 as float)
        THEN '3A'
      WHEN eGFR > 30 and eGFR < cast(44 as float)
        THEN '3B'
      WHEN eGFR > 15 and eGFR < cast(29 as float)
        THEN '4'
      WHEN eGFR < cast(15 as float)
        THEN '5'
      ELSE NULL END
        as Estage
    FROM (
           SELECT DISTINCT
             cr.*,
	     h.Ht,
             CASE WHEN ageAtMeasYear >= 18 AND cr.crVal > cast (0 as float)
               THEN
                 141
                 * POWER(CAST(minCrk AS DECIMAL(9,3)), alphaFactor)
                 * POWER(CAST(maxCrk AS DECIMAL(9,3)), -1.209)
                 * POWER(CAST(0.993 AS DECIMAL(9,3)), ageAtMeasYear)
                 * genderFactor
                 * raceFactor
             WHEN ageAtMeasYear < 18 AND cr.crVal > cast (0 as float)
               THEN
                 0.41 * cast(h.ht as float)/  cast(cr.crVal as float)
             ELSE NULL END AS eGFR
           FROM #creatinine cr
	   JOIN #height h on cr.person_id = h.person_id
         ) egfr
    WHERE eGFR is not NULL;


-- START COHORTS ---



with primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id) as
(
-- Begin Primary Events
select P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
FROM
(
  select E.person_id, E.start_date, E.end_date, row_number() OVER (PARTITION BY E.person_id ORDER BY E.start_date ASC) ordinal, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM 
  (
      -- Begin CDM tables Criteria
      select
        pe.person_id                                             as person_id,
        pe.procedure_occurrence_id                 as event_id,
        pe.procedure_date as start_date,
        pe.procedure_date     as end_date,
        pe.procedure_concept_id                       as TARGET_CONCEPT_ID,
        pe.visit_occurrence_id                         as visit_occurrence_id
      FROM #CKD_codes ckd
        JOIN ohdsi_cumc_deid_pending.dbo.PROCEDURE_OCCURRENCE pe
          on (pe.procedure_concept_id = ckd.concept_id and ckd.category = 'transplant')

	
	union all
	
      select
        co.person_id,
        co.condition_occurrence_id                 as event_id,
        co.condition_start_date as start_date,
        co.condition_end_date     as end_date,
        co.condition_concept_id                       as TARGET_CONCEPT_ID,
        co.visit_occurrence_id
      FROM #CKD_codes ckd
        JOIN ohdsi_cumc_deid_pending.dbo.CONDITION_OCCURRENCE co
          on (co.condition_concept_id = ckd.concept_id and ckd.category = 'transplant')

  ) E
	JOIN ohdsi_cumc_deid_pending.dbo.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
  WHERE DATEADD(day,0,OP.OBSERVATION_PERIOD_START_DATE) <= E.START_DATE AND DATEADD(day,0,E.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
) P
WHERE P.ordinal = 1
-- End Primary Events

)
SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
INTO #qualified_events
FROM 
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM primary_events pe
  
) QE

;

--- Inclusion Rule Inserts

create table #inclusion_events (inclusion_rule_id bigint,
	person_id bigint,
	event_id bigint
);

with cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal) as
(
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  from
  (
    select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    from #qualified_events Q
    LEFT JOIN #inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
  ) MG -- matching groups

)
select event_id, person_id, start_date, end_date, op_start_date, op_end_date
into #included_events
FROM cteIncludedEvents Results
WHERE Results.ordinal = 1
;

-- generate cohort periods into #final_cohort
with cohort_ends (event_id, person_id, end_date) as
(
	-- cohort exit dates
  -- By default, cohort exit at the event's op end date
select event_id, person_id, op_end_date as end_date from #included_events
),
first_ends (person_id, start_date, end_date) as
(
	select F.person_id, F.start_date, F.end_date
	FROM (
	  select I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  from #included_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	) F
	WHERE F.ordinal = 1
)
select person_id, start_date, end_date
INTO #cohort_rows
from first_ends;

with cteEndDates (person_id, end_date) AS -- the magic
(	
	SELECT
		person_id
		, DATEADD(day,-1 * 0, event_date)  as end_date
	FROM
	(
		SELECT
			person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM
		(
			SELECT
				person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM #cohort_rows
		
			UNION ALL
		

			SELECT
				person_id
				, DATEADD(day,0,end_date) as end_date
				, 1 AS event_type
				, NULL
			FROM #cohort_rows
		) RAWDATA
	) e
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
),
cteEnds (person_id, start_date, end_date) AS
(
	SELECT
		 c.person_id
		, c.start_date
		, MIN(e.end_date) AS era_end_date
	FROM #cohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
)
select person_id, min(start_date) as start_date, end_date
into #final_cohort
from cteEnds
group by person_id, end_date
;

DELETE FROM ohdsi_cumc_deid_pending.results.cohort where cohort_definition_id = 1000;
INSERT INTO ohdsi_cumc_deid_pending.results.cohort(cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select 1000 as cohort_definition_id, person_id, start_date, end_date 
FROM #final_cohort CO
;

TRUNCATE TABLE #cohort_rows;
DROP TABLE #cohort_rows;

TRUNCATE TABLE #final_cohort;
DROP TABLE #final_cohort;

TRUNCATE TABLE #inclusion_events;
DROP TABLE #inclusion_events;

TRUNCATE TABLE #qualified_events;
DROP TABLE #qualified_events;

TRUNCATE TABLE #included_events;
DROP TABLE #included_events;


with primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id) as
(
-- Begin Primary Events
select P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
FROM
(
  select E.person_id, E.start_date, E.end_date, row_number() OVER (PARTITION BY E.person_id ORDER BY E.start_date ASC) ordinal, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM 
  (
    -- Begin CDM tables Criteria
      select
        pe.person_id                                             as person_id,
        pe.procedure_occurrence_id                 as event_id,
        pe.procedure_date as start_date,
        pe.procedure_date     as end_date,
        pe.procedure_concept_id                       as TARGET_CONCEPT_ID,
        pe.visit_occurrence_id                         as visit_occurrence_id
      FROM #CKD_codes ckd
        JOIN ohdsi_cumc_deid_pending.dbo.PROCEDURE_OCCURRENCE pe
          on (pe.procedure_concept_id = ckd.concept_id and ckd.category = 'dialysis')
	
	union all
	
      select
        co.person_id,
        co.condition_occurrence_id                 as event_id,
        co.condition_start_date as start_date,
        co.condition_end_date     as end_date,
        co.condition_concept_id                       as TARGET_CONCEPT_ID,
        co.visit_occurrence_id
      FROM #CKD_codes ckd
        JOIN ohdsi_cumc_deid_pending.dbo.CONDITION_OCCURRENCE co
          on (co.condition_concept_id = ckd.concept_id and ckd.category = 'dialysis')
	
	union all
	
      select
        o.person_id,
        o.observation_id                 as event_id,
        o.observation_date as start_date,
        o.observation_date     as end_date,
        o.observation_concept_id                       as TARGET_CONCEPT_ID,
        o.visit_occurrence_id
      FROM #CKD_codes ckd
        JOIN ohdsi_cumc_deid_pending.dbo.OBSERVATION o
          on (o.observation_concept_id = ckd.concept_id and ckd.category = 'dialysis')

  ) E
	JOIN ohdsi_cumc_deid_pending.dbo.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
  WHERE DATEADD(day,0,OP.OBSERVATION_PERIOD_START_DATE) <= E.START_DATE AND DATEADD(day,0,E.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
) P
WHERE P.ordinal = 1
-- End Primary Events

)
SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
INTO #qualified_events
FROM 
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM primary_events pe
  
) QE

;

--- Inclusion Rule Inserts

create table #inclusion_events (inclusion_rule_id bigint,
	person_id bigint,
	event_id bigint
);

with cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal) as
(
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  from
  (
    select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    from #qualified_events Q
    LEFT JOIN #inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
  ) MG -- matching groups

)
select event_id, person_id, start_date, end_date, op_start_date, op_end_date
into #included_events
FROM cteIncludedEvents Results
WHERE Results.ordinal = 1
;



-- generate cohort periods into #final_cohort
with cohort_ends (event_id, person_id, end_date) as
(
	-- cohort exit dates
  -- By default, cohort exit at the event's op end date
select event_id, person_id, op_end_date as end_date from #included_events
),
first_ends (person_id, start_date, end_date) as
(
	select F.person_id, F.start_date, F.end_date
	FROM (
	  select I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  from #included_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	) F
	WHERE F.ordinal = 1
)
select person_id, start_date, end_date
INTO #cohort_rows
from first_ends;

with cteEndDates (person_id, end_date) AS -- the magic
(	
	SELECT
		person_id
		, DATEADD(day,-1 * 0, event_date)  as end_date
	FROM
	(
		SELECT
			person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM
		(
			SELECT
				person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM #cohort_rows
		
			UNION ALL
		

			SELECT
				person_id
				, DATEADD(day,0,end_date) as end_date
				, 1 AS event_type
				, NULL
			FROM #cohort_rows
		) RAWDATA
	) e
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
),
cteEnds (person_id, start_date, end_date) AS
(
	SELECT
		 c.person_id
		, c.start_date
		, MIN(e.end_date) AS era_end_date
	FROM #cohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
)
select person_id, min(start_date) as start_date, end_date
into #final_cohort
from cteEnds
group by person_id, end_date
;

DELETE FROM ohdsi_cumc_deid_pending.results.cohort where cohort_definition_id = 1001;
INSERT INTO ohdsi_cumc_deid_pending.results.cohort (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select 1001 as cohort_definition_id, person_id, start_date, end_date 
FROM #final_cohort CO
;


TRUNCATE TABLE #cohort_rows;
DROP TABLE #cohort_rows;

TRUNCATE TABLE #final_cohort;
DROP TABLE #final_cohort;

TRUNCATE TABLE #inclusion_events;
DROP TABLE #inclusion_events;

TRUNCATE TABLE #qualified_events;
DROP TABLE #qualified_events;

TRUNCATE TABLE #included_events;
DROP TABLE #included_events;


with primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id) as
(
-- Begin Primary Events
select P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
FROM
(
  select E.person_id, E.start_date, E.end_date, row_number() OVER (PARTITION BY E.person_id ORDER BY E.start_date ASC) ordinal, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM 
  (
      -- Begin CDM tables Criteria
      select
        co.person_id,
        co.condition_occurrence_id                as event_id,
        co.condition_start_date as start_date,
        co.condition_end_date   as end_date,
        co.condition_concept_id     as TARGET_CONCEPT_ID,
         co.visit_occurrence_id
      FROM #CKD_codes ckd
         JOIN ohdsi_cumc_deid_pending.dbo.CONDITION_OCCURRENCE co
          on (co.condition_concept_id = ckd.concept_id and ckd.category = 'other_acute')

  ) E
	JOIN ohdsi_cumc_deid_pending.dbo.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
  WHERE DATEADD(day,0,OP.OBSERVATION_PERIOD_START_DATE) <= E.START_DATE AND DATEADD(day,0,E.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
) P
WHERE P.ordinal = 1
-- End Primary Events

)
SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
INTO #qualified_events
FROM 
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM primary_events pe
  
) QE

;

--- Inclusion Rule Inserts

create table #inclusion_events (inclusion_rule_id bigint,
	person_id bigint,
	event_id bigint
);

with cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal) as
(
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  from
  (
    select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    from #qualified_events Q
    LEFT JOIN #inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
  ) MG -- matching groups

)
select event_id, person_id, start_date, end_date, op_start_date, op_end_date
into #included_events
FROM cteIncludedEvents Results
WHERE Results.ordinal = 1
;



-- generate cohort periods into #final_cohort
with cohort_ends (event_id, person_id, end_date) as
(
	-- cohort exit dates
  -- By default, cohort exit at the event's op end date
select event_id, person_id, op_end_date as end_date from #included_events
),
first_ends (person_id, start_date, end_date) as
(
	select F.person_id, F.start_date, F.end_date
	FROM (
	  select I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  from #included_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	) F
	WHERE F.ordinal = 1
)
select person_id, start_date, end_date
INTO #cohort_rows
from first_ends;

with cteEndDates (person_id, end_date) AS -- the magic
(	
	SELECT
		person_id
		, DATEADD(day,-1 * 0, event_date)  as end_date
	FROM
	(
		SELECT
			person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM
		(
			SELECT
				person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM #cohort_rows
		
			UNION ALL
		

			SELECT
				person_id
				, DATEADD(day,0,end_date) as end_date
				, 1 AS event_type
				, NULL
			FROM #cohort_rows
		) RAWDATA
	) e
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
),
cteEnds (person_id, start_date, end_date) AS
(
	SELECT
		 c.person_id
		, c.start_date
		, MIN(e.end_date) AS era_end_date
	FROM #cohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
)
select person_id, min(start_date) as start_date, end_date
into #final_cohort
from cteEnds
group by person_id, end_date
;


DELETE FROM ohdsi_cumc_deid_pending.results.cohort where cohort_definition_id = 1002;
INSERT INTO ohdsi_cumc_deid_pending.results.cohort (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select 1002 as cohort_definition_id, person_id, start_date, end_date 
FROM #final_cohort CO
;


TRUNCATE TABLE #cohort_rows;
DROP TABLE #cohort_rows;

TRUNCATE TABLE #final_cohort;
DROP TABLE #final_cohort;

TRUNCATE TABLE #inclusion_events;
DROP TABLE #inclusion_events;

TRUNCATE TABLE #qualified_events;
DROP TABLE #qualified_events;

TRUNCATE TABLE #included_events;
DROP TABLE #included_events;


with primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id) as
(
-- Begin Primary Events
select P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
FROM
(
  select E.person_id, E.start_date, E.end_date, row_number() OVER (PARTITION BY E.person_id ORDER BY E.start_date ASC) ordinal, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM 
  (
      -- Begin CDM tables Criteria
      select
        co.person_id,
        co.condition_occurrence_id                as event_id,
        co.condition_start_date as start_date,
        co.condition_end_date   as end_date,
        co.condition_concept_id     as TARGET_CONCEPT_ID,
         co.visit_occurrence_id
      FROM #CKD_codes ckd
         JOIN ohdsi_cumc_deid_pending.dbo.CONDITION_OCCURRENCE co
          on (co.condition_concept_id = ckd.concept_id and ckd.category = 'AKD')

  ) E
	JOIN ohdsi_cumc_deid_pending.dbo.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
  WHERE DATEADD(day,0,OP.OBSERVATION_PERIOD_START_DATE) <= E.START_DATE AND DATEADD(day,0,E.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
) P
WHERE P.ordinal = 1
-- End Primary Events

)
SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
INTO #qualified_events
FROM 
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM primary_events pe
  
) QE

;

--- Inclusion Rule Inserts

create table #inclusion_events (inclusion_rule_id bigint,
	person_id bigint,
	event_id bigint
);

with cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal) as
(
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  from
  (
    select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    from #qualified_events Q
    LEFT JOIN #inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
  ) MG -- matching groups

)
select event_id, person_id, start_date, end_date, op_start_date, op_end_date
into #included_events
FROM cteIncludedEvents Results
WHERE Results.ordinal = 1
;



-- generate cohort periods into #final_cohort
with cohort_ends (event_id, person_id, end_date) as
(
	-- cohort exit dates
  -- By default, cohort exit at the event's op end date
select event_id, person_id, op_end_date as end_date from #included_events
),
first_ends (person_id, start_date, end_date) as
(
	select F.person_id, F.start_date, F.end_date
	FROM (
	  select I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  from #included_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	) F
	WHERE F.ordinal = 1
)
select person_id, start_date, end_date
INTO #cohort_rows
from first_ends;

with cteEndDates (person_id, end_date) AS -- the magic
(	
	SELECT
		person_id
		, DATEADD(day,-1 * 0, event_date)  as end_date
	FROM
	(
		SELECT
			person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM
		(
			SELECT
				person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM #cohort_rows
		
			UNION ALL
		

			SELECT
				person_id
				, DATEADD(day,0,end_date) as end_date
				, 1 AS event_type
				, NULL
			FROM #cohort_rows
		) RAWDATA
	) e
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
),
cteEnds (person_id, start_date, end_date) AS
(
	SELECT
		 c.person_id
		, c.start_date
		, MIN(e.end_date) AS era_end_date
	FROM #cohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
)
select person_id, min(start_date) as start_date, end_date
into #final_cohort
from cteEnds
group by person_id, end_date
;



DELETE FROM ohdsi_cumc_deid_pending.results.cohort where cohort_definition_id = 1003;
INSERT INTO ohdsi_cumc_deid_pending.results.cohort (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select 1003 as cohort_definition_id, person_id, start_date, end_date 
FROM #final_cohort CO
;


TRUNCATE TABLE #cohort_rows;
DROP TABLE #cohort_rows;

TRUNCATE TABLE #final_cohort;
DROP TABLE #final_cohort;

TRUNCATE TABLE #inclusion_events;
DROP TABLE #inclusion_events;

TRUNCATE TABLE #qualified_events;
DROP TABLE #qualified_events;

TRUNCATE TABLE #included_events;
DROP TABLE #included_events;

with primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id) as
(
-- Begin Primary Events
select P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
FROM
(
  select E.person_id, E.start_date, E.end_date, row_number() OVER (PARTITION BY E.person_id ORDER BY E.start_date ASC) ordinal, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM 
  (
      -- Begin CDM tables Criteria
      select
        co.person_id,
        co.condition_occurrence_id                as event_id,
        co.condition_start_date as start_date,
        co.condition_end_date   as end_date,
        co.condition_concept_id     as TARGET_CONCEPT_ID,
         co.visit_occurrence_id
      FROM #CKD_codes ckd
         JOIN ohdsi_cumc_deid_pending.dbo.CONDITION_OCCURRENCE co
          on (co.condition_concept_id = ckd.concept_id and ckd.category = 'CKD')
	
	union all
	
      select
        m.person_id,
        m.measurement_id              as event_id,
        m.measurement_date as start_date,
        m.measurement_date     as end_date,
        m.measurement_concept_id                       as TARGET_CONCEPT_ID,
        m.visit_occurrence_id
      FROM #CKD_codes ckd
        JOIN ohdsi_cumc_deid_pending.dbo.MEASUREMENT m
          on (m.measurement_concept_id = ckd.concept_id and ckd.category = 'CKD')

  ) E
	JOIN ohdsi_cumc_deid_pending.dbo.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
  WHERE DATEADD(day,0,OP.OBSERVATION_PERIOD_START_DATE) <= E.START_DATE AND DATEADD(day,0,E.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
) P
WHERE P.ordinal = 1
-- End Primary Events

)
SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
INTO #qualified_events
FROM 
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM primary_events pe
  
) QE

;

--- Inclusion Rule Inserts

create table #inclusion_events (inclusion_rule_id bigint,
	person_id bigint,
	event_id bigint
);

with cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal) as
(
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  from
  (
    select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    from #qualified_events Q
    LEFT JOIN #inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
  ) MG -- matching groups

)
select event_id, person_id, start_date, end_date, op_start_date, op_end_date
into #included_events
FROM cteIncludedEvents Results
WHERE Results.ordinal = 1
;



-- generate cohort periods into #final_cohort
with cohort_ends (event_id, person_id, end_date) as
(
	-- cohort exit dates
  -- By default, cohort exit at the event's op end date
select event_id, person_id, op_end_date as end_date from #included_events
),
first_ends (person_id, start_date, end_date) as
(
	select F.person_id, F.start_date, F.end_date
	FROM (
	  select I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  from #included_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	) F
	WHERE F.ordinal = 1
)
select person_id, start_date, end_date
INTO #cohort_rows
from first_ends;

with cteEndDates (person_id, end_date) AS -- the magic
(	
	SELECT
		person_id
		, DATEADD(day,-1 * 0, event_date)  as end_date
	FROM
	(
		SELECT
			person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM
		(
			SELECT
				person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM #cohort_rows
		
			UNION ALL
		

			SELECT
				person_id
				, DATEADD(day,0,end_date) as end_date
				, 1 AS event_type
				, NULL
			FROM #cohort_rows
		) RAWDATA
	) e
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
),
cteEnds (person_id, start_date, end_date) AS
(
	SELECT
		 c.person_id
		, c.start_date
		, MIN(e.end_date) AS era_end_date
	FROM #cohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
)
select person_id, min(start_date) as start_date, end_date
into #final_cohort
from cteEnds
group by person_id, end_date
;


DELETE FROM ohdsi_cumc_deid_pending.results.cohort where cohort_definition_id = 1004;
INSERT INTO ohdsi_cumc_deid_pending.results.cohort (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select 1004 as cohort_definition_id, person_id, start_date, end_date 
FROM #final_cohort CO
;


TRUNCATE TABLE #cohort_rows;
DROP TABLE #cohort_rows;

TRUNCATE TABLE #final_cohort;
DROP TABLE #final_cohort;

TRUNCATE TABLE #inclusion_events;
DROP TABLE #inclusion_events;

TRUNCATE TABLE #qualified_events;
DROP TABLE #qualified_events;

TRUNCATE TABLE #included_events;
DROP TABLE #included_events;

with primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id) as
(
-- Begin Primary Events
select P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
FROM
(
  select E.person_id, E.start_date, E.end_date, row_number() OVER (PARTITION BY E.person_id ORDER BY E.start_date ASC) ordinal, OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM 
  (

 -- Begin CDM tables Criteria
      select
        co.person_id,
        co.condition_occurrence_id                as event_id,
        co.condition_start_date as start_date,
        co.condition_end_date   as end_date,
        co.condition_concept_id     as TARGET_CONCEPT_ID,
         co.visit_occurrence_id
      FROM #CKD_codes ckd
         JOIN ohdsi_cumc_deid_pending.dbo.CONDITION_OCCURRENCE co
          on (co.condition_concept_id = ckd.concept_id and ckd.category = 'other_KD')


  ) E
	JOIN ohdsi_cumc_deid_pending.dbo.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
  WHERE DATEADD(day,0,OP.OBSERVATION_PERIOD_START_DATE) <= E.START_DATE AND DATEADD(day,0,E.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
) P
WHERE P.ordinal = 1
-- End Primary Events

)
SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
INTO #qualified_events
FROM 
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM primary_events pe
  
) QE

;

--- Inclusion Rule Inserts

create table #inclusion_events (inclusion_rule_id bigint,
	person_id bigint,
	event_id bigint
);

with cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal) as
(
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  from
  (
    select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    from #qualified_events Q
    LEFT JOIN #inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
  ) MG -- matching groups

)
select event_id, person_id, start_date, end_date, op_start_date, op_end_date
into #included_events
FROM cteIncludedEvents Results
WHERE Results.ordinal = 1
;



-- generate cohort periods into #final_cohort
with cohort_ends (event_id, person_id, end_date) as
(
	-- cohort exit dates
  -- By default, cohort exit at the event's op end date
select event_id, person_id, op_end_date as end_date from #included_events
),
first_ends (person_id, start_date, end_date) as
(
	select F.person_id, F.start_date, F.end_date
	FROM (
	  select I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal 
	  from #included_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	) F
	WHERE F.ordinal = 1
)
select person_id, start_date, end_date
INTO #cohort_rows
from first_ends;

with cteEndDates (person_id, end_date) AS -- the magic
(	
	SELECT
		person_id
		, DATEADD(day,-1 * 0, event_date)  as end_date
	FROM
	(
		SELECT
			person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal 
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM
		(
			SELECT
				person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM #cohort_rows
		
			UNION ALL
		

			SELECT
				person_id
				, DATEADD(day,0,end_date) as end_date
				, 1 AS event_type
				, NULL
			FROM #cohort_rows
		) RAWDATA
	) e
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
),
cteEnds (person_id, start_date, end_date) AS
(
	SELECT
		 c.person_id
		, c.start_date
		, MIN(e.end_date) AS era_end_date
	FROM #cohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
)
select person_id, min(start_date) as start_date, end_date
into #final_cohort
from cteEnds
group by person_id, end_date
;


DELETE FROM ohdsi_cumc_deid_pending.results.cohort where cohort_definition_id = 1005;
INSERT INTO ohdsi_cumc_deid_pending.results.cohort (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select 1005 as cohort_definition_id, person_id, start_date, end_date 
FROM #final_cohort CO
;


TRUNCATE TABLE #cohort_rows;
DROP TABLE #cohort_rows;

TRUNCATE TABLE #final_cohort;
DROP TABLE #final_cohort;

TRUNCATE TABLE #inclusion_events;
DROP TABLE #inclusion_events;

TRUNCATE TABLE #qualified_events;
DROP TABLE #qualified_events;

TRUNCATE TABLE #included_events;
DROP TABLE #included_events;


-- START PHENOTYPE----
/*** Block 5C: get most recent eGFR for patient who has eGFR ***/

DROP TABLE #GFRrecent;
CREATE TABLE #GFRrecent (
	person_id INT NOT NULL
	,eGFRrecentVal FLOAT NOT NULL
	,eGFRrecentDt DATETIME2(6) NOT NULL
);

INSERT INTO @target_database_schema.#GFRrecent
SELECT person_id, eGFR AS eGFRrecentVal, measurement_date AS eGFRrecentDt
FROM (
	SELECT person_id, eGFR, measurement_date, ROW_NUMBER() OVER(PARTITION BY person_id ORDER by measurement_date DESC) AS rn
FROM #eGFR
) G
WHERE rn =1;

DROP TABLE #albumin_stage;
CREATE TABLE #albumin_stage (
	person_id INT,
	measurement_date DATETIME2(6),
	AStage VARCHAR(100),
	value_as_number FLOAT 
);
INSERT INTO  #albumin_stage
    SELECT
      person_id,
      measurement_date,
      CASE WHEN value_as_number < 30
        THEN 'A1'
      WHEN value_as_number >= 30 AND value_as_number <= 300
        THEN 'A2'
      WHEN value_as_number > 300
        THEN 'A3' END AS AStage,
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
       FROM ohdsi_cumc_deid_pending.dbo.MEASUREMENT m
       JOIN #ckd_codes ON concept_id = measurement_concept_id where category = 'albumin'
	   WHERE value_as_number IS NOT NULL
      ) alb;

IF OBJECT_ID('#protein_stage') IS NOT NULL
	DROP TABLE #protein_stage;
CREATE TABLE @target_database_schema.#protein_stage (
	person_id INT,
	measurement_date DATETIME2(6),
	PStage VARCHAR(100),
	value_as_number FLOAT 
);

 INSERT INTO #protein_stage
    SELECT
      person_id,
      measurement_date,
      CASE WHEN PA1 >= PA2 AND PA1 >= PA3
        THEN 'A1'
      WHEN PA2 >= PA1 AND PA2 >= PA3
        THEN 'A2'
      WHEN PA3 >= PA1 AND PA3 >= PA2
        THEN 'A3' END AS Pstage,
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
					   unit_concept_id,
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
                     FROM ohdsi_cumc_deid_pending.dbo.MEASUREMENT m
                       join #ckd_codes on measurement_concept_id = concept_id
                     where category = 'protein'
					 and value_as_number is not null ) pr1
					 where pr1.value_as_number is not null 
         ) pr2
  ) pr3;


/* *** BLOCK 6: Dialysis co-occurrent with AKI, defined as AKI happens before or after 1 month of dialysis, 1 month is defined as 31 days (DATEDIFF in month is 1 if the difference between two dates is 1.5 months) ****/
DROP TABLE #DialysisCooccurrentWithAKI;
CREATE TABLE #DialysisCooccurrentWithAKI (
	person_id INT,
	dialysisDt DATETIME2(6),
	akiDt DATETIME2(6),
	dialysisAkiDiffDtAbs INT
);
INSERT INTO #DialysisCooccurrentWithAKI
SELECT DISTINCT T.subject_id, T.cohort_start_date AS dialysisDt, U.cohort_start_date AS akiDt
	, ABS(DATEDIFF(day, T.cohort_start_date, U.cohort_start_date)) AS dialysisAkiDiffDtAbs
FROM ohdsi_cumc_deid_pending.results.cohort T
LEFT JOIN ohdsi_cumc_deid_pending.results.cohort U
ON T.subject_id=U.subject_id 
WHERE T.cohort_definition_id = 1001 -- dialysis
AND U.cohort_definition_id = 1003 -- acute CK
AND ABS(DATEDiff(DAY, T.cohort_start_date, U.cohort_start_date)) <= 31 --For acute calculating of 1 month by using 31 days. 
;
 
/* *** BLOCK 7: eGFR co-occurrent with acute conditions (AKI/prerenal kidney injury/sepsis/volume depletion/shock), defined as acute conditions happen before or after 1 month of eGFR *** */
DROP TABLE  #GfrCooccurrentWithAcuteCondition;
CREATE TABLE  #GfrCooccurrentWithAcuteCondition(
	person_id INT
	,eGfrDt DATETIME2(6)
	,acuteConditionDt DATETIME2(6)
	,eGfrAcuteConditionDiffDtAbs INT
	);
		
INSERT INTO #GfrCooccurrentWithAcuteCondition
SELECT DISTINCT T.person_id, T.measurement_date AS eGfrDt, U.cohort_start_date AS acuteConditionDt
	,  ABS(DATEDIFF(day, T.measurement_date, U.cohort_start_date)) AS eGfrAcuteConditionDiffDtAbs
FROM #eGFR T
LEFT JOIN ohdsi_cumc_deid_pending.results.cohort U ON T.person_id=U.subject_id
WHERE U.cohort_definition_id IN (1002,1003)
AND  ABS(DATEDIFF(day, T.measurement_date, U.cohort_start_date)) <= 31 --For acute calculating of 1 month by using 31 days.
 ;





