<?php
namespace App\controllers;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Container\ContainerInterface;
use PDO;


class Message
{
    protected $container;
    public function __construct(ContainerInterface $c)
    {
        $this->container = $c;
    }

    public function sendMessage(Request $request, Response $response)
    {
        
        $body= json_decode($request->getBody());
        $key_d = $this->container->get('key_decript');
        $con = $this->container->get('data_base');
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        $sql = $dbtype == 'pgsql' ? 'SELECT * FROM fn_send_message' : 'CALL sp_send_message';
        $sql .= '(:id_chat_sender, :content_media, :text_content, :id_user, :id_receiver, :key)';
        
        $query = $con->prepare($sql);
        $query->bindParam(':id_chat_sender', $body->id_chat_sender, PDO::PARAM_INT);
        $query->bindParam(':content_media', $body->content_media, PDO::PARAM_STR);
        $query->bindParam(':text_content', $body->text_content, PDO::PARAM_STR);
        $query->bindParam(':id_user', $body->id_user, PDO::PARAM_INT);
        $query->bindParam(':id_receiver', $body->id_receiver, PDO::PARAM_INT);
        $query->bindParam(':key', $key_d, PDO::PARAM_STR);
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 204 : 409;

        $query = null;
        $con = null;
        return $response->withStatus($status);
    }

    public function loadMessage(Request $request, Response $response, $args)
    {
        $key_d = $this->container->get('key_decript');
        $con = $this->container->get('data_base');
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);

        $sql = $dbtype == 'pgsql' ? 'SELECT * FROM fn_load_message(:id_chat,:key)' : 'CALL sp_load_message(:id_chat,:key)';

        $query = $con->prepare($sql);
        $query->bindParam(':id_chat', $args['id_chat'], PDO::PARAM_INT);
        $query->bindParam(':key', $key_d, PDO::PARAM_STR);
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

    public function editMessage(Request $request, Response $response){
        $key_d = $this->container->get('key_decript');
        $body= json_decode($request->getBody());        
        $con= $this->container->get('data_base');        
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        $sql = $dbtype == 'pgsql'? 'SELECT * FROM fn_edit_message':'CALL sp_edit_message';
        $sql .= '(:id_message, :new_text, :key)';
        
        $query = $con->prepare($sql);
        $query->bindParam(':id_message', $body->id_message, PDO::PARAM_INT);
        $query->bindParam(':new_text', $body->new_text, PDO::PARAM_STR);
        $query->bindParam(':key', $key_d, PDO::PARAM_STR);        
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 200 : 204;
        
        $query = null;
        $con = null;
        return $response->withStatus($status);
    }

     public function deleteMessage(Request $request, Response $response, $args){
        $body= json_decode($request->getBody());        
        $con= $this->container->get('data_base');        
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        $sql = $dbtype == 'pgsql'? 'SELECT * FROM fn_deleted_message':'CALL sp_deleted_message';
        $sql .= '(:id_message)';

        $query= $con->prepare($sql);
        $query->bindParam(':id_message', $args['id_message'], PDO::PARAM_INT);
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 200 : 204;
        
        $query = null;
        $con = null;
        return $response->withStatus($status);
    }
}