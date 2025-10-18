<?php
$k8s_probe  = getenv("K8S_PROBE");
$k8sHeader  = '';

foreach (getallheaders() as $name => $value) {
    if ($name == "X-K8S-PROBE") {
        $k8sHeader = $value;
        break; //foreach loop
    }
}

// Check for magic header
if ($k8sHeader != $k8s_probe) {
    error_log("Unauthorized health check, got: $k8sHeader expected: $k8s_probe");
    header("HTTP/1.1 403 Forbidden");
    die("Unauthorized health check");
}

// Test basic Wordpress functionality
require_once("wp-config.php");

// Test database connection
@$link = mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
if ( ! $link ) {
    header("HTTP/1.1 503 Service Unavailable");
    echo(     sprintf("Could not connect to the MySQL server: %s"   , @mysqli_error($link)));
    error_log(sprintf("Could not connect to the MySQL server: %s"   , @mysqli_error($link)));
    die(      sprintf( "Could not connect to the MySQL server: %s\n", @mysqli_error($link)));
}
echo "OK";
?>
