<?php
namespace App\Controllers;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Routing\RouteCollectorProxy;


$app->group('/api', function (RouteCollectorProxy $api) {
    

    $api->group('/cliente', function (RouteCollectorProxy $endpoint) {
        $endpoint->get('/read[/{id}]', Cliente::class . ':read'); 
        $endpoint->post('', Cliente::class . ':create');
        $endpoint->put('/{id}', Cliente::class . ':update');
        $endpoint->delete('/{id}', Cliente::class . ':delete');
        $endpoint->get('/filtrar/{pag}/{lim}', Cliente::class . ':filtrar');
    });

    //Autorizador 
    $api->group('/auth', function (RouteCollectorProxy $auth) {
        $auth->patch('/login', Auth::class . ':starts');//X
        $auth->patch('/logout/{idUsuario}', Auth::class . ':close');//X
        $auth->patch('/refresh', Auth::class . ':refresh');//X
        $auth->post('/register', Auth::class . ':register');//X
    });

    $api->group('/usr', function(RouteCollectorProxy $endpoint){        
        $endpoint->get('/loadProfile/{id_usr}', Usr::class . ':loadProfile');
        $endpoint->delete('/deletedUser', Usr::class . ':deletedUser');
        $endpoint->patch('/reset[/{idUsuario}]', Usr::class . ':resetPassw');
        $endpoint->patch('/change[/{idUsuario}]', Usr::class . ':changePassw');
        $endpoint->patch('/rol[/{idUsuario}]', Usr::class . ':changeRol');
    });
    
});


