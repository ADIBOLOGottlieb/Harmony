<?php

namespace App\Filament\Resources\Apartments\Pages;

use App\Filament\Resources\Apartments\ApartmentResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditApartment extends EditRecord
{
    protected static string $resource = ApartmentResource::class;

    protected function mutateFormDataBeforeSave(array $data): array
    {
        if (auth()->user()?->isOwner()) {
            unset($data['owner_id'], $data['featured']);
        }
        $data['rules'] ??= [];
        $data['amenities'] ??= [];

        return $data;
    }

    protected function getHeaderActions(): array
    {
        return [DeleteAction::make()->label('Retirer du catalogue')];
    }
}
