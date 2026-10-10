<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\AvatarRequest;
use App\Http\Resources\UserResource;
use App\Support\Media;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/** Photo de profil du client connecté. */
class AvatarController extends Controller
{
    public function store(AvatarRequest $request): UserResource
    {
        $user = $request->user();
        $previous = $user->avatar_path;

        $path = $request->file('photo')->store('avatars', ['disk' => Media::disk(), 'visibility' => 'public']);
        $user->update(['avatar_path' => $path]);

        if ($previous) {
            Storage::disk(Media::disk())->delete($previous);
        }

        return new UserResource($user);
    }

    public function destroy(Request $request): UserResource
    {
        $user = $request->user();
        if ($user->avatar_path) {
            Storage::disk(Media::disk())->delete($user->avatar_path);
            $user->update(['avatar_path' => null]);
        }

        return new UserResource($user);
    }
}
