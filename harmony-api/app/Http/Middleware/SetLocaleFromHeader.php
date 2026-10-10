<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Symfony\Component\HttpFoundation\Response;

/**
 * Langue des messages de l'API selon l'en-tête Accept-Language de l'app (fr par défaut, en).
 * Les textes sont écrits en français et traduits via lang/en.json.
 */
class SetLocaleFromHeader
{
    private const SUPPORTED = ['fr', 'en'];

    public function handle(Request $request, Closure $next): Response
    {
        $language = $request->getPreferredLanguage(self::SUPPORTED) ?? config('app.locale');
        App::setLocale(in_array($language, self::SUPPORTED, true) ? $language : 'fr');

        return $next($request);
    }
}
