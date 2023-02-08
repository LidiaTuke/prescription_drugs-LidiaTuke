--1. 
--    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
 SELECT npi, SUM(total_claim_count) AS num_claim 
 FROM prescription
 GROUP BY npi
 ORDER BY num_claim DESC;
 -- 1881634483
--    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
 SELECT nppes_provider_first_name, 
        nppes_provider_last_org_name,  
		specialty_description, 
		SUM(total_claim_count) AS num_claim 
 FROM prescription AS p 
 INNER JOIN prescriber AS p2
 ON p.npi = p2.npi
 GROUP BY nppes_provider_first_name, 
        nppes_provider_last_org_name,  
		specialty_description
 ORDER BY num_claim DESC;
 --2. 
   -- a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description,
       SUM(total_claim_count) AS num_claim
FROM prescriber AS p2 
INNER JOIN prescription AS p 
ON p2.npi = p.npi
GROUP BY specialty_description
ORDER BY num_claim DESC;
-- Family Practice 9752347
  --  b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description,
       SUM(total_claim_count) AS num_claim 
FROM prescriber AS p2 
INNER JOIN prescription AS p 
ON p2.npi = p.npi
INNER JOIN drug AS d
ON p.drug_name = d.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY num_claim DESC;
-- Nurse Practitioner 900845
  --  c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description,
       SUM(total_claim_count) AS num_claim 
FROM prescriber AS p2 
INNER JOIN prescription AS p 
ON p2.npi = p.npi
WHERE total_claim_count = 1
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL
ORDER BY num_claim DESC;
-- NO 
 --   d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT specialty_description,
      SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count  END) AS num_claim,
	  SUM(total_claim_count),
	  SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count  END) * 100 / SUM(total_claim_count) AS percentage
FROM prescriber AS p2 
INNER JOIN prescription AS p 
ON p2.npi = p.npi
INNER JOIN drug AS d
USING(drug_name)
GROUP BY specialty_description
ORDER BY num_claim DESC NULLS LAST;

--3. a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, 
       SUM(total_drug_cost) AS num_drug_cost
FROM prescription AS p 
INNER JOIN drug AS d
USING(drug_name)
GROUP BY generic_name
ORDER BY num_drug_cost DESC;
--INSULIN GLARGINE,HUM.REC.ANLOG
--    b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT generic_name, 
       ROUND(SUM(total_drug_cost),2) AS num_drug_cost
FROM prescription AS p 
INNER JOIN drug AS d
USING(drug_name)
GROUP BY generic_name
ORDER BY num_drug_cost DESC;
SELECT *
FROM prescription
--4
--a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name,
     CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	      WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		  ELSE 'neither' END AS drug_type
FROM drug; 		  
  --  b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
     SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_drug_cost ::money END) AS opioid,
	 SUM(CASE WHEN antibiotic_drug_flag = 'Y' THEN total_drug_cost ::money END) AS antibiotic
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name); 	
--opioid 
--5. 
--a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa)
FROM cbsa AS c
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN'
-- 10
--    b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsa, SUM(population) AS num_pop
FROM cbsa AS c
INNER JOIN fips_county
USING(fipscounty)
INNER JOIN population AS p
USING(fipscounty)
WHERE state = 'TN'
GROUP BY cbsa
ORDER BY num_pop;
--34100 smallest
--34980 largest
--    c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
(SELECT county, population
FROM population AS p
INNER JOIN fips_county AS f
USING(fipscounty)
WHERE state = 'TN')
EXCEPT
(SELECT cbsa, population 
FROM cbsa AS c
INNER JOIN population AS p
USING(fipscounty))
ORDER BY population DESC
-- SHELBY 
--6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name,
       total_claim_count
FROM prescription 
WHERE total_claim_count >= 3000;
--    b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name,
       total_claim_count,
	   opioid_drug_flag
FROM prescription AS p
INNER JOIN drug AS d 
USING(drug_name)
WHERE total_claim_count >= 3000;
--    c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT drug_name,
       total_claim_count,
	   opioid_drug_flag,
	   nppes_provider_first_name,
	   nppes_provider_last_org_name
FROM prescription AS p
INNER JOIN drug AS d 
USING(drug_name)
INNER JOIN prescriber AS p2
USING(npi)
WHERE total_claim_count >= 3000;
-- 7.The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
SELECT DISTINCT p2.npi, d.drug_name, COALESCE(p.total_claim_count) AS total_claim
FROM prescriber AS p2
CROSS JOIN drug AS d
LEFT JOIN prescription AS p 
ON p2.npi = p.npi
WHERE specialty_description = 'Pain Management'
  AND nppes_provider_city = 'NASHVILLE'
  AND opioid_drug_flag = 'Y';
--    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi, d.drug_name
FROM prescriber AS p2
CROSS JOIN drug AS d
WHERE specialty_description = 'Pain Management'
  AND nppes_provider_city = 'NASHVILLE'
  AND opioid_drug_flag = 'Y'; 
--    b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT npi, d.drug_name, total_claim_count
FROM prescriber AS p2
CROSS JOIN drug AS d
LEFT JOIN prescription AS p
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
  AND nppes_provider_city = 'NASHVILLE'
  AND opioid_drug_flag = 'Y';    
--    c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT npi, d.drug_name, COALESCE(total_claim_count) AS total_claim
FROM prescriber AS p2
CROSS JOIN drug AS d
LEFT JOIN prescription AS p 
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
  AND nppes_provider_city = 'NASHVILLE'
  AND opioid_drug_flag = 'Y'
ORDER BY total_claim DESC NULLS LAST;
--BONUS
--1. How many npi numbers appear in the prescriber table but not in the prescription table?
(SELECT npi
FROM prescriber)
EXCEPT 
(SELECT npi
FROM prescription)
-- 4458
--2.
  --  a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT DISTINCT generic_name,
       npi,
	   specialty_description 
FROM prescriber AS p2
CROSS JOIN drug
WHERE specialty_description = 'Family Practice'
LIMIT 5;

 --   b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT DISTINCT generic_name,
       npi,
	   specialty_description 
FROM prescriber AS p2
CROSS JOIN drug
WHERE specialty_description = 'Cardiology'
LIMIT 5;
 --   c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
  --  a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT DISTINCT npi,
       total_claim_count,
	   state
FROM prescription AS p
CROSS JOIN fips_county AS f
WHERE state = 'TN'
ORDER BY total_claim_count DESC
LIMIT 5;


  --  b. Now, report the same for Memphis.
 SELECT DISTINCT npi,
       total_claim_count,
	   cbsaname
FROM prescription AS p
CROSS JOIN cbsa AS c
WHERE cbsaname LIKE '%Memphis%'
ORDER BY total_claim_count DESC
LIMIT 5;

  --  c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
  
-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT county,
       deaths
FROM fips_county AS f
INNER JOIN overdoses AS o
USING(fipscounty)
WHERE deaths > (SELECT AVG(deaths)
FROM overdoses);

--5.
 --   a. Write a query that finds the total population of Tennessee.
SELECT SUM(population),
       state
FROM population AS p 
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN'
GROUP BY state;
 --   b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
SELECT SUM(CASE WHEN state = 'TN' THEN population END) AS tn_pop,
       SUM(CASE WHEN state = 'TN' THEN population END) * 100 / SUM(population) AS num_pop,
       state,
	   county,
	   population
FROM population AS p 
INNER JOIN fips_county
USING(fipscounty)
GROUP BY state, county,
	   population;