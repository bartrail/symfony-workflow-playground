<?php

namespace App;

enum Marking : string
{
    case DRAFT = 'draft';
    case REVIEWED = 'reviewed';
    case REJECTED = 'rejected';
    case PUBLISHED = 'published';

//    public static function from(string $marking): self
//    {
//        foreach(self::cases() as $case) {
//            if($case->name === $marking) {
//                return $case;
//            }
//        }
//    }
}
