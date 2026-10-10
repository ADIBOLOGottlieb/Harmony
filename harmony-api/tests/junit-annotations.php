<?php

/*
| Transforme les tests en échec d'un rapport JUnit en annotations GitHub Actions
| (visibles publiquement, contrairement aux journaux). Utilisé par la CI.
*/

$file = $argv[1] ?? 'junit.xml';
if (! is_file($file)) {
    exit(0);
}

$xml = simplexml_load_file($file);
foreach ($xml->xpath('//testcase[failure or error]') as $case) {
    $problem = $case->failure ?: $case->error;
    $message = preg_replace('/\s+/', ' ', substr((string) $problem, 0, 900));
    $title = str_replace(['::', "\n"], ' ', (string) $case['name']);
    echo "::error title={$title}::{$message}".PHP_EOL;
}
