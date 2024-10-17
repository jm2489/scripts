<?php
# This is just a test php script to insert the hash to the mysql databse.
# Will probably add this functionality after getting approved for the authentication deliverable: 10/16/2024
$password = 'password';
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);
echo $hashedPassword;

