/*SELECT * 
FROM COVIDDEATHS*/


/*SELECT LOCATION, DATE, total_cases, new_cases, total_deaths, population
FROM COVIDDEATHS
ORDER BY 1,2*/

--Looking at Total Cases vs Total Deaths
--Shows the Likelihood of dying if you get COVID in your country
SELECT LOCATION, DATE, total_cases,total_deaths, CAST(total_deaths AS numeric) / CAST(total_cases AS numeric)* 100 as DeathPercentage
FROM COVIDDEATHS
WHERE LOCATION LIKE '%states%'
ORDER BY 1,2


--Looking at Total Cases vs Population
--Shows what percentage of population got COVID
SELECT LOCATION, DATE, total_cases, population, CAST(total_cases AS numeric) / CAST(population AS numeric)* 100 as DeathPercentage
FROM COVIDDEATHS
WHERE LOCATION LIKE '%states%'
ORDER BY 1,2


--Looking at countries with the highest infection rate
SELECT LOCATION, MAX(total_cases) AS HighestInfectionCount, population, MAX(CAST(total_cases AS numeric) / CAST(population AS numeric))* 100 as PercentInfectedRate
FROM COVIDDEATHS
GROUP BY population, location
ORDER BY PercentInfectedRate DESC


--Showing countries with highest death counts per population
SELECT LOCATION, MAX(cast(total_deaths as numeric)) as TotalDeathCount
FROM COVIDDEATHS
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY TotalDeathCount DESC


-- Showing the continents with the highest death count
SELECT LOCATION, MAX(cast(total_deaths as numeric)) as TotalDeathCount
FROM COVIDDEATHS
WHERE continent IS NULL 
AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC


--Global numbers for deaths per case
SELECT  SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as numeric)) as TotalDeaths, NULLIF(SUM(CAST(new_deaths AS numeric)) / NULLIF(SUM(new_cases), 0), 0) * 100 as DeathPercentage
FROM COVIDDEATHS
WHERE continent IS NULL 
AND location NOT LIKE '%income%'
--GROUP BY date
ORDER BY 1,2 


--Looking at Total Population vs Vaccinations
SELECT deaths.population, deaths.location, deaths.date, deaths.continent, vacs.new_vaccinations, 
SUM(CAST(vacs.new_vaccinations AS numeric)) OVER (Partition by deaths.location ORDER BY deaths.location) as RollingPeopleVaccinated, RollingPeopleVaccinated
FROM COVIDDEATHS as deaths
	JOIN COVIDVACS as vacs
	ON deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL
order by 2, 3 


--Use CTE 
WITH PopVsVac (CONTINENT, LOCATION, DATE, POPULATION, New_Vaccinations, RollingPeopleVaccinated)
as (SELECT deaths.continent, deaths.location, deaths.date,  deaths.population, vacs.new_vaccinations, 
SUM(CAST(vacs.new_vaccinations AS numeric)) OVER (Partition by deaths.location ORDER BY deaths.location) as RollingPeopleVaccinated 
FROM COVIDDEATHS as deaths
	JOIN COVIDVACS as vacs
	ON deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL) 
SELECT *,  (CAST(RollingPeopleVaccinated AS numeric) / CAST(Population AS numeric))*100
FROM PopVsVac


--TempTable
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric)
INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date,  deaths.population, vacs.new_vaccinations, 
SUM(CAST(vacs.new_vaccinations AS numeric)) OVER (Partition by deaths.location ORDER BY deaths.location) as RollingPeopleVaccinated 
FROM COVIDDEATHS as deaths
	JOIN COVIDVACS as vacs
	ON deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL
SELECT *,  (CAST(RollingPeopleVaccinated AS numeric) / CAST(Population AS numeric))*100
FROM #PercentPopulationVaccinated


--Creating view to store data for later visualizations
Create View PercentPopulationVaccinated as
SELECT deaths.continent, deaths.location, deaths.date,  deaths.population, vacs.new_vaccinations, 
SUM(CAST(vacs.new_vaccinations AS numeric)) OVER (Partition by deaths.location ORDER BY deaths.location) as RollingPeopleVaccinated 
FROM COVIDDEATHS as deaths
	JOIN COVIDVACS as vacs
	ON deaths.location = vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL