<?php

namespace App\Http\Resources;

use App\Models\User;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin User */
class UserResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'phone' => $this->phone,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role->value,
            'avatar' => Media::url($this->avatar_path),
        ];
    }
}
