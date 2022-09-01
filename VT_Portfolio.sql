USE VT_PortfolioProject
GO
-- It only First ~65000 rows because of old  Excel versions. From 1/1/2020 - 30/4/2021

/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, PROCEDURE, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/
-- Khám phá dữ liệu
-- So sánh 2 bảng có giống nhau chưa?
SELECT d.iso_code, count(d.continent) 
  FROM dbo.CovidDeaths as d
 GROUP BY d.iso_code
 ORDER BY d.iso_code

SELECT v.iso_code, count(v.continent) 
  FROM dbo.CovidVaccinations as v
 GROUP BY v.iso_code
 ORDER BY v.iso_code;
 -- Số quốc gia
 SELECT DISTINCT location
 FROM dbo.CovidDeaths
 -- Số lục địa
 SELECT DISTINCT continent
 FROM dbo.CovidDeaths


-- 1. Look at my tables 
SELECT * 
  FROM dbo.CovidDeaths as Dea
 WHERE Dea.continent is NOT NULL
 ORDER BY 3,4;

SELECT * FROM dbo.CovidVaccinations as Vac
 WHERE Vac.continent is NOT NULL
 ORDER BY 3,4;


-- 2. Select data which we are going to be starting with
SELECT date, location, new_cases, total_cases, total_deaths, population
  FROM dbo.CovidDeaths
 WHERE continent is NOT NULL -- don't use this rows
 ORDER BY 2,1;

-- 3. Total cases vs Total deaths
SELECT date, location, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
  FROM dbo.CovidDeaths
 WHERE continent is NOT NULL
 ORDER BY 2,1;

-- 4. Total cases vs Population
SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
  FROM dbo.CovidDeaths
 WHERE continent is NOT NULL
 ORDER BY 1,2;

--  5. Top 10 Countries with highest infection rate compare to Population 
SELECT  TOP 10 location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases)/population*100 as PercentPopulationInfected
  FROM dbo.CovidDeaths
 WHERE continent is NOT NULL
 GROUP BY location, population
 ORDER BY PercentPopulationInfected DESC

-- 6. Top 10 Contries with highest Deaths Rate compare to Population
SELECT TOP 10 location, population, MAX(CONVERT(int,total_deaths)) as HighestDeathCount, MAX(total_deaths)/population*100 as PercentPopulationDeaths
  FROM dbo.CovidDeaths
 WHERE continent is NOT NULL
 GROUP BY location, population
 ORDER BY 4 DESC

-- BREAKING THINGS DOWN BY CONTINENT
-- 7. Showing contintents with the highest death count per population
SELECT continent, MAX(total_deaths) as HighestDeathCount
  FROM dbo.CovidDeaths
 WHERE continent is NOT NULL
 GROUP BY continent
 ORDER BY 2 DESC

-- 8. GLOBAL NUMBERS
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
 FROM dbo.CovidDeaths
--Where location like '%states%'
 WHERE continent is not null 
 ORDER BY 1,2
-- 2,172,084 người trên thế gioi đã chết trong đại dịch vừa qua chỉ tính đến 30/4/2021


-- 9. Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
	   SUM(Vac.new_vaccinations) OVER (Partition by Dea.location ORDER by Dea.location, Dea.date) as RollingPeopleVaccinated
	   --(RollingPeopleVaccinated/population)*100 as result	   
	   FROM dbo.CovidDeaths as Dea 
			INNER JOIN dbo.CovidVaccinations as Vac 
					ON Dea.location = Vac.location
				   AND Dea.date = Vac.date
 WHERE dea.continent IS NOT NULL 
 ORDER BY 2,3;


-- 10. Using CTE to perform Calculation on Partition By in previous query
With PopvsVac(Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as 
(
		SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
			   SUM(Vac.new_vaccinations) OVER (Partition by Dea.location ORDER by Dea.location, Dea.date) as RollingPeopleVaccinated
			   --(RollingPeopleVaccinated/population)*100 as result	   
			   FROM dbo.CovidDeaths as Dea 
				    INNER JOIN dbo.CovidVaccinations as Vac 
						    ON Dea.location = Vac.location
						   AND Dea.date = Vac.date
		 WHERE dea.continent IS NOT NULL
		 --ORDER BY 2,3
)
SELECT *, CAST(RollingPeopleVaccinated as real)/Population*100 as ResultVaccinated
  FROM PopvsVac
 WHERE RollingPeopleVaccinated is NOT NULL
 ORDER BY 2,3;


-- 11. Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent NVARCHAR(255),
	Location NVARCHAR(255),
	Date DATETIME,
	Population NUMERIC,
	New_vaccinations NUMERIC,
	RollingPeopleVaccinated NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
	   SUM(Vac.new_vaccinations) OVER (Partition by Dea.location ORDER by Dea.location, Dea.date) as RollingPeopleVaccinated   
  FROM dbo.CovidDeaths as Dea 
       INNER JOIN dbo.CovidVaccinations as Vac 
			   ON Dea.location = Vac.location
			  AND Dea.date = Vac.date
 WHERE dea.continent IS NOT NULL; 

GO

SELECT *, (RollingPeopleVaccinated/Population)*100 as Result
  FROM  #PercentPopulationVaccinated
 WHERE RollingPeopleVaccinated is NOT NULL
 ORDER BY 2,3;


-- 12. Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
	   SUM(Vac.new_vaccinations) OVER (Partition by Dea.location ORDER by Dea.location, Dea.date) as RollingPeopleVaccinated   
	   FROM dbo.CovidDeaths as Dea 
		    INNER JOIN dbo.CovidVaccinations as Vac 
				    ON Dea.location = Vac.location
				   AND Dea.date = Vac.date
 WHERE dea.continent IS NOT NULL;  


 -- 13. Epidemic Control ở Mĩ hoặc các nước khác
CREATE PROCEDURE CountryEpidemicControl_1
	( @location NVARCHAR(255) = 'Russia')
AS
		SELECT Dea.location, Dea.date, Dea.population, (Vac.aged_65_older + Vac.aged_70_older)*100 as OldPeople, Dea.total_cases, Vac.total_tests ,
			   SUM(Vac.new_vaccinations) OVER (Partition by Dea.location ORDER by Dea.location, Dea.date) as RollingPeopleVaccinated , Dea.total_deaths
		  FROM dbo.CovidDeaths as Dea 
			   INNER JOIN dbo.CovidVaccinations as Vac 
					   ON Dea.location = Vac.location
					  AND Dea.date = Vac.date
		 WHERE dea.continent IS NOT NULL AND Dea.location = @location
		 ORDER BY 1,2

 GO

 EXEC CountryEpidemicControl_1 @location = 'Belgium';

 GO
 ------------------------------------------------------- END --------------------------------------------------------------

