<?php
namespace App\Controllers;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Routing\RouteCollectorProxy;


$app->group('/api', function (RouteCollectorProxy $api) {    

    //Autorizador 
    $api->group('/auth', function (RouteCollectorProxy $auth) {
        $auth->patch('/login', Auth::class . ':starts');//X
        $auth->patch('/logout/{idUsuario}', Auth::class . ':close');//X
        $auth->patch('/refresh', Auth::class . ':refresh');//X
        $auth->post('/register', Auth::class . ':register');//X
    });
    //Datos de usuario 
    $api->group('/usr', function(RouteCollectorProxy $endpoint){        
        $endpoint->get('/loadProfile/{id_usr}', Usr::class . ':loadProfile');
        $endpoint->delete('/deletedUser', Usr::class . ':deletedUser');
        $endpoint->put('/reactive', Usr::class . ':reactiveUser');
        $endpoint->put('/update', Usr::class . ':update_User');
    });
    //Datos de contactos
    $api->group('/contact', function(RouteCollectorProxy $endpoint){        
        $endpoint->post('/create', Contact::class . ':createContact');
        $endpoint->get('/load', Contact::class . ':loadContact');
        $endpoint->put('/update', Contact::class . ':updateContact');
        $endpoint->patch('/delete', Contact::class . ':deleteContact');        
    });
    //Datos de Chats
    $api->group('/chat', function(RouteCollectorProxy $endpoint){        
        $endpoint->post('/create', Message::class . ':createChat');
        $endpoint->get('/load', Message::class . ':loadChat');               
    });

    //Datos de mensajes
    $api->group('/message', function(RouteCollectorProxy $endpoint){        
        $endpoint->post('/send', Message::class . ':sendMessage');
        $endpoint->get('/load', Message::class . ':loadMessage');
        $endpoint->put('/edit', Message::class . ':editMessage');
        $endpoint->patch('/delete', Message::class . ':deleteMessage');        
    });

});


