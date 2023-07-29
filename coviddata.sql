SELECT *
FROM covidcases AS css
JOIN Coviddata..vaccination AS vac
ON css.Country = vac.location and css.Date_reported = vac.date

----
--clean up data

--select Country, New_deaths
--From covidcases
--where New_cases<0

--update covidcases
--set New_deaths = 0 
--where New_deaths < 0

--delete
--from Coviddata..covidcases
--where WHO_region like 'Other'

----

--convert date time data to date

ALTER TABLE covidcases
ALTER COLUMN Date_reported DATE

ALTER TABLE vaccination
ALTER COLUMN date DATE

--

----- create stored procedure to look at data
-- retrive list of countries
GO
CREATE PROCEDURE listofcountry 
AS
SELECT DISTINCT Country
FROM Coviddata..covidcases
ORDER BY 1
GO
EXEC listofcountry 

-- Fatalrate of covid of a country
GO
CREATE PROCEDURE fatalrate @country varchar(50)
AS
SELECT Country, Date_reported, Cumulative_cases, Cumulative_deaths, 
CASE
	WHEN Cumulative_cases !=0 then (Cumulative_deaths/Cumulative_cases)*100
	else 0
	end as FatalRate
FROM Coviddata..covidcases
WHERE Country like @country
ORDER BY 1,2
GO
EXEC fatalrate @country = 'Australia'

--infection rate of covid of a country

GO
CREATE PROCEDURE infectionrate @country VARCHAR(50)
AS
SELECT Country, Date_reported, Cumulative_cases, population, (Cumulative_cases/population)*100 AS InfectionRate
FROM Coviddata..covidcases AS css
JOIN Coviddata..vaccination AS vac
ON css.Country = vac.location and css.Date_reported = vac.date
WHERE LOCATION like @country
ORDER BY 1,2
GO
EXEC infectionrate @country = 'Australia'

-- vaccination rate 
GO
CREATE PROCEDURE vaccinationrate @country VARCHAR(50)
AS
SELECT location, population, people_vaccinated, (people_vaccinated/population)*100 as Vaccination_rate
FROM Coviddata..vaccination
WHERE location like @country
GO
EXEC vaccinationrate @country = 'Australia'

----Global data
-- Using CTE
GO
CREATE PROCEDURE global_data
AS
WITH cte_global AS
(
SELECT SUM(cases.New_cases) AS Total_cases, SUM(cases.New_deaths) AS Total_deaths
FROM Coviddata..covidcases AS cases
)
SELECT Total_cases,Total_deaths, Total_deaths/Total_cases*100 as Fatal_rate
FROM cte_global
GO
EXEC global_data

-- Data break down by WHO_region
--Using temp table
GO
CREATE PROCEDURE region_data
AS
DROP TABLE IF EXISTS #temp_region_data
SELECT WHO_region, SUM(cases.New_cases) AS Total_cases, SUM(cases.New_deaths) AS Total_deaths
INTO #temp_region_data
FROM Coviddata..covidcases AS cases
GROUP BY cases.WHO_region
SELECT *, Total_deaths/Total_cases*100 as Fatal_rate,
CASE
WHEN WHO_region like 'WPRO' THEN 'Western Pacific'
WHEN WHO_region like 'AFRO' THEN 'Africa'
WHEN WHO_region like 'EMRO' THEN 'Eastern Mediterranean'
WHEN WHO_region like 'EURO' THEN 'Europe'
WHEN WHO_region like 'SEARO' THEN 'South-East Asia'
WHEN WHO_region like 'AMRO' THEN 'Americas'
END as Name_of_the_region
FROM #temp_region_data
GO
EXEC region_data

---------------------

--country index
GO
CREATE VIEW Countryindex AS
SELECT Country, median_age, life_expectancy, human_development_index, gdp_per_capita
FROM covidcases AS css
JOIN Coviddata..vaccination AS vac
ON css.Country = vac.location and css.Date_reported = vac.date
GROUP BY Country, median_age, life_expectancy, human_development_index,  gdp_per_capita
GO
----create views
GO
CREATE VIEW VacinationRate AS
SELECT Date_reported, Country, population, people_vaccinated, people_fully_vaccinated, 
people_vaccinated/population*100 as vaccination_rate,
people_fully_vaccinated/population*100 as fully_vaccination_rate
FROM covidcases AS css
JOIN Coviddata..vaccination AS vac
ON css.Country = vac.location and css.Date_reported = vac.date
GO
---- List of stored queries
--Global data
EXEC global_data
EXEC region_data

-- Countries data
EXEC listofcountry 
EXEC infectionrate @country = 'Australia'
EXEC fatalrate @country = 'Australia'
EXEC vaccinationrate @country = 'Australia'
-----------