CREATE TABLE height
  as
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
      else null end AS value_as_number,
      m.value_as_concept_id
    FROM MEASUREMENT m
      JOIN creatinine c using (person_id)
    WHERE m.measurement_concept_id IN (select concept_id
                                     from ckd_codes
                                     where category = 'height')
          AND (c.measurement_date + INTERVAL '12 month') >= m.measurement_date
          AND (c.measurement_date - INTERVAL '12 month') <= m.measurement_date;
