/* Covid-19 Data Exploration Using SQL */


/* We can create the table using the below commands. 
   Here I have used Import/Export option in PgAdmin to import data into the table */

--CREATE TABLE covidDeaths(iso_code varchar(10),continent varchar(25),location varchar(40),date date,population numeric,total_cases numeric,new_cases numeric,new_cases_smoothed numeric,total_deaths numeric,new_deaths numeric,new_deaths_smoothed numeric,total_cases_per_million numeric,new_cases_per_million numeric,new_cases_smoothed_per_million numeric,total_deaths_per_million numeric,new_deaths_per_million numeric,new_deaths_smoothed_per_million numeric,reproduction_rate numeric,icu_patients numeric,icu_patients_per_million numeric,hosp_patients numeric,hosp_patients_per_million numeric,weekly_icu_admissions numeric,weekly_icu_admissions_per_million numeric,weekly_hosp_admissions numeric,weekly_hosp_admissions_per_million numeric);
--CREATE TABLE covidVaccination(iso_code varchar(10),continent varchar(25),location varchar(40),date date,total_tests numeric,new_tests numeric,total_tests_per_thousand numeric,new_tests_per_thousand numeric,new_tests_smoothed numeric,new_tests_smoothed_per_thousand numeric,positive_rate numeric,tests_per_case numeric,tests_units varchar(50),total_vaccinations numeric,people_vaccinated numeric,people_fully_vaccinated numeric,total_boosters numeric,new_vaccinations numeric,new_vaccinations_smoothed numeric,total_vaccinations_per_hundred numeric,people_vaccinated_per_hundred numeric,people_fully_vaccinated_per_hundred numeric,total_boosters_per_hundred numeric,new_vaccinations_smoothed_per_million numeric,new_people_vaccinated_smoothed numeric,new_people_vaccinated_smoothed_per_hundred numeric,stringency_index numeric,population_density numeric,median_age numeric,aged_65_older numeric,aged_70_older numeric,gdp_per_capita numeric,extreme_poverty numeric,cardiovasc_death_rate numeric,diabetes_prevalence numeric,female_smokers numeric,male_smokers numeric,handwashing_facilities numeric,hospital_beds_per_thousand numeric,life_expectancy numeric,human_development_index numeric,excess_mortality_cumulative_absolute numeric,excess_mortality_cumulative numeric,excess_mortality numeric,excess_mortality_cumulative_per_million numeric);

--Selecting all columns of CovidDeaths table
SELECT * FROM coviddeaths
ORDER BY location,date;


-- Selecting all columns of CovidVaccination Table
SELECT * FROM covidvaccination
ORDER BY location,date;


-- Total cases and Total Deaths at a location at a particular date
SELECT location,date,population,total_cases,total_deaths
FROM coviddeaths
ORDER BY location,date;


--Total cases VS Total Deaths
-- Shows Likelihood of Dying if you contract covid in India
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 DeathPercentage
FROM coviddeaths
WHERE location LIKE '%India%' and continent is not NULL
ORDER BY 1,2;


-- Total cases VS Population
-- Shows percentage of Population who got Covid at certain Date
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM coviddeaths
WHERE location LIKE '%India%' and  continent is not NULL
ORDER BY 1,2;


-- Countries with Highest Infection Rate compared to Population
SELECT location, population, Max(total_cases) Highest_Infection_Count, Max(total_cases/population)*100 AS Percent_Population_Infected
FROM coviddeaths
WHERE continent is not NULL
GROUP BY location,population
ORDER BY Percent_Population_Infected DESC;


-- Countries with highest Death count per population
SELECT location, population, Max(total_deaths) Total_Death_Count, Max(total_deaths/population)*100 AS Percent_Population_Died
FROM coviddeaths
WHERE continent is not NULL and total_deaths is not NULL
GROUP BY location,population
ORDER BY Percent_Population_Died DESC;


-- Showing continents with highest Death count
SELECT location, Max(total_deaths) Total_Death_Count
FROM coviddeaths
WHERE continent is NULL and total_deaths is not NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;


