<?php

header('Content-Type: application/json');

$data = '';

$port  = filter_var($_GET['port'], FILTER_SANITIZE_STRING);
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "http://localhost:$port/status");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 2);
curl_setopt($ch, CURLOPT_TIMEOUT, 2);
$data = curl_exec($ch);
$httpcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo $data;
?>
