<?php
// Simple language-based redirection (no cookies)
// Default to /en/ for undefined or unknown languages

$defaultLang = 'en';
$availableLangs = ['en', 'fr'];

$acceptLanguage = $_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? $defaultLang;
$languages = explode(',', $acceptLanguage);
$lang = strtolower(substr(trim($languages[0]), 0, 2));

if (!in_array($lang, $availableLangs)) {
    $lang = $defaultLang;
}

// Bypass redirection for crawlers to prevent indexing confusion
$userAgent = strtolower($_SERVER['HTTP_USER_AGENT'] ?? '');
if (preg_match('/(googlebot|bingbot|slurp|duckduckbot)/', $userAgent)) {
    $lang = $defaultLang;
}

header("Location: /$lang/", true, 302);
header("Vary: Accept-Language");
header("Cache-Control: private, max-age=3600");
exit();
?>
