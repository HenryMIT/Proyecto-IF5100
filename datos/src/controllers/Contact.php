<?php
namespace App\controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Container\ContainerInterface;

use PDO;

class Contact{

    protected $container;
    public function __construct(ContainerInterface $c)
    {
        $this->container = $c;
    }

    public function createContact(Request $request, Response $response){
        $body= json_decode($request->getBody());
        $con= $this->container->get('data_base');        
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        
        $sql = $dbtype == 'pgsql'? 'SELECT * FROM fn_create_contact':'CALL sp_create_contact';
        $sql .= '(:id_usr,:contact_number, :contact_name)';
        
        $query=$con->prepare($sql);
        $query->bindParam(':id_usr', $body->id_usr, PDO::PARAM_INT);
        $query->bindParam(':contact_number', $body->contact_number, PDO::PARAM_STR);
        $query->bindParam(':contact_name', $body->contact_name, PDO::PARAM_STR);        
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 204 : 409;
        
        $query = null;
        $con = null;
        return $response->withStatus($status);
    }

        public function loadContact(Request $request, Response $response, $args){

            $data = $request->getQueryParams();                
            $con= $this->container->get('data_base');        
            $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
            
            $sql = $dbtype == 'pgsql'? 'SELECT * FROM fn_load_contact(:lim, :phone_contact, :contact_name, :id_user)':
                                        'CALL sp_load_contact(:lim,:pag, :phone_contact, :contact_name, :id_user)';
            
            $query=$con->prepare($sql);        
            $query->bindValue(':lim', $args['lim'], PDO::PARAM_INT);
            if($dbtype != 'pgsql'){
                $query->bindValue(':pag', $args['pag'], PDO::PARAM_INT);
            }
            foreach ($data as $key => $value) {
                $query->bindValue(":$key", "$value", PDO::PARAM_STR);
            }
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

    public function updateContact(Request $request, Response $response){
        $body= json_decode($request->getBody());        
        $con= $this->container->get('data_base');        
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        $sql = $dbtype == 'pgsql'? 'SELECT * FROM fn_update_contact':'CALL sp_update_contact';
        $sql .= '(:id_contact, :contact_number, :contact_name)';
        
        $query = $con->prepare($sql);
        $query->bindParam(':id_contact', $body->id_usr, PDO::PARAM_INT);
        $query->bindParam(':contact_number', $body->contact_number, PDO::PARAM_STR);
        $query->bindParam(':contact_name', $body->contact_name, PDO::PARAM_STR);        
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 200 : 204;
        
        $query = null;
        $con = null;
        return $response->withStatus($status);
    }

    public function deleteContact(Request $request, Response $response, $args){
        $body= json_decode($request->getBody());        
        $con= $this->container->get('data_base');        
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        $sql = $dbtype == 'pgsql'? 'SELECT * FROM fn_deleted_contact':'CALL sp_deleted_contact';
        $sql .= '(:id_contact)';

        $query= $con->prepare($sql);
        $query->bindParam(':id_contact', $body->id_usr, PDO::PARAM_INT);
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 200 : 204;
        
        $query = null;
        $con = null;
        return $response->withStatus($status);
    }
    
}