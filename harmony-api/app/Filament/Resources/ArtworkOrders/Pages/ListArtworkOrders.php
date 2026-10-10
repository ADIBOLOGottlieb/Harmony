<?php

namespace App\Filament\Resources\ArtworkOrders\Pages;

use App\Filament\Resources\ArtworkOrders\ArtworkOrderResource;
use Filament\Resources\Pages\ListRecords;

class ListArtworkOrders extends ListRecords
{
    protected static string $resource = ArtworkOrderResource::class;
}
