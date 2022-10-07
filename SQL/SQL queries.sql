-- Show the columns we are going to deal with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM COVID..Deaths
WHERE continent is not null --to exclude the data representing the whole continent
ORDER BY 1, 2 --Order by date and total cases


-- Total Deaths vs Total Cases
-- Death percentage of total cases
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as "deaths_percentage"
FROM COVID..Deaths
WHERE deaths_percentage IS NOT NULL 
AND continent IS NOT NULL
--AND location LIKE 'United Arab Emirates'
ORDER BY 1, 2


-- Total Cases and Total Deaths vs Population
-- Cases percentage of Country Population
-- Deaths percentage of Country Population
SELECT Location, date, population, total_cases, total_deaths, 
(total_cases/population)*100 AS "cases_percentage", (total_deaths/population)*100 as "deaths_percentage"
FROM COVID..Deaths
WHERE cases_percentage IS NOT NULL and continent IS NOT NULL
--and Location like 'United Arab Emirates'
ORDER BY 1, 2


-- Total infection and deaths for all countries 
SELECT location, Max(CAST(total_cases AS INT)) total_cases_count,  Max(CAST(total_deaths AS INT)) AS total_deaths_count
FROM COVID..Deaths
WHERE continent IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC


-- Countries infection rate vs Population
SELECT location, population, Max(total_cases) AS max_infection,  Max(total_cases/population)*100 AS infection_rate
FROM COVID..Deaths
WHERE continent IS NOT NULL
GROUP BY 1, 2
ORDER BY infection_rate DESC


-- Countries death rate vs Population
SELECT location, population, Max(Cast(total_deaths AS INT)) AS max_deaths,  Max(total_deaths/population)*100 AS death_rate
FROM COVID..Deaths
WHERE continent IS NOT NULL
GROUP BY 1, 2
ORDER BY death_rate DESC


-- Continent level aggregation
SELECT location,
    Max(Cast(total_cases AS INT)) total_cases_count,  Max(Cast(total_deaths AS INT)) AS total_deaths_count,
    Max(Cast(total_cases AS INT)) total_cases_count,  Max(Cast(total_deaths AS INT)) AS total_deaths_count
FROM COVID..Deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_cases_count DESC


-- Worldwide daily report
SELECT *
FROM(
    SELECT date,
        Sum(CAST(new_cases AS INT)) total_new_cases,
        Sum(CAST(new_deaths AS INT)) AS total_new_deaths
    FROM COVID..Deaths
    WHERE continent IS NOT NULL
    GROUP BY date
    )
WHERE (total_new_cases IS NOT NULL OR total_new_deaths IS NOT NULL)
ORDER BY 1, 2

-- Total worldwide
SELECT Sum(Cast(new_cases AS INT)) total_cases,  Sum(Cast(new_deaths AS INT)) AS total_deaths
FROM COVID..Deaths
WHERE continent IS NOT NULL


-- New daily vaccinations and rolling total vaccinations
SELECT *
FROM (
    SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
    -- Apply window function over the location to calculate the cumulative vaccinations instead of the original column
        Sum(Cast(v.new_vaccinations AS INT)) OVER (partition BY d.location ORDER BY d.location AND d.date) AS total_vaccinations
    FROM COVID..Deaths AS d
    JOIN COVID..Vaccinations AS v
    ON d.location=v.location
    AND d.date=v.date
    WHERE d.continent IS NOT NULL
    ORDER BY 1, 2, 3
    )
WHERE new_vaccinations IS NOT NULL
AND total_vaccinations IS NOT NULL


-- Total Vaccinations for countries
SELECT *, (total_vaccinations/population)*100 AS vaccinated_people_percentage
FROM (
    SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, v.total_vaccinations,
    -- Apply window function over the location to calculate the cumulative vaccinations instead of the original column
        Sum(Cast(v.new_vaccinations AS INT)) OVER (partition BY d.location ORDER BY d.location, d.date) AS rolling_vaccinations
    FROM COVID..Deaths AS d
    JOIN COVID..Vaccinations AS v
        ON d.location=v.location
        AND d.date=v.date
    WHERE d.continent IS NOT NULL
    --order by 1, 2, 3
    )

-- Create new Table PercentPopulationVaccinated
DROP TABLE IF EXISTS PercentPopulationVaccinated

create table PercentPopulationVaccinated
(
Continent nvarchar(225),
Location nvarchar(225),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingTotalVaccinated numeric
)

Insert into PercentPopulationVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
    SUM(CAST(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) as rolling_vaccinations
from COVID..Deaths as d
join COVID..Vaccinations as v
    on d.location=v.location
    and d.date=v.date
where d.continent is not null