-- Global Total Cases, Total Deaths, DeathPercentage at certain Date
SELECT date, SUM(new_cases) as TotalCases, SUM(new_deaths) TotalDeaths, (SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage
FROM coviddeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY date;


-- Overall Global Total Cases, Total Deaths, DeathPercentage
SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) TotalDeaths, (SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage
FROM coviddeaths
WHERE continent is not NULL;


-- Shows Vaccinated Population till date at a Location 
SELECT covD.continent, covD.location, covD.date, covVac.new_vaccinations, 
	SUM(covVac.new_vaccinations) OVER (PARTITION BY covD.location ORDER BY covD.location, covD.date) as Total_Vaccinations_Till_Date_Per_Location
FROM coviddeaths as covD
JOIN covidvaccination as covVac
	ON covD.location=covVac.location 
	AND covD.date=covVac.date
WHERE covD.continent is not NULL
ORDER BY covD.location, covD.date;


-- Using CTE to calculate Percentage Population that has been Vaccinated
WITH Vaccines_Rolled AS
	(SELECT covD.continent, covD.location, covD.date, covD.population, covVac.new_vaccinations, 
		SUM(covVac.new_vaccinations) OVER (PARTITION BY covD.location ORDER BY covD.location, covD.date) as Total_Vaccinations_Till_Date_Per_Location
	FROM coviddeaths as covD
	JOIN covidvaccination as covVac
		ON covD.location=covVac.location 
		AND covD.date=covVac.date
	WHERE covD.continent is not NULL
	ORDER BY covD.location, covD.date )
SELECT *,(Total_Vaccinations_Till_Date_Per_Location/population)*100 as Perc_Population_Vacc
FROM Vaccines_Rolled;


-- Calculating Total Percentage People got Vaccinated at a particular Location
WITH Total_Vaccines_Rolled AS
	(SELECT covD.location, covD.population, MAX(covD.population), 
		MAX(covVac.total_vaccinations) as Total_Vacc
	FROM coviddeaths as covD
	JOIN covidvaccination as covVac
		ON covD.location=covVac.location 
		AND covD.date=covVac.date
	WHERE covD.continent is not NULL
	GROUP BY covD.location,covD.population
	ORDER BY covD.location )
SELECT *,(Total_Vacc/population)*100 as Perc_Population_Vacc
FROM Total_Vaccines_Rolled;


-- Alternate way to calculate Percentage population calculated using Temp Table
CREATE TEMP TABLE PercPopulationVaccinated(
	Continent varchar(50), Location varchar(50), Date date, Population numeric, New_vaccinations numeric
	, Vaccinations_Rolled_Till_Date numeric
);

INSERT INTO PercPopulationVaccinated
SELECT covD.continent, covD.location, covD.date, covD.population, covVac.new_vaccinations, 
 SUM(covVac.new_vaccinations) OVER (PARTITION BY covD.location ORDER BY covD.location, covD.date) as Total_Vaccinations_Till_Date_Per_Location
FROM coviddeaths as covD
JOIN covidvaccination as covVac
	ON covD.location=covVac.location 
	AND covD.date=covVac.date

SELECT *, (Vaccinations_Rolled_Till_Date/Population) as Percentage_Vacccination
FROM PercPopulationVaccinated;


-- CREATE View for Average Life Expectancy Per Location
DROP VIEW if exists Life_expectancy;
CREATE VIEW Life_expectancy as
SELECT continent,location,AVG(life_expectancy) as Avg_Life_Expectancy
FROM covidvaccination
WHERE continent is not NULL
GROUP BY continent,location
ORDER BY Avg_Life_Expectancy

SELECT * FROM Life_expectancy


-- Percentage of people older than 65yr and 70yr in Different locations who got Covid
SELECT continent,location,MAX(median_age) as Median_age,MAX(aged_65_older) as aged_65_yr_older,MAX(aged_70_older) as aged_70_yr_older
FROM covidvaccination
WHERE continent is not NULL
GROUP BY continent,location


-- Counting the female and male smokers who got Covid
SELECT covD.location, covD.population, (Max(covD.total_cases)*Max(covVac.female_smokers))/100 as Female_smokers_who_got_covid,
	(Max(covD.total_cases)*Max(covVac.male_smokers))/100 as Male_smokers_who_got_covid
FROM coviddeaths as covD
JOIN covidvaccination as covVac
	ON covD.location = covVac.location
	AND covD.date = covVac.date
WHERE covD.continent is not NULL
GROUP BY covD.location, covD.population
ORDER BY covD.location


-- Percentage Tests Per Population Size at a location
SELECT covD.continent, covD.location, covD.population, (MAX(covVac.total_tests)/MAX(covD.population))*100 as Perc_Tests_Per_Population
FROM coviddeaths as covD
JOIN covidvaccination as covVac
	ON covD.location = covVac.location
	AND covD.date = covVac.date
WHERE covD.continent is not NULL
GROUP BY covD.continent, covD.location, covD.population









