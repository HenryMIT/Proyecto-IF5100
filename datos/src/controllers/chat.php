<?php
namespace App\controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Container\ContainerInterface;

use PDO;

class Chat
{

    protected $container;

    public function __construct(ContainerInterface $c)
    {
        $this->container = $c;
    }

    public function createChat(Request $request, Response $response)
    {
        $body = json_decode($request->getBody());
        $con = $this->container->get('data_base');
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);

        $sql = $dbtype == 'pgsql' ? 'SELECT * FROM fn_create_chat' : 'CALL sp_create_chat';
        $sql .= '(:id_usr,:id_contact)';

        $query = $con->prepare($sql);
        $query->bindParam(':id_usr', $body->id_usr, PDO::PARAM_INT);
        $query->bindParam(':id_contact', $body->id_contact, PDO::PARAM_INT);
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 204 : 404;

        $query = null;
        $con = null;
        return $response->withStatus($status);
    }


    public function loadChat(Request $request, Response $response, $args)
    {
        $con = $this->container->get('data_base');
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);

        $sql = $dbtype == 'pgsql' ? 'SELECT * FROM fn_load_chat(:id_user)' : 'CALL sp_load_chat(:id_user)';

        $query = $con->prepare($sql);
        $query->bindParam(':id_user', $args['id_user'], PDO::PARAM_INT);
        $query->execute();
        $res = $query->fetchAll();
        $status = $res > 0 ? 200 : 204;

        $query = null;
        $con = null;

        //Obtener un a respuesta
        $response->getBody()->write(json_encode($res));
        return $response
            ->withHeader('Content-type', 'Application/json')
            ->withStatus($status);
    }
}