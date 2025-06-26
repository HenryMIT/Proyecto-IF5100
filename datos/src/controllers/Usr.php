<?php
namespace App\controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Container\ContainerInterface;

use PDO;

class Usr extends Autenticar
{
    public function __construct(ContainerInterface $c)
    {
        $this->container = $c;
    }

    public function loadProfile(Request $request, Response $response, $args)
    {
        $key_decrypt = $this->container->get('key_decript');
        $con = $this->container->get('data_base');
        $bdType = $con->getAttribute(PDO::ATTR_DRIVER_NAME);

        $sql = $bdType == 'pgsql' ? "SELECT * FROM fn_read_Profile" : "CALL sp_read_profile";
        $sql .= "(:id_usr)";

        $query = $con->prepare($sql);
        $query->bindParam(':id_usr', $args['id_usr'], PDO::PARAM_INT);
        $query->execute();

        $res = $query->fetch(PDO::FETCH_ASSOC);
        $status = $res > 0 ? 200 : 204;

        $query = null;
        $con = null;

        //Obtener un a respuesta
        $response->getBody()->write(json_encode($res));
        return $response
            ->withHeader('Content-type', 'Application/json')
            ->withStatus($status);
    }

    public function deletedUser(Request $request, Response $response)
    {
        $body= json_decode($request->getBody());
        $key_d= $this->container->get('key_decript');
        $con= $this->container->get('data_base');        
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        $sql = $dbtype == 'pgsql'? 'SELECT * FROM fn_deleted_user':'CALL sp_delete_user';
        $sql .= '(:id_usr,:pass, :key)';
        $query = $con->prepare($sql);
        
        $query->bindParam(':id_usr', $body->id_usr, PDO::PARAM_INT);
        $query->bindParam(':pass', $body->pass, PDO::PARAM_STR);
        $query->bindParam(':key', $key_d, PDO::PARAM_STR);
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 200 : 204;
        
        $query = null;
        $con = null;

        return $response->withStatus($status);
    }

    public function reactiveUser(Request $request, Response $response){
        $body= json_decode($request->getBody());
        $key_d= $this->container->get('key_decript');
        $con= $this->container->get('data_base');        
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        $sql = $dbtype == 'pgsql'? 'SELECT * FROM fn_reactive_user':'CALL sp_reactive_User';
        $sql .= '(:id_usr,:pass, :key)';
        $query = $con->prepare($sql);
        
        $query->bindParam(':id_usr', $body->id_usr, PDO::PARAM_INT);
        $query->bindParam(':pass', $body->pass, PDO::PARAM_STR);
        $query->bindParam(':key', $key_d, PDO::PARAM_STR);
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 200 : 204;
        
        $query = null;
        $con = null;

        return $response->withStatus($status);    
    }

    public function update_User(Request $request, Response $response){
        $body= json_decode($request->getBody());
        $key_d= $this->container->get('key_decript');
        $con= $this->container->get('data_base');        
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        $sql = $dbtype == 'pgsql'? 'SELECT * FROM fn_update_user':'CALL sp_update_user';
        $sql .= '(:id_usr, :username, :pass, :phone_number, :profile_picture,:profile_description, :key)';
        
        $query = $con->prepare($sql);
        $query->bindParam(':id_usr', $body->id_usr, PDO::PARAM_INT);
        $query->bindParam(':username', $body->username, PDO::PARAM_STR);
        $query->bindParam(':pass', $body->pass, PDO::PARAM_STR);
        $query->bindParam(':phone_number', $body->phone_number, PDO::PARAM_STR);
        $query->bindParam(':profile_picture', $body->phone_number, PDO::PARAM_STR);
        $query->bindParam(':profile_description', $body->phone_number, PDO::PARAM_STR);        
        $query->bindParam(':key', $key_d, PDO::PARAM_STR);
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 200 : 204;
        
        $query = null;
        $con = null;
        return $response->withStatus($status);
    }
}