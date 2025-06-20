<?php

namespace App\Console\Commands;

use Illuminate\Foundation\Console\ServeCommand as BaseServeCommand;

class CustomServeCommand extends BaseServeCommand
{
    /**
     * Get the port for the command.
     *
     * @return int
     */
    protected function port()
    {
        $port = $this->input->getOption('port') ?: 8000;
        
        // Ép kiểu $port thành số nguyên
        if (is_string($port)) {
            $port = (int) $port;
        }
        
        return $port + $this->portOffset;
    }
}
