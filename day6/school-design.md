# School Database Design

## 1. Tables and their purpose

### Students
The `students` table stores information about each student. It contains an `id` as the primary key, a `name`, and an `email`. The email is required and must be unique so that two students cannot register with the same email address.

### Courses
The `courses` table stores the courses offered by the school. It contains an `id` as the primary key, a unique course `name`, and an optional `description`.

### Enrolments
The `enrolments` table records which student is enrolled in which course and the student's grade. It contains `student_id` and `course_id` as foreign keys, together with a `grade` column. The combination of `student_id` and `course_id` forms a composite primary key, preventing the same student from enrolling in the same course more than once.

## 2. Relationships

The relationship between students and enrolments is one-to-many because one student can have several enrolments, while each enrolment belongs to one student.

The relationship between courses and enrolments is also one-to-many because one course can have many students enrolled in it, while each enrolment refers to one course.

Students and courses therefore have a many-to-many relationship: a student can take several courses, and a course can have several students. The `enrolments` table is needed as a join table to represent this relationship. It also stores information specific to the relationship, such as the student's grade for a particular course.

## 3. Index

I would add an index on `enrolments(course_id)`. This can speed up queries that find all students enrolled in a particular course and queries that count enrolments for each course. The index uses additional storage and can make inserts, updates, and deletes slightly slower, so indexes should be added where they are useful.

## 4. SQL or NoSQL?

I would choose a relational SQL database for this school system. Students, courses, and enrolments have clearly defined relationships, and the system needs primary keys, foreign keys, unique constraints, joins, and grouping queries. SQL databases help maintain data integrity and consistency. A NoSQL database can be useful for flexible or document-based data, but a relational database is a better fit for managing student enrolments and grades in this system.