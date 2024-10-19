<?php

// GitLab instance and Personal Access Token (PAT)
$gitlab_instance = "https://git.recolic.net";
$pat = "<your_personal_access_token>";

// Check if the request method is POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["error" => "Only POST requests are allowed."]);
    exit(1);
}

// Validate required POST parameters
if (!isset($_POST['name'], $_POST['username'], $_POST['email'], $_POST['password'])) {
    echo json_encode(["error" => "Missing required parameters: name, username, email, and password."]);
    exit(1);
}

// Assign POST variables
$name = $_POST['name'];
$username = $_POST['username'];
$email = $_POST['email'];
$password = $_POST['password'];

// GitLab API URL for creating users
$url = "$gitlab_instance/api/v4/users";

// Set up the data to send in the POST request
$data = [
    "name" => $name,
    "username" => $username,
    "email" => $email,
    "password" => $password,
    "skip_confirmation" => "true"
];

// Initialize cURL
$ch = curl_init();

// Set cURL options
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "PRIVATE-TOKEN: $pat"
]);

// Execute the request
$response = curl_exec($ch);

// Check if the request was successful
if ($response === false) {
    echo json_encode(["error" => curl_error($ch)]);
} else {
    // Output the API response
    echo $response;
}

// Close cURL resource
curl_close($ch);
?>
