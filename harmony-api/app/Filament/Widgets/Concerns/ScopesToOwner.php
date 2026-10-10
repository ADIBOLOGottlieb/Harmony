<?php

namespace App\Filament\Widgets\Concerns;

use Illuminate\Database\Eloquent\Builder;

/** Restreint les indicateurs aux biens du propriétaire connecté. */
trait ScopesToOwner
{
    protected function scopeApartments(Builder $query, string $relation = 'apartment'): Builder
    {
        $user = auth()->user();
        if (! $user?->isOwner()) {
            return $query;
        }

        return $relation === ''
            ? $query->where('owner_id', $user->id)
            : $query->whereHas($relation, fn (Builder $q) => $q->where('owner_id', $user->id));
    }
}
