const API_URL = "https://jsonplaceholder.typicode.com/users";

const loadButton = document.querySelector("#load-users");
const filterInput = document.querySelector("#filter-input");
const statusText = document.querySelector("#status");
const usersList = document.querySelector("#users-list");

let allUsers = [];
let usersLoaded = false;

function renderUsers(list) {
  usersList.replaceChildren();

  if (list.length === 0) {
    if (usersLoaded && filterInput.value.trim()) {
      statusText.textContent = "No users match your filter.";
    }
    return;
  }

  list.forEach((user) => {
    const listItem = document.createElement("li");

    const name = document.createElement("h2");
    name.textContent = user.name;

    const email = document.createElement("p");
    email.textContent = `Email: ${user.email}`;

    const city = document.createElement("p");
    city.textContent = `City: ${user.address.city}`;

    const company = document.createElement("p");
    company.textContent = `Company: ${user.company.name}`;

    listItem.appendChild(name);
    listItem.appendChild(email);
    listItem.appendChild(city);
    listItem.appendChild(company);

    usersList.appendChild(listItem);
  });
}

async function loadUsers() {
  statusText.textContent = "Loading users...";
  loadButton.disabled = true;
  usersList.replaceChildren();

  allUsers = [];
  usersLoaded = false;

  try {
    const response = await fetch(API_URL);

    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }

    const users = await response.json();

    allUsers = users;
    usersLoaded = true;

    renderUsers(allUsers);
    statusText.textContent = `Successfully loaded ${allUsers.length} users.`;
  } catch (error) {
    statusText.textContent =
      "Could not load users. Please try again.";

    console.error("Error fetching users:", error);
  } finally {
    loadButton.disabled = false;
  }
}

loadButton.addEventListener("click", loadUsers);

filterInput.addEventListener("input", () => {
  if (!usersLoaded) {
    return;
  }

  const searchText = filterInput.value.trim().toLowerCase();

  const filteredUsers = allUsers.filter((user) =>
    user.name.toLowerCase().includes(searchText)
  );

  renderUsers(filteredUsers);

  if (filteredUsers.length > 0) {
    statusText.textContent =
      `Showing ${filteredUsers.length} of ${allUsers.length} users.`;
  } else {
    statusText.textContent = "No users match your filter.";
  }
});