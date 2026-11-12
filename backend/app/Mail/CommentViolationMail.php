<?php

namespace App\Mail;

use App\Models\EthicsPolicy;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class CommentViolationMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public User $user,
        public EthicsPolicy $policy,
        public string $contentTitle,
        public string $commentBody,
        public int $pointsDeducted,
        public int $remainingPoints,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Pemberitahuan Pelanggaran Etika & Pengurangan Poin - GrowHub',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.comment-violation',
        );
    }
}

