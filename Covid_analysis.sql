--Here we display the data set on covid deaths
SELECT *
	FROM PortfolioProject..CovidDeaths$
	ORDER BY 3,4

--Here we display the data set on covid vaccinations
SELECT *
	FROM PortfolioProject..CovidVacinations$
	ORDER BY 3,4  

--Selecting data that will be used
SELECT location,date,total_cases,new_cases,total_deaths,population
	FROM PortfolioProject..CovidDeaths$
	ORDER BY 1,2

----Now, looking at total cases compared to total deaths
----Want to know % of people dying who are reported to be infected
SELECT location,date,total_cases,total_deaths,(CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS DeathPercentage
	FROM PortfolioProject..CovidDeaths$
	WHERE location like '%states%'
	ORDER BY 1,2

--Now, looking at Total Cases compared to population
SELECT  location,date,population,total_cases,(CAST(total_cases AS int)/population)*100 AS PositivePercentage
	FROM PortfolioProject..CovidDeaths$
	WHERE location like '%states%'
	ORDER BY 1,2
	
--Looking at the countries with the highest infection rates
SELECT location,population,MAX(CAST(total_cases AS int)) AS HighestInfectionCount,MAX((CAST(total_cases AS int)/population)*100) AS InfectionPercentage
	FROM PortfolioProject..CovidDeaths$
	GROUP BY location,population
	ORDER BY InfectionPercentage desc

--Now looking at the countries with the highest death rate
SELECT location,population,MAX(CAST(total_deaths AS int)) AS HighestDeathCount,MAX((CAST(total_deaths AS int)/population)*100) AS DeathPercentage
	FROM PortfolioProject..CovidDeaths$
	WHERE continent is not NULL
	GROUP BY location,population
	ORDER BY HighestDeathCount desc

--Now, we will break things down by continent
SELECT continent,MAX(CAST(total_deaths AS int)) AS DeathCount
	FROM PortfolioProject..CovidDeaths$
	WHERE continent is not NULL
	GROUP BY continent
	ORDER BY DeathCount desc

--Now, showing continents with the highest death count per population
SELECT continent,MAX((CAST(total_deaths AS int)/population)*100) AS DeathPercentage
	FROM PortfolioProject..CovidDeaths$
	WHERE continent is not NULL
	GROUP BY continent
	ORDER BY DeathPercentage desc

--Global Numbers
SELECT SUM(new_cases) AS Cases,SUM(CAST(new_deaths AS int)) as Deaths,SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
	FROM PortfolioProject..CovidDeaths$
	WHERE continent is not NULL AND new_cases <> 0 AND new_deaths <> 0
	--GROUP BY date
	ORDER BY 1,2
	
--Now, looking at global vaccinations
SELECT *
	FROM PortfolioProject..CovidVacinations$

--Let's join the two tables together
SELECT *
	FROM PortfolioProject..CovidDeaths$ dea
	JOIN PortfolioProject..CovidVacinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date

--Looking at total population compared to vaccinations
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) AS TotalVacs
	FROM PortfolioProject..CovidDeaths$ dea
	JOIN PortfolioProject..CovidVacinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not NULL
	ORDER BY 2,3

--Now, looking at population compared to vaccinations using CTE
WITH PopvsVac(continent,location,date,population,new_vaccinations,TotalVacs)
	AS 
	(
		SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY  dea.location,dea.date) AS TotalVacs
			FROM PortfolioProject..CovidDeaths$ dea
			JOIN PortfolioProject..CovidVacinations$ vac
				ON dea.location = vac.location
				AND dea.date = vac.date
			WHERE dea.continent is not NULL
			
	)
	SELECT *, (TotalVacs/population) AS VacRate
	FROM PopvsVac
	ORDER BY 2,3

--Now, let's look at a temp table
DROP TABLE IF exists #PercentagePopVac
CREATE TABLE #PercentagePopVac
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	TotalVacs numeric
)

INSERT INTO #PercentagePopVac
	SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY  dea.location,dea.date) AS TotalVacs
		FROM PortfolioProject..CovidDeaths$ dea
		JOIN PortfolioProject..CovidVacinations$ vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent is not NULL

	SELECT *,(TotalVacs/population)*100
		FROM #PercentagePopVac

--Creating view to store th data for visualization 
CREATE VIEW PercentagePopVacView AS
	SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(CONVERT(bigint,new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY  dea.location,dea.date) AS TotalVacs
		FROM PortfolioProject..CovidDeaths$ dea
		JOIN PortfolioProject..CovidVacinations$ vac
			ON dea.location = vac.location
			AND dea.date = vac.date
		WHERE dea.continent is not NULL

--Now, we can query off of this view 
SELECT *
	FROM PercentagePopVacView