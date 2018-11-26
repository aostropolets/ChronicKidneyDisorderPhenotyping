IF OBJECT_ID('#creatinine') IS NOT NULL
	DROP TABLE @target_database_schema.#creatinine;
CREATE TABLE @target_database_schema.#creatinine (
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
		
	
INSERT INTO @target_database_schema.#creatinine 
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
	FROM @cdm_database_schema.person p
    JOIN @cdm_database_schema.MEASUREMENT m on p.person_id = m.person_id
    JOIN @target_database_schema.#CKD_codes on measurement_concept_id = concept_id and category = 'creatinine' 
    WHERE m.value_as_number IS NOT NULL and m.value_as_number>0
	) CR 
    ;