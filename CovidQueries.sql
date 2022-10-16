/*
Queries used for Tableau Project
*/

-- 1. Table for total deaths, total cases and death rate

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
where continent is not null 
order by 1,2

-- 2. Looking at death counts 

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths$
Where continent is null 
and location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low Income')
Group by location
order by TotalDeathCount desc


-- 3. Creating table to show cases location by country for the past week

Select Location, Population, Sum((new_cases)) as CurrentInfectionCount,  sum((new_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths$
Where location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low Income', 'Micronesia (Country)', 'Saint Helena')
and date >= '2022-10-01'
Group by Location, Population
order by PercentPopulationInfected desc

--4. Seeing whether population density  

Select dea.continent, dea.location, dea.date, dea.population, population_density, dea.total_cases
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and dea.location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low Income')
group by dea.continent, dea.location, dea.date, dea.population, vac.population_density, dea.total_cases
having dea.date = '2022-10-08'
order by 1,2,3

--5. Firstly turning null into 0's 
--After that using a CTE to determine vaccination percentages in each country

update PortfolioProject..CovidVaccinations$
set people_vaccinated=0
where people_vaccinated is null

update PortfolioProject..CovidVaccinations$
set people_fully_vaccinated=0
where people_fully_vaccinated is null

update PortfolioProject..CovidVaccinations$
set total_boosters=0
where total_boosters is null

with VaccinationPercentage (Continent, Location, Population, Current_People_Vaccinated, Current_People_Fully_Vaccinated, Current_People_with_boosters)
as
(
Select dea.continent, dea.location, dea.population, Max(cast(people_vaccinated as bigint)) as Current_People_Vaccinated, Max(cast(people_fully_vaccinated as bigint)) as Current_People_Fully_Vaccinated,
Max(cast(total_boosters as bigint)) as Current_People_with_boosters
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and dea.location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low Income')
group by dea.continent, dea.location, dea.population
)
Select *, (((Current_People_Vaccinated/Population)*100)-(Current_People_Fully_Vaccinated/Population)*100) as PercentOfPopulationWithOneDoseVaccinated, 
(((Current_People_Fully_Vaccinated/Population)*100)-(Current_People_with_boosters/Population)*100) as PercentOfPopulationFullyVaccinated,
(Current_People_with_boosters/Population)*100 as PercentOfPopulationWithBoosters
from VaccinationPercentage
order by 2

-- There are values over 100% (Gilbrator, UAE & Qatar) which suggests that census data may be too old causing a lower population or vaccination records aren't entered correctly causing inflated vaccine amounts