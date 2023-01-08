<?php

namespace App\Entity;

use App\Marking;

class BlogPost
{
    // the configured marking store property must be declared
    private Marking $currentPlace;
    private string $title;
    private string $content;

    public function __construct(string $title, string $content)
    {
        $this->title = $title;
        $this->content = $content;
        $this->currentPlace = Marking::DRAFT;
    }

    public function getTitle(): string
    {
        return $this->title;
    }

    public function getContent(): string
    {
        return $this->content;
    }

    public function getCurrentPlace(): Marking
    {
        return $this->currentPlace;
    }

    public function setCurrentPlace(string|Marking $marking): void
    {

        $this->currentPlace = is_string($marking) ? Marking::from($marking) : $marking;
    }
}
