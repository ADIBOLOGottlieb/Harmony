<?php

namespace App\Filament\Resources\Apartments\Pages;

use App\Filament\Resources\Apartments\ApartmentResource;
use Filament\Resources\Pages\CreateRecord;

class CreateApartment extends CreateRecord
{
    protected static string $resource = ApartmentResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $user = auth()->user();
        if ($user?->isOwner()) {
            $data['owner_id'] = $user->id; // un propriétaire ne crée que pour lui-même
            $data['featured'] = false;
        }
        $data['listed_at'] ??= now();
        $data['rules'] ??= [];
        $data['amenities'] ??= [];

        return $data;
    }
}
