-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
-- 1881634483	"PENDLEY"	99707
select npi,
	nppes_provider_last_org_name,
	--nppes_provider_first_name,
	sum(total_claim_count) as total_overall_claims
from prescription p_n
inner join prescriber p_r using(npi)
group by npi, nppes_provider_last_org_name
order by total_overall_claims desc;
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
select npi,
	nppes_provider_last_org_name,
	nppes_provider_first_name,
	specialty_description,
	sum(total_claim_count) as total_overall_claims
from prescription p_n
inner join prescriber p_r using(npi)
group by npi, nppes_provider_last_org_name, nppes_provider_first_name, specialty_description
order by total_overall_claims desc;

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
-- "Family Practice"	9752347
select specialty_description,
	sum(total_claim_count) as total_overall_claims
from prescription p_n
inner join prescriber p_r using(npi)
group by specialty_description
order by total_overall_claims desc;
--     b. Which specialty had the most total number of claims for opioids?
-- "Nurse Practitioner"	900845
select specialty_description,
	sum(total_claim_count) as total_overall_claims
from prescription p_n
inner join prescriber p_r using(npi)
inner join drug d using(drug_name)
where opioid_drug_flag = 'Y'
group by specialty_description
order by total_overall_claims desc;

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
-- "INSULIN GLARGINE,HUM.REC.ANLOG"
select generic_name,
	cast(sum(total_drug_cost) as money)
from drug d
inner join prescription p using(drug_name)
group by generic_name
order by sum(total_drug_cost) desc;


--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
-- "CINRYZE"
select drug_name,
	cast(sum(total_drug_cost) as money) / sum(total_day_supply) as cost_per_day
from drug d
inner join prescription p using(drug_name)
group by drug_name
order by cost_per_day desc;
-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
select drug_name,
	case 
		when opioid_drug_flag = 'Y' then 'opiod'
		when antibiotic_drug_flag = 'Y' then 'antibiotic'
		else 'neither' end as drug_type
from drug; 
--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
-- opiods
select	case 
		when opioid_drug_flag = 'Y' then 'opiod'
		when antibiotic_drug_flag = 'Y' then 'antibiotic'
		else 'neither'
	end as drug_type,
	cast(sum(pr.total_drug_cost) as money) as money_spent
from drug d
join prescription pr using(drug_name)
group by drug_type;

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
--10
select count(distinct cbsaname)
from cbsa
where cbsaname ~~ '%, TN%';
--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--largest: "Nashville-Davidson--Murfreesboro--Franklin, TN"
--smallest: "Morristown, TN"
select c.cbsaname,
	sum(p.population)
from cbsa c
join population p using(fipscounty)
where c.cbsaname ~~ '%, TN%'
group by c.cbsaname
order by sum(p.population) desc;

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
-- Sevier
select *
from population p
join fips_county fc using(fipscounty)
left join cbsa using(fipscounty)
where cbsa is null
order by population desc
limit 1;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
select drug_name,
	total_claim_count
from prescription
where total_claim_count >= 3000

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
select d.drug_name,
	pr.total_claim_count,
	case 
		when opioid_drug_flag = 'Y' then 'opiod'
		when antibiotic_drug_flag = 'Y' then 'antibiotic'
		else 'neither'
	end as drug_type
from prescription pr
join drug d using(drug_name)
where total_claim_count >= 3000;
--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
select d.drug_name,
	pr.total_claim_count,
	case 
		when opioid_drug_flag = 'Y' then 'opiod'
		when antibiotic_drug_flag = 'Y' then 'antibiotic'
		else 'neither'
	end as drug_type,
	concat(pr_r.nppes_provider_first_name, ' ', pr_r.nppes_provider_last_org_name) as full_name
from prescription pr
join drug d using(drug_name)
join prescriber pr_r using(npi)
where total_claim_count >= 3000;
-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
select p.npi,
	d.drug_name
from prescriber p
cross join drug d
where specialty_description = 'Pain Management'
	and nppes_provider_city = 'NASHVILLE'
	and opioid_drug_flag = 'Y';


--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
select p.npi,
	d.drug_name,
	coalesce(sum(total_claim_count), '0')
from prescriber p
cross join drug d
full join prescription as p2 using(drug_name)
where specialty_description = 'Pain Management'
	and nppes_provider_city = 'NASHVILLE'
	and opioid_drug_flag = 'Y'
group by d.drug_name, p.npi
order by sum(total_claim_count) desc;
