<?php

namespace App;

enum Transition : string
{
    case TO_REVIEW = 'to-review';
    case PUBLISH = 'publish';
    case REJECT = 'reject';
}
