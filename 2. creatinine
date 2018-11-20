CREATE TABLE creatinine 
AS
SELECT cr.*,
	  CASE WHEN crVal/kappaFactor < 1 THEN crVal/kappaFactor ELSE 1 END AS minCrK,
	  CASE WHEN crVal/kappaFactor > 1 THEN crVal/kappaFactor ELSE 1 END AS maxCrK
	  FROM (
SELECT DISTINCT person_id, gender_concept_id, race_concept_id,  
		measurement_start_date,
        extract(year from measurement_start_date) - year_of_birth as ageAtMeasYear
		measurement_concept_id, 
		case 
		when unit_concept_id = 8840 then value_as_number-- mg/dl
		when unit_concept_id = 8842 then value_as_number*0.0001 -- ng/ml
		when unit_concept_id = 8749 then value_as_number*0.0113  -- mcmol/l
		when unit_concept_id = when unit_concept_id =9586 then value_as_number*11300 -- mol/l
		when unit_concept_id = 8753 then value_as_number*11.3 -- mmol/l 
		when unit_concept_id = 8636 then value_as_number*1000-- g/l
		else null end as value_as_number,
		value_as_concept_id,
		value_as_string,
        CASE 
		WHEN gender_concept_id = 8532 -- female THEN 1.018
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
	FROM person
    JOIN MEASUREMENT using (person_id)
    JOIN CKD_codes on measurement_concept_id = concept_id and category = 'creatinine' ) CR 
    ;
