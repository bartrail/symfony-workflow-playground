<?php

namespace App;

enum Marking
{
    case DRAFT;
    case REVIEWED;
    case REJECTED;
    case PUBLISHED;

    public static function from(string $marking): self
    {
        foreach(self::cases() as $case) {
            if($case->name === $marking) {
                return $case;
            }
        }
    }
}
