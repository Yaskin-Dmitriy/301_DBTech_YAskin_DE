#!/bin/bash
if command -v chcp >/dev/null 2>&1; then chcp 65001; fi

sqlite3 movies_rating.db < db_init.sql

echo "1. Составить список фильмов, имеющих хотя бы одну оценку. Отсортировать по году выпуска и названию. Вывести первые 10 фильмов."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT m.title, m.year FROM movies m JOIN ratings r ON m.id = r.movie_id ORDER BY m.year, m.title LIMIT 10;"

echo " "
echo "2. Вывести первых 5 пользователей, фамилия которых начинается на A. Отсортировать по дате регистрации."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT id, name, email, gender, register_date, occupation FROM users WHERE substr(name, instr(name, ' ') + 1) LIKE 'A%' ORDER BY register_date LIMIT 5;"

echo " "
echo "3. Составить отчёт об оценках: имя и фамилия пользователя, название фильма, год выпуска, оценка и дата выставления оценки в формате ГГГГ-ММ-ДД. Отсортировать по имени пользователя, названию фильма и оценке. Вывести первые 50 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT u.name AS expert, m.title, m.year, r.rating, date(r.timestamp, 'unixepoch') AS rating_date FROM ratings r JOIN users u ON r.user_id = u.id JOIN movies m ON r.movie_id = m.id ORDER BY u.name, m.title, r.rating LIMIT 50;"

echo " "
echo "4. Вывести фильмы, которым пользователи присвоили теги. Отсортировать по году выпуска, названию фильма и тегу. Вывести первые 40 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, t.tag FROM movies m JOIN tags t ON t.movie_id = m.id ORDER BY m.year, m.title, t.tag LIMIT 40;"

echo " "
echo "5. Вывести все фильмы, выпущенные в самый поздний год, имеющийся в базе данных."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT title, year FROM movies WHERE year = (SELECT MAX(year) FROM movies) ORDER BY title;"

echo " "
echo "6. Вывести драмы, выпущенные после 2005 года и получившие оценки не ниже 4.5 от женщин. Для каждого фильма указать название, год выпуска и количество таких оценок. Отсортировать по году и названию."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, COUNT(*) AS positive_female_ratings FROM movies m JOIN ratings r ON r.movie_id = m.id JOIN users u ON u.id = r.user_id WHERE m.year > 2005 AND ('|' || m.genres || '|') LIKE '%|Drama|%' AND u.gender = 'female' AND r.rating >= 4.5 GROUP BY m.id, m.title, m.year ORDER BY m.year, m.title;"

echo " "
echo "7. Подсчитать количество зарегистрированных пользователей по годам и определить годы с максимальным и минимальным количеством регистраций."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH yearly AS (SELECT strftime('%Y', register_date) AS year, COUNT(*) AS user_count FROM users GROUP BY strftime('%Y', register_date)), extrema AS (SELECT MAX(user_count) AS max_count, MIN(user_count) AS min_count FROM yearly) SELECT yearly.year, yearly.user_count, CASE WHEN yearly.user_count = extrema.max_count THEN 'MAX' WHEN yearly.user_count = extrema.min_count THEN 'MIN' ELSE '' END AS category FROM yearly CROSS JOIN extrema ORDER BY yearly.year;"