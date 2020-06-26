
/* Final Project
Student: Thi Mai Chi Nguyen
.*/

# Part 2: Primary and Foreign Key Setup in MySQL

CREATE SCHEMA IF NOT EXISTS `Final_Project_Schema` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci ;
USE `Final_Project_Schema` ;

CREATE TABLE IF NOT EXISTS `Final_Project_Schema`.`dim_drug_brand_info` (
  `drug_brand_generic_code` INT(11) NOT NULL,
  `drug_brand_generic_desc` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`drug_brand_generic_code`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

--
CREATE TABLE IF NOT EXISTS `Final_Project_Schema`.`dim_drug_form_info` (
  `drug_form_code` CHAR(2) NOT NULL,
  `drug_form_desc` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`drug_form_code`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

-- 
CREATE TABLE IF NOT EXISTS `Final_Project_Schema`.`dim_drug_info` (
  `drug_ndc` INT(11) NOT NULL,
  `drug_name` VARCHAR(100) NOT NULL,
  `drug_brand_generic_code` INT(11) NOT NULL,
  `drug_form_code` CHAR(2) NOT NULL,
  INDEX `drug_brand_generic_code_idx` (`drug_brand_generic_code` ASC) VISIBLE,
  INDEX `drug_form_code_idx` (`drug_form_code` ASC) VISIBLE,
  PRIMARY KEY (`drug_ndc`),
  CONSTRAINT `drug_brand_generic_code`
    FOREIGN KEY (`drug_brand_generic_code`)
    REFERENCES `Final_Project_Schema`.`dim_drug_brand_info` (`drug_brand_generic_code`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `drug_form_code`
    FOREIGN KEY (`drug_form_code`)
    REFERENCES `Final_Project_Schema`.`dim_drug_form_info` (`drug_form_code`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;

-- 
CREATE TABLE IF NOT EXISTS `Final_Project_Schema`.`dim_member_info` (
  `member_id` INT(11) NOT NULL,
  `member_first_name` VARCHAR(100) NOT NULL,
  `member_last_name` VARCHAR(100) NOT NULL,
  `member_birth_date` DATETIME NOT NULL,
  `member_age` INT(11) NOT NULL,
  `member_gender` CHAR(1) NOT NULL,
  PRIMARY KEY (`member_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


-- 
CREATE TABLE IF NOT EXISTS `Final_Project_Schema`.`dim_phar_claim_info` (
 `pci_id` INT(11) NOT NULL,
  `member_id` INT(11) NOT NULL,
  `drug_ndc` INT(11) NOT NULL,
  `Fill_date` TEXT NOT NULL,
  `Copay` INT(11) NOT NULL,
  `Insurancepaid` INT(11) NOT NULL,
  INDEX `member_id_idx` (`member_id` ASC) VISIBLE,
  INDEX `drug_ndc_idx` (`drug_ndc` ASC) VISIBLE,
  CONSTRAINT `drug_ndc`
    FOREIGN KEY (`drug_ndc`)
    REFERENCES `Final_Project_Schema`.`dim_drug_info` (`drug_ndc`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `member_id`
    FOREIGN KEY (`member_id`)
    REFERENCES `Final_Project_Schema`.`dim_member_info` (`member_id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_0900_ai_ci;


# Part 4: Analytics and Reporting
use Final_Project;
/*
Write a SQL query that identifies the number of prescriptions grouped by drug name
*/
SELECT d2.drug_name, count(*) as number_of_prescriptions
FROM dim_phar_claims_info as d1
LEFT JOIN dim_drug_info as d2
ON d1.drug_ndc = d2.drug_ndc
GROUP BY drug_name;

SELECT d2.drug_name,d1.number_of_prescriptions
FROM dim_drug_info as d2,
 (SELECT drug_ndc, count(fill_date) as number_of_prescriptions 
 FROM dim_phar_claims_info GROUP BY (drug_ndc))as d1
WHERE d1.drug_ndc=d2.drug_ndc 
AND d2.drug_name like'%Ambien%';

/*
-	Write a SQL query that counts total prescriptions, 
counts unique (i.e. distinct) members, sums copay $$, 
and sums insurance paid $$, for members grouped as either ‘age 65+’ or ’ < 65’.
    How many unique members are over 65 years of age? 
	How many prescriptions did they fill?
*/


SELECT CASE WHEN  d3.member_age > 65 then "65+" 
WHEN d3.member_age < 65 then "65-" end as age,
count(d1.drug_ndc) as total_prescription, 
count(distinct d1.member_id) as sum_unique_member, 
sum(d1.copay) as sum_copay, sum(d1.insurancepaid) as sum_insurancepaid
FROM dim_phar_claims_info as d1

INNER JOIN dim_member_info as d3 
ON d1.member_id = d3.member_id
GROUP BY age; 

/*
-	Write a SQL query that identifies the amount paid by the insurance
 for the most recent prescription fill date
*/
DROP table if exists new_table_1;
CREATE table new_table_1 as select member_id, fill_date, insurancepaid, drug_ndc,
row_number() over (partition by member_id order by member_id, fill_date DESC) as flag 
FROM dim_phar_claims_info ;

SELECT d3.member_id,d3.member_first_name,d3.member_last_name,d2.drug_name,
d1.fill_date as recent_fill_date,
d1.insurancepaid as most_recent_insurance_paid
FROM dim_member_info as d3
INNER JOIN new_table_1 as d1
ON d3.member_id=d1.member_id 
INNER JOIN dim_drug_info as d2
ON d2.drug_ndc =d1.drug_ndc
WHERE d1.flag=1;

/* For member ID 10003, what was the drug name listed on their most recent fill date?
How much did their insurance pay for that medication?
*/
SELECT d3.member_id,d3.member_first_name,d3.member_last_name,
d2.drug_name,d1.fill_date as recent_fill_date,
d1.insurancepaid as most_recent_insurance_paid 
FROM new_table_1 as d1 
INNER JOIN dim_drug_info as d2
ON d1.drug_ndc =d2.drug_ndc
INNER JOIN dim_member_info as d3
ON d1.member_id = d3.member_id 
AND d1.flag=1 AND d3.member_id='10003';