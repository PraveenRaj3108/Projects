use film_rental;
select * from rental;
select * from payment;
select * from film;
select * from film_category;
select * from category;
select * from inventory;

-- Actor Info	Actor | Film_Actor
-- Film Info	Film | Film_Category | Category | Language
-- Customer Info	Customer | Address | City | Country
-- Store Info	Store | Staff | Rental | Payment



-- 1. What is the total revenue generated from all rentals in the database? (2 Marks)

select sum(amount) total_revenue from payment;

-- 2. How many rentals were made in each month_name? (2 Marks)

select monthname(rental_date) Month,count(monthname(rental_date)) number_of_rentals from rental 
group by month order by number_of_rentals desc;

-- 3. What is the rental rate of the film with the longest title in the database? (2 Marks)

select title, rental_rate from film where length(title) = (select max(length(title)) from film);

-- 4. What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")? (2 Marks)

select round(avg(rental_rate),2) average_rental_rate from film f
inner join inventory i on i.film_id=f.film_id
inner join rental r on i.inventory_id = r.inventory_id
where datediff(rental_date,"2005-05-05 22:04:30") <= 30;

-- 5. What is the most popular category of films in terms of the number of rentals? (3 Marks)
select name,count(*) as number_of_rentals from film f
inner join inventory i on i.film_id=f.film_id
inner join rental r on i.inventory_id = r.inventory_id
inner join film_category fc on f.film_id = fc.film_id
inner join category c on fc.category_id = c.category_id 
group by name
order by number_of_rentals desc limit 1;

-- 6. Find the longest movie duration from the list of films that have not been rented by any customer. (3 Marks)

select title,length from film  where film_id not in (select distinct film_id from inventory)
order by length desc limit 1;

-- 7. What is the average rental rate for films, broken down by category? (3 Marks)

select name,round(avg(rental_rate),2) as avg_rental_rate from film f
inner join inventory i on i.film_id=f.film_id
inner join rental r on i.inventory_id = r.inventory_id
inner join film_category fc on f.film_id = fc.film_id
inner join category c on fc.category_id = c.category_id 
group by name
order by avg_rental_rate desc;

-- 8. What is the total revenue generated from rentals for each actor in the database? (3 Marks)

select a.actor_id,a.first_name,a.last_name,sum(p.amount) as total_revenue from rental r
inner join inventory i on i.inventory_id = r.inventory_id
inner join film f on i.film_id=f.film_id
inner join payment p on r.customer_id = p.customer_id
inner join film_actor fa on f.film_id = fa.film_id
inner join actor a on fa.actor_id = a.actor_id
group by a.actor_id
order by total_revenue desc;

-- 9. Show all the actresses who worked in a film having a "Wrestler" in the description. (3 Marks)

select * from  actor;
select * from film_actor;
select * from film;
select distinct a.*,f.description from film f
inner join film_actor fa on f.film_id = fa.film_id
inner join actor a on fa.actor_id = a.actor_id
where description like "%Wrestler%" ;

-- 10. Which customers have rented the same film more than once? (3 Marks)

select r.customer_id,concat(first_name," ",last_name) fullname,f.title,count(r.rental_id) as count_rented from inventory i 
inner join rental r on i.inventory_id = r.inventory_id 
inner join film f on i.film_id = f.film_id
inner join customer c on r.customer_id = c.customer_id
group by 1,2,3
having count(r.rental_id) > 1;

-- 11. How many films in the comedy category have a rental rate higher than the average rental rate? (3 Marks)

select count(title) films from film f
inner join film_category fc on f.film_id = fc.film_id
inner join category c on fc.category_id = c.category_id 
where name='Comedy' and rental_rate > (select avg(rental_rate) from film);

-- 12. Which films have been rented the most by customers living in each city? (3 Marks)
SELECT 
    COUNT(f.title) AS titlecount,
    f.title,
    c.city 
FROM 
    rental r
    INNER JOIN inventory i ON r.inventory_id = i.inventory_id
    INNER JOIN film f ON f.film_id = i.film_id
    INNER JOIN store s ON s.store_id = i.store_id
    INNER JOIN address a ON a.address_id = s.address_id
    INNER JOIN city c ON c.city_id = a.city_id
GROUP BY 
    c.city,
    f.title
ORDER BY 
    c.city,
    titlecount DESC;
    
-- 13. What is the total amount spent by customers whose rental payments exceed $200? (3 Marks)
select customer_id,sum(amount) total_amount from payment group by customer_id having total_amount >200;

-- 14. Display the fields which are having foreign key constraints related to the "rental" table. [Hint: using Information_schema] (2 Marks)
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'rental' AND TABLE_SCHEMA = 'film_rental';

SELECT 
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM 
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE 
    TABLE_NAME = 'rental';


-- 15. Create a View for the total revenue generated by each staff member, broken down by store city with the country name. (4 Marks)
CREATE VIEW StaffRevenueByCity AS
SELECT 
    s.staff_id,
    CONCAT(s.first_name, ' ', s.last_name) AS staff_name,
    c.city AS store_city,
    co.country AS store_country,
    SUM(p.amount) AS total_revenue
FROM 
    staff s
INNER JOIN 
    store st ON s.store_id = st.store_id
INNER JOIN 
    address a ON st.address_id = a.address_id
INNER JOIN 
    city c ON a.city_id = c.city_id
INNER JOIN 
    country co ON c.country_id = co.country_id
INNER JOIN 
    payment p ON s.staff_id = p.staff_id
GROUP BY 
    s.staff_id, c.city, co.country;
    
select * from StaffRevenueByCity   ; 

-- 16. Create a view based on rental information consisting of visiting_day, customer_name, the title of the film, no_of_rental_days, the amount paid by the customer along with the percentage of customer spending. (4 Marks)
CREATE VIEW RentalInfo AS
SELECT
    r.rental_id,
    r.rental_date AS visiting_day,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    f.title AS film_title,
    DATEDIFF(r.return_date, r.rental_date) AS no_of_rental_days,
    p.amount AS amount_paid,
    ROUND((p.amount / (SELECT SUM(amount) FROM payment WHERE customer_id = r.customer_id) * 100), 2) AS spending_percentage
FROM
    rental r
INNER JOIN
    customer c ON r.customer_id = c.customer_id
INNER JOIN
    payment p ON r.rental_id = p.rental_id
INNER JOIN
    inventory i ON r.inventory_id = i.inventory_id
INNER JOIN
    film f ON i.film_id = f.film_id;
    
 SELECT * FROM RentalInfo;   



-- 17. Display the customers who paid 50% of their total rental costs within one day. (5 Marks)

    CREATE VIEW PAID50INONEDAY AS
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    r.rental_id,
    r.rental_date,
    SUM(p.amount) AS total_payment_amount,
    SUM(f.rental_rate) AS total_rental_cost,
    CASE
        WHEN DATEDIFF(MAX(p.payment_date), r.rental_date) = 0 THEN 'Within One Day'
        ELSE 'Not Within One Day'
    END AS payment_timing
FROM 
    customer c
JOIN 
    rental r ON c.customer_id = r.customer_id
JOIN 
    payment p ON r.rental_id = p.rental_id
JOIN 
    inventory i ON r.inventory_id = i.inventory_id
JOIN 
    film f ON i.film_id = f.film_id
GROUP BY 
    c.customer_id, r.rental_id
HAVING 
    SUM(p.amount) >= 0.5 * SUM(f.rental_rate)

    AND DATEDIFF(MAX(p.payment_date), r.rental_date) = 0;
    
Select * from paid50inoneday;    

Select * from customer;
