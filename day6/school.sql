-- Day 6 Assignment: School Database
PRAGMA foreign_keys = ON;

-- Drop existing tables so this script can be run again safely.
DROP TABLE IF EXISTS enrolments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;

-- 1. Students table
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE
);

-- 2. Courses table
CREATE TABLE courses (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT
);

-- 3. Enrolments table: connects students and courses.
CREATE TABLE enrolments (
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    grade TEXT NOT NULL DEFAULT 'Pending',
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(id)
        ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id)
        ON DELETE CASCADE
);

-- Sample students (at least 3)
INSERT INTO students (id, name, email) VALUES
(1, 'Amina Hassan', 'amina@example.com'),
(2, 'Brian Otieno', 'brian@example.com'),
(3, 'Carol Wanjiku', 'carol@example.com');

-- Sample courses (at least 3)
INSERT INTO courses (id, name, description) VALUES
(1, 'Database Systems', 'Introduction to databases and SQL'),
(2, 'Computer Networks', 'Networking fundamentals'),
(3, 'Web Development', 'Building websites with HTML, CSS and JavaScript');

-- Sample enrolments (at least 5)
INSERT INTO enrolments (student_id, course_id, grade) VALUES
(1, 1, 'A'),
(1, 3, 'B'),
(2, 1, 'B'),
(2, 2, 'A'),
(2, 3, 'B');

-- QUERY 1: All courses taken by one student, searched by name.
SELECT courses.name AS course_name
FROM students
JOIN enrolments ON enrolments.student_id = students.id
JOIN courses ON courses.id = enrolments.course_id
WHERE students.name = 'Amina Hassan'
ORDER BY courses.name;

-- QUERY 2: All students enrolled in one course.
SELECT students.name AS student_name
FROM courses
JOIN enrolments ON enrolments.course_id = courses.id
JOIN students ON students.id = enrolments.student_id
WHERE courses.name = 'Database Systems'
ORDER BY students.name;

-- QUERY 3: Number of students enrolled in each course.
-- LEFT JOIN includes courses with zero enrolments.
SELECT courses.name AS course_name,
       COUNT(enrolments.student_id) AS student_count
FROM courses
LEFT JOIN enrolments ON enrolments.course_id = courses.id
GROUP BY courses.id, courses.name
ORDER BY courses.name;

-- QUERY 4: Students who have no enrolments.
SELECT students.name AS student_name
FROM students
LEFT JOIN enrolments ON enrolments.student_id = students.id
WHERE enrolments.student_id IS NULL;

-- QUERY 5: Update one enrolment's grade.
UPDATE enrolments
SET grade = 'A'
WHERE student_id = 1 AND course_id = 3;

-- Verify the grade update.
SELECT students.name AS student_name,
       courses.name AS course_name,
       enrolments.grade
FROM enrolments
JOIN students ON students.id = enrolments.student_id
JOIN courses ON courses.id = enrolments.course_id
WHERE enrolments.student_id = 1
  AND enrolments.course_id = 3;

-- Index to help find enrolments by course.
CREATE INDEX idx_enrolments_course_id
ON enrolments(course_id);