<?php

namespace App\Support;

/** Montants en FCFA (entiers) : « 15 000 FCFA », espace fine insécable entre les milliers. */
final class Fcfa
{
    public static function format(?int $amount): string
    {
        return number_format((int) $amount, 0, ',', "\u{202F}")."\u{00A0}FCFA";
    }
}
