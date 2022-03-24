--select *
--from CovidProject..CovidDeaths
--order by 3,4

--select *
--from CovidProject..CovidVaccinations
--order by 3,4

--Select Data that we are going to be using

select Location, Date, total_cases, new_cases, total_deaths, population
from CovidProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

select Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
from CovidProject..CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

select Location, Date, population, total_cases, (total_cases/population)*100 AS InfectedPercentage
from CovidProject..CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at Countries with Highest Infection Rate compared to population

select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage
from CovidProject..CovidDeaths
--where location like '%states%'
group by Location, population
order by InfectedPercentage desc

-- Showing Countries with Highest Death Count per Population

select Location, MAX(cast (total_deaths as bigint)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent IS NOT NULL
group by Location
order by TotalDeathCount desc

-- Showing Continents with Highest Death Count per Population

select location, MAX(cast (total_deaths as bigint)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent IS NULL
group by location
order by TotalDeathCount desc

-- Showing continents with highest death count per population 2

select continent, MAX(cast (total_deaths as bigint)) as TotalDeathCount
from CovidProject..CovidDeaths
where continent IS NOT NULL
group by continent
order by TotalDeathCount desc

-- Global numbers

select SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as DeathPercentage
from CovidProject..CovidDeaths
where continent IS NOT NULL
--Group by date
order by 1,2


-- Looking at Total Population vs Vaccinations and rolling count

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
	on dea.Location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- CTE

with PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
	on dea.Location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100 
from PopvsVac


-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
	on dea.Location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 
from #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidProject..CovidDeaths dea
join CovidProject..CovidVaccinations vac
	on dea.Location = vac.location
	and dea.date = vac.date
where dea.continent is not null


-- FINAL QUERIES FOR VISUALS

-- total deaths
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidProject..CovidDeaths
where continent is not null 
order by 1,2

-- deaths by location

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From CovidProject..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

-- infections by location

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

-- infections by date

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidProject..CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc

-- total vaccinations by date

Select dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null AND dea.location = 'United States'
group by dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated
order by 1,2,3