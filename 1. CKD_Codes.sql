create table @target_database_schema.ckd_codes
(category nvarchar(400),
concept_id int,
concept_name nvarchar(400),
concept_code nvarchar(400),
vocabulary_id nvarchar(400),
domain_id nvarchar(400)
);


insert into @target_database_schema.ckd_codes (category,concept_id,concept_name,concept_code,vocabulary_id,domain_id )
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
          from @cdm_database_schema.concept c
          where concept_id in (4030731, 3014149, 3008989, 3015514, 3019171, 3013842, 3023357, 3023540, 3035463, 3036277)
          union all
          select
            'creatinine',
            c.*
          from @cdm_database_schema.concept c
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
          from @cdm_database_schema.concept c
          where concept_id in
                (46236963, 3033268, 3050449, 3018097, 3027035, 043771, 40766204, 3005577, 3040290, 3043179, 40759673, 3049506, 40761549)
          union all
          select
            'albumin',
            c.* --	mass/volume
          from @cdm_database_schema.concept c
          where concept_id in
                (3008512, 3012516, 46236875, 3039775, 3018104, 3030511, 3008960, 37393656, 4193719, 40760483, 3005031, 3039436, 3046828, 3000034)
          union all
          select
            'albumin',
            c.* -- albumin general codes
          from @cdm_database_schema.concept c
          where concept_id in (4017498, 2212188, 2212189, 4152996)
          union all
          select
            'protein',
            c.* -- general
          from @cdm_database_schema.concept c
          where concept_id in (4152995, 4064934,3001237,3005897,3011705,3014051,3017756,3017817,3019077,3020876,3028250,3029872,3033812,3035511,
			       3037121,3037185,3038906,3039271,3040443,3040816,3044927,4025832,4041881,4064934,4152995,4154500,
	                       4211845,4220762,4251338,21491095,40760845,40762085,46235791)
          union all
          select
            'alb/creat_ratio',
            c.*
          from @cdm_database_schema.concept c
          where
            concept_id in (3000819, 3034485, 3002812, 3000837, 46235897, 3020682, 3043209, 3002827, 3001802, 40762252,
                                    46235435, 3022826, 46235434, 3023556, 4154347)
          union all
          select
            'egfr',
            c.*
          from @cdm_database_schema.concept c
          where concept_id in
                (3029829, 3029859, 3030104, 3045262, 36304157, 36306178, 40478895, 40478963, 40483219, 40485075,
                  40490315, 40764999, 40771922, 42869913, 4478827544790183, 44806420, 46236952, 46236975, 3049187,
                  3053283, 36303797)
          union all
          select
            'gravity',
            c.*
          from @cdm_database_schema.concept c
          where concept_id in
                (2212165, 2212166, 2212577, 3000330, 3019150, 3029991, 3032448, 3033543, 3034076, 3039919, 3043812, 4147583)
        ) c
;

INSERT INTO @target_database_schema.ckd_codes
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
FROM @cdm_database_schema.concept_ancestor
  JOIN @cdm_database_schema.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
  JOIN @cdm_database_schema.concept c
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


INSERT INTO @target_database_schema.ckd_codes
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
FROM @cdm_database_schema.concept_ancestor
  JOIN @cdm_database_schema.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
  JOIN @cdm_database_schema.concept c
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
45887996,--End-Stage Renal Disease Services
45889365 --Dialysis Services and Procedures
)
AND   c.vocabulary_id NOT IN ('MeSH','PPI','SUS');


INSERT INTO @target_database_schema.ckd_codes
  (category, concept_id, concept_name, concept_code, vocabulary_id, domain_id)
SELECT
  'AKD' AS category,
  c.concept_id,
  c.concept_name,
  c.concept_code,
  c.vocabulary_id,
  c.domain_id
FROM @cdm_database_schema.concept_ancestor
  JOIN @cdm_database_schema.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
  JOIN @cdm_database_schema.concept c
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



INSERT INTO @target_database_schema.ckd_codes
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
  FROM @cdm_database_schema.concept_ancestor
    JOIN @cdm_database_schema.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
    JOIN @cdm_database_schema.concept c
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

INSERT INTO @target_database_schema.ckd_codes
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
  FROM @cdm_database_schema.concept_ancestor
    JOIN @cdm_database_schema.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
    JOIN @cdm_database_schema.concept c
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
INSERT INTO @target_database_schema.ckd_codes
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
  FROM @cdm_database_schema.concept_ancestor
    JOIN @cdm_database_schema.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
    JOIN @cdm_database_schema.concept c
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

INSERT INTO @target_database_schema.ckd_codes
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
  FROM @cdm_database_schema.concept_ancestor
    JOIN @cdm_database_schema.concept_relationship cr ON cr.concept_id_2 = descendant_concept_id
    JOIN @cdm_database_schema.concept c
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
