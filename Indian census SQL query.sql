select * from Census.dbo.Data1

select * from Census.dbo.Data2

--Number of rows in our datasets

select count(*) from Census..Data1
select count(*) from Census..Data2

--Dataset fro jharkhand and bihar

select * from Census..Data1 where State in ('Jharkhand','Bihar')

--Population of India

select sum(population) as total_population from Census..Data2

--Average Growth Percentage of India

select round((avg(growth)*100),2) as avg_growth from Census..Data1

--Average Growth Percentage of Indian States

select state, round((avg(growth)*100),2) as avg_growth from Census..Data1 group by State

--Average Sex Ratio

select state, round((avg(Sex_Ratio)),0) as avg_sex_ratio from Census..Data1 group by State order by 2 desc

--Average Literacy Rate

select state, round((avg(Literacy)),0) as avg_literacy from Census..Data1 
group by State having round((avg(Literacy)),0) >90 order by 2 desc

--Top 3 states having highest growth ratio

select top 3 state, round((avg(Growth)*100),0) as avg_growth from Census..Data1 
group by State order by 2 desc

--Bottom 3 states having lowest sex ratio
select top 3 state, round((avg(Sex_Ratio)),0) as avg_sex_ratio from Census..Data1 
group by State order by 2

--Top and Bottom 3 states in literacy

drop table if exists #topstates;
create table #topstates
 ( state nvarchar(225),
   top_state float
   )

insert into #topstates
select state, round((avg(Literacy)),0) as avg_literacy from Census..Data1 
group by State order by avg_literacy desc;

select top 3 * from #topstates order by #topstates.top_state desc;

drop table if exists #bottomstates;
create table #bottomstates
 ( state nvarchar(225),
   bottom_state float
   )

insert into #bottomstates
select state, round((avg(Literacy)),0) as avg_literacy from Census..Data1 
group by State order by avg_literacy asc;

select top 3 * from #bottomstates order by #bottomstates.bottom_state;

--Union operator
select * from(select top 3 * from #topstates order by #topstates.top_state desc) a
union
select * from (select top 3 * from #bottomstates order by #bottomstates.bottom_state) b

--States starting with letter a

select distinct state from Census..Data1 where LOWER(state) like 'a%'

--Join Data1 and Data2 Table

--get male & female population

select d.State, sum(d.males) total_males, sum(d.females) total_females 
from
(select c.District,c.State,round((c.Population/(c.Sex_Ratio +1)),0) as males, round(((c.population * c.Sex_Ratio)/(c.Sex_Ratio +1)),0) as females 
from
(Select a.District,a.State,a.Sex_Ratio/1000 as Sex_Ratio, b.Population 
from Census..Data1 a inner join Census..Data2 b on a.District=b.District) c) as d group by d.state order by 2 desc

--Total Literacy rate


select c.state, sum (literate_people) as total_literate_pop, sum( illiterate_people) as total_illiterate_pop
from(select d.District, d.state, round(d.Literacy*d.Population,0) as literate_people,round((1-d.Literacy)*d.Population,0) as illiterate_people
from (Select a.District,a.State,a.Literacy/100 as Literacy, b.Population 
from Census..Data1 a inner join Census..Data2 b on a.District=b.District)d)c
group by c.state



--population in previous census

select sum(m.prev_census_population) prev_census_population,sum(m.current_census_population) current_census_population
from(select e.state, sum(e.prev_census_population) prev_census_population, sum(e.current_census_population) current_census_population
from(select d.District,d.state, round((d.population/(1+d.growth)),0) as prev_census_population, d.Population as current_census_population
from(select a.district, a.state, a.growth/100 as growth , b.population from Census..data1 a inner join Census..Data2 b on a.district = b.District) d)e
group by e.state) m


-- population vs area

select (g.total_area/g.prev_census_population)prev_census_population , (g.total_area/g.current_census_population)current_census_population from
(select q.*,r.total_area from(
select '1' as keyy, n.*from
(select sum(m.prev_census_population) prev_census_population,sum(m.current_census_population) current_census_population
from(select e.state, sum(e.prev_census_population) prev_census_population, sum(e.current_census_population) current_census_population
from(select d.District,d.state, round((d.population/(1+d.growth)),0) as prev_census_population, d.Population as current_census_population
from(select a.district, a.state, a.growth/100 as growth , b.population from Census..data1 a inner join Census..Data2 b on a.district = b.District) d)e
group by e.state) m) n)q
inner join(
select '1' as keyy, z.*from
(select sum(area_km2) total_area from Census..data2)z) r on q.keyy = r.keyy) g

--Window Function
--Output top 3 districts from each state with highest literacy rate
select a.* from(
select district, state, literacy, rank() over(partition by state order by literacy desc) rnk from Census..data1) a
Where a.rnk in (1,2,3) order by a.state