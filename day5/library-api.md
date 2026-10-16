# Library Books REST API

Base URL: `https://api.example.com`

## 1. List All Books

- **Method:** GET
- **Path:** `/books`
- **Description:** Retrieves a list of all books in the library.
- **Success status:** 200 OK

## 2. Get a Single Book

- **Method:** GET
- **Path:** `/books/{id}`
- **Description:** Retrieves details of a specific book using its ID.
- **Example:** `/books/42`
- **Success status:** 200 OK

## 3. Create a Book

- **Method:** POST
- **Path:** `/books`
- **Description:** Adds a new book to the library.
- **Example request body:**

```json
{
  "title": "Things Fall Apart",
  "author": "Chinua Achebe",
  "publishedYear": 1958
}