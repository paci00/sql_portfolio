-- looking at deaths to cases ratio so what precentage of cases were leathal
Select location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS death_prec
from deaths 
where location like '%'
order by 1, 2 desc;

--total cases to population ratio so what precentage has covid
Select location, date, total_cases,population, 
(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS sick_prec
from deaths 
where location like '%'
order by 1, 2 desc;

-- countries with highest infection rate compared to pop
Select location, max(total_cases) most_cases,population,
max((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100) AS sick_prec
from deaths 
where location like '%poland%'
group by location,population
order by 4 desc;

--countries with max death count per population
SELECT 
location,
max(cast(total_deaths as float))
FROM deaths
WHERE location LIKE '%' and continent is not null
GROUP BY location
ORDER BY 2 DESC;

--data breakdown by contiennt

--highest death count per continent
SELECT 
continent,
max(cast(total_deaths as float))
FROM deaths
WHERE continent is not null
GROUP BY continent
ORDER BY 2 DESC;

-- contiennts with highest death count to population ratio
SELECT 
continent,
round(100*max(cast(total_deaths/population as float)),2) deathpop_ratio
FROM deaths
WHERE continent is not null
GROUP BY continent
ORDER BY 2 DESC;


-- global numbers

-- by date
select date,  sum(new_deaths) as deaths, sum(new_cases) as cases ,
sum(cast(new_deaths as float))/nullif(sum(cast(new_cases as float)),0) as death_ratio
from deaths
group by date
order by date asc;

--total
select  sum(new_deaths) as deaths, sum(new_cases) as cases ,
100*sum(cast(new_deaths as float))/nullif(sum(cast(new_cases as float)),0) as death_ratio
from deaths;

--joing vacc
select d.continent,d.location,d.date,d.population,v.new_vaccinations
from deaths d
join vacc v
on d.date=v.date and d.location=v.location and d.continent=v.continent and d.iso_code=v.iso_code;

--wypociny
with cte as(
SELECT 
    d.location,
    d.date,
    v.total_vaccinations / NULLIF(d.population, 0) AS vaccinations_per_population,
	rank() over(partition by d.location order by d.date desc) as srank
FROM 
    deaths d
JOIN 
    vacc v ON d.date = v.date AND d.location = v.location AND d.continent = v.continent AND d.iso_code = v.iso_code
)

select * from cte 
where srank=1
order by vaccinations_per_population desc;

--total pop vs vacc
select d.continent,d.location,d.date,d.population,v.new_vaccinations,

sum(convert(float,v.new_vaccinations)) 
over(partition by d.location order by d.location,d.date) rolling_vacc

from deaths d
join vacc v
on d.date=v.date and d.location=v.location and d.continent=v.continent and d.iso_code=v.iso_code

where d.location is not null


--rolling vac per pop with cte
with cte as (
select d.continent,d.location,d.date,d.population,v.new_vaccinations,

sum(convert(float,v.new_vaccinations)) 
over(partition by d.location order by d.location,d.date) rolling_vacc

from deaths d
join vacc v
on d.date=v.date and d.location=v.location and d.continent=v.continent and d.iso_code=v.iso_code

where d.location is not null
)

select *, ROUND(rolling_vacc/population,8)*100 as rolling_vacc_perc

from cte
where rolling_vacc is not null and
location like 'poland%'

order by ROUND(rolling_vacc/population,8)*100 desc

--temp table
drop table if exists #percent_pop_vacc
create table #percent_pop_vacc
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population float,
new_vaccinations float,
rolling_vacc float)

insert into #percent_pop_vacc
select d.continent,d.location,d.date,d.population,v.new_vaccinations,

sum(convert(float,v.new_vaccinations)) 
over(partition by d.location order by d.location,d.date) rolling_vacc

from deaths d
join vacc v
on d.date=v.date and d.location=v.location and d.continent=v.continent and d.iso_code=v.iso_code

select * from #percent_pop_vacc;


--view for tableau
create view percent_pop_vacc  as
select d.continent,d.location,d.date,d.population,v.new_vaccinations,

sum(convert(float,v.new_vaccinations)) 
over(partition by d.location order by d.location,d.date) rolling_vacc

from deaths d
join vacc v
on d.date=v.date and d.location=v.location and d.continent=v.continent and d.iso_code=v.iso_code
where d.location is not null