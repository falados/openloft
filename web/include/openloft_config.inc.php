<?php
/*	This file is part of OpenLoft.
//
//	OpenLoft is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	OpenLoft is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with OpenLoft.  If not, see <http://www.gnu.org/licenses/>.
//
//	Authors: Falados Kapuskas
*/
defined('OL_INCLUDE') || die("Can't access this page directly");

require_once('http_request.inc.php');
//--Configuration Parameters--//
define('RESPONSE_LEN',2048);
define('FLOAT_PRECISION',3);

//--Subnets for LL Servers--//
$ll_subnets = array(
	'8.2.32.0/22',
	'8.4.128.0/22',
	'8.10.144.0/21',
	'63.210.156.0/22',
	'64.129.40.0/21',
	'64.154.220.0/22',
	'66.150.244.0/23',
	'69.25.104.0/23',
	'72.5.12.0/22',
	'216.82.0.0/18'
);

//--Other Neat Stuff--//

function net_match($network, $ip) {
	  // determines if a network in the form of 192.168.17.1/16 or
	  // 127.0.0.1/255.255.255.255 or 10.0.0.1 matches a given ip
	  $ip_arr = explode('/', $network);
	  $network_long = ip2long($ip_arr[0]);

	  $x = ip2long($ip_arr[1]);
	  $mask =  long2ip($x) == $ip_arr[1] ? $x : 0xffffffff << (32 - $ip_arr[1]);
	  $ip_long = ip2long($ip);

	  // echo ">".$ip_arr[1]."> ".decbin($mask)."\n";
	  return ($ip_long & $mask) == ($network_long & $mask);
}

function fullpath($file){
	$host  = $_SERVER['HTTP_HOST'];
	$uri  = rtrim($_SERVER['PHP_SELF'], "/\\");
	$uri = str_replace(basename($_SERVER['PHP_SELF']),"",$uri);
	return "http://$host$uri$file";
}

$is_ll = FALSE;
foreach( $ll_subnets as $network) {
	if(net_match($network,$_SERVER['REMOTE_ADDR'] )) {
		$is_ll = TRUE;
		break;
	}
}

// -- Process all request headers -- //
$request = new http_request();
$nheaders = array_map('strtolower',$request->headers());
$headers = array();
foreach( $nheaders as $key => $value )
{
	$headers[strtolower($key)] = $value;
}

// -- Put Headers into Variables --//

// -- Simulator Information
$ll_grid = $headers['x-secondlife-shard'];
$ll_region_name = $headers['x-secondlife-region'];

// -- Owner Information
$ll_owner_key = $headers['x-secondlife-owner-key'];
$ll_owner_name = $headers['x-secondlife-owner-name'];

// -- Object Information
$ll_object_key = $headers['x-secondlife-object-key'];
$ll_object_name = $headers['x-secondlife-object-name'];
$ll_object_pos = $headers['x-secondlife-local-position'];
$ll_object_rot = $headers['x-secondlife-local-rotation'];
$ll_object_vel = $headers['x-secondlife-local-velocity'];?>
