<?php
namespace App\controllers;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Container\ContainerInterface;
use PDO;

class Autenticar
{
    protected $container;

    public function __construct(ContainerInterface $c)
    {
        $this->container = $c;
    }
    public function autenticar($phone_number, $passw)
    {
        $retorns = null;        
        $con = $this->container->get('data_base');      
        $key_d= $this->container->get('key_decript');
        $dbtype=$con->getAttribute(PDO::ATTR_DRIVER_NAME);

        $sql = $dbtype == 'pgsql' ? "SELECT * FROM fn_authorized_user(:phone_number, :pass, :key)":"CALL sp_authorized_user(:phone_number, :pass, :key)";                
        
        $query = $con->prepare($sql);
        $query->bindParam(':phone_number', $phone_number, PDO::PARAM_STR);
        $query->bindParam(':pass', $passw, PDO::PARAM_STR);
        $query->bindParam(':key', $key_d, PDO::PARAM_STR);
        $query->execute();

        $res= $query->fetch(PDO::FETCH_NUM)[0];
        
        if ($res > 0) {
            $retorns['id_usr'] = $res;
            
            //Obtenemos los datos del usuario 
            $sql = $dbtype == 'pgsql'? "SELECT username FROM fn_read_profile(:id_user)":"CALL sp_read_profile(:id_user)";
            $query = $con->prepare($sql);

            $query->bindParam(":id_user", $res);
            $query->execute();
            $datosNombre = $query->fetch(PDO::FETCH_OBJ)->username;
            
            //validamos si hubo se consigui el nombre 
            if ($datosNombre) {
                $retorns["username"] = $datosNombre;
            }

        }

        $query = null;
        $con = null;

        return $retorns; // devuelve los valores obtenidos o null si no se autenticó correctamente
    }

}