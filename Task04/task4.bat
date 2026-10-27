#!/bin/bash
if command -v chcp >/dev/null 2>&1; then chcp 65001; fi

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Исключить пары с самим собой и дубликаты. Вывести первые 100 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT u1.name AS user1, u2.name AS user2, m.title FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id JOIN users u1 ON u1.id = r1.user_id JOIN users u2 ON u2.id = r2.user_id JOIN movies m ON m.id = r1.movie_id ORDER BY u1.name, u2.name, m.title LIMIT 100;"

echo " "
echo "2. Найти 10 самых старых оценок от разных пользователей. Вывести название фильма, имя пользователя, оценку и дату в формате ГГГГ-ММ-ДД."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH ranked AS (SELECT r.*, ROW_NUMBER() OVER (PARTITION BY r.user_id ORDER BY r.timestamp, r.id) AS rn FROM ratings r) SELECT m.title, u.name, r.rating, date(r.timestamp, 'unixepoch') AS rating_date FROM ranked r JOIN users u ON u.id = r.user_id JOIN movies m ON m.id = r.movie_id WHERE r.rn = 1 ORDER BY r.timestamp, r.id LIMIT 10;"

echo " "
echo "3. Вывести фильмы с максимальным и минимальным средним рейтингом. Отсортировать по году выпуска и названию. Указать, рекомендуем ли фильм."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH averages AS (SELECT m.id, m.title, m.year, AVG(r.rating) AS avg_rating FROM movies m JOIN ratings r ON r.movie_id = m.id GROUP BY m.id, m.title, m.year), extrema AS (SELECT MAX(avg_rating) AS max_rating, MIN(avg_rating) AS min_rating FROM averages) SELECT title, year, ROUND(avg_rating, 3) AS avg_rating, CASE WHEN avg_rating = max_rating THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем' FROM averages CROSS JOIN extrema WHERE avg_rating = max_rating OR avg_rating = min_rating ORDER BY year, title;"

echo " "
echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT COUNT(*) AS ratings_count, ROUND(AVG(r.rating), 3) AS average_rating FROM ratings r JOIN users u ON u.id = r.user_id WHERE u.gender = 'male' AND date(r.timestamp, 'unixepoch') >= '2011-01-01' AND date(r.timestamp, 'unixepoch') < '2015-01-01';"

echo " "
echo "5. Составить список фильмов со средней оценкой и количеством пользователей, которые их оценили. Отсортировать по году и названию. Вывести первые 20 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT m.title, m.year, ROUND(AVG(r.rating), 3) AS avg_rating, COUNT(DISTINCT r.user_id) AS users_count FROM movies m JOIN ratings r ON r.movie_id = m.id GROUP BY m.id, m.title, m.year ORDER BY m.year, m.title LIMIT 20;"

echo " "
echo "6. Определить самый распространенный жанр фильма и количество фильмов этого жанра."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE genre_split(movie_id, genre, rest) AS (SELECT id, '', genres || '|' FROM movies WHERE genres IS NOT NULL AND genres <> '' UNION ALL SELECT movie_id, substr(rest, 1, instr(rest, '|') - 1), substr(rest, instr(rest, '|') + 1) FROM genre_split WHERE rest <> ''), genre_counts AS (SELECT genre, COUNT(DISTINCT movie_id) AS movies_count FROM genre_split WHERE genre <> '' GROUP BY genre) SELECT genre, movies_count FROM genre_counts WHERE movies_count = (SELECT MAX(movies_count) FROM genre_counts) ORDER BY genre;"

echo " "
echo "7. Вывести 10 последних зарегистрированных пользователей в формате Фамилия Имя|Дата регистрации."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT substr(name, instr(name, ' ') + 1) || ' ' || substr(name, 1, instr(name, ' ') - 1) || '|' || register_date AS user_registration FROM users ORDER BY register_date DESC, id DESC LIMIT 10;"

echo " "
echo "8. С помощью рекурсивного CTE определить день недели, на который приходилось 8 июня каждого года с 2006 по 2026 год."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE years(y) AS (SELECT 2006 UNION ALL SELECT y + 1 FROM years WHERE y < 2026) SELECT y AS year, date(y || '-06-08') AS birthday, CASE strftime('%w', date(y || '-06-08')) WHEN '0' THEN 'Воскресенье' WHEN '1' THEN 'Понедельник' WHEN '2' THEN 'Вторник' WHEN '3' THEN 'Среда' WHEN '4' THEN 'Четверг' WHEN '5' THEN 'Пятница' WHEN '6' THEN 'Суббота' END AS weekday FROM years ORDER BY y;"
