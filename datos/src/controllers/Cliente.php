<?php
namespace App\controllers;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Container\ContainerInterface;
use PDO;
use PDOException;

class Cliente extends Persona
{
    protected $container;
    private const ROL = 4; //?Rol de cliente
    private const RECURSO = "Cliente";
    public function __construct(ContainerInterface $c)
    {
        $this->container = $c;
    }

    public function read(Request $request, Response $response, $args)
    {
        $sql = "SELECT * FROM self::RECURSO ";

        if (isset($args['id'])) {
            $sql .= "WHERE id = :id ";

        }

        $sql .= "LIMIT 0,5;";
        $con = $this->container->get('base_datos');
        $query = $con->prepare($sql);

        if (isset($args['id'])) {
            $query->execute(['id' => $args['id']]);
        } else {
            $query->execute();
        }

        $res = $query->fetchAll();

        $status = $query->rowCount() > 0 ? 200 : 204; //?200 si hay resultados, 204 si no hay resultados

        $query = null;
        $con = null;


        $response->getbody()->write(json_encode($res));
        return $response
            ->withHeader('Content-Type', 'application/json')
            ->withStatus($status);
    }

    public function create(Request $request, Response $response, $args) {
            $body = json_decode($request->getBody(),1);
            $status = $this->createP(self::RECURSO, self::ROL, $body);
            return $response->withStatus($status);           
        }

        public function update(Request $request, Response $response, $args) {
            $body = json_decode($request->getBody(),1);
            $status = $this->updateP(self::RECURSO, $body, $args['id']);
            return $response->withStatus($status);            
        }

        public function delete(Request $request, Response $response, $args) {
            $status = $this->deleteP(self::RECURSO, $args['id']);
            return $response->withStatus($status);
        }
        public function filtrar(Request $request,Response $response, $args) {
           //%idCliente%&%nombre%&%apellido1%&%apellido2
            $datos = $request->getQueryParams();
            $resp = $this->filtrarP(self::RECURSO, $datos, $args['pag'], $args['lim']);
            
            $response->getBody()->write(json_encode($resp['datos']));
            return $response
                ->withHeader('Content-type', 'Application/json')
                ->withStatus($resp['status']);
        }
}
