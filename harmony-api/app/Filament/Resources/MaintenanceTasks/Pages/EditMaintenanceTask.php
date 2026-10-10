<?php

namespace App\Filament\Resources\MaintenanceTasks\Pages;

use App\Enums\MaintenanceStatus;
use App\Filament\Resources\MaintenanceTasks\MaintenanceTaskResource;
use Filament\Resources\Pages\EditRecord;

class EditMaintenanceTask extends EditRecord
{
    protected static string $resource = MaintenanceTaskResource::class;

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $status = $data['status'] ?? null;
        $done = $status === MaintenanceStatus::Done || $status === MaintenanceStatus::Done->value;
        $data['completed_at'] = $done ? ($this->record->completed_at ?? now()) : null;

        return $data;
    }
}
