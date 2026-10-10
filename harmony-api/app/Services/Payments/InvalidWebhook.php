<?php

namespace App\Services\Payments;

use RuntimeException;

/** Signature de webhook absente, invalide ou trop ancienne. */
final class InvalidWebhook extends RuntimeException {}
