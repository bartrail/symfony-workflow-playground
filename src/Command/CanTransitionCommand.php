<?php

declare(strict_types=1);

namespace App\Command;

use App\Entity\BlogPost;
use App\Marking;
use App\Transition;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Helper\Table;
use Symfony\Component\Console\Helper\TableSeparator;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Workflow\WorkflowInterface;

final class CanTransitionCommand extends Command
{
    public function __construct(
        private readonly WorkflowInterface $blogPublishingStateMachine
    )
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->setName('app:workflow:can');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $table = new Table($output);
        $table->setHeaders(['CurrentPlace', 'Transition', 'Allowed']);

        foreach(Marking::cases() as $marking) {
            foreach(Transition::cases() as $transition) {
                $this->renderRow($marking, $transition, $table);
            }
        }

        $table->addRow(new TableSeparator());

        foreach(Transition::cases() as $transition) {
            foreach(Marking::cases() as $marking) {
                $this->renderRow($marking, $transition, $table);
            }
        }

        $table->render();

        return self::SUCCESS;
    }

    private function renderRow(Marking $marking, Transition $transition, Table $table): void
    {
        $blog = new BlogPost('my Title', 'my Content');
        $blog->setCurrentPlace($marking);

        $table->addRow([
            $blog->getCurrentPlace()->name,
            $transition->name,
            $this->blogPublishingStateMachine->can($blog, $transition) ? 'yes' : 'no'
        ]);
    }
}
