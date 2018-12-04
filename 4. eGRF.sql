IF OBJECT_ID('#EGFR') IS NOT NULL
	DROP TABLE @target_database_schema.#EGFR;
CREATE TABLE @target_database_schema.#EGFR (
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
	Estage VARCHAR(5)
);

INSERT INTO @target_database_schema.#EGFR
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
	    UNION
	    SELECT person_id,gender_concept_id,race_concept_id,measurement_date,measurement_concept_id,
	    year(measurement_date) - year_of_birth AS ageAtMeasYear, year_of_birth, null, null, null, null,
	    null, null, null, value_as_number
	    FROM @cdm_database_schema.measurement
	    join @target_database_schema.CKD_codes on  measurement_concept_id = concept_id and category= 'egfr'

         ) egfr
    WHERE eGFR is not NULL;
