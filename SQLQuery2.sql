

SELECT *
FROM Project1.dbo.covid_death_data
ORDER BY 3,4

--Calculating Mortality Percentage
SELECT location,date,total_cases,total_deaths,ROUND((CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100,2) AS mortality_ratio
FROM Project1.dbo.covid_death_data
WHERE location LIKE '%india%'
ORDER BY 1,2

--Calculating Infection Percentage
SELECT location,date,total_cases,population,ROUND((CAST(total_cases AS FLOAT)/population)*100,3) AS Infection_Percentage
FROM Project1..covid_death_data
ORDER BY 1,2

--Countries with maximum death for population
SELECT location,MAX(total_cases) AS total_cases,population,ROUND((MAX(CAST(total_cases AS FLOAT))/population)*100,3) AS Death_percentage
FROM Project1..covid_death_data
WHERE iso_code is NOT NULL AND iso_code NOT LIKE '%OWID%'
GROUP BY location,population
ORDER BY 4 DESC

--Highest death count per population
SELECT location,MAX(CONVERT(BIGINT,total_deaths)) AS total_deaths,population,
	ROUND((MAX(CONVERT(BIGINT,total_deaths))/population)*100,4) AS DEATH_TO_POPULATION
FROM Project1.dbo.covid_death_data
WHERE iso_code is NOT NULL AND iso_code NOT LIKE '%OWID%'
GROUP BY location,population
ORDER BY 4 DESC

--DEATH PER CONTINENT
SELECT continent,MAX(CONVERT(BIGINT,total_deaths)) AS total_deaths,MAX(population) AS population,
		ROUND((MAX(CONVERT(BIGINT,total_deaths))/MAX(population))*100,4) AS death_to_population
FROM Project1.dbo.covid_death_data
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY 4 DESC

--GLOBAL DAILY CASES AND DEATHS
SELECT date,SUM(new_cases) AS total_infected,SUM(new_deaths) AS total_deaths,
CASE
	WHEN SUM(new_deaths) = 0 AND SUM(new_cases) = 0 THEN 0
	ELSE ROUND(SUM(new_deaths)/SUM(new_cases),3)*100
END AS mortality_rate
FROM Project1.dbo.covid_death_data
GROUP BY date
ORDER BY date


--Total Population vs Vaccinations
--Using CTE
WITH people_vac(location,date,new_vaccinations,population,vaccinated_count)
AS
(
SELECT cov_v.location,cov_v.date,cov_v.new_vaccinations,cov_d.population
	,SUM(CAST(cov_v.new_vaccinations AS BIGINT))OVER (PARTITION BY cov_v.location ORDER BY cov_v.location,cov_v.date) 
	AS vaccinated_count
FROM Project1.dbo.covid_death_data cov_d
JOIN Project1.dbo.covid_vacination_data cov_v
ON cov_v.location = cov_d.location AND cov_v.date=cov_d.date
WHERE cov_d.continent IS NOT NULL

)

SELECT *,(vaccinated_count/population)*100 AS vaccinated_percent
FROM people_vac


--Total Population vs Vaccinations
--Using Temp table
DROP TABLE IF EXISTS #people_vaccinated
CREATE TABLE #people_vaccinated
(
location NVARCHAR(255),
date DATETIME,
new_vaccinations NVARCHAR(255),
population NUMERIC,
vaccinated_count NUMERIC
)

INSERT INTO #people_vaccinated(location,date,new_vaccinations,population,vaccinated_count)
SELECT cov_v.location,cov_v.date,cov_v.new_vaccinations,cov_d.population
	,SUM(CAST(cov_v.new_vaccinations AS BIGINT))OVER (PARTITION BY cov_v.location ORDER BY cov_v.location,cov_v.date) 
	AS vaccinatons_per_day
FROM Project1.dbo.covid_death_data cov_d
JOIN Project1.dbo.covid_vacination_data cov_v
ON cov_v.location = cov_d.location AND cov_v.date=cov_d.date
WHERE cov_d.continent IS NOT NULL

SELECT *,(vaccinated_count/population)*100 AS vaccinated_percent
FROM #people_vaccinated
ORDER BY 1,2

--Creating view for later visulaization 
DROP TABLE IF EXISTS people_vaccinated
CREATE VIEW people_vaccinated AS 
SELECT cov_v.location,cov_v.date,cov_v.new_vaccinations,cov_d.population
	,SUM(CAST(cov_v.new_vaccinations AS BIGINT))OVER (PARTITION BY cov_v.location ORDER BY cov_v.location,cov_v.date) 
	AS vaccinatons_per_day
FROM Project1.dbo.covid_death_data cov_d
JOIN Project1.dbo.covid_vacination_data cov_v
ON cov_v.location = cov_d.location AND cov_v.date=cov_d.date
WHERE cov_d.continent IS NOT NULL