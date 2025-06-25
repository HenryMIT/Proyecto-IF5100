<?php

namespace App\controllers;
use Attribute;
use Psr\Container\ContainerInterface;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use PDO;

class Auth extends Autenticar
{
    protected $container;
    public function __construct(ContainerInterface $c)
    {
        $this->container = $c;
    }

    private function accessToken(string $proc, string $id_usr, string $tkr = "")
    {
        $con = $this->container->get('data_base');
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);

        $sql = $dbtype == 'pgsql' ? 'SELECT * FROM fn_' : 'CALL sp_';
        $sql .= $proc === "modify" ? "update_tkr" : "verify_tokens";
        $sql .= "(:id_usr, :tkr)";

        $query = $con->prepare($sql);

        $query->execute(['id_usr' => $id_usr, 'tkr' => $tkr]);
        $res = $query->fetch(PDO::FETCH_NUM)[0];

        $query = null;
        $con = null;

        return $res;
    }

    private function modifyToken(string $id_usr, string $tkRef = "")
    {
        return $this->accessToken('modify', $id_usr, $tkRef);
    }

    private function verifyTokens($idUsuario, $tkRef)
    {
        return $this->accessToken('verify', $idUsuario, $tkRef);
    }

    private function generateToken(string $id_usr, string $phone_number, string $username)
    {
        $key = $this->container->get("key");
        $payload = [
            'iss' => $_SERVER['SERVER_NAME'],
            'iat' => time(),
            'exp' => time() + 300,
            'sub' => $id_usr,
            'id_usr' => $id_usr,
            'num' => $phone_number,
            'name' => $username
        ];

        $payloadRef = [
            'iss' => $_SERVER['SERVER_NAME'],
            'iat' => time(),
            'num' => $phone_number,
            'name' => $username
        ];

        return [
            "id_usr" => $id_usr,
            "token" => JWT::encode($payload, $key, 'HS256'),
            "tkRef" => JWT::encode($payloadRef, $key, 'HS256')
        ];

    }

    public function starts(Request $request, Response $response, $args)
    {
        $body = json_decode($request->getBody());

        if ($datos = $this->autenticar($body->phone_number, $body->pass)) {


            $tokens = $this->generateToken($datos['id_usr'], $body->phone_number, $datos['username']);

            $this->modifyToken(id_usr: $datos['id_usr'], tkRef: $tokens['tkRef']);

            $response->getBody()->write(json_encode($tokens));
            $status = 200;
        } else {
            $status = 401;
        }

        return $response->withHeader('Content-type', 'Application/json')->withStatus($status);
    }

    public function close(Request $request, Response $response, $args)
    {
        $this->modifyToken(id_usr: $args['idUsuario']);
        return $response->withStatus(200);
    }

    public function refresh(Request $request, Response $response, $args)
    {
        $body = json_decode($request->getBody());
        $res = $this->verifyTokens($body->id_usr, $body->tkRef);
        $status = 200;

        if ($res > 0) {
            $datos = JWT::decode($body->tkRef, new Key($this->container->get('key'), 'HS256'));
            
            $tokens = $this->generateToken($body->id_usr, $datos->num, $datos->name);
            
            $this->modifyToken(id_usr: $body->id_usr, tkRef: $tokens['tkRef']);
            $response->getBody()->write(json_encode($tokens));
        } else {
            $status = 401;
        }

        return $response->withStatus($status);
    }

    public function register(Request $request, Response $response)
    {
        $body = json_decode($request->getBody());
        $con = $this->container->get('data_base');
        $key_d = $this->container->get('key_decript');
        $dbtype = $con->getAttribute(PDO::ATTR_DRIVER_NAME);
        
        $sql = $dbtype == 'pgsql' ? 'SELECT * FROM fn_register_user' : 'CALL sp_register_user';
        $sql .= "(:username, :phone_number, :email, :pass, :key)";
        
        $query = $con->prepare($sql);
        $query->bindParam(':username', $body->username, PDO::PARAM_STR);
        $query->bindParam(':phone_number', $body->phone_number, PDO::PARAM_STR);
        $query->bindParam(':email', $body->email, PDO::PARAM_STR);
        $query->bindParam(':pass', $body->pass, PDO::PARAM_STR);
        $query->bindParam(':key', $key_d, PDO::PARAM_STR);
        $query->execute();

        $res = $query->fetch(PDO::FETCH_NUM)[0];
        $status = $res > 0 ? 201 : 409;
        
        $query = null;
        $con = null;

        return $response->withStatus($status);
    }
}