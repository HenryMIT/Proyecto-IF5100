<?php
    $container->set('config_bd', function(){
        return(object)[
            "hostPG" => $_ENV["hostPG"],
            "portPG" => $_ENV["portPG"],
            "hostMYSQL" => $_ENV["hostMYSQL"],
            "portMYSQL" => $_ENV["portMYSQL"],
            "db" => $_ENV["db"],
            "usrPG" => $_ENV["usrPG"],
            "usrMYSQL" => $_ENV["usrMYSQL"],
            "passPG" => $_ENV["passPG"],
            "passMYSQL" => $_ENV["passMYSQL"]
        ];
    });

    $container->set('key', function(){
        return $_ENV['key'];
    });

    $container->set('key_decript', function(){
        return $_ENV['key_decryption'];
    });