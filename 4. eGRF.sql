CREATE TABLE EGFR
  AS
    SELECT
      egfr.*,
      CASE WHEN eGFR > 90
        THEN '1'
      WHEN eGFR > 60 and eGFR < 89
        THEN '2'
      WHEN eGFR > 45 and eGFR < 59
        THEN '3A'
      WHEN eGFR > 30 and eGFR < 44
        THEN '3B'
      WHEN eGFR > 15 and eGFR < 29
        THEN '4'
      WHEN eGFR < 15
        THEN '5'
      ELSE NULL END
        as Estage
    FROM (
           SELECT DISTINCT
             cr.*,
             CASE WHEN ageAtMeasYear >= 18 AND value_as_number > 0
               THEN
                 141
                 * POWER(CAST(minCrk AS DECIMAL(9, 3)), alphaFactor)
                 * POWER(CAST(maxCrk AS DECIMAL(9, 3)), -1.209)
                 * POWER(CAST(0.993 AS DECIMAL(9, 3)), ageAtMeasYear)
                 * genderFactor
                 * raceFactor
             WHEN ageAtMeasYear < 18 AND value_as_number > 0
               THEN
                 0.41
                 * (SELECT value_as_number
                    FROM height h
                    WHERE h.person_id = cr.person_id)
                 / value_as_number
             ELSE NULL END AS eGFR
           FROM creatinine cr
         ) egfr
    WHERE eGFR is not NULL;
