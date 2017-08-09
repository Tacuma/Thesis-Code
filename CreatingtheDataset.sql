/*
The code pulled the patient number, the gender, age, race, religion, marital status, and places it into a temporary table called feature_set.
*/
create global temporary table feature_set
on commit preserve rows
as select patient_dimension.patient_num Patient_number, patient_dimension.SEX_CD gender, patient_dimension.AGE_IN_YEARS_NUM Age, patient_dimension.race_cd race, 
patient_dimension.religion_cd religion, 
  patient_dimension.marital_status_cd marital_status, count(observation_fact.encounter_num) Number_of_Inpatient_Encounters
  from patient_dimension
  join observation_fact
  on patient_dimension.patient_num = Observation_Fact.Patient_Num
  join concept_dimension
  on observation_fact.concept_cd = concept_dimension.concept_cd
  where (name_char like '%diabet%type%II%') or (name_char like '%type%II%diabet%') or     
       (concept_path like '%diabet%type%II%') or (concept_path like '%type%II%diabet%') 
  group by patient_dimension.patient_num, patient_dimension.SEX_CD, patient_dimension.AGE_IN_YEARS_NUM, patient_dimension.race_cd, patient_dimension.religion_cd, 

/*
To obtain the average length of stay for each patient, the end date was subtracted from the start date
for all a patient’s encounters in the encounter_dimension table, where they were all averaged and 
associated with a Patient Number. This result of this was then placed in table called average_length_of_stay.
*/
create global temporary table average_length_of_stay
on commit preserve rows

as select patient_num, Round(avg(end_date - start_date),4) Average_length_of_stay
from observation_fact
join concept_dimension
on observation_fact.concept_cd = concept_dimension.concept_cd
where (name_char like '%diabet%type%II%') or (name_char like '%type%II%diabet%') or     
       (concept_path like '%diabet%type%II%') or (concept_path like '%type%II%diabet%') 
group by patient_num;

/*
The next set of SQL queries then merged the feature_set and average_length_of_stay into one table
*/

create global temporary table final_feature_set
on commit preserve rows

as select patient_number, gender, race, age, religion, marital_status, Feature_Set.Zip_Code, 
   Feature_Set.Number_Of_Inpatient_Encounters, Average_Length_Of_Stay.Average_Length_Of_Stay from feature_set
join average_length_of_stay
on Feature_Set.Patient_Number = Average_Length_Of_Stay.Patient_Num;


/* Creates a temporary able listing the Patient Number, Concept Cd, Name Char, Count, Max count of concept cds 
The last step in creating the complete dataset was to append the mode concept_cd to the dataset. 
This showed the most frequent co-disease that each patient has. 
The first thing that was done was to create a table called concept_count. 
In this temporary table, the database was queried so that for every patient, there would be a Patient Number, Concept_cd, Name_car, Max count of concept cds. 
*/      

create global temporary table concept_count
on commit preserve rows
as select observation_fact.patient_num, observation_fact.concept_cd, concept_dimension.name_char, Count(observation_fact.concept_cd) cnt, max(count(observation_fact.concept_cd)) over (partition by observation_fact.patient_num) max_count 
      from observation_fact
      join concept_dimension
      on observation_fact.concept_cd = concept_dimension.concept_cd
      where observation_fact.concept_cd not in (select observation_fact.concept_cd from observation_fact where (concept_cd like 'DEM%') or (concept_cd like 'CTSA:%') or (concept_cd like 'HU_LAB:%') or
      (name_char like '%diabet%type%II%') or (name_char like '%type%II%diabet%') or (concept_path like '%diabet%type%II%') or (concept_path like '%type%II%diabet%') )
      group by observation_fact.patient_num, observation_fact.concept_cd, Concept_Dimension.Name_Char;  


/*
This SQL code created a temporary table in oracle called concept_count. 
The table contains the mode ICD-9 codes for every patient in encounter fact. It is not complete however; 
there was still the problem of repeat rows per patient. What was needed was only one mode. This was solved with this code:
*/

create global temporary table final_concept_count
on commit preserve rows
as  select t.patient_num, t.concept_cd, t.name_char
from (select concept_count.patient_num, concept_count.concept_cd, concept_count.name_char, ROW_NUMBER() OVER (PARTITION BY patient_num ORDER BY patient_num ) as rnum
from concept_count) t 
where t.rnum = 1;

/*
Joining these two tables generated the final dataset for export. This is done with the following SQL code
*/

create global temporary table last_feature_set
on commit preserve rows
as select patient_number, gender, race, age, religion, marital_status, Number_Of_Inpatient_Encounters, Average_Length_Of_Stay, final_concept_count.concept_cd 
from final_feature_set
join final_concept_count
on Final_Feature_Set.Patient_Number = Final_Concept_Count.Patient_Num;

