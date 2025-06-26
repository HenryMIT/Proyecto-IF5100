<?php

use Psr\Container\ContainerInterface;

define('PREF_FILE', '/tmp/preferred_db.txt');

function getPreferredDB()
{
    if (file_exists(PREF_FILE)) {
        $data = json_decode(file_get_contents(PREF_FILE), true);
        if ($data && ($data['time'] + 3000) > time()) {
            return $data['db']; // 'pg' o 'mysql'
        }
    }
    return null;
}
function setPreferredDB($db)
{
    file_put_contents(PREF_FILE, json_encode(['db' => $db, 'time' => time()]));
}

$container->set('data_base', function (ContainerInterface $c) {

    $con = null;
    $error = '';
    $conf = $c->get('config_bd');

    $opc = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_OBJ,
        PDO::ATTR_TIMEOUT => 1
    ];


    $prefer = getPreferredDB();
    if ($prefer === 'pg') {
        try {
            $dsnPG = "pgsql:host=$conf->hostPG;dbname=$conf->db;connect_timeout=1";
            $con = new PDO($dsnPG, $conf->usrPG, $conf->passPG, $opc);
        } catch (PDOException $e) {
            $error = 'Error connecting to PostgreSQL database: ' . $e->getMessage();
        }
    } else if ($prefer === 'mysql') {
        try {
            $dsnMYSQL = "mysql:host=$conf->hostMYSQL;dbname=$conf->db;";
            $con = new PDO($dsnMYSQL, $conf->usrMYSQL, $conf->passMYSQL, $opc);
        } catch (PDOException $e) {
            $error .= '<br>' . 'Error connecting to MySQL database: ' . $e->getMessage();
            die($error);
        }
    } else {
        // try {
        //     $dsnPG = "pgsql:host=$conf->hostPG;dbname=$conf->db;connect_timeout=1";
        //     $con = new PDO($dsnPG, $conf->usrPG, $conf->passPG, $opc);
        //     setPreferredDB('pg');
        // } catch (PDOException $e) {
        //     $error = 'Error connecting to PostgreSQL database: ' . $e->getMessage();
        // }
        if ($con == null) {
            $dsnMYSQL = "mysql:host=$conf->hostMYSQL;dbname=$conf->db;connect_timeout=2";
            try {
                $con = new PDO($dsnMYSQL, $conf->usrMYSQL, $conf->passMYSQL, $opc);
                setPreferredDB('mysql');
            } catch (PDOException $e) {
                $error .= '<br>' . 'Error connecting to MySQL database: ' . $e->getMessage();
                die($error);
            }
        }
    }
    return $con;
});