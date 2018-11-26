IF OBJECT_ID('#height') IS NOT NULL
	DROP TABLE @target_database_schema.#height;
CREATE TABLE @target_database_schema.#height (
	person_id INT,
	measurement_date DATETIME2(6),
	measurement_concept_id INT,
	ht VARCHAR(100),
	value_as_concept_id INT
	);
	

INSERT INTO @target_database_schema.#height
    SELECT DISTINCT
      person_id,
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
    FROM @cdm_database_schema.MEASUREMENT m
      JOIN @target_database_schema.#creatinine c using (person_id)
    WHERE m.measurement_concept_id IN (select concept_id
                                     from @target_database_schema.#ckd_codes
                                     where category = 'height')
          AND DATEADD(year, 1, c.measurement_date) >= m.measurement_date
          AND DATEADD(year, -1, c.measurement_date) <= m.measurement_date
	  AND m.value_as_number IS NOT NULL;
