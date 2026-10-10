<?php

namespace App\Support;

use Illuminate\Support\Facades\Storage;

/**
 * Photos du catalogue. Les chemins « demo/… » sont embarqués dans l'app ;
 * les autres vivent sur le disque configuré (MEDIA_DISK : public en local,
 * stockage S3 compatible en production, le disque de Render étant éphémère).
 */
final class Media
{
    public static function disk(): string
    {
        return (string) config('harmony.media_disk', 'public');
    }

    public static function url(?string $path): ?string
    {
        if ($path === null || $path === '' || str_starts_with($path, 'demo/') || str_starts_with($path, 'http')) {
            return $path;
        }

        return Storage::disk(self::disk())->url($path);
    }
}
