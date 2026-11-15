<?php
/* ============================================================
   lib/errors.php — error types shared by the website and the API.

   Services throw these. Web pages catch UserError and flash the message;
   the API maps each class to an HTTP status (see api/index.php).
   ============================================================ */

if (class_exists('UserError')) {
    return;
}

/** A problem the user can fix; the message is safe to show (Arabic). → 422 */
class UserError extends Exception
{
    /** @var array<string,string> per-field messages, e.g. ['email' => '...'] */
    public $fields;

    public function __construct($message, array $fields = array())
    {
        parent::__construct($message);
        $this->fields = $fields;
    }
}

/** Record does not exist or does not belong to the caller. → 404 */
class NotFoundError extends UserError {}

/** Duplicate or state clash (email taken, already claimed, …). → 409 */
class ConflictError extends UserError {}

/** Wrong credentials or missing/expired login. → 401 */
class AuthError extends UserError {}

/** Logged in, but not allowed (wrong role, pending admin). → 403 */
class ForbiddenError extends UserError {}
