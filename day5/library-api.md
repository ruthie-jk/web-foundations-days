# Library Books REST API

## Base URL

`https://api.example.com`

## 1. List All Books

- **Method:** GET
- **Endpoint:** `/books`
- **Description:** Retrieves a list of all books available in the library.
- **Success status:** `200 OK`
- **Example request:** `GET /books`

## 2. Retrieve a Single Book

- **Method:** GET
- **Endpoint:** `/books/{id}`
- **Description:** Retrieves the details of a specific book using its unique ID.
- **Success status:** `200 OK`
- **Example request:** `GET /books/42`

## 3. Create a Book

- **Method:** POST
- **Endpoint:** `/books`
- **Description:** Adds a new book to the library.
- **Example request body:**

```json
{
  "title": "Things Fall Apart",
  "author": "Chinua Achebe",
  "publishedYear": 1958
}
```

- **Success status:** `201 Created`

## 4. Update a Book

- **Method:** PUT
- **Endpoint:** `/books/{id}`
- **Description:** Updates an existing book identified by its ID.
- **Example request:** `PUT /books/42`
- **Example request body:**

```json
{
  "title": "Things Fall Apart",
  "author": "Chinua Achebe",
  "publishedYear": 1958
}
```

- **Success status:** `200 OK`

## 5. Delete a Book

- **Method:** DELETE
- **Endpoint:** `/books/{id}`
- **Description:** Deletes a specific book from the library using its ID.
- **Example request:** `DELETE /books/42`
- **Success status:** `204 No Content`

## 6. Find Books by Author

- **Method:** GET
- **Endpoint:** `/books?author=Chinua%20Achebe`
- **Description:** Retrieves books written by the specified author using the `author` query parameter.
- **Example request:** `GET /books?author=Chinua%20Achebe`
- **Success status:** `200 OK`

## Error Responses

### 400 Bad Request

- **Description:** The request contains invalid data or is missing required information.
- **Example scenario:** A client attempts to create a book without providing its title.
- **Status code:** `400 Bad Request`
- **Example response body:**

```json
{
  "error": "Bad Request",
  "message": "The title field is required."
}
```

### 404 Not Found

- **Description:** The requested resource does not exist.
- **Example scenario:** A client requests `/books/9999`, but no book with ID `9999` exists.
- **Status code:** `404 Not Found`
- **Example response body:**

```json
{
  "error": "Not Found",
  "message": "Book not found."
}